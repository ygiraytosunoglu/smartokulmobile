
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_okul_mobile/screens/devam_durumu_screen.dart';
import 'package:smart_okul_mobile/screens/door_control_page.dart';
import 'package:smart_okul_mobile/screens/etkinlik_screen.dart';
import 'package:smart_okul_mobile/screens/meal_list_screen_new.dart';
import 'package:smart_okul_mobile/screens/photo_gallery_screen.dart';
import 'package:smart_okul_mobile/screens/send_notification_screen_p.dart';
import 'package:smart_okul_mobile/screens/survey_screen.dart';
import 'package:smart_okul_mobile/screens/user_profile_screen.dart';
import 'package:smart_okul_mobile/screens/duyuru_listesi_screen.dart';
import 'package:smart_okul_mobile/screens/send_notification_screen.dart';
import 'package:smart_okul_mobile/screens/send_notification_screen_m.dart';
import 'package:logger/logger.dart';

import 'package:smart_okul_mobile/screens/teacher_students_meal_screen.dart';
import 'package:smart_okul_mobile/screens/parent_student_meal_screen.dart';
import 'package:smart_okul_mobile/screens/login_screen.dart'; // LoginScreen import edildi
import '../constants.dart';
import 'package:http/http.dart' as http;
import 'package:smart_okul_mobile/globals.dart' as globals;
import '../services/api_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight / 6 - 24; // 6 satır, padding 16
    print("home screen "+cardHeight.toString());
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // geri butonu kapatıldı
        title: Text(globals.globalOkulAdi),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Çıkış",
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Çıkış Yap"),
                    content:
                    const Text("Çıkış yapmak istediğinize emin misiniz?"),
                    actions: [
                      TextButton(
                        child: const Text("Hayır"),
                        onPressed: () {
                          Navigator.of(context).pop(); // dialog kapanır
                        },
                      ),
                      TextButton(
                        child: const Text("Evet"),
                        onPressed: () {
                          Navigator.of(context).pop(); // dialog kapanır
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                                (Route<dynamic> route) => false,
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio:
            (MediaQuery.of(context).size.width / 2) / cardHeight,
            padding: const EdgeInsets.all(8),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: <Widget>[
              // if(globals.menuListesi.contains("Kapi")
              //Anons, YemekList, Kapi, GelenDuyurular, YemekUykuBilgisi, Etkinlikler, Galeri, Anketler, DuyuruGonder, Profil,DevamBilgisi
              //if (globals.globalKullaniciTipi == 'P')


              if(globals.menuListesi.contains("Anons"))
                _buildMenuCard(
                  context,
                  'Öğrenci Anons',
                  Icons.campaign,
                  AppColors.primary,
                      () => _bildirim(context),
                ),
              if(globals.menuListesi.contains("AnaKapi")|| globals.menuListesi.contains("Otopark"))
                _buildMenuCard(
                  context,
                  'Kapı Kontrol',
                  Icons.door_front_door,
                  AppColors.primary,
                      () {
                    kapiKontrol(context);
                  },
                ),
              //if (globals.globalKullaniciTipi != 'M')
              if (globals.menuListesi.contains("GelenMesajlar"))
                ValueListenableBuilder<bool>(
                  valueListenable: globals.duyuruVar,
                  builder: (context, duyuruVar, _) {
                    return _buildMenuCard(
                      context,
                      'Gelen Mesajlar',
                      Icons.notifications_active,
                      duyuruVar ? Colors.red : AppColors.primary,
                          () {
                        _duyuruListesiSayfasiniAc(context);
                      },
                    );
                  },
                ),
              //if (["M", "T"].contains(globals.globalKullaniciTipi))
              if(globals.menuListesi.contains("MesajGonder"))
                _buildMenuCard(
                  context,
                  'Mesaj Gönder',
                  Icons.message ,
                  AppColors.primary,
                      () {
                    _bildirimGonderSayfasiniAc(context);
                  },
                ),
              if(globals.menuListesi.contains("Galeri"))
                _buildMenuCard(
                  context,
                  'Galeri',
                  Icons.photo_library,
                  AppColors.primary,
                      () {
                    _galeriSayfasiniAc(context);
                  },
                ),
              if(globals.menuListesi.contains("Etkinlikler"))
                ValueListenableBuilder<bool>(
                  valueListenable: globals.etkinlikVar,
                  builder: (context, etkinlikVar, _) {
                    return _buildMenuCard(
                      context,
                      'Etkinlikler',
                      Icons.event,
                      etkinlikVar ? Colors.red : AppColors.primary,
                          () {
                        _etkinlikSayfasiniAc(context);
                      },
                    );
                  },
                ),
              //if (["P", "T"].contains(globals.globalKullaniciTipi))
              if(globals.menuListesi.contains("YemekUykuBilgisi"))
                _buildMenuCard(
                  context,
                  'Yemek/Uyku Bilgisi',
                  Icons.restaurant,
                  AppColors.primary,
                      () {
                    _gunlukOgrYemekSayfaAc(context);
                  },
                ),
              if(globals.menuListesi.contains("YemekList"))
                _buildMenuCard(
                  context,
                  'Yemek Listesi',
                  Icons.restaurant_menu,
                  AppColors.primary,
                      () {
                    _yemekListesiSayfasiniAc(context);
                  },
                ),
              if(globals.menuListesi.contains("Anketler"))
                ValueListenableBuilder<bool>(
                  valueListenable: globals.anketVar,
                  builder: (context, anketVar, _) {
                    return _buildMenuCard(
                      context,
                      'Anketler',
                      Icons.bar_chart,
                      anketVar ? Colors.red : AppColors.primary,
                          () {
                        _anketSayfasiniAc(context);
                      },
                    );
                  },
                ),

              if(globals.menuListesi.contains("Profil"))
                _buildMenuCard(
                  context,
                  //'Profil/Yoklama'
                  globals.globalKullaniciTipi == "M" ? 'Profil' : 'Profil/Yoklama',
                  Icons.person,
                  AppColors.primary,
                      () => _profilSayfasiniAc(context),
                ),
              //if (["P"].contains(globals.globalKullaniciTipi))
              if(globals.menuListesi.contains("DevamBilgisi"))
                _buildMenuCard(
                  context,
                  'Devam Durumu',
                  Icons.assignment_turned_in,
                  AppColors.primary,
                      () => _devamDurumuSayfasiniAc(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon,
      Color iconColor, VoidCallback onTap) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade100,
              ],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.blue.withOpacity(0.3),
            highlightColor: Colors.blue.withOpacity(0.15),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: iconColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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

  void _duyuruListesiSayfasiniAc(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => DuyuruListesiScreen()));
  }

  void _etkinlikSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => EtkinlikScreen()));
  }

  Future<void> _galeriSayfasiniAc(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(),
      ),
    );
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

  void _profilSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen()));
  }

  void _devamDurumuSayfasiniAc(BuildContext context) {
    final ogrenciler = globals.globalOgrenciListesi;

    if (ogrenciler.length == 1) {
      // Tek öğrenci varsa direkt aç
      String tckn = ogrenciler.first['TCKN'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DevamDurumuScreen(tckn: tckn),
        ),
      );
    } else {
      // Birden fazla öğrenci varsa seçim popup'ı aç
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Öğrenci Seçiniz"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: ogrenciler.length,
                itemBuilder: (context, index) {
                  final ogrenci = ogrenciler[index];
                  return ListTile(
                    title: Text(ogrenci['Name'].toString()), // öğrenci adı
                    onTap: () {
                      Navigator.pop(context); // popup kapat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DevamDurumuScreen(tckn: ogrenci['TCKN']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    }
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

  void _yemekListesiSayfasiniAc(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => MealListScreenNew()));
  }

  void _bildirimGonderSayfasiniAc(BuildContext context) {
    if (["M", "T", "P"].contains(globals.globalKullaniciTipi)) {
      if (globals.globalKullaniciTipi == 'T') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => SendNotificationScreen()));
      }

      if (globals.globalKullaniciTipi == 'M') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => SendNotificationScreenM()));
      }

      if (globals.globalKullaniciTipi == 'P') {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => SendNotificationScreenP()));
      }
    } else {
      _pencereAc(context, "Sadece öğretmenler ve yöneticiler velilere bildirim gönderebilir!");
    }
  }


  void _bildirim(BuildContext context) async {
    print("kullanıcı tipi: ${globals.globalKullaniciTipi}");

    final ogrenciler = globals.globalOgrenciListesi;

    if (globals.globalKullaniciTipi != "P" &&
        globals.globalKullaniciTipi != "S" &&
        globals.globalKullaniciTipi != "H") {
      await _pencereAc(context, "Sadece öğrenci, veli ve hostes öğretmene bildirim gönderebilir!");
      return;
    }

    if (ogrenciler.length == 1) {
      // Tek öğrenci varsa direkt gönder
      String tckn = ogrenciler.first['TCKN'];
      await ApiService().yoklamaEkle(tckn, DateTime.now());
      print("$tckn için yoklama eklendi");

      final cevap = await ApiService().bildirimGonder();

      await _pencereAc(
        context,
        cevap == "200" ? "Öğretmeninize Bildirim gönderildi" : "Bildirim gönderilemedi",
      );
    } else {
      // Çoklu öğrenci seçimi için popup
      int? secilenDurum; // 🔹 artık burada tanımlı
      List<bool> secilen = List.generate(ogrenciler.length, (index) => true);

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  globals.globalKullaniciTipi == "H"
                      ? "Öğretmene/Veliye Bildir"
                      : "Öğretmene Bildir",
                ),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    minWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Eğer kullanıcı hostes ise radio butonlar başta gözüksün
                        if (globals.globalKullaniciTipi == "H") ...[
                          const Text(
                            "Durum Seçiniz",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          RadioListTile<int>(
                            title: const Text("Okula bıraktım"),
                            value: 1,
                            groupValue: secilenDurum,
                            visualDensity: const VisualDensity(vertical: -4),
                            dense: true,
                            onChanged: (value) {
                              setState(() {
                                secilenDurum = value;
                              });
                            },
                          ),
                          RadioListTile<int>(
                            title: const Text("Okuldan aldım"),
                            value: 2,
                            groupValue: secilenDurum,
                            visualDensity: const VisualDensity(vertical: -4),
                            dense: true,
                            onChanged: (value) {
                              setState(() {
                                secilenDurum = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Öğrenci listesi başlığı
                        const Text(
                          "Öğrenci Seçiniz",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Öğrenci listesi
                        ...List.generate(ogrenciler.length, (index) {
                          final ogrenci = ogrenciler[index];
                          return CheckboxListTile(
                            title: Text(
                              ogrenci['Name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 15,
                              ),
                            ),
                            value: secilen[index],
                            visualDensity: const VisualDensity(vertical: -4),
                            dense: true,
                            onChanged: (bool? value) {
                              setState(() {
                                secilen[index] = value ?? false;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Seçili öğrenciler
                      final secilenOgrenciler = <String>[];
                      for (int i = 0; i < ogrenciler.length; i++) {
                        if (secilen[i]) {
                          secilenOgrenciler.add(ogrenciler[i]['TCKN']);
                        }
                      }

                      if (secilenOgrenciler.isEmpty) {
                        await _pencereAc(context, "En az bir öğrenci seçili olmalıdır!");
                        return;
                      }

                      // Eğer hostes ise radio kontrolü
                      if (globals.globalKullaniciTipi == "H" && secilenDurum == null) {
                        await _pencereAc(context, "Lütfen durum seçiniz!");
                        return;
                      }

                      Navigator.pop(context); // popup kapat

                      // Yoklama ekleme (toplu)
                      await ApiService().yoklamaBulkAdd(secilenOgrenciler, DateTime.now());
                      print("Seçilen öğrenciler için yoklama eklendi");

                      // Bildirim gönderme
                      final cevap = await ApiService().sendStudentNotification(
                        schoolId: int.parse(globals.globalSchoolId),
                        senderTckn: globals.kullaniciTCKN,
                        studentTcknList: secilenOgrenciler,
                        durum: globals.globalKullaniciTipi == "H" ? secilenDurum! : 0,
                      );

                      await _pencereAc(
                        context,
                        cevap == "200" ? "Öğretmeninize Bildirim gönderildi" : "Bildirim gönderilemedi",
                      );
                    },
                    child: const Text("Bildir"),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

/*  void _bildirim(BuildContext context) async {
    if (globals.globalKullaniciTipi == "P" || globals.globalKullaniciTipi == "S") {
      for (var ogrenci in globals.globalOgrenciListesi) {
        String tckn = ogrenci['TCKN'];
        await ApiService().yoklamaEkle(tckn, DateTime.now());
        print(tckn+" icin yoklama eklendi");
      }

      _bildirimGonder().then((cevap) {
        if (cevap == "200") {
          _pencereAc(context, "Öğretmeninize Bildirim gönderildi");
        } else {
          _pencereAc(context, "Bildirim gönderilemedi ");
        }
      });
    } else {
      _pencereAc(context,
          "Sadece öğrenci ve veliler öğretmene bildirim gönderebilir!");
    }
  }
*/
  Future _pencereAc(BuildContext context, String mesaj) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(title: Text(mesaj));
      },
    );
  }

  double mesafeHesapla(double enlem1, double boylam1, double enlem2, double boylam2) {
    double mesafe = Geolocator.distanceBetween(enlem1, boylam1, enlem2, boylam2);
    return mesafe;
  }



  /*Future<String> _bildirimGonderHostes() async {
    final String baseUrl = globals.serverAdrr +
        "/api/school/send-notification?schoolId=" +
        globals.globalSchoolId +
        "&TCKN=" +
        globals.kullaniciTCKN;
    Uri uri = Uri.parse(baseUrl);
    print("_bildirimGonder çağırıldı");
    http.Response response = await http.get(uri);
    return Future.delayed(const Duration(seconds: 2), () => response.statusCode.toString());
  }*/
  void kapiKontrol(BuildContext context) async {
    String konum = await konumAlYeni();
    final logger = Logger();

    if (globals.mevcutBoylam != null && globals.mevcutEnlem != null) {
      double mesafe = mesafeHesapla(
          double.parse(globals.globalKonumEnlem),
          double.parse(globals.globalKonumBoylam),
          double.parse(globals.mevcutEnlem),
          double.parse(globals.mevcutBoylam));

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



  Future<String> konumAlYeni() async {
    String _konumBilgisi = "Konum bilgisi bekleniyor...";

    bool servisAktif = await Geolocator.isLocationServiceEnabled();
    if (!servisAktif) {
      _konumBilgisi = "Konum servisi kapalı.";
      return _konumBilgisi;
    }

    LocationPermission izinDurumu = await Geolocator.checkPermission();
    if (izinDurumu == LocationPermission.denied) {
      izinDurumu = await Geolocator.requestPermission();
      if (izinDurumu == LocationPermission.denied) {
        _konumBilgisi = "Konum izni reddedildi.";
        return _konumBilgisi;
      }
    }

    if (izinDurumu == LocationPermission.deniedForever) {
      _konumBilgisi = "Konum izni kalıcı olarak reddedildi.";
      return _konumBilgisi;
    }

    Position konum = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    globals.mevcutEnlem = konum.latitude.toString();
    globals.mevcutBoylam = konum.longitude.toString();

    _konumBilgisi = "Enlem: ${konum.latitude}, Boylam: ${konum.longitude}";

    return _konumBilgisi;
  }

}
