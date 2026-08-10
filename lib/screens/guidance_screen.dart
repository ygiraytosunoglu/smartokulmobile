import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_okul_mobile/screens/olcek_detay_screen.dart';
import 'dart:convert';
import '../constants.dart';
import '../globals.dart' as globals;
import 'create_survey_screen.dart';
import '../services/api_service.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';
import '../utils/error_translator.dart';

import 'olcek_sonuc_screen.dart';
//import 'olcek_detay_screen.dart'; // 🔥 EKLENDİ

class GuidanceScreen extends StatefulWidget {
  const GuidanceScreen({super.key});

  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  final ApiService apiService = ApiService();

  /// 🔽 YENİ STATE'LER
  List<dynamic> olcekList = [];
  dynamic selectedOlcek;
  bool isOlcekLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchOlcekList(); // ✅ yeni
    _fetchOlcekList(); // ✅ yeni
  }



  /// 🔹 ÖLÇEK LİSTESİ ÇEK
  Future<void> _fetchOlcekList() async {
    setState(() => isOlcekLoading = true);

    try {
      final data = await apiService.getOkulaTanimliOlcekler(tckn: globals.kullaniciTCKN,);
      setState(() {
        olcekList = data;
        if (data.isNotEmpty) {
          selectedOlcek = data[0];
        }
      });
    } catch (e) {
      debugPrint("Olcek hata: $e");
    } finally {
      setState(() => isOlcekLoading = false);
    }
  }

  Future<String> savePdf(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/olcek_sonuc.pdf");

    await file.writeAsBytes(bytes);

    return file.path;
  }

  /// 🔹 SONUÇ GETİR
  Future<void> _getOlcekSonuc() async {
    if (selectedOlcek == null) return;

    try {
      final result="";

      if(selectedOlcek["Dosya"]==0){
        final data = await apiService.getKisiSonuclari(
                                    tckn: globals.kullaniciTCKN,
                                    olcekId: selectedOlcek["Id"],
                                    personId: 0,
                                    okulId: 0
                                    );
        print("Sonuç: $data");
        if (data.isEmpty) {
          // liste boş
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title:  Text(AppLocalizations.of(context)!.result),
              content: Text(AppLocalizations.of(context)!.resultNotFound),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:  Text(AppLocalizations.of(context)!.close),
                )
              ],
            ),
          );
        }
       else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OlcekSonucScreen(
                  sonuclar: List<Map<String, dynamic>>.from(data["Sonuclar"])/*[
                {"Ad": "Sonuç", "Deger": 2.0},
                {"Ad": "Ortalama", "Deger": 0.5},
              ],*/
              ),
            ),
          );
        }


      }


      if(selectedOlcek["Dosya"]==1){
        final data = await apiService.getOlcekSonucPdf(
            tckn: globals.kullaniciTCKN,
            olcekId: selectedOlcek["Id"]
        );
        print("Sonuç pdf: $data");
        String path = await savePdf(data);
        print("dosya kaydedildi");
        await OpenFilex.open(path);
      }

    } catch (e) {
      //debugPrint("Sonuç hata: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title:  Text(""),
          content: Text(translateError(e.toString(), context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  Text(AppLocalizations.of(context)!.close),
            )
          ],
        ),
      );
    }
  }

  /// 🔹 FORM EKRANI
  void _goToForm() {
    if (selectedOlcek == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OlcekDetayScreen(
          olcek: selectedOlcek,
          tckn: globals.kullaniciTCKN
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.guidance,
          textAlign: TextAlign.center,
          style: AppStyles.titleLarge,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withOpacity(0.8),
              AppColors.background.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [

                            if (isOlcekLoading)
                              const CircularProgressIndicator()
                            else if (olcekList.isEmpty)
                              Text("Ölçek bulunamadı")
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonFormField<dynamic>(
                                  dropdownColor: Colors.white,
                                  value: olcekList.contains(selectedOlcek)
                                      ? selectedOlcek
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: "Ölçek Seç",
                                    border: OutlineInputBorder(),
                                  ),
                                  items: olcekList.map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item["Ad"] ?? ""),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedOlcek = value;
                                    });
                                  },
                                ),
                              ),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: selectedOlcek == null
                                        ? null
                                        : _goToForm,
                                    child:  Text(AppLocalizations.of(context)!.fillForm),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: selectedOlcek == null
                                        ? null
                                        : _getOlcekSonuc,
                                    child:  Text(AppLocalizations.of(context)!.getResult),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}