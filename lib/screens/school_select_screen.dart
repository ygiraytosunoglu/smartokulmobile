import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/services/api_service.dart';
import 'package:smart_okul_mobile/utils/post_login_navigation.dart';
import '../constants.dart'; // AppColors

class SchoolSelectScreen extends StatefulWidget {
  const SchoolSelectScreen({super.key});

  @override
  State<SchoolSelectScreen> createState() => _SchoolSelectScreenState();
}

class _SchoolSelectScreenState extends State<SchoolSelectScreen> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();

    /// 🟢 TEK OKUL VARSA EKRANI ATLA
    if (globals.secilebilirOkullar.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final selectedPerson = globals.secilebilirOkullar.first;

        ApiService().parsePerson(
          Map<String, dynamic>.from(selectedPerson),
        );
        unawaited(ApiService.fetchLoginCounts());
        unawaited(navigateAfterSuccessfulLogin(context));
      });
    } else if (globals.secilebilirOkullar.isNotEmpty) {
      /// 🟢 ÇOK OKUL VARSA İLKİ SEÇİLİ GELSİN
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.newAppBar,
        elevation: 0,
        title: Text(
          "Okul Seçiniz",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: globals.secilebilirOkullar.isEmpty
          ? const Center(
        child: Text(
          "Seçilebilecek okul bulunamadı",
          style: TextStyle(fontSize: 16),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: globals.secilebilirOkullar.length,
              itemBuilder: (context, index) {
                final Map<String, dynamic> p =
                Map<String, dynamic>.from(
                    globals.secilebilirOkullar[index]);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: RadioListTile<int>(
                    value: index,
                    groupValue: _selectedIndex,
                    activeColor: AppColors.newAppBar,
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      p["SchoolName"] ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    /*subtitle: Text(
                      "SchoolId: ${p["SchoolId"]}",
                    ),*/
                    onChanged: (value) {
                      setState(() {
                        _selectedIndex = value;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          /// 🔵 DEVAM BUTONU
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedIndex == null
                    ? null
                    : () {
                  final selectedPerson =
                  globals.secilebilirOkullar[_selectedIndex!];

                  ApiService().parsePerson(
                    Map<String, dynamic>.from(selectedPerson),
                  );
                  unawaited(ApiService.fetchLoginCounts());
                  unawaited(navigateAfterSuccessfulLogin(context));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.newAppBar,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Devam Et",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
