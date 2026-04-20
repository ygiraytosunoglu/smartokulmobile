import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants.dart';
import '../globals.dart' as globals;
import 'create_survey_screen.dart';
import '../services/api_service.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

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
      debugPrint(AppLocalizations.of(context)!.err+": $e");
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
              title: Text(surveyData["subject"] ?? AppLocalizations.of(context)!.survey),
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
                       Text(
                         AppLocalizations.of(context)!.answerDetails,
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
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:  Text(AppLocalizations.of(context)!.close),
                ),
                if (["P", "S"].contains(globals.globalKullaniciTipi))
            ElevatedButton(
            child:  Text(AppLocalizations.of(context)!.send),
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
             SnackBar(content: Text(AppLocalizations.of(context)!.submitError)),
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
        title:
        Text(
            AppLocalizations.of(context)!.surveyListTitle,
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
                        AppLocalizations.of(context)!.newSurvey,
                        style: AppStyles.buttonTextStyle,//TextStyle(color: AppColors.primary),
                      ),
                      style: AppStyles.buttonStyle,
                    ),
                  ),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : surveys.isEmpty
                    ?  Center(child: Text(AppLocalizations.of(context)!.noSurvey))
                    : ListView.builder(
                  itemCount: surveys.length,
                  itemBuilder: (context, index) {
                    final survey = surveys[index];
                    String subject = AppLocalizations.of(context)!.noTitle;
                    try {
                      final parsed = jsonDecode(survey["Data"]);
                      subject = parsed["subject"] ?? AppLocalizations.of(context)!.noTitle;
                    } catch (_) {}

                    final answered = survey["Answer"] != null &&
                        survey["Answer"].toString().trim().isNotEmpty;

                    final answerText = answered
                        ? survey["Answer"].toString()
                        : AppLocalizations.of(context)!.unanswered;

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
                            subtitle: globals.globalKullaniciTipi == 'P'
                                ? Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(AppLocalizations.of(context)!.answer+": $answerText"),
                            )
                                : null,
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
          title:  Text(AppLocalizations.of(context)!.deleteConfirmTitle),
          content:  Text(
            AppLocalizations.of(context)!.deleteConfirmMessage,
          ),
          actions: [
            TextButton(
              child:  Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child:  Text(AppLocalizations.of(context)!.delete),
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
           SnackBar(
            content: Text(AppLocalizations.of(context)!.deleteSuccess),
            backgroundColor: Colors.green,
          ),
        );

        // 🔄 LİSTEYİ YENİDEN ÇEK
        await _fetchSurveys();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(AppLocalizations.of(context)!.noDeletePermission),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.activityDeleteError+' $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
