import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smart_okul_mobile/constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

class UpdateOdevScreen extends StatefulWidget {
  final Map<String, dynamic> odev;

  const UpdateOdevScreen({Key? key, required this.odev}) : super(key: key);

  @override
  State<UpdateOdevScreen> createState() => _UpdateOdevScreenState();
}

class _UpdateOdevScreenState extends State<UpdateOdevScreen> {
  dynamic seciliDers;
  final aciklamaCtrl = TextEditingController();
  final expireCtrl = TextEditingController();

  List<dynamic> dersListesi = [];
  bool dersLoading = true;

  List<File> selectedFiles = [];
  List<dynamic> mevcutDosyalar = [];

  @override
  void initState() {
    super.initState();
    _fillData();
    _loadDersler();
    mevcutDosyalar = widget.odev['Files'] ?? [];
  }

  void _fillData() {
    try {
      final parsed = jsonDecode(widget.odev['Data'] ?? '');
      aciklamaCtrl.text = parsed['aciklama'] ?? '';
    } catch (_) {
      aciklamaCtrl.text = widget.odev['Data'] ?? '';
    }

    if (widget.odev['ExpireDate'] != null) {
      expireCtrl.text = DateFormat('dd-MM-yyyy')
          .format(DateTime.parse(widget.odev['ExpireDate']));

    }
  }

  Future<void> _loadDersler() async {
    try {
      final schoolId = int.parse(globals.globalSchoolId.toString());
      final data = await ApiService().getAllDersler(schoolId);

      setState(() {
        dersListesi = data ?? [];

        seciliDers = dersListesi.firstWhere(
              (d) => d['Id'] == widget.odev['DersId'],
          orElse: () => null,
        );

        dersLoading = false;
      });
    } catch (_) {
      setState(() => dersLoading = false);
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _removeExistingFile(int index) {
    setState(() {
      mevcutDosyalar.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödev Güncelle', style: AppStyles.titleLarge),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withOpacity(0.9),
                  AppColors.background.withOpacity(0.6),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // DERS
                  dersLoading
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<dynamic>(
                    value: seciliDers,
                    decoration: _decoration("Ders"),
                    items: dersListesi
                        .map(
                          (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d['Ad'] ?? ''),
                      ),
                    )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => seciliDers = v),
                  ),

                  const SizedBox(height: 12),

                  // AÇIKLAMA
                  TextField(
                    controller: aciklamaCtrl,
                    maxLines: 3,
                    decoration: _decoration("Açıklama"),
                  ),

                  const SizedBox(height: 12),

                  // TARİH
                  TextField(
                    controller: expireCtrl,
                    readOnly: true,
                    decoration: _decoration("Son Teslim Tarihi"),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        expireCtrl.text = DateFormat('dd-MM-yyyy').format(d);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // 📎 MEVCUT DOSYALAR
                  if (mevcutDosyalar.isNotEmpty) ...[
                    const Text(
                      "Mevcut Dosyalar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mevcutDosyalar.length,
                      itemBuilder: (context, index) {
                        final file = mevcutDosyalar[index];

                        return Card(
                          child: ListTile(
                            leading:
                            const Icon(Icons.insert_drive_file),
                            title: Text(file['FileName'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () {
                                _removeExistingFile(index);
                              },
                            ),
                            onTap: () {
                              _openFile(file['Url']);
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // DOSYA EKLE
                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    style: AppStyles.buttonStyle,
                    label: const Text("Dosya Ekle"),
                    onPressed: () async {
                      final result = await FilePicker.platform
                          .pickFiles(allowMultiple: true);
                      if (result != null) {
                        setState(() {
                          selectedFiles = result.paths
                              .whereType<String>()
                              .map((e) => File(e))
                              .toList();
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // GÜNCELLE
                  ElevatedButton(
                    child: const Text("Güncelle"),
                    style: AppStyles.buttonStyle,
                    onPressed: () async {
                      await ApiService().updateOdev(
                        odevId: widget.odev['Id'],
                        dersId: seciliDers?['Id'],
                        schoolId: int.parse(
                            globals.globalSchoolId.toString()),
                        data: jsonEncode({
                          "aciklama": aciklamaCtrl.text,
                        }),
                        expireDate: expireCtrl.text.isNotEmpty
                            ? DateFormat('dd-MM-yyyy').parse(expireCtrl.text)
                            : null,
                        files: selectedFiles,
                      );

                      Navigator.pop(context, true);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
/*import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_okul_mobile/constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

class UpdateOdevScreen extends StatefulWidget {
  final Map<String, dynamic> odev;

  const UpdateOdevScreen({Key? key, required this.odev}) : super(key: key);

  @override
  State<UpdateOdevScreen> createState() => _UpdateOdevScreenState();
}

class _UpdateOdevScreenState extends State<UpdateOdevScreen> {
  dynamic seciliDers;
  final aciklamaCtrl = TextEditingController();
  final expireCtrl = TextEditingController();

  List<dynamic> dersListesi = [];
  bool dersLoading = true;

  List<File> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _fillData();
    _loadDersler();
  }

  void _fillData() {
    // Açıklama
    try {
      final parsed = jsonDecode(widget.odev['Data'] ?? '');
      aciklamaCtrl.text = parsed['aciklama'] ?? '';
    } catch (_) {
      aciklamaCtrl.text = widget.odev['Data'] ?? '';
    }

    // Tarih
    if (widget.odev['ExpireDate'] != null) {
      expireCtrl.text = DateFormat('yyyy-MM-dd')
          .format(DateTime.parse(widget.odev['ExpireDate']));
    }
  }

  Future<void> _loadDersler() async {
    try {
      final schoolId = int.parse(globals.globalSchoolId.toString());
      final data = await ApiService().getAllDersler(schoolId);

      setState(() {
        dersListesi = data ?? [];

        // ✅ Seçili dersi Id ile eşleştir
        seciliDers = dersListesi.firstWhere(
              (d) => d['Id'] == widget.odev['DersId'],
          orElse: () => null,
        );

        dersLoading = false;
      });
    } catch (_) {
      setState(() => dersLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödev Güncelle', style: AppStyles.titleLarge),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.9),
                  AppColors.primary.withOpacity(0.6),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Ders
                  dersLoading
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<dynamic>(
                    value: seciliDers,
                    decoration: _inputDecoration("Ders"),
                    items: dersListesi
                        .map(
                          (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d['Ad'] ?? ''),
                      ),
                    )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => seciliDers = v),
                  ),

                  const SizedBox(height: 12),

                  // Açıklama
                  TextField(
                    controller: aciklamaCtrl,
                    maxLines: 3,
                    decoration: _inputDecoration("Açıklama"),
                  ),

                  const SizedBox(height: 12),

                  // Tarih
                  TextField(
                    controller: expireCtrl,
                    readOnly: true,
                    decoration: _inputDecoration("Son Teslim Tarihi"),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        expireCtrl.text =
                            DateFormat('yyyy-MM-dd').format(d);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.attach_file),
                    label: const Text("Dosya Ekle"),
                    onPressed: () async {
                      final result = await FilePicker.platform
                          .pickFiles(allowMultiple: true);
                      if (result != null) {
                        setState(() {
                          selectedFiles = result.paths
                              .whereType<String>()
                              .map((e) => File(e))
                              .toList();
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    child: const Text("Güncelle"),
                    onPressed: () async {
                      await ApiService().updateOdev(
                        odevId: widget.odev['Id'],
                        dersId: seciliDers?['Id'],
                        schoolId: int.parse(
                            globals.globalSchoolId.toString()),
                        data: jsonEncode({
                          "aciklama": aciklamaCtrl.text,
                        }),
                        expireDate: expireCtrl.text.isNotEmpty
                            ? DateTime.parse(expireCtrl.text)
                            : null,
                        files: selectedFiles,
                      );

                      Navigator.pop(context, true);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
*/