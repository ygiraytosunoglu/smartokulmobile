import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants.dart';
import '../globals.dart' as globals;
import 'create_survey_screen.dart';
import '../services/api_service.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> surveys = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSurveys();
  }

  Future<void> _fetchSurveys() async {
    setState(() => isLoading = true);
    try {
      final data = await apiService.getSurveysByTckn(globals.kullaniciTCKN);
      setState(() {
        surveys = data;
      });
    } catch (e) {
      debugPrint("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anketler yüklenemedi.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSurveyScreen()),
    );
    if (result == true) {
      _fetchSurveys();
    }
  }

  void _showSurveyDialog(Map<String, dynamic> survey) async {
    // ✅ Eğer cevap verilmişse, uyarı popup olarak göster
    if (survey["Answer"] != null && survey["Answer"].toString().trim().isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Zaten Cevapladınız"),
          content: const Text(
              "Bu anketi daha önce cevapladınız, tekrar cevaplayamazsınız."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
      return;
    }

    final surveyData = jsonDecode(survey["Data"]);
    final surveyId = survey["SurveyId"];
    final List<dynamic> options = surveyData["secenek"];
    String? selectedOption;

    Map<String, dynamic>? summaryData;

    if (["M", "T"].contains(globals.globalKullaniciTipi)) {
      try {
        final classesParam =
        globals.globalSinifListesi.map((c) => c["Id"].toString()).join(",");
        summaryData = await apiService.getSurveySummary(
          surveyId: surveyId,
          tckn: globals.kullaniciTCKN,
          classes: classesParam,
        );
      } catch (e) {
        debugPrint("Summary Hata: $e");
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(surveyData["subject"] ?? "Başlıksız Anket"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(surveyData["aciklama"] ?? ""),
                    const SizedBox(height: 16),
                    if (["P", "S"].contains(globals.globalKullaniciTipi))
                      ...options.map((o) {
                        final optionText = o["secenekAdi"] ?? "";
                        return RadioListTile<String>(
                          title: Text(optionText),
                          value: optionText,
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedOption = value;
                            });
                          },
                        );
                      }).toList(),
                    if (summaryData != null) ...[
                      const Divider(),
                      const Text("Özet:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Colors.grey),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(4),
                                child: Text("Seçenek",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(4),
                                child: Text("Oy Sayısı",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          ...summaryData.entries.map((e) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(e.key),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text("${e.value}"),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kapat"),
                ),
                if (["P", "S"].contains(globals.globalKullaniciTipi))
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedOption == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Lütfen bir seçenek seçin")),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      try {
                        await apiService.submitSurvey(
                          tckn: globals.kullaniciTCKN,
                          surveyId: surveyId,
                          answer: selectedOption!,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cevabınız gönderildi")),
                          );
                        }

                        setState(() {
                          survey["Answer"] = selectedOption; // ✅ artık cevap var
                        });
                      } catch (e) {
                        debugPrint("Submit Hata: $e");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cevap gönderilemedi")),
                          );
                        }
                      }
                    },
                    child: const Text("Gönder"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anket Listesi"),
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
        child: SafeArea(
          child: Column(
            children: [
              if (["M", "T"].contains(globals.globalKullaniciTipi))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createSurvey,
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      label: const Text(
                        "Yeni Anket Oluştur",
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : surveys.isEmpty
                    ? const Center(child: Text("Henüz anket bulunmuyor."))
                    : ListView.builder(
                  itemCount: surveys.length,
                  itemBuilder: (context, index) {
                    final survey = surveys[index];
                    String subject = "Başlıksız";
                    try {
                      final parsed = jsonDecode(survey["Data"]);
                      subject = parsed["subject"] ?? "Başlıksız";
                    } catch (_) {}

                    final answered = survey["Answer"] != null &&
                        survey["Answer"].toString().trim().isNotEmpty;

                    final answerText = answered
                        ? survey["Answer"].toString()
                        : "Cevaplanmamış";

                    return Opacity(
                      opacity: answered ? 0.5 : 1.0, // ✅ Soluk görünüm
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              subject,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text("Cevap: $answerText"),
                            ),
                            leading: const Icon(Icons.poll,
                                size: 36, color: AppColors.primary),
                            onTap: () => _showSurveyDialog(survey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/*import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants.dart';
import '../globals.dart' as globals;
import 'create_survey_screen.dart';
import '../services/api_service.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> surveys = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSurveys();
  }

  Future<void> _fetchSurveys() async {
    setState(() => isLoading = true);
    try {
      final data = await apiService.getSurveysByTckn(globals.kullaniciTCKN);
      setState(() {
        surveys = data;
      });
    } catch (e) {
      debugPrint("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anketler yüklenemedi.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _createSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSurveyScreen()),
    );
    if (result == true) {
      _fetchSurveys();
    }
  }

  void _showSurveyDialog(Map<String, dynamic> survey) async {
    if (survey["answered"] == true) return; // zaten cevaplandıysa açılmasın

    final surveyData = jsonDecode(survey["Data"]);
    final surveyId = survey["SurveyId"];
    final List<dynamic> options = surveyData["secenek"];
    String? selectedOption;

    Map<String, dynamic>? summaryData;

    // Öğretmen veya Müdür ise summary al
    if (["M", "T"].contains(globals.globalKullaniciTipi)) {
      try {
        // classesParam artık globalSinifListesi içindeki Id değerlerinden oluşacak
        final classesParam = globals.globalSinifListesi
            .map((c) => c["Id"].toString())
            .join(",");
        summaryData = await apiService.getSurveySummary(
          surveyId: surveyId,
          tckn: globals.kullaniciTCKN,
          classes: classesParam,
        );
      } catch (e) {
        debugPrint("Summary Hata: $e");
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(surveyData["subject"] ?? "Başlıksız Anket"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(surveyData["aciklama"] ?? ""),
                    const SizedBox(height: 16),
                    // Öğrenci veya veli anket seçenekleri
                    if (["P", "S"].contains(globals.globalKullaniciTipi)) ...options.map((o) {
                      final optionText = o["secenekAdi"] ?? "";
                      return RadioListTile<String>(
                        title: Text(optionText),
                        value: optionText,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedOption = value;
                          });
                        },
                      );
                    }).toList(),
                    // Öğretmen/Müdür veya summary varsa tablo göster
                    if (summaryData != null) ...[
                      const Divider(),
                      const Text("Özet:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Colors.grey),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(4),
                                child: Text("Seçenek", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(4),
                                child: Text("Oy Sayısı", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          ...summaryData.entries.map((e) {
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text(e.key),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Text("${e.value}"),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Kapat"),
                ),
                if (["P", "S"].contains(globals.globalKullaniciTipi))
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedOption == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Lütfen bir seçenek seçin")),
                        );
                        return;
                      }

                      Navigator.pop(context); // popup kapat

                      try {
                        await apiService.submitSurvey(
                          tckn: globals.kullaniciTCKN,
                          surveyId: surveyId,
                          answer: selectedOption!,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cevabınız gönderildi")),
                          );
                        }

                        setState(() {
                          survey["answered"] = true; // tekrar tıklanmayı engelle
                        });
                      } catch (e) {
                        debugPrint("Submit Hata: $e");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cevap gönderilemedi")),
                          );
                        }
                      }
                    },
                    child: const Text("Gönder"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anket Listesi"),
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
        child: SafeArea(
          child: Column(
            children: [
              if (["M", "T"].contains(globals.globalKullaniciTipi))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createSurvey,
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      label: const Text(
                        "Yeni Anket Oluştur",
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : surveys.isEmpty
                    ? const Center(child: Text("Henüz anket bulunmuyor."))
                    : ListView.builder(
                  itemCount: surveys.length,
                  itemBuilder: (context, index) {
                    final survey = surveys[index];
                    String subject = "Başlıksız";
                    try {
                      final parsed = jsonDecode(survey["Data"]);
                      subject = parsed["subject"] ?? "Başlıksız";
                    } catch (_) {}
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          leading: const Icon(Icons.poll, size: 36, color: AppColors.primary),
                          onTap: () => _showSurveyDialog(survey),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/