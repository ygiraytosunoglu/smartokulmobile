import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class YeniGelisimScreen extends StatefulWidget {
  const YeniGelisimScreen({Key? key}) : super(key: key);

  @override
  State<YeniGelisimScreen> createState() => _YeniGelisimScreenState();
}

class _YeniGelisimScreenState extends State<YeniGelisimScreen> {

  /// 📘 Dersler
  List<dynamic> gelisimTipleri = [];
  bool dersLoading = true;

  /// 🧾 Form alanları
  dynamic seciliDers;
  String? seciliOgrenciTckn;

  final TextEditingController aciklamaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    /// Varsayılan ilk öğrenci
    if (globals.globalOgrenciListesi.isNotEmpty) {
      seciliOgrenciTckn =
          globals.globalOgrenciListesi.first['TCKN'].toString();
    }

    _loadGelisimTipleri();
  }

  /// 📘 Dersleri API'den çek
  Future<void> _loadGelisimTipleri() async {
    try {
      final schoolId = int.parse(globals.globalSchoolId.toString());
      final data = await ApiService().getGelisimTipleri(schoolId);

      setState(() {
        gelisimTipleri = data ?? [];
        dersLoading = false;
      });
    } catch (_) {
      setState(() {
        gelisimTipleri = [];
        dersLoading = false;
      });
    }
  }

  @override
  void dispose() {
    aciklamaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.newGrowth,
          style: AppStyles.titleLarge,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,

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

        child: dersLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  /// 📘 Ders
                  DropdownButtonFormField<dynamic>(
                    decoration: InputDecoration(
                      labelText:
                      AppLocalizations.of(context)!.growtType + " *",
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: gelisimTipleri.map((d) {
                      return DropdownMenuItem<dynamic>(
                        value: d,
                        child: Text(d['Ad']+" ("+d['Birim']+")" ?? ''),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        seciliDers = v;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 👨‍🎓 Öğrenci Dropdown
                  DropdownButtonFormField<String>(
                    value: seciliOgrenciTckn,
                    decoration: InputDecoration(
                      labelText:
                      AppLocalizations.of(context)!.students + " *",
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: globals.globalOgrenciListesi.map((ogr) {

                      final tckn = ogr['TCKN'].toString();

                      return DropdownMenuItem<String>(
                        value: tckn,
                        child: Text(ogr['Name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        seciliOgrenciTckn = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  /// 📝 Numeric + Decimal Açıklama
                  TextField(
                    controller: aciklamaCtrl,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText:
                      AppLocalizations.of(context)!.value +
                          " *",
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// 💾 Kaydet
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppStyles.buttonStyle,
                      child: Text(
                          AppLocalizations.of(context)!.save),
                      onPressed: () async {

                        final List<String> secilenOgrenciler = [];

                        if (seciliOgrenciTckn != null) {
                          secilenOgrenciler.add(seciliOgrenciTckn!);
                        }

                        if (seciliDers == null ||
                            aciklamaCtrl.text.trim().isEmpty ||
                            secilenOgrenciler.isEmpty) {

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!
                                    .fillRequiredFields,
                              ),
                            ),
                          );

                          return;
                        }

                        try {
                          await ApiService().addGelisim(
                            tckn: seciliOgrenciTckn!,
                            deger: aciklamaCtrl.text,
                            tipId: seciliDers['Id'],
                          );
                          if (!mounted) return;
                          setState(() {
                            aciklamaCtrl.clear();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.savedAll,
                              ),
                            ),
                          );
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!.saveError,
                              ),
                            ),
                          );
                        }
                      },
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
}