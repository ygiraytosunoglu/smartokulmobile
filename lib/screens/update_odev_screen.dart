import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'package:smart_okul_mobile/constants.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';
import '../models/conversation_item.dart';
import '../models/ders_catalog.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../utils/chat_attachment.dart';

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

  List<DersTema> _temalar = [];
  List<DersKonu> _konular = [];
  int? _temaId;
  int? _konuId;
  bool _cascadeLoading = false;

  List<File> selectedFiles = [];
  List<dynamic> mevcutDosyalar = [];
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    _fillData();
    _temaId = jsonInt(widget.odev, 'temaId');
    _konuId = jsonInt(widget.odev, 'konuId');
    _loadDersler();
    mevcutDosyalar = widget.odev['Files'] ?? widget.odev['files'] ?? [];
  }

  Future<void> _kaydet() async {
    if (_kaydediliyor) return;
    setState(() => _kaydediliyor = true);
    try {
      await ApiService().updateOdev(
        odevId: jsonInt(widget.odev, 'id') ?? widget.odev['Id'],
        dersId: seciliDers?['Id'],
        schoolId: int.parse(globals.globalSchoolId.toString()),
        data: jsonEncode({
          "aciklama": aciklamaCtrl.text,
        }),
        expireDate: expireCtrl.text.isNotEmpty
            ? DateFormat('dd-MM-yyyy').parse(expireCtrl.text)
            : null,
        files: selectedFiles,
        temaId: _temaId,
        konuId: _konuId,
        actorTckn: globals.kullaniciTCKN,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediliyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  int? _dersIdOf(dynamic d) {
    if (d is! Map) return null;
    final id = d['Id'] ?? d['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  Future<void> _loadTemalar(int dersId, {bool preserve = false}) async {
    setState(() => _cascadeLoading = true);
    final temalar = await ApiService.getDersTemalar(dersId: dersId);
    if (!mounted) return;
    setState(() {
      _temalar = temalar;
      if (!preserve || !_temalar.any((t) => t.id == _temaId)) {
        _temaId = null;
        _konuId = null;
        _konular = [];
      }
      _cascadeLoading = false;
    });
    if (_temaId != null) await _loadKonular(_temaId!, preserve: preserve);
  }

  Future<void> _loadKonular(int temaId, {bool preserve = false}) async {
    setState(() => _cascadeLoading = true);
    final konular = await ApiService.getDersKonular(temaId);
    if (!mounted) return;
    setState(() {
      _konular = konular;
      if (!preserve || !_konular.any((k) => k.id == _konuId)) {
        _konuId = null;
      }
      _cascadeLoading = false;
    });
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
    if (dersId != null) await _loadTemalar(dersId);
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
      final hedefDersId =
          jsonInt(widget.odev, 'dersId') ?? widget.odev['DersId'];

      setState(() {
        dersListesi = data ?? [];
        seciliDers = null;
        for (final d in dersListesi) {
          if (d is Map && (d['Id'] == hedefDersId || d['id'] == hedefDersId)) {
            seciliDers = d;
            break;
          }
        }
        dersLoading = false;
      });
      final dersId = _dersIdOf(seciliDers);
      if (dersId != null) await _loadTemalar(dersId, preserve: true);
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
        title: Text('Ödev Güncelle', style: AppStyles.titleLarge),
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
                    onChanged: _dersSecildi,
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    value: _temalar.any((t) => t.id == _temaId) ? _temaId : null,
                    decoration: _decoration(
                      AppLocalizations.of(context)!.learningAreaOptional,
                    ),
                    items: _temalar
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.ad, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: seciliDers == null
                        ? null
                        : (v) async {
                            setState(() {
                              _temaId = v;
                              _konuId = null;
                              _konular = [];
                            });
                            if (v != null) await _loadKonular(v);
                          },
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    value: _konular.any((k) => k.id == _konuId) ? _konuId : null,
                    decoration: _decoration(
                      AppLocalizations.of(context)!.topicOptional,
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
                    Text(
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
                    label: Text(
                      selectedFiles.isEmpty
                          ? 'Dosya Ekle'
                          : 'Dosya Ekle (${selectedFiles.length})',
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
                        leading:
                            const Icon(Icons.insert_drive_file, size: 20),
                        title: Text(
                          p.basename(f.path),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () =>
                              setState(() => selectedFiles.removeAt(i)),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),

                  // GÜNCELLE
                  ElevatedButton(
                    style: AppStyles.buttonStyle,
                    onPressed: _kaydediliyor ? null : _kaydet,
                    child: Text(_kaydediliyor ? 'Güncelleniyor...' : 'Güncelle'),
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
        title: Text('Ödev Güncelle', style: AppStyles.titleLarge),
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
                    label: Text("Dosya Ekle"),
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
                    child: Text("Güncelle"),
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