import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'package:smart_okul_mobile/screens/login_screen.dart';
import 'package:smart_okul_mobile/services/dio_client.dart';
import '../globals.dart' as globals;
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

// Bildirim nesnesi global tanımlanmalı
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 401 durumunda interceptor'dan login'e yönlendirmek için global key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Firebase arka plan bildirim handler'ı.
/// Background isolate'te globals ValueNotifier güncellenmemelidir;
/// sadece Firebase initialize edilip loglama yapılır.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('📩 Arka planda bildirim alındı: ${message.messageId}');
  debugPrint('📩 data: ${message.data}');
}

/// Firebase Messaging ve iOS/Android bildirim izinlerini başlatır.
Future<void> initializeFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  final NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  debugPrint(
    '🔔 Bildirim izin durumu: ${settings.authorizationStatus}',
  );

  // FCM token Android ve iOS'ta alınabilir.
  // iOS'ta APNS yapılandırması Firebase tarafında tamamlanmış olmalıdır.
  try {
    final token = await messaging.getToken();
    debugPrint('🔥 ${Platform.isIOS ? 'iOS' : 'Android'} FCM Token: $token');
  } catch (e) {
    debugPrint('⚠️ FCM token alınamadı: $e');
  }

  // Token değişirse tekrar logla.
  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    debugPrint('🔄 FCM Token yenilendi: $token');
    // Gerekirse yeni token backend'e burada gönderilebilir.
  });

  // iOS'ta uygulama açıkken sistem bildirimini göstermek için.
  if (Platform.isIOS) {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📲 Bildirim açıldı: ${message.messageId}');
    debugPrint('📲 data: ${message.data}');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // LoginScreen içerisinde senkron okunabilmesi için SharedPreferences
  // önceden cache'lenir.
  await SharedPreferences.getInstance();

  // Firebase'i platforma uygun firebase_options.dart ile başlat.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Dio istemcisini başlat.
  DioClient.instance.init(globals.serverAdrr);

  // Background Firebase Messaging handler.
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // Local notifications: Android + iOS.
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  await initializeFirebaseMessaging();

  // Sadece dikey yönlendirmeye izin ver.
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

    // Uygulama açıkken gelen Firebase bildirimlerini yakala.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '🔔 Uygulama açıkken bildirim alındı: '
        '${message.notification?.title}',
      );
      debugPrint('🔔 data: ${message.data}');

      _updateNotificationFlags(message);

      // iOS'ta Firebase'in kendi foreground presentation'ı kullanılacağı
      // için local notification tekrar gösterilmez.
      // Android'de local notification gösterilir.
      if (Platform.isAndroid) {
        _showLocalNotification(message);
      }
    });
  }

  void _updateNotificationFlags(RemoteMessage message) {
    final tipi = (message.data['tipi'] ?? message.data['type'] ?? '')
        .toString()
        .toLowerCase();

    if (tipi == 'mesaj' || tipi == 'message') {
      globals.mesajVar.value = true;
    } else if (tipi == 'duyuru' || tipi == 'announcement') {
      globals.duyuruVar.value = true;
    } else {
      // Bildirim tipi bilinmiyorsa her ikisini de işaretle.
      globals.duyuruVar.value = true;
      globals.mesajVar.value = true;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'Bildirim',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const LoginScreen(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
