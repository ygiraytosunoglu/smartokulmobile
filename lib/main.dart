import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_okul_mobile/screens/login_screen.dart';
import 'package:smart_okul_mobile/services/api_service.dart';
import 'package:smart_okul_mobile/services/dio_client.dart';
import 'package:smart_okul_mobile/services/notification_navigation.dart';
import '../globals.dart' as globals;
import 'package:smart_okul_mobile/l10n/app_localizations.dart';
//import 'package:flutterservices.dart';
//import 'package:smart_okul_mobile/generated/l10n.dart';
// Bildirim nesnesi global tanımlanmalı
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 401 durumunda interceptor'dan login'e yönlendirmek için global key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Arka plan isolate'te globals widget tree'ye bağlı değil;
  // ValueNotifier güncellenemez, sadece loglama yapılır.
  print('📩 Arka planda bildirim alındı: ${message.messageId}');
  print('📩 data: ${message.data}');
}
Future<void> _initializeFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  var _token = await messaging.getToken();
  print("FirebaseMessaging Token: $_token");

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    print('Message data: ${message.data}');
  });

  // Token yenilendiğinde server'ı güncelle
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    print('🔄 FCM token yenilendi: $newToken');
    if (globals.kullaniciTCKN.isNotEmpty) {
      await ApiService().registerFcmToken(globals.kullaniciTCKN, newToken);
    }
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences instance'ını baştan cache'le — LoginScreen'de senkron okunabilsin
  await SharedPreferences.getInstance();

  await Firebase.initializeApp();

  // Dio istemcisini başlat — baseUrl, api_service'deki endpoint'lerle örtüşmeli
  DioClient.instance.init(globals.serverAdrr);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      Map<String, dynamic> data = {};
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
        } catch (_) {}
      }
      NotificationNavigation.openFromPush(data);
    },
  );

  // Server'ın kullandığı kanal ID'siyle birebir eşleşen kanalı oluştur
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'smart_okul_channel',
    'Smart Okul Bildirimleri',
    description: 'Smart Okul uygulama bildirimleri',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Sadece dikey yönlendirmeye izin ver
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Uygulama ön plandayken gelen bildirimleri yakala
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Uygulama açıkken bildirim alındı: ${message.notification?.title}');
      print('🔔 data: ${message.data}');

      // Bildirim tipine göre ilgili ValueNotifier'ı güncelle.
      // Sunucu 'tipi' veya 'type' alanıyla tip bilgisi gönderiyorsa kullan;
      // aksi halde her iki notifier da true yapılır — kullanıcı
      // hangisinin geldiğini açarak görecek, okuma sonrası sıfırlanacak.
      final tipi = (message.data['tipi'] ?? message.data['type'] ?? '').toString().toLowerCase();
      final hasGroupId = message.data.keys.any((k) {
        final lower = k.toLowerCase();
        return lower == 'groupid' || lower == 'grupid';
      });
      if (tipi == 'mesaj' || tipi == 'message' || hasGroupId) {
        globals.mesajVar.value = true;
      } else if (tipi == 'duyuru' || tipi == 'announcement') {
        globals.duyuruVar.value = true;
      } else {
        globals.duyuruVar.value = true;
        globals.mesajVar.value = true;
      }

      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationNavigation.openFromPush(message.data);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        NotificationNavigation.openFromPush(message.data);
      }
    });
  }

  String _pushField(Map<String, dynamic> data, List<String> keys) {
    for (final key in data.keys) {
      final lower = key.toString().toLowerCase();
      for (final want in keys) {
        if (lower == want) {
          final v = data[key]?.toString().trim() ?? '';
          if (v.isNotEmpty) return v;
        }
      }
    }
    return '';
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Sunucu bazen sadece data gönderir; notification.title/body null olur.
    // Eski fallback ("Başlık yok" / "Mesaj yok") bu yüzden görünüyordu.
    final title = (message.notification?.title ?? '').trim().isNotEmpty
        ? message.notification!.title!.trim()
        : _pushField(message.data, const [
            'title',
            'baslik',
            'başlık',
            'subject',
          ]);
    final body = (message.notification?.body ?? '').trim().isNotEmpty
        ? message.notification!.body!.trim()
        : _pushField(message.data, const [
            'body',
            'message',
            'mesaj',
            'data',
            'content',
            'aciklama',
          ]);

    if (title.isEmpty && body.isEmpty) {
      print('🔔 Boş bildirim içeriği; yerel bildirim gösterilmedi. data=${message.data}');
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'smart_okul_channel',
      'Smart Okul Bildirimleri',
      channelDescription: 'Smart Okul uygulama bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'smart_okul',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Smart Okul',
      message.notification?.body ?? 'Smart Okul',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const LoginScreen(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: AppLocalizations.supportedLocales
    );

    /*return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('📲 Bildirim Testi'),
        ),
      ),
    );*/
  }
}
