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
      setState(() => surveys = data);
    } catch (e) {
      debugPrint("Hata: $e");
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

  // 🔹 CEVAPLARI SEÇENEĞE GÖRE GRUPLA
  Map<String, List<String>> _groupAnswers(
      Map<String, dynamic> summaryData,
      List<dynamic> options,
      ) {
    final Map<String, List<String>> grouped = {};

    // seçenek anahtarları (a,b,c)
    for (var o in options) {
      grouped[o["secenekKey"] ?? o["secenekAdi"]] = [];
    }

    grouped["Cevapsız"] = [];

    final detay = summaryData["detay"] as Map<String, dynamic>;

    detay.forEach((kisi, cevap) {
      if (cevap == "-" || cevap == null) {
        grouped["Cevapsız"]!.add(kisi);
      } else {
        grouped.putIfAbsent(cevap, () => []);
        grouped[cevap]!.add(kisi);
      }
    });

    return grouped;
  }

  Future<String?> _showSurveyDialog(Map<String, dynamic> survey) async {

      final surveyData = jsonDecode(survey["Data"]);
    final surveyId = survey["SurveyId"];
    final List<dynamic> options = surveyData["secenek"];
    String? selectedOption;

    Map<String, dynamic>? summaryData;
    Map<String, List<String>>? groupedAnswers;

    // 🔹 Öğretmen / Müdür özet alır
    if (["M", "T"].contains(globals.globalKullaniciTipi)) {
      try {
        final classes = globals.globalSinifListesi
            .map((c) => c["Id"].toString())
            .join(",");

        summaryData = await apiService.getSurveySummary(
          surveyId: surveyId,
          tckn: globals.kullaniciTCKN,
          classes: classes,
        );

        groupedAnswers = _groupAnswers(summaryData, options);
      } catch (e) {
        debugPrint("Summary hata: $e");
      }
    }

      return  showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(surveyData["subject"] ?? "Anket"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(surveyData["aciklama"] ?? ""),
                    const SizedBox(height: 16),

                    // 🔹 Veli / Öğrenci seçenekler
                    if (["P", "S"].contains(globals.globalKullaniciTipi))
                      ...options.map((o) {
                        final key = (o["secenekKey"] ?? o["secenekAdi"]).toString();
                        final text = (o["secenekAdi"] ?? "").toString();

                        return RadioListTile<String>(
                          title: Text(text),
                          value: key,              // ✅ ARTIK ASLA NULL DEĞİL
                          groupValue: selectedOption,
                          onChanged: (v) {
                            setStateDialog(() {
                              selectedOption = v;
                            });
                          },
                        );

                      }).toList(),

                    // 🔹 ÖĞRETMEN / MÜDÜR DETAY
                    if (groupedAnswers != null) ...[
                      const Divider(),
                      const Text(
                        "Cevap Detayları",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...groupedAnswers.entries.map((e) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${e.key} (${e.value.length})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),

                            e.value.isEmpty
                                ? const Text("—")
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: e.value
                                  .map(
                                    (kisi) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person,
                                          size: 16, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(kisi)),
                                    ],
                                  ),
                                ),
                              )
                                  .toList(),
                            ),

                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                     /* ...groupedAnswers.entries.map((e) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${e.key} (${e.value.length})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            e.value.isEmpty
                                ? const Text("—")
                                : Wrap(
                              spacing: 6,
                              children: e.value
                                  .map(
                                    (kisi) => Chip(
                                  label: Text(kisi),
                                  backgroundColor:
                                  Colors.grey.shade200,
                                ),
                              )
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                   */ ],
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
            child: const Text("Gönder"),
            onPressed: () async {
            if (selectedOption == null) return;

            try {
            await apiService.submitSurvey(
            tckn: globals.kullaniciTCKN,
            surveyId: surveyId,
            answer: selectedOption!,
            );

            Navigator.pop(context, selectedOption); // ✅ CEVABI GERİ GÖNDER

            } catch (e) {
            debugPrint("Submit hata: $e");
            if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cevap gönderilemedi")),
            );
            }
            }
            },
            )


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
        title: const
        Text(
            "Anket Listesi",
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
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
          child: Column(
            children: [
              if (["M", "T"].contains(globals.globalKullaniciTipi))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createSurvey,
                      icon: const Icon(Icons.add, color: AppColors.onPrimary),
                      label:  Text(
                        "Yeni Anket Oluştur",
                        style: AppStyles.buttonTextStyle,//TextStyle(color: AppColors.primary),
                      ),
                      style: AppStyles.buttonStyle,
                      /*ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),*/
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
                            leading: const Icon(
                              Icons.poll,
                              size: 36,
                              color: AppColors.primary,
                            ),

                            // 👇 SAĞ TARAF BUTONLARI
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if(globals.globalKullaniciTipi!='P')
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: "Sil",
                                    onPressed: () {
                                      _deleteSurvey(survey["SurveyId"]);
                                    },
                                  ),
                              ],
                            ),

                            /*onTap: () => _showSurveyDialog(survey),*/
                            onTap: () async {
                              final result = await _showSurveyDialog(survey);

                              if (result != null) {
                                setState(() {
                                  survey["Answer"] = result; // ✅ ANINDA UI GÜNCELLENİR
                                });

                                // Arka planda gerçek refresh
                                _fetchSurveys();
                              }
                            },


                          ),

                          /*child: ListTile(
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
                          ),*/
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

  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Silme Onayı'),
          content: const Text(
            'Bu anketi silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Sil'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  Future<void> _deleteSurvey(int surveyId) async {
    final confirm = await _showDeleteConfirmDialog(context);

    if (!confirm) return;

    try {
      final success = await ApiService().deleteSurvey(
        tckn: globals.kullaniciTCKN,
        surveyId: surveyId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktivite silindi'),
            backgroundColor: Colors.green,
          ),
        );

        // 🔄 LİSTEYİ YENİDEN ÇEK
        await _fetchSurveys();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silme yetkiniz yok'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
 /* @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Anket Listesi", style: AppStyles.titleLarge),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: surveys.length,
        itemBuilder: (context, i) {
          final survey = surveys[i];
          final parsed = jsonDecode(survey["Data"]);
          final answered =
              survey["Answer"] != null && survey["Answer"].toString() != "";

          return Opacity(
            opacity: answered ? 0.5 : 1,
            child: Card(
              margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.poll,
                    color: AppColors.primary, size: 36),
                title: Text(parsed["subject"] ?? ""),
                subtitle: Text(
                  answered
                      ? "Cevap: ${survey["Answer"]}"
                      : "Cevaplanmamış",
                ),
                onTap: () => _showSurveyDialog(survey),
              ),
            ),
          );
        },
      ),
    );
  }*/
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

  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Silme Onayı'),
          content: const Text(
            'Bu anketi silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Sil'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  Future<void> _deleteSurvey(int surveyId) async {
    final confirm = await _showDeleteConfirmDialog(context);

    if (!confirm) return;

    try {
       final success = await ApiService().deleteSurvey(
        tckn: globals.kullaniciTCKN,
        surveyId: surveyId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktivite silindi'),
            backgroundColor: Colors.green,
          ),
        );

        // 🔄 LİSTEYİ YENİDEN ÇEK
        await _fetchSurveys();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silme yetkiniz yok'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, List<String>> groupAnswersByOption(
      Map<String, dynamic> summaryData,
      List<dynamic> options,
      ) {
    final Map<String, List<String>> grouped = {};

    // seçenek adlarını al (a, b, c gibi)
    final optionKeys = options
        .map((o) => o["secenekKey"] ?? o["secenekAdi"])
        .toList();

    for (var key in optionKeys) {
      grouped[key] = [];
    }

    grouped["Cevapsız"] = [];

    final detay = summaryData["detay"] as Map<String, dynamic>;

    detay.forEach((name, answer) {
      if (answer == "-" || answer == null) {
        grouped["Cevapsız"]!.add(name);
      } else {
        grouped.putIfAbsent(answer, () => []);
        grouped[answer]!.add(name);
      }
    });

    return grouped;
  }


  void _showSurveyDialog(Map<String, dynamic> survey) async {
    // ✅ Eğer cevap verilmişse, uyarı popup olarak göster
   /* if (survey["Answer"] != null && survey["Answer"].toString().trim().isNotEmpty) {
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
    }*/

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
        title: const
        Text(
            "Anket Listesi",
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
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
          child: Column(
            children: [
              if (["M", "T"].contains(globals.globalKullaniciTipi))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createSurvey,
                      icon: const Icon(Icons.add, color: AppColors.onPrimary),
                      label:  Text(
                        "Yeni Anket Oluştur",
                        style: AppStyles.buttonTextStyle,//TextStyle(color: AppColors.primary),
                      ),
                      style: AppStyles.buttonStyle,
                      /*ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),*/
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
                            leading: const Icon(
                              Icons.poll,
                              size: 36,
                              color: AppColors.primary,
                            ),

                            // 👇 SAĞ TARAF BUTONLARI
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if(globals.globalKullaniciTipi!='P')
                                  IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: "Sil",
                                  onPressed: () {
                                    _deleteSurvey(survey["SurveyId"]);
                                  },
                                ),
                              ],
                            ),

                            onTap: () => _showSurveyDialog(survey),
                          ),

                          /*child: ListTile(
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
                          ),*/
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