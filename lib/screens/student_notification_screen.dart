import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/screens/home_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';
import 'dart:typed_data';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class StudentNotificationScreen extends StatefulWidget {
  const StudentNotificationScreen({Key? key}) : super(key: key);

  @override
  _StudentNotificationScreenState createState() =>
      _StudentNotificationScreenState();
}

class _StudentNotificationScreenState
    extends State<StudentNotificationScreen> {
  late List<bool> selected;
  bool isButtonEnabled = true;
  final Map<String, Uint8List?> studentPhotos = {};

  @override
  void initState() {
    super.initState();
    selected = List.generate(
        globals.globalOgrenciListesi.length, (index) => true);
    _fetchStudentPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final students = globals.globalOgrenciListesi;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:  Text(
          AppLocalizations.of(context)!.studentNotification,// "Öğrenci Anons",
          style: AppStyles.titleLarge,
        ),
        backgroundColor: AppColors.newAppBar,
        foregroundColor: AppColors.onPrimary,
      ),

      // ✅ SADECE LİSTE
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.newBody,
                AppColors.newBody,
              ],
            ),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final Uint8List? photo =
              studentPhotos[student['TCKN']];

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
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                          photo != null ? MemoryImage(photo) : null,
                          child: photo == null
                              ? const Icon(Icons.person,
                              color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 12),
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
                        Checkbox(
                          value: selected[index],
                          onChanged: (bool? value) {
                            setState(() {
                              selected[index] = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),

      // ✅ ALT BUTONLAR – HER ZAMAN GÖRÜNÜR
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔵 YAKLAŞTIM / BIRAKTIM
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  isButtonEnabled ? () => sendNotification(1) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    globals.globalKullaniciTipi == "H"
                        ? AppLocalizations.of(context)!.notification1 //"Bıraktım"
                        : AppLocalizations.of(context)!.notification2,//"Yaklaştım",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🟢 GELDİM / ALDIM
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  isButtonEnabled ? () => sendNotification(2) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    globals.globalKullaniciTipi == "H"
                        ? AppLocalizations.of(context)!.notification3//"Aldım"
                        : AppLocalizations.of(context)!.notification4, //"Geldim",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🏠 ANA SAYFA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomeScreen()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:  Text(
                    AppLocalizations.of(context)!.mainScreen,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📸 Fotoğrafları getir
  Future<void> _fetchStudentPhotos() async {
    for (var ogrenci in globals.globalOgrenciListesi) {
      final tckn = ogrenci['TCKN'];
      final fotoVersion = ogrenci['FotoVersion'].toString();

      final photo = await ApiService().getPhoto(
        tckn,
        "${tckn}_$fotoVersion",
      );

      studentPhotos[tckn] = photo;
    }
    setState(() {});
  }

  // 📢 Bildirim
  Future<void> sendNotification(int durum) async {
    setState(() => isButtonEnabled = false);

    final students = globals.globalOgrenciListesi;
    final selectedStudents = <String>[];

    for (int i = 0; i < students.length; i++) {
      if (selected[i]) {
        selectedStudents.add(students[i]['TCKN']);
      }
    }

    if (selectedStudents.isEmpty) {
      await _showMessage(AppLocalizations.of(context)!.studentLengthMsg);
      setState(() => isButtonEnabled = true);
      return;
    }

    await ApiService().yoklamaBulkAdd(
      selectedStudents,
      DateTime.now(),
    );

    final response = await ApiService().sendStudentNotification(
      schoolId: int.parse(globals.globalSchoolId),
      senderTckn: globals.kullaniciTCKN,
      studentTcknList: selectedStudents,
      durum: durum,
    );

    await _showMessage(response == "200"
        ? AppLocalizations.of(context)!.notificationSuccessMsg
        : AppLocalizations.of(context)!.notificationFailMsg);

    setState(() => isButtonEnabled = true);

    if (response == "200") {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _showMessage(String msg) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text(msg)),
    );
  }
}
