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
import '../utils/error_translator.dart';

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

  /// 0 = Öğrenciler, 1 = Sınıflar
  int _aliciTab = 0;

  /// 👨‍🎓 Öğrenciler
  List<Map<String, dynamic>> ogrenciler = [];
  late Map<String, bool> ogrenciSecim;
  bool hepsiSecili = true;
  bool ogrenciLoading = true;
  final TextEditingController _ogrenciAramaCtrl = TextEditingController();
  String _ogrenciArama = '';

  /// 🏫 Sınıflar (assignable-classes)
  List<Map<String, dynamic>> _siniflar = [];
  final Map<int, bool> _sinifSecim = {};
  bool _sinifLoading = true;
  bool _sinifHepsi = false;

  /// 📎 Dosyalar
  List<File> selectedFiles = [];
  bool _kaydediliyor = false;

  @override
  void initState() {
    super.initState();
    ogrenciSecim = {};
    _loadDersler();
    _loadOgrenciler();
    _loadSiniflar();
  }

  List<String> get _secilenOgrenciTcknleri => ogrenciSecim.entries
      .where((e) => e.value)
      .map((e) => ApiService.fullStudentTckn(e.key))
      .toList();

  List<int> get _secilenSinifIdleri => _sinifSecim.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList();

  String? get _sinifIdsParam {
    final ids = _secilenSinifIdleri;
    if (ids.isEmpty) return null;
    return ids.join(',');
  }

  bool get _aliciVar =>
      _secilenOgrenciTcknleri.isNotEmpty || _secilenSinifIdleri.isNotEmpty;

  Future<void> _kaydet() async {
    if (_kaydediliyor) return;

    if (seciliDers == null ||
        aciklamaCtrl.text.trim().isEmpty ||
        expireCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fillRequiredFields),
        ),
      );
      return;
    }
    if (!_aliciVar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir öğrenci veya sınıf seçiniz')),
      );
      return;
    }

    setState(() => _kaydediliyor = true);
    try {
      final expireDate = DateFormat('dd-MM-yyyy').parse(expireCtrl.text);
      await ApiService().addOdev(
        gonderenTckn: globals.kullaniciTCKN,
        alanTcknList:
            _secilenOgrenciTcknleri.isEmpty ? null : _secilenOgrenciTcknleri,
        sinifIds: _sinifIdsParam,
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
          content: Text(translateError(e.toString(), context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSiniflar() async {
    try {
      final list = await ApiService.getAssignableClasses();
      if (!mounted) return;
      setState(() {
        _siniflar = list;
        _sinifSecim
          ..clear()
          ..addEntries(list.map((s) => MapEntry(s['Id'] as int, false)));
        _sinifHepsi = false;
        _sinifLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _siniflar = [];
        _sinifLoading = false;
      });
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
      // Sadece öğretmenin öğrencileri: /api/Teacher/getStudents
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
        ogrenciler = [];
        ogrenciSecim = {};
        hepsiSecili = false;
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

  String _ogrenciSinifAdi(Map ogr) {
    final direct = (ogr['ClassName'] ??
            ogr['className'] ??
            ogr['SinifAdi'] ??
            ogr['sinifAdi'] ??
            ogr['sinifAd'] ??
            '')
        .toString()
        .trim();
    if (direct.isNotEmpty) return direct;

    final classId = ogr['ClassId'] ?? ogr['classId'] ?? ogr['SinifId'];
    final cid = classId is int
        ? classId
        : int.tryParse(classId?.toString().split('.').first ?? '');
    if (cid == null) return '';
    for (final s in globals.globalSinifListesi) {
      final sid = s['Id'] ?? s['id'];
      final parsed = sid is int
          ? sid
          : int.tryParse(sid?.toString().split('.').first ?? '');
      if (parsed == cid) {
        return (s['Ad'] ?? s['ad'] ?? '').toString().trim();
      }
    }
    return '';
  }

  int? _ogrenciSinifId(Map ogr) {
    final classId = ogr['ClassId'] ?? ogr['classId'] ?? ogr['SinifId'];
    if (classId is int) return classId;
    if (classId is num) return classId.toInt();
    return int.tryParse(classId?.toString().split('.').first ?? '');
  }

  List<Map<String, dynamic>> get _filtrelenmisOgrenciler {
    final q = _ogrenciArama.trim().toLowerCase();
    if (q.isEmpty) return ogrenciler;
    return ogrenciler.where((o) {
      final name = (o['Name'] ?? '').toString().toLowerCase();
      final sinif = _ogrenciSinifAdi(o).toLowerCase();
      final tckn = (o['TCKN'] ?? '').toString().toLowerCase();
      return name.contains(q) || sinif.contains(q) || tckn.contains(q);
    }).toList();
  }

  /// Filtrelenmiş öğrenciler — classId / className kırılımı
  List<MapEntry<String, List<Map<String, dynamic>>>> get _ogrenciSinifKirilim {
    final byKey = <String, List<Map<String, dynamic>>>{};
    final titles = <String, String>{};
    for (final o in _filtrelenmisOgrenciler) {
      final id = _ogrenciSinifId(o);
      final ad = _ogrenciSinifAdi(o);
      final key = id != null
          ? 'id_$id'
          : (ad.isNotEmpty ? 'ad_${ad.toLowerCase()}' : 'none');
      titles.putIfAbsent(key, () => ad.isNotEmpty ? ad : '—');
      byKey.putIfAbsent(key, () => []).add(o);
    }
    final entries = byKey.entries.toList()
      ..sort((a, b) {
        if (a.key == 'none') return 1;
        if (b.key == 'none') return -1;
        return (titles[a.key] ?? '')
            .toLowerCase()
            .compareTo((titles[b.key] ?? '').toLowerCase());
      });
    return [
      for (final e in entries) MapEntry(titles[e.key] ?? e.key, e.value),
    ];
  }

  void _hepsiDurumunuGuncelle() {
    final list = _filtrelenmisOgrenciler;
    hepsiSecili = list.isNotEmpty &&
        list.every((o) => ogrenciSecim[o['TCKN'].toString()] == true);
  }

  void _sinifHepsiDurumunuGuncelle() {
    _sinifHepsi =
        _sinifSecim.isNotEmpty && _sinifSecim.values.every((v) => v);
  }

  void _toggleSinifOgrencileri(
    List<Map<String, dynamic>> liste,
    bool? value,
  ) {
    final sec = value ?? false;
    setState(() {
      for (final o in liste) {
        ogrenciSecim[o['TCKN'].toString()] = sec;
      }
      _hepsiDurumunuGuncelle();
    });
  }

  List<Widget> _ogrenciSinifGruplari() {
    final l10n = AppLocalizations.of(context)!;
    return _ogrenciSinifKirilim.map((entry) {
      final sinifAdi = entry.key;
      final liste = entry.value;
      final hepsi = liste.isNotEmpty &&
          liste.every((o) => ogrenciSecim[o['TCKN'].toString()] == true);
      final kismi = !hepsi &&
          liste.any((o) => ogrenciSecim[o['TCKN'].toString()] == true);
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            '$sinifAdi  (${liste.length})',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          children: [
            CheckboxListTile(
              dense: true,
              title: Text(l10n.allOfThem),
              tristate: true,
              value: hepsi ? true : (kismi ? null : false),
              onChanged: (v) => _toggleSinifOgrencileri(liste, v ?? false),
            ),
            ...liste.map((ogr) {
              final tckn = ogr['TCKN'].toString();
              return CheckboxListTile(
                dense: true,
                title: Text(ogr['Name']?.toString() ?? ''),
                value: ogrenciSecim[tckn] ?? false,
                onChanged: (v) {
                  setState(() {
                    ogrenciSecim[tckn] = v ?? false;
                    _hepsiDurumunuGuncelle();
                  });
                },
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _sinifCheckboxlari() {
    return _siniflar.map((s) {
      final id = s['Id'] as int;
      final ad = (s['Ad'] ?? '').toString();
      final count = s['StudentCount'] as int? ?? 0;
      return CheckboxListTile(
        dense: true,
        title: Text(ad),
        subtitle: Text(
          count > 0 ? '$count öğrenci' : 'Öğrenci sayısı bilinmiyor',
        ),
        value: _sinifSecim[id] ?? false,
        onChanged: (v) {
          setState(() {
            _sinifSecim[id] = v ?? false;
            _sinifHepsiDurumunuGuncelle();
          });
        },
      );
    }).toList();
  }

  Widget _aliciBolumu() {
    final loading = _aliciTab == 0 ? ogrenciLoading : _sinifLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Alıcılar',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Öğrenciler'), icon: Icon(Icons.person)),
            ButtonSegment(value: 1, label: Text('Sınıflar'), icon: Icon(Icons.groups)),
          ],
          selected: {_aliciTab},
          onSelectionChanged: (s) => setState(() => _aliciTab = s.first),
        ),
        const SizedBox(height: 8),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_aliciTab == 0) ...[
          if (ogrenciler.isEmpty)
            Text(
              AppLocalizations.of(context)!.noStudentsFound,
              style: const TextStyle(color: Colors.white70),
            )
          else ...[
            TextField(
              controller: _ogrenciAramaCtrl,
              onChanged: (v) {
                setState(() {
                  _ogrenciArama = v;
                  _hepsiDurumunuGuncelle();
                });
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _ogrenciArama.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ogrenciAramaCtrl.clear();
                          setState(() {
                            _ogrenciArama = '';
                            _hepsiDurumunuGuncelle();
                          });
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: Text(AppLocalizations.of(context)!.allOfThem),
              subtitle: Text(
                '${_filtrelenmisOgrenciler.length} / ${ogrenciler.length} öğrenci',
              ),
              value: hepsiSecili,
              tileColor: Colors.white.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onChanged: _filtrelenmisOgrenciler.isEmpty
                  ? null
                  : (v) {
                      setState(() {
                        hepsiSecili = v ?? false;
                        for (final o in _filtrelenmisOgrenciler) {
                          ogrenciSecim[o['TCKN'].toString()] = hepsiSecili;
                        }
                      });
                    },
            ),
            const SizedBox(height: 4),
            if (_filtrelenmisOgrenciler.isEmpty)
              Text(
                AppLocalizations.of(context)!.noStudentsFound,
                style: const TextStyle(color: Colors.white70),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: _ogrenciSinifGruplari()),
              ),
          ],
        ] else ...[
          if (_siniflar.isEmpty)
            const Text('Atanabilir sınıf bulunamadı',
                style: TextStyle(color: Colors.white70))
          else ...[
            CheckboxListTile(
              title: Text(AppLocalizations.of(context)!.allOfThem),
              subtitle: Text('${_siniflar.length} sınıf'),
              value: _sinifHepsi,
              tileColor: Colors.white.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onChanged: (v) {
                setState(() {
                  _sinifHepsi = v ?? false;
                  for (final id in _sinifSecim.keys) {
                    _sinifSecim[id] = _sinifHepsi;
                  }
                });
              },
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: _sinifCheckboxlari()),
            ),
          ],
        ],
        if (_aliciVar)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              [
                if (_secilenOgrenciTcknleri.isNotEmpty)
                  '${_secilenOgrenciTcknleri.length} öğrenci',
                if (_secilenSinifIdleri.isNotEmpty)
                  '${_secilenSinifIdleri.length} sınıf',
              ].join(' · '),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    aciklamaCtrl.dispose();
    expireCtrl.dispose();
    _ogrenciAramaCtrl.dispose();
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
            : SafeArea(
                top: false,
                child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.learningAreaOptional,
                  border: const OutlineInputBorder(),
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
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.topicOptional,
                  border: const OutlineInputBorder(),
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

              /// 👥 Alıcılar: Öğrenciler | Sınıflar
              _aliciBolumu(),

              const SizedBox(height: 24),

              /// 💾 Kaydet
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.buttonStyle,
                  onPressed:
                      (_kaydediliyor || !_aliciVar) ? null : _kaydet,
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