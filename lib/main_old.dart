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
//import 'package:flutterservices.dart';
//import 'package:smart_okul_mobile/generated/l10n.dart';
// Bildirim nesnesi global tanımlanmalı
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 401 durumunda interceptor'dan login'e yönlendirmek için global key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


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
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
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
