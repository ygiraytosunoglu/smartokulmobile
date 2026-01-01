import 'dart:convert';
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
  /// 📘 Dersler
  List<dynamic> dersListesi = [];
  bool dersLoading = true;

  /// 🧾 Form alanları
  dynamic seciliDers;
  final TextEditingController aciklamaCtrl = TextEditingController();
  final TextEditingController expireCtrl = TextEditingController();

  /// 👨‍🎓 Öğrenciler
  late Map<String, bool> ogrenciSecim;
  bool hepsiSecili = true;

  /// 📎 Dosyalar
  List<File> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    ogrenciSecim = {
      for (var o in globals.globalOgrenciListesi)
        o['TCKN'].toString(): true
    };
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
        title: const Text('Yeni Ödev Oluştur', style: AppStyles.titleLarge),
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

              /// 📅 Son Teslim Tarihi (dd-MM-yyyy)
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
                        DateFormat('dd-MM-yyyy').format(d);
                  }
                },
              ),

              const SizedBox(height: 16),

              /// 👥 Öğrenciler
              CheckboxListTile(
                title: const Text("Hepsi"),
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
                final tckn = ogr['TCKN'].toString();
                return CheckboxListTile(
                  title: Text(ogr['Name'] ?? ''),
                  value: ogrenciSecim[tckn],
                  onChanged: (v) {
                    setState(() {
                      ogrenciSecim[tckn] = v!;
                      _hepsiDurumunuGuncelle();
                    });
                  },
                );
              }),

              const SizedBox(height: 12),

              /// 📎 Dosya Ekle
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text("Dosya Ekle"),
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
                      .map((f) =>
                      Text("📎 ${f.path.split('/').last}"))
                      .toList(),
                ),
              ],

              const SizedBox(height: 24),

              /// 💾 Kaydet
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.buttonStyle,
                  child: const Text("Kaydet"),
                  onPressed: () async {
                    final List<String> secilenOgrenciler =
                    ogrenciSecim.entries
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

                    /// dd-MM-yyyy → DateTime
                    final expireDate = DateFormat('dd-MM-yyyy')
                        .parse(expireCtrl.text);
                    print("secilenOgrenciler kaç tane:"+secilenOgrenciler.length.toString());
                    await ApiService().addOdev(
                      gonderenTckn: globals.kullaniciTCKN,
                      alanTcknList: secilenOgrenciler,
                      dersId: seciliDers['Id'],
                      schoolId: int.parse(
                          globals.globalSchoolId.toString()),
                      data: jsonEncode({
                        "aciklama": aciklamaCtrl.text,
                      }),
                      expireDate: expireDate,
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
        title: const Text('Yeni Ödev Oluştur', style: AppStyles.titleLarge),
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
                title: const Text("Hepsi"),
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
                label: const Text("Dosya Ekle"),
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
                  child: const Text("Kaydet"),
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