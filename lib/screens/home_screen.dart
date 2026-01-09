import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:smart_okul_mobile/screens/mesaj_ana_screen.dart';
import 'package:smart_okul_mobile/screens/odev_screen.dart';
import 'package:smart_okul_mobile/screens/duyuru_listesi_screen.dart';

import '../constants.dart';
import '../globals.dart' as globals;
import '../services/api_service.dart';

import 'login_screen.dart';
import 'photo_gallery_screen.dart';
import 'plan_screen.dart';
import 'survey_screen.dart';
import 'etkinlik_screen.dart';
import 'meal_screen.dart';
import 'course_schedule_screen.dart';
import 'devam_durumu_screen.dart';
import 'ilac_screen.dart';
import 'user_profile_screen.dart';
import 'door_control_page.dart';
import 'qr_or_code_create_screen.dart';
import 'qr_scan_or_manuel_screen.dart';
import 'student_notification_screen.dart';
import 'teacher_students_meal_screen.dart';
import 'parent_student_meal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? selectedStudent;

  Future<Uint8List?>? _studentPhotoFuture;

  @override
  void initState() {
    super.initState();

    // 👶 Veli ise ilk öğrenciyi otomatik seç
    if (globals.globalKullaniciTipi == 'P' &&
        globals.globalOgrenciListesi.isNotEmpty) {
      selectedStudent = globals.globalOgrenciListesi.first;

      globals.studentTckn = selectedStudent!['TCKN'];
      globals.studentClassId = selectedStudent!['ClassId'];

      _loadStudentPhoto();
    }
  }

 /* void _loadStudentPhoto() async{
    if (selectedStudent == null) return;

    final tckn = selectedStudent!['TCKN'];
    final fotoVersion = selectedStudent!['FotoVersion'].toString();

     _studentPhotoFuture = await ApiService().getPhoto(
      tckn,
      "${tckn}_$fotoVersion",
    );
  }*/

  void _loadStudentPhoto() {
    if (selectedStudent == null) return;

    final tckn = selectedStudent!['TCKN'];
    final fotoVersion = selectedStudent!['FotoVersion'].toString();

    setState(() {
      _studentPhotoFuture = ApiService().getPhoto(
        tckn,
        "${tckn}_$fotoVersion",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ================= APPBAR =================
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 12),

            /// LOGO
            FutureBuilder<Uint8List>(
              future: ApiService().getLogo(globals.kullaniciTCKN),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    snapshot.data!,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                globals.globalOkulAdi,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            },
          )
        ],
      ),

      // ================= BODY =================
      body: SafeArea(
        child: Column(
          children: [
            /// 👶 VELİ ÖĞRENCİ SEÇİCİ
            if (globals.globalKullaniciTipi == 'P')
              _buildStudentSelector(),

            /// ================= GRID =================
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(8),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
                children: [
                  if (globals.menuListesi.contains("GelenMesajlar"))
                  ValueListenableBuilder<bool>(
                    valueListenable: globals.mesajVar,
                    builder: (context, mesajVar, _) {
                      return buildSquareIconButton(context, 'mesajlar.png', "MESAJLAR",() { _mesajSayfasiniAc(context); },
                        showRedBorder: mesajVar, );
                    },
                  ),
                  if (globals.menuListesi.contains("Galeri"))
                    buildSquareIconButton(
                      context,
                      'galeri.png',
                      "GALERİ",
                          () => _galeriSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Anons"))
                    buildSquareIconButton(
                      context,
                      'anons.png',
                      "ANONS",
                          () => _bildirimYeni(context),
                    ),

                /*  if (globals.menuListesi.contains("Plan"))
                    buildSquareIconButton(
                      context,
                      'planlar.png',
                      "PLANLAR",
                          () => _planSayfasiniAc(context),
                    ),*/

                  /*if (globals.menuListesi.contains("YemekList"))
                    buildSquareIconButton(
                      context,
                      'yemekler.png',
                      "YEMEK LİSTESİ",
                          () => _yemekListesiSayfasiniAc(context),
                    ),*/

                  if (globals.menuListesi.contains("Profil"))
                    buildSquareIconButton(
                      context,
                      'profil.png',
                      "PROFİL",
                          () => _profilSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Duyuru"))
                    ValueListenableBuilder<bool>(
                      valueListenable: globals.duyuruVar,
                      builder: (context, duyuruVar, _) {
                        return buildSquareIconButton(context, 'duyurular.png', "DUYURULAR",() { _duyuruListesiSayfasiniAc(context); },
                          showRedBorder: duyuruVar, );
                      },
                    ),
                  if (globals.menuListesi.contains("DevamBilgisi"))
                    buildSquareIconButton(
                      context,
                      'devam.png',
                      "DEVAM BİLGİSİ",
                          () => _devamDurumuSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Ilac"))
                    buildSquareIconButton(
                      context,
                      'ilac.png',
                      "İLAÇ",
                          () => _ilacSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Bulten"))
                    buildSquareIconButton(
                      context,
                      'bultenler.png',
                      "BÜLTENLER",
                          () {},
                    ),

                  if (globals.menuListesi.contains("Servis"))
                    buildSquareIconButton(
                      context,
                      'servis.png',
                      "SERVİS",
                          () {},
                    ),

                  if (globals.menuListesi.contains("Evrak"))
                    buildSquareIconButton(
                      context,
                      'evraklar.png',
                      "EVRAKLAR",
                          () {},
                    ),

                  if(globals.menuListesi.contains("AnaKapi")|| globals.menuListesi.contains("Otopark"))
                    buildSquareIconButton(context, 'kapi.png', "KAPI KONTROL", () { kapiKontrol(context); }),

                  if(globals.menuListesi.contains("Plan"))
                    buildSquareIconButton(context, 'planlar.png', "PLANLAR",() { _planSayfasiniAc(context); }),
                  if(globals.menuListesi.contains("Etkinlikler"))
                    ValueListenableBuilder<bool>(
                      valueListenable: globals.etkinlikVar,
                      builder: (context, etkinlikVar, _) {
                        return buildSquareIconButton(context, 'etkinlikler.png', "ETKINLİKLER",() { _etkinlikSayfasiniAc(context); },
                          showRedBorder: etkinlikVar,);
                      },
                    ),
                  if(globals.menuListesi.contains("YemekUykuBilgisi"))
                    buildSquareIconButton(context, 'gunluk_defterim.png',"GÜNLÜK", () { _gunlukOgrYemekSayfaAc(context); }),
                  if(globals.menuListesi.contains("YemekList"))
                    buildSquareIconButton(context, 'yemekler.png',"YEMEK LİSTESİ", () { _yemekListesiSayfasiniAc(context); }),
                  if(globals.menuListesi.contains("DersProgrami"))
                    buildSquareIconButton(context, 'ders_programi.png', "DERS PROGRAMI",() { _dersProgramiSayfasiniAc(context); }),
                  if(globals.menuListesi.contains("Anketler"))
                    ValueListenableBuilder<bool>(
                      valueListenable: globals.anketVar,
                      builder: (context, anketVar, _) {
                        return buildSquareIconButton(context, 'anketler.png', "ANKETLER",() { _anketSayfasiniAc(context); },
                          showRedBorder: anketVar, );

                      },
                    ),
                  if (globals.menuListesi.contains("Karekod"))
                    buildSquareIconButton(
                      context,
                      'karekod.png',
                      "KAREKOD",
                          () {
                        if (globals.globalKullaniciTipi == 'P' ||
                            globals.globalKullaniciTipi == 'S') {
                          _qrOlusturSayfasiniAc(context);
                        } else {
                          _qrOkutSayfasiniAc(context);
                        }
                      },
                    ),
                if (globals.menuListesi.contains("Odev"))
                    buildSquareIconButton(
                      context,
                      'odevler.png',
                      "ÖDEV",
                            () => _odevSayfasiniAc(context),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== ÖĞRENCİ SEÇİCİ ==================
  Widget _buildStudentSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          /// FOTO
          FutureBuilder<Uint8List?>(
            future: _studentPhotoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircleAvatar(
                  radius: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person),
                );
              }

              return CircleAvatar(
                radius: 22,
                backgroundImage: MemoryImage(snapshot.data!),
              );
            },
          ),

          /*    FutureBuilder<Uint8List?>(
            future: _studentPhotoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircleAvatar(
                  radius: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person),
                );
              }

              return CircleAvatar(
                radius: 22,
                backgroundImage: MemoryImage(snapshot.data!),
              );
            },
          ),
*/
          const SizedBox(width: 12),

          /// DROPDOWN
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                value: selectedStudent,
                items: globals.globalOgrenciListesi.map((ogrenci) {
                  return DropdownMenuItem(
                    value: ogrenci,
                    child: Text(
                      ogrenci['Name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStudent = value;

                    globals.studentTckn = value!['TCKN'];
                    globals.studentClassId = value['ClassId'];

                    _loadStudentPhoto();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== MENU BUTTON ==================
  Widget _menuButton(String icon, String text, VoidCallback onTap) {
    final width = (MediaQuery.of(context).size.width - 32) / 3;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: width,
        height: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/$icon",
              width: width * 0.55,
              height: width * 0.55,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
// ================== KARE BUTON ==================
  Widget buildSquareIconButton(
      BuildContext context,
      String iconName,
      String labelText,
      VoidCallback onTap, {
        bool showRedBorder = false, // 👈 YENİ
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32) / 3;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: cardWidth,
          height: cardWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),

            // 🔴 OKUNMAMIŞ MESAJ VARSA KIRMIZI ÇERÇEVE
            border: showRedBorder
                ? Border.all(color: Colors.red, width: 3)
                : null,

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(3, 3),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 8,
                offset: const Offset(-3, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/icons/$iconName",
                width: cardWidth * 0.55,
                height: cardWidth * 0.55,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                labelText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /*Widget buildSquareIconButton(
      BuildContext context,
      String iconName,
      String labelText,
      VoidCallback onTap,
      ) {
    final cardWidth = (MediaQuery.of(context).size.width - 32) / 3;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: cardWidth,
        height: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/$iconName",
              width: cardWidth * 0.55,
              height: cardWidth * 0.55,
            ),
            const SizedBox(height: 8),
            Text(
              labelText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  // ================== NAVIGATIONS ==================
  void kapiKontrol(BuildContext context) async {
    String konum = await ApiService().konumAlYeni();
    final logger = Logger();

    if (globals.mevcutBoylam != null && globals.mevcutEnlem != null) {
      double mesafe = 0;/* ACILACAK ApiService().mesafeHesapla(
          double.parse(globals.globalKonumEnlem),
          double.parse(globals.globalKonumBoylam),
          double.parse(globals.mevcutEnlem),
          double.parse(globals.mevcutBoylam));*/

      logger.i("okula mesafe " + mesafe.toString());
      if (globals.globalKullaniciTipi=='M' || mesafe < globals.mesafeLimit) {
        int saatKontrol= await ApiService().checkCurrentTime(int.parse(globals.globalSchoolId), globals.globalKullaniciTipi);
        if(saatKontrol==1){
          _kapiKontrolSayfasiniAc(context);
        } else {
          _pencereAc(context, "Kapıyı açmak için saat aralığı uygun değil!");
        }
      }else{
        _pencereAc(context, "Kapıyı açmak için konumunuz uygun değil!");
      }
    } else {
      _pencereAc(context, "Mevcut konum bulunamadı. Konum ayarlarınızı kontrol ediniz!");
    }
  }

  Future _pencereAc(BuildContext context, String mesaj) {
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(title: Text(mesaj));
      },
    );
  }

  void _mesajSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MesajAnaScreen()));
  }
  void _duyuruListesiSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DuyuruListesiScreen(),
      ),
    );

  }

  void _galeriSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => PhotoGalleryScreen()));
  }

  void _planSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => PlanScreen()));
  }

  void _etkinlikSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => EtkinlikScreen()));
  }

  void _yemekListesiSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MealScreen(tckn: globals.kullaniciTCKN)));
  }

  void _profilSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => UserProfileScreen()));
  }

  void _bildirimYeni(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const StudentNotificationScreen()));
  }

  void _qrOlusturSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => QrOrCodeCreateScreen()));
  }

  void _qrOkutSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => QRScanOrManualScreen()));
  }

  void _devamDurumuSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DevamDurumuScreen(tckn: globals.studentTckn!)),
    );
  }
  void _ilacSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IlacScreen()),
    );
  }

  void _odevSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OdevScreen()),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }


  void _anketSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SurveyScreen()));
  }

  void _kapiKontrolSayfasiniAc(BuildContext context) {
    bool vhasGateAccess = true;
    bool vhasParkingAccess = false;

    if (globals.globalKullaniciTipi == "M" || globals.globalKullaniciTipi == "T") {
      vhasParkingAccess = true;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DoorControlPage(
                hasGateAccess: vhasGateAccess, hasParkingAccess: vhasParkingAccess)));
  }

  void _gunlukOgrYemekSayfaAc(BuildContext context) {
    if (globals.globalKullaniciTipi == 'P') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParentStudentsMealScreen(parentTckn: globals.kullaniciTCKN),
        ),
      );
    }
    if (globals.globalKullaniciTipi == 'T') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherStudentsMealScreen(teacherTckn: globals.kullaniciTCKN),
        ),
      );
    }
  }

  void _dersProgramiSayfasiniAc(BuildContext context) async {
    final sinifListesi = globals.globalSinifListesi;

    if (sinifListesi.isEmpty) {
      // Hiç sınıf yoksa uyarı mesajı
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Uyarı"),
          content: const Text("Tanımlı sınıf bulunamadı. Lütfen yönetici ile iletişime geçiniz."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
    }
    else if (sinifListesi.length == 1) {
      // Tek sınıf varsa direkt geçiş
      final sinifId = sinifListesi[0]["Id"];
      print("1 sınıf tanımlı sinifId:"+sinifId.toString());
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseScheduleScreen(sinifId: sinifId),
        ),
      );
    }
    else {
      // Birden fazla sınıf varsa seçim popup'ı
      final secilenSinif = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Sınıf Seçiniz"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: sinifListesi.map<Widget>((sinif) {
                return ListTile(
                  title: Text(sinif["Ad"]),
                  onTap: () {
                    Navigator.pop(context, sinif);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      );

      if (secilenSinif != null) {
        final sinifId = secilenSinif["Id"];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseScheduleScreen(sinifId: sinifId),
          ),
        );
      }
    }
  }

}
/*import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../constants.dart';
import '../globals.dart' as globals;
import '../services/api_service.dart';

import 'login_screen.dart';
import 'duyuru_listesi_screen.dart';
import 'photo_gallery_screen.dart';
import 'plan_screen.dart';
import 'survey_screen.dart';
import 'etkinlik_screen.dart';
import 'meal_screen.dart';
import 'course_schedule_screen.dart';
import 'devam_durumu_screen.dart';
import 'ilac_screen.dart';
import 'user_profile_screen.dart';
import 'door_control_page.dart';
import 'qr_or_code_create_screen.dart';
import 'qr_scan_or_manuel_screen.dart';
import 'student_notification_screen.dart';
import 'teacher_students_meal_screen.dart';
import 'parent_student_meal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Map<String, dynamic>? selectedStudent;

  @override
  void initState() {
    super.initState();

    // 👶 Veli ise ilk öğrenciyi otomatik seç
    if (globals.globalKullaniciTipi == 'P' &&
        globals.globalOgrenciListesi.isNotEmpty) {
      selectedStudent = globals.globalOgrenciListesi.first;

      globals.studentTckn = selectedStudent!['TCKN'];
      globals.studentClassId = selectedStudent!['ClassId'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ================= APPBAR =================
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        toolbarHeight: 70,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 12),

            // LOGO
            FutureBuilder<Uint8List>(
              future: ApiService().getLogo(globals.kullaniciTCKN),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    snapshot.data!,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                globals.globalOkulAdi,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            },
          )
        ],
      ),

      // ================= BODY =================
      body: SafeArea(
        child: Column(
          children: [

            // 👶 VELİ ÖĞRENCİ KARTI
            if (globals.globalKullaniciTipi == 'P')
              _buildStudentSelector(context),

            // ================= GRID =================
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(8),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
                children: [

                  if (globals.menuListesi.contains("GelenMesajlar"))
                    buildSquareIconButton(
                      context,
                      'mesajlar.png',
                      "MESAJLAR",
                          () => _duyuruListesiSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Galeri"))
                    buildSquareIconButton(
                      context,
                      'galeri.png',
                      "GALERİ",
                          () => _galeriSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Anons"))
                    buildSquareIconButton(
                      context,
                      'anons.png',
                      "ANONS",
                          () => _bildirimYeni(context),
                    ),

                  if (globals.menuListesi.contains("Plan"))
                    buildSquareIconButton(
                      context,
                      'planlar.png',
                      "PLANLAR",
                          () => _planSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Etkinlikler"))
                    buildSquareIconButton(
                      context,
                      'etkinlikler.png',
                      "ETKİNLİKLER",
                          () => _etkinlikSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("YemekList"))
                    buildSquareIconButton(
                      context,
                      'yemekler.png',
                      "YEMEK LİSTESİ",
                          () => _yemekListesiSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Profil"))
                    buildSquareIconButton(
                      context,
                      'profil.png',
                      "PROFİL",
                          () => _profilSayfasiniAc(context),
                    ),
                  if (globals.menuListesi.contains("DevamBilgisi"))
                    buildSquareIconButton(
                      context,
                      'devam.png',
                      "DEVAM BİLGİSİ",
                          () => _devamDurumuSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Ilac"))
                    buildSquareIconButton(
                      context,
                      'ilac.png',
                      "İLAÇ",
                          () => _ilacSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Bulten"))
                    buildSquareIconButton(
                      context,
                      'bultenler.png',
                      "BÜLTENLER",
                          () {},
                    ),

                  if (globals.menuListesi.contains("Servis"))
                    buildSquareIconButton(
                      context,
                      'servis.png',
                      "SERVİS",
                          () {},
                    ),

                  if (globals.menuListesi.contains("Evrak"))
                    buildSquareIconButton(
                      context,
                      'evraklar.png',
                      "EVRAKLAR",
                          () {},
                    ),

                  if (globals.menuListesi.contains("Karekod"))
                    buildSquareIconButton(
                      context,
                      'karekod.png',
                      "KAREKOD",
                          () {
                        if (globals.globalKullaniciTipi == 'P' ||
                            globals.globalKullaniciTipi == 'S') {
                          _qrOlusturSayfasiniAc(context);
                        } else {
                          _qrOkutSayfasiniAc(context);
                        }
                      },
                    ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchStudentPhotos() async {
    for (var ogrenci in globals.globalOgrenciListesi) {
      final String tckn = ogrenci['TCKN'];
      final String fotoVersion = ogrenci['FotoVersion'].toString();

       Uint8List? photo = await ApiService.getPhoto(
        tckn,
        "${tckn}_$fotoVersion",
      );

      studentPhotos[tckn] = photo;
    }

    setState(() {});
  }


  // ================== ÖĞRENCİ SEÇİCİ ==================
  Widget _buildStudentSelector(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [

          /// 👤 PROFİL FOTOĞRAFI
          FutureBuilder<Uint8List>(
            future: ApiService().getProfilePhoto(
              selectedStudent?['TCKN'] ?? '',
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircleAvatar(
                  radius: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              return CircleAvatar(
                radius: 22,
                backgroundImage: MemoryImage(snapshot.data!),
              );
            },
          ),

          const SizedBox(width: 12),

          /// 🔽 SADECE İSİM DROPDOWN
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                value: selectedStudent,
                hint: const Text("Öğrenci Seç"),
                items: globals.globalOgrenciListesi.map((ogrenci) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: ogrenci,
                    child: Text(
                      ogrenci['Name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStudent = value;
                    globals.studentTckn = value!['TCKN'];
                    globals.studentClassId = value['ClassId'];
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* Widget _buildStudentSelector(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [

          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: selectedStudent?['PhotoUrl'] != null
                ? NetworkImage(selectedStudent!['PhotoUrl'])
                : null,
            child: selectedStudent?['PhotoUrl'] == null
                ? const Icon(Icons.person, size: 30)
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStudent?['Name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Sınıf: ${selectedStudent?['ClassName'] ?? '-'}",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          if (globals.globalOgrenciListesi.length > 1)
            DropdownButton<Map<String, dynamic>>(
              value: selectedStudent,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down),
              items: globals.globalOgrenciListesi.map((ogrenci) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: ogrenci,
                  child: Text(ogrenci['Name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStudent = value;
                  globals.studentTckn = value!['TCKN'];
                  globals.studentClassId = value['ClassId'];
                });
              },
            ),
        ],
      ),
    );
  }
*/
  // ================== KARE BUTON ==================
  Widget buildSquareIconButton(
      BuildContext context,
      String iconName,
      String labelText,
      VoidCallback onTap,
      ) {
    final cardWidth = (MediaQuery.of(context).size.width - 32) / 3;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: cardWidth,
        height: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/icons/$iconName",
              width: cardWidth * 0.55,
              height: cardWidth * 0.55,
            ),
            const SizedBox(height: 8),
            Text(
              labelText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== NAVIGATIONS ==================
  void _duyuruListesiSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => DuyuruListesiScreen()));
  }

  void _galeriSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => PhotoGalleryScreen()));
  }

  void _planSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => PlanScreen()));
  }

  void _etkinlikSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => EtkinlikScreen()));
  }

  void _yemekListesiSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MealScreen(tckn: globals.kullaniciTCKN)));
  }

  void _profilSayfasiniAc(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => UserProfileScreen()));
  }

  void _bildirimYeni(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const StudentNotificationScreen()));
  }

    void _qrOlusturSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => QrOrCodeCreateScreen()));
    }

    void _qrOkutSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => QRScanOrManualScreen()));
    }

  void _devamDurumuSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DevamDurumuScreen(tckn: globals.studentTckn!)),
    );
  }
  void _ilacSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IlacScreen()),
    );
  }


}
*/