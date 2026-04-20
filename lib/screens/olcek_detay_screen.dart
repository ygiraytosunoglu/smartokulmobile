import 'package:flutter/material.dart';
import '../constants.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

class OlcekDetayScreen extends StatefulWidget {
  final dynamic olcek;
  final String tckn;

  const OlcekDetayScreen({
    super.key,
    required this.olcek,
    required this.tckn,
  });

  @override
  State<OlcekDetayScreen> createState() => _OlcekDetayScreenState();
}

class _OlcekDetayScreenState extends State<OlcekDetayScreen> {
  final ApiService apiService = ApiService();

  Map<String, dynamic>? olcekData;
  bool isLoading = true;

  /// 🔹 Seçilen cevaplar
  Map<int, dynamic> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 🔹 API'den veri çek
  Future<void> _loadData() async {
    try {
      final data = await apiService.getOlcekAyrinti(
        olcekId: widget.olcek["Id"],
        tckn: widget.tckn,
      );

      setState(() {
        olcekData = data;
      });
    } catch (e) {
      _showError(e.toString());
      Navigator.pop(context);
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔹 Hata göster
  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 🔹 Gönder
  Future<void> _submit() async {
    if (olcekData == null) return;

    final sorular = olcekData!["Sorular"] as List;

    /// ✅ VALIDATION
    if (selectedAnswers.length != sorular.length) {
      _showError("Lütfen tüm soruları cevaplayın");
      return;
    }

    try {
      print("answers:"+selectedAnswers.toString());
      /// 🔹 Payload oluştur
      final answers = selectedAnswers.entries.map((e) {
        return {
          "soruId": e.key,
          "cevapId": e.value["Id"],
          //"deger": e.value["CevapDegeri"],
        };
      }).toList();
      print("answers map:"+answers.toString());

      await apiService.submitOlcek(
        tckn: widget.tckn,
        olcekId: widget.olcek["Id"],
        cevaplar: answers,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Başarıyla gönderildi")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _showError("Gönderim hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.olcek["Ad"] ?? AppLocalizations.of(context)!.measurement),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body:
      Container(
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : olcekData == null
            ? const Center(child: Text("Veri bulunamadı"))
            : Column(
          children: [
            /// 🔽 SORULAR
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: olcekData!["Sorular"].length,
                itemBuilder: (context, index) {
                  final soru = olcekData!["Sorular"][index];
                  final soruId = soru["Id"];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          /// 🔹 SORU
                          Text(
                            "${soru["SiraNo"]}. ${soru["SoruIcerigi"]}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// 🔹 CEVAPLAR (RADIO)
                          ...soru["Cevaplar"].map<Widget>((cevap) {
                            return RadioListTile<dynamic>(
                              title: Text(
                                  cevap["CevapAciklamasi"]),
                              value: cevap,
                              groupValue:
                              selectedAnswers[soruId],
                              onChanged: (value) {
                                setState(() {
                                  selectedAnswers[soruId] =
                                      value;
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// 🔽 BUTONLAR
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Vazgeç"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text("Gönder"),
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
}