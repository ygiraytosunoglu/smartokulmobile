import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

import '../constants.dart';
import '../models/ders_catalog.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../utils/chat_attachment.dart';

class YeniOdevScreen extends StatefulWidget {
  const YeniOdevScreen({Key? key}) : super(key: key);

  @override
  State<YeniOdevScreen> createState() => _YeniOdevScreenState();
}

class _YeniOdevScreenState extends State<YeniOdevScreen> {
  /// 📘 Dersler
  List<dynamic> dersListesi = [];
  bool dersLoading = true;

  List<DersTema> _temalar = [];
  List<DersKonu> _konular = [];
  int? _temaId;
  int? _konuId;
  bool _cascadeLoading = false;

  /// 🧾 Form alanları
  dynamic seciliDers;
  final TextEditingController aciklamaCtrl = TextEditingController();
  final TextEditingController expireCtrl = TextEditingController();

  /// 👨‍🎓 Öğrenciler
  List<Map<String, dynamic>> ogrenciler = [];
  late Map<String, bool> ogrenciSecim;
  bool hepsiSecili = true;
  bool ogrenciLoading = true;

  /// 📎 Dosyalar
  List<File> selectedFiles = [];
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    ogrenciSecim = {};
    _loadDersler();
    _loadOgrenciler();
  }

  Future<void> _kaydet() async {
    if (_kaydediliyor) return;
    final List<String> secilenOgrenciler = ogrenciSecim.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (seciliDers == null ||
        aciklamaCtrl.text.trim().isEmpty ||
        expireCtrl.text.isEmpty ||
        secilenOgrenciler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fillRequiredFields),
        ),
      );
      return;
    }

    setState(() => _kaydediliyor = true);
    try {
      final expireDate = DateFormat('dd-MM-yyyy').parse(expireCtrl.text);
      await ApiService().addOdev(
        gonderenTckn: globals.kullaniciTCKN,
        alanTcknList: secilenOgrenciler,
        dersId: seciliDers['Id'],
        schoolId: int.parse(globals.globalSchoolId.toString()),
        data: jsonEncode({
          "aciklama": aciklamaCtrl.text,
        }),
        expireDate: expireDate,
        files: selectedFiles,
        temaId: _temaId,
        konuId: _konuId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int? _dersIdOf(dynamic d) {
    if (d is! Map) return null;
    final id = d['Id'] ?? d['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  Future<void> _dersSecildi(dynamic v) async {
    setState(() {
      seciliDers = v;
      _temaId = null;
      _konuId = null;
      _temalar = [];
      _konular = [];
    });
    final dersId = _dersIdOf(v);
    if (dersId == null) return;
    setState(() => _cascadeLoading = true);
    final temalar = await ApiService.getDersTemalar(dersId: dersId);
    if (!mounted) return;
    setState(() {
      _temalar = temalar;
      _cascadeLoading = false;
    });
  }

  Future<void> _temaSecildi(int? id) async {
    setState(() {
      _temaId = id;
      _konuId = null;
      _konular = [];
    });
    if (id == null) return;
    setState(() => _cascadeLoading = true);
    final konular = await ApiService.getDersKonular(id);
    if (!mounted) return;
    setState(() {
      _konular = konular;
      _cascadeLoading = false;
    });
  }

  Future<void> _loadOgrenciler() async {
    try {
      final data = await ApiService.loadHomeworkStudents();
      if (!mounted) return;
      setState(() {
        ogrenciler = data;
        ogrenciSecim = {
          for (var o in ogrenciler) o['TCKN'].toString(): true,
        };
        hepsiSecili = ogrenciler.isNotEmpty;
        ogrenciLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        ogrenciler = List<Map<String, dynamic>>.from(
          globals.globalOgrenciListesi,
        );
        ogrenciSecim = {
          for (var o in ogrenciler) o['TCKN'].toString(): true,
        };
        hepsiSecili = ogrenciler.isNotEmpty;
        ogrenciLoading = false;
      });
    }
  }

  /// 📘 Dersleri API'den çek
  Future<void> _loadDersler() async {
    try {
      final schoolId = int.parse(globals.globalSchoolId.toString());
      final data = await ApiService().getAllDersler(schoolId);

      setState(() {
        dersListesi = data ?? [];
        dersLoading = false;
      });
    } catch (_) {
      setState(() {
        dersListesi = [];
        dersLoading = false;
      });
    }
  }

  void _hepsiDurumunuGuncelle() {
    hepsiSecili = ogrenciSecim.values.every((v) => v);
  }

  List<Widget> _ogrenciCheckboxlari() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final ogr in ogrenciler) {
      final sinif = (ogr['ClassName'] ?? '').toString().trim();
      final key = sinif.isEmpty ? 'Diğer' : sinif;
      grouped.putIfAbsent(key, () => []).add(ogr);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      if (grouped.length > 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }
      for (final ogr in entry.value) {
        final tckn = ogr['TCKN'].toString();
        widgets.add(
          CheckboxListTile(
            title: Text(ogr['Name'] ?? ''),
            subtitle: grouped.length == 1 &&
                    (ogr['ClassName'] ?? '').toString().isNotEmpty
                ? Text(ogr['ClassName'].toString())
                : null,
            value: ogrenciSecim[tckn] ?? false,
            onChanged: (v) {
              setState(() {
                ogrenciSecim[tckn] = v!;
                _hepsiDurumunuGuncelle();
              });
            },
          ),
        );
      }
    }
    return widgets;
  }

  @override
  void dispose() {
    aciklamaCtrl.dispose();
    expireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(AppLocalizations.of(context)!.createHomework, style: AppStyles.titleLarge),
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
        child: dersLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// 📘 Ders
              DropdownButtonFormField<dynamic>(
                decoration:  InputDecoration(
                  labelText: AppLocalizations.of(context)!.lesson +" *",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: dersListesi.map((d) {
                  return DropdownMenuItem<dynamic>(
                    value: d,
                    child: Text(d['Ad'] ?? ''),
                  );
                }).toList(),
                onChanged: _dersSecildi,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _temalar.any((t) => t.id == _temaId) ? _temaId : null,
                decoration: const InputDecoration(
                  labelText: 'Öğrenme Alanı (opsiyonel)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _temalar
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.ad, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: seciliDers == null ? null : _temaSecildi,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _konular.any((k) => k.id == _konuId) ? _konuId : null,
                decoration: const InputDecoration(
                  labelText: 'Konu (opsiyonel)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _konular
                    .map(
                      (k) => DropdownMenuItem(
                        value: k.id,
                        child: Text(k.ad, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _temaId == null
                    ? null
                    : (v) => setState(() => _konuId = v),
              ),

              if (_cascadeLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              const SizedBox(height: 12),

              /// 📝 Açıklama
              TextField(
                controller: aciklamaCtrl,
                maxLines: 3,
                decoration:  InputDecoration(
                  labelText: AppLocalizations.of(context)!.activityDescription+" *",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              /// 📅 Son Teslim Tarihi (dd-MM-yyyy)
              TextField(
                controller: expireCtrl,
                readOnly: true,
                decoration:  InputDecoration(
                  labelText: AppLocalizations.of(context)!.dueDate+" *",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) {
                    expireCtrl.text =
                        DateFormat('dd-MM-yyyy').format(d);
                  }
                },
              ),

              const SizedBox(height: 12),

              /// 📎 Dosya Ekle (tarihin altı, öğrenci listesinin üstü)
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text(
                  selectedFiles.isEmpty
                      ? AppLocalizations.of(context)!.addFile
                      : '${AppLocalizations.of(context)!.addFile} (${selectedFiles.length})',
                ),
                onPressed: () async {
                  final files = await pickMultipleAttachments(context);
                  if (files.isEmpty || !mounted) return;
                  setState(() => selectedFiles.addAll(files));
                },
              ),

              if (selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...List.generate(selectedFiles.length, (i) {
                  final f = selectedFiles[i];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file, size: 20),
                    title: Text(
                      p.basename(f.path),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () =>
                          setState(() => selectedFiles.removeAt(i)),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 16),

              /// 👥 Öğrenciler
              if (ogrenciLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context)!.allOfThem),
                  value: hepsiSecili,
                  onChanged: (v) {
                    setState(() {
                      hepsiSecili = v!;
                      ogrenciSecim.updateAll((key, value) => hepsiSecili);
                    });
                  },
                ),
                ..._ogrenciCheckboxlari(),
              ],

              const SizedBox(height: 24),

              /// 💾 Kaydet
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.buttonStyle,
                  onPressed: _kaydediliyor ? null : _kaydet,
                  child: Text(
                    _kaydediliyor
                        ? 'Kaydediliyor...'
                        : AppLocalizations.of(context)!.save,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

class YeniOdevScreen extends StatefulWidget {
  const YeniOdevScreen({Key? key}) : super(key: key);

  @override
  State<YeniOdevScreen> createState() => _YeniOdevScreenState();
}

class _YeniOdevScreenState extends State<YeniOdevScreen> {
  /// 🔄 Dersler
  List<dynamic> dersListesi = [];
  bool dersLoading = true;

  /// 🧾 Form alanları
  dynamic seciliDers;
  final TextEditingController aciklamaCtrl = TextEditingController();
  final TextEditingController expireCtrl = TextEditingController();

  /// 👨‍🎓 Öğrenciler
  Map<String, bool> ogrenciSecim = {
    for (var o in globals.globalOgrenciListesi) o['TCKN']: true
  };
  bool hepsiSecili = true;

  /// 📎 Dosyalar
  List<File> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadDersler();
  }

  /// 📘 Dersleri API'den çek
  Future<void> _loadDersler() async {
    try {
      final schoolId = int.parse(globals.globalSchoolId.toString());
      final data = await ApiService().getAllDersler(schoolId);

      setState(() {
        dersListesi = data ?? [];
        dersLoading = false;
      });
    } catch (_) {
      setState(() {
        dersListesi = [];
        dersLoading = false;
      });
    }
  }

  void _hepsiDurumunuGuncelle() {
    hepsiSecili = ogrenciSecim.values.every((v) => v);
  }

  @override
  void dispose() {
    aciklamaCtrl.dispose();
    expireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Ödev Oluştur', style: AppStyles.titleLarge),
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
        child: dersLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// 📘 Ders
              DropdownButtonFormField<dynamic>(
                decoration: const InputDecoration(
                  labelText: "Ders *",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: dersListesi.map((d) {
                  return DropdownMenuItem<dynamic>(
                    value: d,
                    child: Text(d['Ad'] ?? ''),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    seciliDers = v;
                  });
                },
              ),

              const SizedBox(height: 12),

              /// 📝 Açıklama
              TextField(
                controller: aciklamaCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Açıklama *",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              /// 📅 Son Teslim Tarihi
              TextField(
                controller: expireCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Son Teslim Tarihi *",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
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

              /// 👥 Öğrenciler
              CheckboxListTile(
                title: Text("Hepsi"),
                value: hepsiSecili,
                onChanged: (v) {
                  setState(() {
                    hepsiSecili = v!;
                    ogrenciSecim
                        .updateAll((key, value) => hepsiSecili);
                  });
                },
              ),

              ...globals.globalOgrenciListesi.map((ogr) {
                return CheckboxListTile(
                  title: Text(ogr['Name'] ?? ''),
                  value: ogrenciSecim[ogr['TCKN']],
                  onChanged: (v) {
                    setState(() {
                      ogrenciSecim[ogr['TCKN']] = v!;
                      _hepsiDurumunuGuncelle();
                    });
                  },
                );
              }),

              const SizedBox(height: 12),

              /// 📎 Dosya Ekle
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: Text("Dosya Ekle"),
                onPressed: () async {
                  final result =
                  await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                  );
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

              if (selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedFiles
                      .map((f) => Text(
                      "📎 ${f.path.split('/').last}"))
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),

              /// 💾 Kaydet
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.buttonStyle,
                  child: Text("Kaydet"),
                  onPressed: () async {
                    final secilenOgrenciler = ogrenciSecim.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();

                    if (seciliDers == null ||
                        aciklamaCtrl.text.trim().isEmpty ||
                        expireCtrl.text.isEmpty ||
                        secilenOgrenciler.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                          Text("Zorunlu alanları doldurun"),
                        ),
                      );
                      return;
                    }

                    await ApiService().addOdev(
                      gonderenTckn: globals.kullaniciTCKN,
                      alanTcknList: secilenOgrenciler,
                      dersId: seciliDers['Id'],
                      schoolId: int.parse(
                          globals.globalSchoolId.toString()),
                      data: jsonEncode({
                        "aciklama": aciklamaCtrl.text,
                      }),
                      expireDate:
                      DateTime.parse(expireCtrl.text),
                      files: selectedFiles,
                    );

                    Navigator.pop(context, true);
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