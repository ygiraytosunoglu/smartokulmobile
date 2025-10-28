import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/screens/kvkk_screen.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  }

  @override
  void dispose() {
    _tcNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _girisYap(BuildContext context) async {
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
    ]);

    try {
      logger.i("Kullanıcı bilgileri öncesi");

      String sonuc = await ApiService().kullaniciBilgileriniCek(
        _tcNoController.text,
        _passwordController.text,
      );
      logger.i("Kullanıcı bilgilerini çektik: $sonuc");

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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
      _pencereAc(context, "Bir hata oluştu. Tekrar deneyin. $e");
      logger.e("Hata oluştu: $e");
      setState(() {
        _isLoading = false; // hata olursa buton eski haline dönsün
      });
    }
  }

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
