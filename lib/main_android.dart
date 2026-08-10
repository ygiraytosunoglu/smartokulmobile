import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_okul_mobile/screens/login_screen.dart';
import 'package:smart_okul_mobile/services/dio_client.dart';
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

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
      if (tipi == 'mesaj' || tipi == 'message') {
        globals.mesajVar.value = true;
      } else if (tipi == 'duyuru' || tipi == 'announcement') {
        globals.duyuruVar.value = true;
      } else {
        // Tip bilinmiyorsa her ikisini de işaretle
        globals.duyuruVar.value = true;
        globals.mesajVar.value = true;
      }

      _showLocalNotification(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Başlık yok',
      message.notification?.body ?? 'Mesaj yok',
      platformChannelSpecifics,
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
