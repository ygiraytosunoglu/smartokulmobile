import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_okul_mobile/screens/forgot_password_screen.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/screens/kvkk_screen.dart';
import 'package:smart_okul_mobile/screens/school_select_screen.dart';
import 'package:smart_okul_mobile/screens/student_notification_screen.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'package:logger/logger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';
import '../utils/error_translator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _tcNoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // loading durumu eklendi
  String _selectedRole = "P";

  late final SharedPreferences _prefs;
  bool _prefsReady = false;

  @override
  void initState() {
    super.initState();
    _yukleBilgileri();
  }

  Future<void> _yukleBilgileri() async {
    // main()'de await SharedPreferences.getInstance() çağrıldığı için
    // bu çağrı anında cache'den döner — async bekleme yaşanmaz
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    _prefs = prefs;
    _prefsReady = true;

    _tcNoController.text     = prefs.getString("kullaniciAdi")  ?? "";
    _passwordController.text = prefs.getString("sifre")         ?? "";

    setState(() {
      _selectedRole = prefs.getString("kullaniciTipi") ?? "P";
    });
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
         /* image: DecorationImage(
            image: AssetImage('assets/images/arka_plan2.png'),
            fit: BoxFit.cover,      // Tüm ekranı kaplasın
          ),*/
          color: AppColors.newAppBar,//const Color(0xFF2E354E),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/smartokul.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Smart Okul Sistemi',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Giriş Formu
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.background,//CColors.white.withOpacity(0.90), // hafif şeffaflık
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _tcNoController,
                            keyboardType: TextInputType.number,
                            maxLength: 11,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.userCode,
                              hintText: AppLocalizations.of(context)!.userHint,
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.userEmpty;
                              }
                              if (value.length != 11) {
                                return AppLocalizations.of(context)!.userLength;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.password,
                              hintText: AppLocalizations.of(context)!.pswHint,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.pswEmpty;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),
// 🔵 Rol Seçimi - Radio Buttons
                          // 🔵 Rol Seçimi - Radio Buttons (yan yana)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /*Text(
                                "Kullanıcı Tipi",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),*/
                              // 🔵 Rol Seçimi - Dropdown
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text(
                                    AppLocalizations.of(context)!.userType,// ,// "Kullanıcı Tipi",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: AppStyles.fieldDecoration,
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedRole,
                                        items:  [
                                          DropdownMenuItem(
                                            value: "T",
                                            child: Text(AppLocalizations.of(context)!.teacher),
                                          ),
                                          DropdownMenuItem(
                                            value: "P",
                                            child: Text(AppLocalizations.of(context)!.parent),
                                          ),
                                          DropdownMenuItem(
                                            value: "M",
                                            child: Text(AppLocalizations.of(context)!.manager),
                                          ),
                                          DropdownMenuItem(
                                            value: "H",
                                            child: Text(AppLocalizations.of(context)!.hostes),
                                          ),
                                        ],
                                        onChanged: (value) async {
                                          setState(() => _selectedRole = value!);
                                          SharedPreferences prefs = await SharedPreferences.getInstance();
                                          await prefs.setString("kullaniciTipi", _selectedRole);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                            ],
                          ),

                          const SizedBox(height: 16),

                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                              if (_formKey.currentState!.validate()) {
                                _girisYap(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isLoading
                                  ? Colors.blue[300]
                                  : Colors.blue[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              _isLoading ? AppLocalizations.of(context)!.enterLoading: AppLocalizations.of(context)!.enter,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // 🔵 Şifremi Unuttum Yazısı
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () { _sifremiUnuttum(); },
                              child: Text(
                                AppLocalizations.of(context)!.pswForget,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 🔒 Gizlilik Politikası linki
                          Center(
                            child: GestureDetector(
                              onTap: () => launchUrl(
                                Uri.parse('https://www.smartokul.com.tr/privacy.html'),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: const Text(
                                'Gizlilik Politikası',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),   // Column
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

  }

  @override
  void dispose() {
    _tcNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _sifremiUnuttum() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
    );
  }
  void _girisYap(BuildContext context) async {
    setState(() => _isLoading = true);

    final logger = Logger();

    if (_prefsReady) {
      await Future.wait([
        _prefs.setString("kullaniciAdi", _tcNoController.text),
        _prefs.setString("sifre",        _passwordController.text),
        _prefs.setString("kullaniciTipi", _selectedRole),
      ]);
    }

    try {
      logger.i("Kullanıcı bilgileri çekiliyor...");

      final sonuc = await ApiService().kullaniciBilgileriniCek(
        _tcNoController.text,
        _passwordController.text,
        _selectedRole,
      );

      logger.i("Login sonucu: $sonuc");

      /// ❌ HATA
      if (sonuc != "OK" && sonuc != "SELECT_SCHOOL") {
        _pencereAc(context, translateError(sonuc, context));
        setState(() => _isLoading = false);
        return;
      }

      /// 🔐 FCM TOKEN
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        // orjKullaniciTCKN: ham TCKN (server bu formatta bekliyor)
        // kullaniciTCKN: "TCKN_schoolId_tip" formatında — registerFcmToken'a gönderilmemeli
        await ApiService().registerFcmToken(globals.kullaniciTCKN, token);
      }

      /// 🟡 1'DEN FAZLA OKUL → OKUL SEÇ
      if (sonuc == "SELECT_SCHOOL") {
        setState(() => _isLoading = false);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SchoolSelectScreen()),
        );
        return;
      }

      /// 🟢 TEK OKUL → NORMAL DEVAM
      setState(() => _isLoading = false);

      if (globals.kvkk == "1") {
        if (globals.globalKullaniciTipi == 'P' &&
            globals.menuListesi.contains("Anons")) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const StudentNotificationScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const KvkkScreen()),
        );
      }

    } catch (e) {
      logger.e("Login hatası", error: e);
      _pencereAc(context, AppLocalizations.of(context)!.enterError);
        //  "Bir hata oluştu. Tekrar deneyin.");
      setState(() => _isLoading = false);
    }
  }

  //performans acısından bu hale getirildi
  Future<void> _pencereAc(BuildContext context, String mesaj) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue, // İstersen burada rengi değiştirebilirsin
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
