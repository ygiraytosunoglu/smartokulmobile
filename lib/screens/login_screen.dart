import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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

  late Future<SharedPreferences> _prefs;

  @override
  void initState() {
    super.initState();
    //_initializeFirebaseMessaging();
    _prefs = SharedPreferences.getInstance();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kullaniciAdiniKontrolEt(context);
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


  void _kullaniciAdiniKontrolEt(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _tcNoController.text = prefs.getString("kullaniciAdi") ?? "";
    _passwordController.text = prefs.getString("sifre") ?? "";
    _selectedRole = prefs.getString("kullaniciTipi") ?? "P";

    setState(() {}); // ekrana uygula

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
                  const Text(
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
                              labelText: 'Kullanıcı No',
                              hintText: '11 haneli Kullanıcı No giriniz',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'TC Kimlik No boş bırakılamaz';
                              }
                              if (value.length != 11) {
                                return 'TC Kimlik No 11 haneli olmalıdır';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              hintText: 'Şifrenizi giriniz',
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
                                return 'Şifre boş bırakılamaz';
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
                              /*const Text(
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
                                  const Text(
                                    "Kullanıcı Tipi",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedRole,
                                        items: const [
                                          DropdownMenuItem(
                                            value: "T",
                                            child: Text("Öğretmen"),
                                          ),
                                          DropdownMenuItem(
                                            value: "P",
                                            child: Text("Veli"),
                                          ),
                                          DropdownMenuItem(
                                            value: "M",
                                            child: Text("Yönetici"),
                                          ),
                                          DropdownMenuItem(
                                            value: "H",
                                            child: Text("Hostes"),
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
                              _isLoading ? 'Giriş Yapılıyor...' : 'Giriş Yap',
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
                              onPressed: () {
                                _sifremiUnuttum();
                              },
                              child: Text(
                                "Şifremi Unuttum",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    /*return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[700]!,
              Colors.blue[900]!,
            ],
          ),
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
                    /*child: const Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.blue,
                    ),*/
                    child: Image.asset(
                      'assets/smartokul.png',
                      width: 80,   // istediğiniz boyut
                      height: 80,  // istediğiniz boyut
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
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
                      color: Colors.white,
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
                          // TC Kimlik No
                          TextFormField(
                            controller: _tcNoController,
                            keyboardType: TextInputType.number,
                            maxLength: 11,
                            decoration: InputDecoration(
                              labelText: 'Kullanıcı No',
                              hintText: '11 haneli Kullanıcı No giriniz',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.blue, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'TC Kimlik No boş bırakılamaz';
                              }
                              if (value.length != 11) {
                                return 'TC Kimlik No 11 haneli olmalıdır';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Şifre
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              hintText: 'Şifrenizi giriniz',
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
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Colors.blue, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre boş bırakılamaz';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Giriş Butonu
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
                              padding:
                              const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              _isLoading ? 'Giriş Yapılıyor...' : 'Giriş Yap',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  */}

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

    final prefs = await _prefs;
    final logger = Logger();

    await Future.wait([
      prefs.setString("kullaniciAdi", _tcNoController.text),
      prefs.setString("sifre", _passwordController.text),
      prefs.setString("kullaniciTipi", _selectedRole),
    ]);

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
        _pencereAc(context, sonuc);
        setState(() => _isLoading = false);
        return;
      }

      /// 🔐 FCM TOKEN
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
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
      _pencereAc(context, "Bir hata oluştu. Tekrar deneyin.");
      setState(() => _isLoading = false);
    }
  }

/*
  void _girisYap(BuildContext context) async {
    print("Seçilen Rol: $_selectedRole");

    setState(() {
      _isLoading = true; // loading aktif
    });

   // SharedPreferences prefs = await SharedPreferences.getInstance();
    /*await prefs.setString("kullaniciAdi", _tcNoController.text);
    await prefs.setString("sifre", _passwordController.text);*/
    final prefs = await _prefs; // aynı instance kullanılır
    final logger = Logger();

    await Future.wait([
      prefs.setString("kullaniciAdi", _tcNoController.text),
      prefs.setString("sifre", _passwordController.text),
      prefs.setString("kullaniciTipi", _selectedRole),

    ]);

    try {
      logger.i("Kullanıcı bilgileri öncesi");

      String sonuc = await ApiService().kullaniciBilgileriniCek(
        _tcNoController.text,
        _passwordController.text,
          _selectedRole
      );
      logger.i("Kullanıcı bilgilerini çektik: $sonuc");
      // Firebase token al
      String? token = await FirebaseMessaging.instance.getToken();

      logger.i("token:"+token!);
      logger.i("kullaniciTCKN:"+globals.kullaniciTCKN);
     // logger.i("tckn:"+_tcNoController.text);
      bool success = await ApiService().registerFcmToken(globals.kullaniciTCKN, token!);

      if (success) {
        logger.i("🔥 FCM token server'a başarıyla gönderildi");
      } else {
        logger.i("⚠️ FCM token gönderilemedi");
      }


      if (globals.globalStatusCode != "200") {
        _pencereAc(context, globals.globalErrMsg);
        setState(() {
          _isLoading = false; // hata olursa buton eski haline dönsün
        });
        return;
      }
      logger.i("Kullanıcı bilgileri sonrasi");

      // Giriş başarılı ise HomeScreen’e yönlendir
      if (globals.kvkk=="1"){
        if(globals.globalKullaniciTipi=='P' && globals.menuListesi.contains("Anons")){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentNotificationScreen()),
          );
        }
        else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        logger.i("home screen sonrasi");
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const KvkkScreen()),
        );
        logger.i("kvkk screen sonrasi");
      }

      _initializeFirebaseMessaging();
      logger.i("_initializeFirebaseMessaging sonrasi");

    } catch (e) {
      _pencereAc(context, "Bir hata oluştu. Tekrar deneyin.");
      logger.e("Hata oluştu: $e");
      setState(() {
        _isLoading = false; // hata olursa buton eski haline dönsün
      });
    }
  }
*/
  /*Future _pencereAc(BuildContext context, String mesaj) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(title: Text(mesaj));
      },
    );
  }*/
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
