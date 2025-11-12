import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/screens/home_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';

class StudentNotificationScreen extends StatefulWidget {
  const StudentNotificationScreen({Key? key}) : super(key: key);

  @override
  _StudentNotificationScreenState createState() => _StudentNotificationScreenState();
}

class _StudentNotificationScreenState extends State<StudentNotificationScreen> {
  late List<bool> selected;
  bool isButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    selected = List.generate(globals.globalOgrenciListesi.length, (index) => true);
  }

  @override
  Widget build(BuildContext context) {
    final students = globals.globalOgrenciListesi;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Öğrenci Anons"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
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
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              "Öğrenci Seçiniz",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return CheckboxListTile(
                    title: Text(
                      student['Name'],
                      style: const TextStyle(color: Colors.white),
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
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isButtonEnabled ? () => sendNotification(1) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        globals.globalKullaniciTipi == "H" ? "Bıraktım" : "Yaklaştım",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isButtonEnabled ? () => sendNotification(2) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      child: Text(
                        globals.globalKullaniciTipi == "H" ? "Aldım" : "Geldim",
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
