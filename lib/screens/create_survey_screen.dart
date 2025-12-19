import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import '../globals.dart' as globals;

class CreateSurveyScreen extends StatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController()
  ];

  bool _isSubmitting = false;
  Map<String, bool> _selectedStudents = {};
  bool _isAllSelected = true;

  // sınıflar için seçim map'i
  Map<int, bool> _selectedClasses = {};

  @override
  void initState() {
    super.initState();

    // öğrenciler
    if (globals.globalOgrenciListesi.isNotEmpty) {
      _selectedStudents = {
        for (var ogr in globals.globalOgrenciListesi) ogr["TCKN"]: true
      };
    }

    // sınıflar -> hepsi seçili gelsin
    if (globals.globalSinifListesi.isNotEmpty) {
      _selectedClasses = {
        for (var sinif in globals.globalSinifListesi) sinif["Id"] as int: true
      };
    }
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En az 2 seçenek olmalı.")),
      );
      return;
    }
    setState(() {
      _optionControllers.removeAt(index);
    });
  }

 /* Future<void> _sendSurvey() async {
    if (!_formKey.currentState!.validate()) return;

    final options = _optionControllers
        .map((c) => {"secenekAdi": c.text.trim()})
        .where((v) => v["secenekAdi"]!.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En az 2 seçenek ekleyin.")),
      );
      return;
    }

    // seçili sınıflar
    final selectedClassIds = _selectedClasses.entries
        .where((e) => e.value)
        .map((e) => e.key.toString())
        .toList();

    if (selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En az 1 sınıf seçin.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dataMap = {
        "subject": _titleController.text,
        "aciklama": _descController.text,
        "ownerTckn": globals.kullaniciTCKN,
        "classes": selectedClassIds.join(","), // seçili sınıflar
        "secenek": options,
      };

      final response = await http.post(
        Uri.parse("${globals.serverAdrr}/api/survey/create"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "data": json.encode(dataMap),
          "dayCount": "7",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Anket başarıyla oluşturuldu.")),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Anket oluşturulamadı");
      }
    } catch (e) {
      debugPrint("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anket gönderilemedi.")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }*/
  Future<void> _sendSurvey() async {
    if (!_formKey.currentState!.validate()) return;

    final options = _optionControllers
        .map((c) => {"secenekAdi": c.text.trim()})
        .where((v) => v["secenekAdi"]!.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En az 2 seçenek ekleyin.")),
      );
      return;
    }

    // seçili sınıflar
    final selectedClassIds = _selectedClasses.entries
        .where((e) => e.value)
        .map((e) => e.key.toString())
        .toList();

    if (selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En az 1 sınıf seçin.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dataMap = {
        "subject": _titleController.text,
        "aciklama": _descController.text,
        "secenek": options,
      };

      final response = await http.post(
        Uri.parse("${globals.serverAdrr}/api/survey/create"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "data": json.encode(dataMap), // JSON string
          "classes": selectedClassIds.join(","), // comma-separated
          "dayCount": "7",
          "ownerTckn": globals.kullaniciTCKN, // opsiyonel, gönderilebilir
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Anket başarıyla oluşturuldu.")),
        );
        Navigator.pop(context, true);
      } else {
        debugPrint("Server hata: ${response.statusCode} - ${response.body}");
        throw Exception("Anket oluşturulamadı");
      }
    } catch (e) {
      debugPrint("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anket gönderilemedi.")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(
            "Yeni Anket Oluştur",
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
              AppColors.background.withOpacity(0.6)
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.poll, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        "Yeni Anket",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: "Anket Başlığı",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) =>
                        v == null || v.isEmpty ? "Başlık gerekli" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: "Açıklama",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      const Text("Seçenekler",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._optionControllers.asMap().entries.map((entry) {
                        int index = entry.key;
                        TextEditingController controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: "Seçenek ${index + 1}",
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeOption(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      TextButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add),
                        label: const Text("Seçenek Ekle"),
                      ),
                      const SizedBox(height: 12),

                      // sınıflar listesi
                      const Text("Sınıflar",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...globals.globalSinifListesi.map((sinif) {
                        final id = sinif["Id"] as int;
                        final name = sinif["Name"] ?? "Sınıf $id";
                        return CheckboxListTile(
                          title: Text(name),
                          value: _selectedClasses[id] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _selectedClasses[id] = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList(),

                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _sendSurvey,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: Text(
                          _isSubmitting ? "Gönderiliyor..." : "Anketi Gönder",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
