import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:smart_okul_mobile/screens/gelisim_screen.dart';
import 'package:smart_okul_mobile/screens/guidance_screen.dart';
import 'package:smart_okul_mobile/screens/mesaj_ana_screen.dart';
import 'package:smart_okul_mobile/screens/mesaj_ana_screen_m.dart';
import 'package:smart_okul_mobile/screens/odev_screen.dart';
import 'package:smart_okul_mobile/screens/duyuru_listesi_screen.dart';
import 'package:smart_okul_mobile/screens/photo_gallery_screen_sinif.dart';
import 'package:smart_okul_mobile/screens/academic_record_list_screen.dart';
import 'package:smart_okul_mobile/screens/ders_yonetim_screen.dart';
import 'package:smart_okul_mobile/models/academic_record.dart';

import '../constants.dart';
import '../globals.dart' as globals;
import '../l10n/app_localizations.dart';
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
  late final Future<Uint8List?> _logoFuture;

  @override
  void initState() {
    super.initState();
    _logoFuture = ApiService().getLogo(globals.kullaniciTCKN);

    // 👶 Veli ise ilk öğrenciyi otomatik seç
    if (globals.globalKullaniciTipi == 'P' &&
        globals.globalOgrenciListesi.isNotEmpty) {
      selectedStudent = globals.globalOgrenciListesi.first;

      globals.studentTckn = selectedStudent!['TCKN'];
      globals.studentClassId = selectedStudent!['ClassId'];

      _loadStudentPhoto();
    } else if (globals.globalKullaniciTipi == 'S') {
      // Öğrenci kendi kaydı — devam/ödev vb. studentTckn bekler
      globals.studentTckn = globals.orjKullaniciTCKN.isNotEmpty
          ? globals.orjKullaniciTCKN
          : globals.kullaniciTCKN.split('_').first;
    }
  }

  String _panelLabel() {
    switch (globals.globalKullaniciTipi) {
      case 'P': return 'Veli Paneli';
      case 'T': return 'Öğretmen Paneli';
      case 'M': return 'Yönetici Paneli';
      case 'S': return 'Öğrenci Paneli';
      default:  return '';
    }
  }

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
        toolbarHeight: 76,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const SizedBox(width: 4),

            /// LOGO
            FutureBuilder<Uint8List?>(
              future: _logoFuture,
              builder: (context, snapshot) {
                const size = 52.0;
                Widget empty() => const SizedBox(width: size, height: size);

                if (snapshot.connectionState != ConnectionState.done) {
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }

                final bytes = snapshot.data;
                if (bytes == null || bytes.isEmpty) return empty();

                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    bytes,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => empty(),
                  ),
                );
              },
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    globals.globalOkulAdi,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _panelLabel(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış',
            onPressed: () async {
              await ApiService.clearToken();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                );
              }
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  if (globals.menuListesi.contains("GelenMesajlar"))
                  ValueListenableBuilder<bool>(
                    valueListenable: globals.mesajVar,
                    builder: (context, mesajVar, _) {
                      return buildSquareIconButton(context, 'mesajlar.png', AppLocalizations.of(context)!.messages,() { _mesajSayfasiniAc(context); },
                        showRedBorder: mesajVar, );
                    },
                  ),
                  if (globals.menuListesi.contains("Galeri"))
                    buildSquareIconButton(
                      context,
                      'galeri.png',
                      AppLocalizations.of(context)!.gallery,//"GALERİ",
                          () => _galeriSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Anons"))
                    buildSquareIconButton(
                      context,
                      'anons.png',
                      AppLocalizations.of(context)!.notification,
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
                      AppLocalizations.of(context)!.profile,
                          () => _profilSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Duyuru"))
                    ValueListenableBuilder<bool>(
                      valueListenable: globals.duyuruVar,
                      builder: (context, duyuruVar, _) {
                        return buildSquareIconButton(context, 'duyurular.png', AppLocalizations.of(context)!.anouncement,() { _duyuruListesiSayfasiniAc(context); },
                          showRedBorder: duyuruVar, );
                      },
                    ),
                  if (globals.menuListesi.contains("DevamBilgisi"))
                    buildSquareIconButton(
                      context,
                      'devam.png',
                      AppLocalizations.of(context)!.attendance,
                          () => _devamDurumuSayfasiniAc(context),
                    ),

                  if (globals.menuListesi.contains("Ilac"))
                    buildSquareIconButton(
                      context,
                      'ilac.png',
                      AppLocalizations.of(context)!.medicine,
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
                    buildSquareIconButton(context, 'kapi.png', AppLocalizations.of(context)!.gateControl, () { kapiKontrol(context); }),

                  if(globals.menuListesi.contains("Plan"))
                    buildSquareIconButton(context, 'planlar.png', "PLANLAR",() { _planSayfasiniAc(context); }),
                  if(globals.menuListesi.contains("Etkinlikler"))
                    ValueListenableBuilder<bool>(
                      valueListenable: globals.etkinlikVar,
                      builder: (context, etkinlikVar, _) {
                        return buildSquareIconButton(context, 'etkinlikler.png', AppLocalizations.of(context)!.activities,() { _etkinlikSayfasiniAc(context); },
                          showRedBorder: etkinlikVar,);
                      },
                    ),
                  if(globals.menuListesi.contains("YemekUykuBilgisi"))
                    buildSquareIconButton(context, 'gunluk_defterim.png',AppLocalizations.of(context)!.daily, () { _gunlukOgrYemekSayfaAc(context); }),
                  if(globals.menuListesi.contains("YemekList"))
                    buildSquareIconButton(context, 'yemekler.png',AppLocalizations.of(context)!.mealList, () { _yemekListesiSayfasiniAc(context); }),
                  if(globals.menuListesi.contains("DersProgrami"))
                    buildSquareIconButton(context, 'ders_programi.png', "DERS PROGRAMI",() { _dersProgramiSayfasiniAc(context); }),
                  if(globals.menuListesi.contains("Anketler"))
                    ValueListenableBuilder<bool>(
                      valueListenable: globals.anketVar,
                      builder: (context, anketVar, _) {
                        return buildSquareIconButton(context, 'anketler.png', AppLocalizations.of(context)!.survey,() { _anketSayfasiniAc(context); },
                          showRedBorder: anketVar, );

                      },
                    ),
                  if (globals.menuListesi.contains('OzelDers'))
                    buildSquareIconButton(
                      context,
                      'ders_programi.png',
                      AppLocalizations.of(context)!.privateLesson,
                      () => _ozelDersSayfasiniAc(context),
                    ),
                  if (globals.menuListesi.contains('Etut'))
                    buildSquareIconButton(
                      context,
                      'etut.png',
                      AppLocalizations.of(context)!.tutoring,
                      () => _etutSayfasiniAc(context),
                    ),
                  if (globals.menuListesi.contains('Dersler') ||
                      globals.menuListesi.contains('OkulDersleri'))
                    buildSquareIconButton(
                      context,
                      'bultenler.png',
                      AppLocalizations.of(context)!.schoolLessons,
                      () => _dersYonetimSayfasiniAc(context),
                    ),
                  if(globals.menuListesi.contains("Rehberlik"))
                    ValueListenableBuilder<bool>(
                      valueListenable: globals.anketVar,
                      builder: (context, anketVar, _) {
                        return buildSquareIconButton(context, 'rehberlik.png', AppLocalizations.of(context)!.guidanceTitle,() { _rehberlikSayfasiniAc(context); },
                          showRedBorder: anketVar, );

                      },
                    ),
                  if (globals.menuListesi.contains("Karekod"))
                    buildSquareIconButton(
                      context,
                      'karekod.png',
                      AppLocalizations.of(context)!.qrCode,
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
                      AppLocalizations.of(context)!.homework,
                            () => _odevSayfasiniAc(context),
                    ),
                if (globals.menuListesi.contains("Gelisim"))
                    buildSquareIconButton(
                      context,
                      'gelisim.png',
                      AppLocalizations.of(context)!.gelisimTitle,
                          () => _gelisimSayfasiniAc(context),
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                return CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.divider,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.divider,
                  child: const Icon(Icons.person, color: AppColors.textSecondary),
                );
              }

              return CircleAvatar(
                radius: 22,
                backgroundImage: MemoryImage(snapshot.data!),
              );
            },
          ),

          const SizedBox(width: 12),

          /// DROPDOWN
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                value: selectedStudent,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                items: globals.globalOgrenciListesi.map((ogrenci) {
                  return DropdownMenuItem(
                    value: ogrenci,
                    child: Text(
                      ogrenci['Name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
        bool showRedBorder = false,
      }) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 3 sütun + 2 boşluk (16px) + kenar (16+16)
    final cardWidth = (screenWidth - 32 - 32) / 3;

    return Container(
      width: cardWidth,
      height: cardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          // Uzak, yumuşak gölge — derinlik hissi
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
          // Yakın, keskin gölge — zemin ayrımı
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          // Üst vurgu — ışık yansıması (kaldırılmış gibi görünür)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.95),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                const Color(0xFFECF1F7),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: showRedBorder
                ? Border.all(color: AppColors.primary, width: 2)
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            splashColor: AppColors.secondary.withValues(alpha: 0.18),
            highlightColor: AppColors.primary.withValues(alpha: 0.07),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showRedBorder)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.asset(
                        "assets/icons/$iconName",
                        width: cardWidth * 0.52,
                        height: cardWidth * 0.52,
                        fit: BoxFit.contain,
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  )
                else
                  Image.asset(
                    "assets/icons/$iconName",
                    width: cardWidth * 0.52,
                    height: cardWidth * 0.52,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    labelText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
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
    if (globals.globalKullaniciTipi == 'M'){
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => MesajAnaScreenM()));
    } else {
      Navigator.push(context,
        MaterialPageRoute(builder: (_) => MesajAnaScreen(tckn:globals.kullaniciTCKN)));
    }

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
    if (globals.menuListesi.contains("GaleriSecim")){
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => PhotoGalleryScreen()));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => PhotoGalleryScreenSinif()));
    }
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

  String? _aktifOgrenciTckn() {
    if (globals.globalKullaniciTipi == 'S') {
      if (globals.orjKullaniciTCKN.isNotEmpty) return globals.orjKullaniciTCKN;
      final parts = globals.kullaniciTCKN.split('_');
      return parts.isNotEmpty ? parts.first : null;
    }
    final t = (globals.studentTckn ?? '').trim();
    return t.isEmpty ? null : t;
  }

  void _devamDurumuSayfasiniAc(BuildContext context) {
    final tckn = _aktifOgrenciTckn();
    if (tckn == null || tckn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selectStudentError)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DevamDurumuScreen(tckn: tckn)),
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

  void _gelisimSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GelisimScreen()),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }


  void _anketSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SurveyScreen()));
  }

  void _ozelDersSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AcademicRecordListScreen(
          type: AcademicRecordType.ozelDers,
        ),
      ),
    );
  }

  void _etutSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AcademicRecordListScreen(
          type: AcademicRecordType.etut,
        ),
      ),
    );
  }

  void _dersYonetimSayfasiniAc(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DersYonetimScreen()),
    );
  }

  void _rehberlikSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => GuidanceScreen()));
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
          title: Text("Uyarı"),
          content: Text("Tanımlı sınıf bulunamadı. Lütfen yönetici ile iletişime geçiniz."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tamam"),
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
          title: Text("Sınıf Seçiniz"),
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
                hint: Text("Öğrenci Seç"),
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