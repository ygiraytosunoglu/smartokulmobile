import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/screens/home_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class StudentNotificationScreen extends StatefulWidget {
  const StudentNotificationScreen({Key? key}) : super(key: key);

  @override
  _StudentNotificationScreenState createState() => _StudentNotificationScreenState();
}

class _StudentNotificationScreenState extends State<StudentNotificationScreen> {
  late List<bool> selected;
  bool isButtonEnabled = true;
  final Map<String, Uint8List?> studentPhotos = {};

  @override
  void initState() {
    super.initState();
    selected = List.generate(globals.globalOgrenciListesi.length, (index) => true);
    _fetchStudentPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final students = globals.globalOgrenciListesi;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 👈 GERİ TUŞUNU KALDIRIR
        title: const
        Text(
            "Öğrenci Anons",
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),
        backgroundColor: AppColors.newAppBar,//.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.newBody, //.primary.withOpacity(0.8),
              AppColors.newBody//primary.withOpacity(0.6),
            ],
          ),
        ),
        child: Column(
          children: [
            /*const SizedBox(height: 12),
            const Text(
              "Öğrenci Seçiniz",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),*/
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final Uint8List? photo = studentPhotos[student['TCKN']];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          selected[index] = !selected[index];
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            // FOTOĞRAF
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: photo != null ? MemoryImage(photo) : null,
                              child: photo == null
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),

                            const SizedBox(width: 12),

                            // İSİM
                            Expanded(
                              child: Text(
                                student['Name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),

                            // CHECKBOX
                            Checkbox(
                              value: selected[index],
                              onChanged: (bool? value) {
                                setState(() {
                                  selected[index] = value ?? false;
                                });
                              },
                              checkColor: Colors.white,
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },

                /*  itemBuilder: (context, index) {
                  /*final student = students[index];
                  return CheckboxListTile(
                    title: Text(
                      student['Name'],
                      style: const TextStyle(color: AppColors.primary),
                    ),
                    value: selected[index],
                    onChanged: (bool? value) {
                      setState(() {
                        selected[index] = value ?? false;
                      });
                    },
                    checkColor: AppColors.primary,
                    activeColor: Colors.white,
                  );
                */
                  final student = students[index];
                  final Uint8List? photo = studentPhotos[student['TCKN']];

                  return CheckboxListTile(
                    secondary: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: photo != null ? MemoryImage(photo) : null,
                      child: photo == null
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(
                      student['Name'],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: selected[index],
                    onChanged: (bool? value) {
                      setState(() {
                        selected[index] = value ?? false;
                      });
                    },
                    checkColor: AppColors.primary,
                    activeColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                },
              */),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // YAKLAŞTIM / BIRAKTIM → MAVİ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isButtonEnabled ? () => sendNotification(1) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                      child: Text(
                        globals.globalKullaniciTipi == "H" ? "Bıraktım" : "Yaklaştım",
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // GELDİM / ALDIM → YEŞİL
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isButtonEnabled ? () => sendNotification(2) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                      child: Text(
                        globals.globalKullaniciTipi == "H" ? "Aldım" : "Geldim",
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // GELDİM / ALDIM → YEŞİL
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isButtonEnabled ? () =>         Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      ) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                      child: Text("Ana Sayfa",
                      ),
                    ),
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
      String tckn = ogrenci['TCKN'];
      String fotoVersion = ogrenci['FotoVersion'].toString();

      Uint8List? photo = await ApiService().getPhoto(
        tckn,
        "${tckn}_$fotoVersion",
      );

      studentPhotos[tckn] = photo;
    }
    setState(() {});
  }
/*
  Future<Uint8List?> _getPhoto(String tckn, String fotoName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/$fotoName.jpg');

      if (await localFile.exists()) {
        return await localFile.readAsBytes();
      }

      try {
        final byteData =
        await rootBundle.load('assets/images/$fotoName.jpg');
        return byteData.buffer.asUint8List();
      } catch (_) {}

      final response = await http.get(Uri.parse(
        '${globals.serverAdrr}/api/school/get-person-photo?tckn=$tckn',
      ));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await localFile.writeAsBytes(bytes);
        return bytes;
      }
    } catch (e) {
      print('⚠️ Fotoğraf getirme hatası: $e');
    }
    return null;
  }
*/

  Future<int> mesafeKontrol(int tip) async {
    if (globals.globalKullaniciTipi == "P") {
      String konum = await ApiService().konumAlYeni();
      final logger = Logger();
      double mesafe = 100000000;
      if (globals.mevcutBoylam != null && globals.mevcutEnlem != null) {
        mesafe = ApiService().mesafeHesapla(
          double.parse(globals.globalKonumEnlem),
          double.parse(globals.globalKonumBoylam),
          double.parse(globals.mevcutEnlem),
          double.parse(globals.mevcutBoylam),
        );
      }
      print("mesafe: $mesafe");
      if (tip == 1 && mesafe > globals.mesafeLimit) {
        _pencereAc(context, "Okula mesafeniz uygun değil!");
        return 0;
      } else if (tip == 2 && mesafe > 100) {
        _pencereAc(context, "Okula mesafeniz uygun değil!");
        return 0;
      }
    }
    return 1;
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

  Future<void> sendNotification(int durum) async {
    setState(() {
      isButtonEnabled = false;
    });
/*ACILACAK ?????????
    if(!globals.globalKullaniciTipi == "H"){
      int mesafeKont = await mesafeKontrol(durum);

      if (mesafeKont == 0) {
        setState(() {
          isButtonEnabled = true;
        });
        return;
      }
    }*/


    final students = globals.globalOgrenciListesi;
    final selectedStudents = <String>[];

    for (int i = 0; i < students.length; i++) {
      if (selected[i]) selectedStudents.add(students[i]['TCKN']);
    }

    if (selectedStudents.isEmpty) {
      await showMessage("En az bir öğrenci seçili olmalıdır!");
      setState(() {
        isButtonEnabled = true;
      });
      return;
    }

    await ApiService().yoklamaBulkAdd(selectedStudents, DateTime.now());
    final response = await ApiService().sendStudentNotification(
      schoolId: int.parse(globals.globalSchoolId),
      senderTckn: globals.kullaniciTCKN,
      studentTcknList: selectedStudents,
      durum: durum,
    );

    if (response == "200") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Öğretmeninize Bildirim gönderildi'),
          backgroundColor: Colors.green,
        ),
      );
    }

    await showMessage(response == "200"
        ? "Öğretmeninize Bildirim gönderildi"
        : "Bildirim gönderilemedi");

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      isButtonEnabled = true;
    });

    if (response == "200") {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> showMessage(String msg) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text(msg)),
    );
  }
}
