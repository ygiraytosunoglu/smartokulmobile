import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'globals.dart' as globals;
import 'package:smart_okul_mobile/screens/login_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🔥 BACKGROUND HANDLER
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  globals.duyuruVar.value = true;
  debugPrint('📩 Background message: ${message.messageId}');
}

Future<void> initializeFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  /// 🔐 Permission (iOS & Android)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  /// ✅ SADECE ANDROID TOKEN ALIR
  if (Platform.isAndroid) {
    final token = await messaging.getToken();
    debugPrint('🔥 Android FCM Token: $token');
    // backend’e gönder
  }

  /// ❌ iOS’ta token / APNS / onTokenRefresh YOK
  /// ❌ Simulator’da APNS olmadığı için bu bilinçli kapalı

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📨 Foreground message');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📲 Notification opened');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// ✅ TEK VE DOĞRU INIT
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const iosSettings = DarwinInitializationSettings();

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  await initializeFirebaseMessaging();

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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      globals.duyuruVar.value = true;
      _showLocalNotification(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Genel Bildirimler',
      channelDescription: 'Smart Okul bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'Bildirim',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
