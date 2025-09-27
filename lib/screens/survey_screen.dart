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

/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../globals.dart' as globals;
import 'create_survey_screen.dart'; // CreateSurveyScreen import edildi

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
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
      final response = await http.get(
        Uri.parse("${globals.serverAdrr}/api/survey/list-by-tckn?tckn=${globals.kullaniciTCKN}"),
      );
      if (response.statusCode == 200) {
        setState(() {
          surveys = json.decode(response.body);
        });
      } else {
        throw Exception("Anketler alınamadı!");
      }
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
      _fetchSurveys(); // Listeyi güncelle
    }
  }

  String _parseSurveyData(String data) {
    try {
      // '=' işaretini ':' ile değiştir ve JSON olarak parse et
      final parsed = jsonDecode(data.replaceAll('=', ':'));
      return parsed["data"] ?? data;
    } catch (e) {
      return data; // Parse edemezse direkt stringi döndür
    }
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
              // Yeni anket oluştur butonu (öğretmenler için)
              if (["M", "T"].contains(globals.globalKullaniciTipi))                Padding(
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

                    // Data alanını parse et
                    String subject = "Başlıksız";
                    try {
                      final parsedData = jsonDecode(survey["Data"]);
                      subject = parsedData["subject"] ?? "Başlıksız";
                    } catch (e) {
                      subject = "Başlıksız";
                    }

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
/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../globals.dart' as globals;
import 'create_survey_screen.dart'; // CreateSurveyScreen import edildi

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
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
      final response = await http.get(Uri.parse("${globals.serverAdrr}/api/survey/list-by-tckn?tckn=${globals.kullaniciTCKN}"));
      if (response.statusCode == 200) {
        setState(() {
          surveys = json.decode(response.body);
        });
      } else {
        throw Exception("Anketler alınamadı!");
      }
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
    // CreateSurveyScreen açılır, başarılı gönderimde true döner
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateSurveyScreen()),
    );
    if (result == true) {
      _fetchSurveys(); // Listeyi güncelle
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anket"),
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity, // tam genişlik
                  child: ElevatedButton.icon(
                    onPressed: _createSurvey,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text(
                      "Yeni Anket Oluştur",
                      style: TextStyle(color: AppColors.primary),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white, // arka plan beyaz
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
                            survey["subject"] ?? "Başlıksız",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(survey["aciklama"] ?? ""),
                          leading: const Icon(Icons.poll, size: 36, color: AppColors.primary),
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
}*/
