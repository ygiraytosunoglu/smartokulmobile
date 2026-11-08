import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../globals.dart' as globals;
import '../models/academic_record.dart';
import '../models/conversation_item.dart';
import '../models/ders_catalog.dart';
import '../services/api_service.dart';
import '../utils/error_translator.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class AcademicRecordFormScreen extends StatefulWidget {
  final AcademicRecordType type;
  final AcademicRecord? kayit;

  const AcademicRecordFormScreen({
    super.key,
    required this.type,
    this.kayit,
  });

  @override
  State<AcademicRecordFormScreen> createState() =>
      _AcademicRecordFormScreenState();
}

class _AcademicRecordFormScreenState extends State<AcademicRecordFormScreen> {
  final _aciklamaCtrl = TextEditingController();
  final _soruCtrl = TextEditingController(text: '0');
  final _dogruCtrl = TextEditingController(text: '0');
  final _yanlisCtrl = TextEditingController(text: '0');

  List<Map<String, dynamic>> _ogrenciler = [];
  List<DersItem> _dersler = [];
  List<DersTema> _temalar = [];
  List<DersKonu> _konular = [];

  String? _studentTckn;
  int? _sinifSeviye;
  int? _dersId;
  int? _temaId;
  int? _konuId;
  DersKonu? _seciliKonu;

  DateTime _tarih = DateTime.now();
  TimeOfDay _saat = TimeOfDay.now();
  bool _loading = true;
  bool _cascadeLoading = false;
  bool _saving = false;

  bool get _etut => widget.type == AcademicRecordType.etut;
  bool get _duzenleme => widget.kayit?.id != null;
  String get _baslik => _etut
      ? (_duzenleme ? 'Etüt Düzenle' : 'Yeni Etüt')
      : (_duzenleme ? 'Özel Ders Düzenle' : 'Yeni Özel Ders');

  String _orig(String tckn) {
    final t = tckn.trim();
    if (t.contains('_')) return t.split('_').first;
    return t;
  }

  String _ogrenciAdi(Map o) => (o['Name'] ?? '').toString();

  String _ogrenciAlt(Map o) {
    final sinif = (o['ClassName'] ?? '').toString().trim();
    final no = (o['SchoolNumber'] ?? '').toString().trim();
    return [if (sinif.isNotEmpty) sinif, if (no.isNotEmpty) 'No: $no']
        .join('  •  ');
  }

  int? _sinifSeviyeFromOgrenci(Map o) {
    final name = (o['ClassName'] ?? '').toString();
    final m = RegExp(r'(\d{1,2})').firstMatch(name);
    if (m != null) {
      final n = int.tryParse(m.group(1)!);
      if (n != null && n >= 1 && n <= 12) return n;
    }
    return null;
  }

  String get _seciliOgrenciYazi {
    if (_studentTckn == null || _studentTckn!.isEmpty) return 'Öğrenci seçiniz';
    for (final o in _ogrenciler) {
      if ((o['TCKN'] ?? '').toString() == _studentTckn) {
        final ad = _ogrenciAdi(o);
        final alt = _ogrenciAlt(o);
        if (ad.isEmpty) return _studentTckn!;
        return alt.isEmpty ? ad : '$ad  ($alt)';
      }
    }
    return widget.kayit?.studentName.isNotEmpty == true
        ? widget.kayit!.studentName
        : _studentTckn!;
  }

  Future<void> _ogrenciAraVeSec() async {
    final secilen = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        var sorgu = '';
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final q = sorgu.trim().toLowerCase();
            final liste = _ogrenciler.where((o) {
              if (q.isEmpty) return true;
              final ad = _ogrenciAdi(o).toLowerCase();
              final sinif = (o['ClassName'] ?? '').toString().toLowerCase();
              final no = (o['SchoolNumber'] ?? '').toString().toLowerCase();
              return ad.contains(q) || sinif.contains(q) || no.contains(q);
            }).toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        autofocus: true,
                        onChanged: (v) => setSheet(() => sorgu = v),
                        decoration: InputDecoration(
                          hintText: 'Öğrenci ara',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: sorgu.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setSheet(() => sorgu = ''),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: liste.isEmpty
                          ? const Center(child: Text('Öğrenci bulunamadı'))
                          : ListView.builder(
                              itemCount: liste.length,
                              itemBuilder: (_, i) {
                                final o = liste[i];
                                final tckn = (o['TCKN'] ?? '').toString();
                                final secili = tckn == _studentTckn;
                                final alt = _ogrenciAlt(o);
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      _ogrenciAdi(o).isNotEmpty
                                          ? _ogrenciAdi(o)[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(_ogrenciAdi(o)),
                                  subtitle: alt.isEmpty ? null : Text(alt),
                                  trailing: secili
                                      ? const Icon(
                                          Icons.check,
                                          color: AppColors.primary,
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(ctx, o),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (secilen == null || !mounted) return;
    final suggested = _sinifSeviyeFromOgrenci(secilen);
    setState(() {
      _studentTckn = (secilen['TCKN'] ?? '').toString();
      if (suggested != null) _sinifSeviye = suggested;
    });
    if (_dersId != null) await _temalariYukle();
  }

  @override
  void initState() {
    super.initState();
    final k = widget.kayit;
    if (k != null) {
      _studentTckn =
          k.studentTckn.isNotEmpty ? k.studentTckn : k.studentTcknOrig;
      _sinifSeviye = k.sinifSeviye;
      _dersId = k.dersId;
      _temaId = k.temaId;
      _konuId = k.konuId;
      _aciklamaCtrl.text = k.aciklama;
      if (k.tarih != null) _tarih = k.tarih!;
      final parts = k.saatYazi.split(':');
      if (parts.length >= 2) {
        _saat = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? _saat.hour,
          minute: int.tryParse(parts[1]) ?? _saat.minute,
        );
      }
      _soruCtrl.text = '${k.soruSayisi ?? 0}';
      _dogruCtrl.text = '${k.dogruSayisi ?? 0}';
      _yanlisCtrl.text = '${k.yanlisSayisi ?? 0}';
    }
    _sinifSeviye ??= 5;
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final schoolId = int.tryParse(globals.globalSchoolId.toString()) ?? 0;
      final students = await ApiService.loadHomeworkStudents();
      final dersler =
          schoolId > 0 ? await ApiService.getSchoolDersler(schoolId) : <DersItem>[];
      if (!mounted) return;

      final seenTckn = <String>{};
      final ogr = students.where((o) {
        final tckn = (o['TCKN'] ?? '').toString();
        if (tckn.isEmpty || seenTckn.contains(tckn)) return false;
        seenTckn.add(tckn);
        return true;
      }).toList();

      if (_studentTckn != null && _studentTckn!.isNotEmpty) {
        final orig = _orig(_studentTckn!);
        Map<String, dynamic>? match;
        for (final o in ogr) {
          if (_orig((o['TCKN'] ?? '').toString()) == orig) {
            match = o;
            break;
          }
        }
        if (match != null) {
          _studentTckn = (match['TCKN'] ?? '').toString();
          _sinifSeviye ??= _sinifSeviyeFromOgrenci(match);
        } else {
          ogr.insert(0, {
            'Name': widget.kayit?.studentName.isNotEmpty == true
                ? widget.kayit!.studentName
                : _studentTckn,
            'TCKN': _studentTckn,
          });
        }
      }

      setState(() {
        _ogrenciler = ogr;
        _dersler = dersler;
        _loading = false;
      });

      if (_dersId != null) {
        await _temalariYukle(preserve: true);
        if (_temaId != null) {
          await _konulariYukle(preserve: true);
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ogrenciler =
            List<Map<String, dynamic>>.from(globals.globalOgrenciListesi);
        _loading = false;
      });
    }
  }

  Future<void> _temalariYukle({bool preserve = false}) async {
    final dersId = _dersId;
    if (dersId == null) return;
    setState(() => _cascadeLoading = true);
    final temalar = await ApiService.getDersTemalar(
      dersId: dersId,
      sinifSeviye: _sinifSeviye,
    );
    if (!mounted) return;
    setState(() {
      _temalar = temalar;
      if (!preserve || !_temalar.any((t) => t.id == _temaId)) {
        _temaId = null;
        _konuId = null;
        _seciliKonu = null;
        _konular = [];
      }
      _cascadeLoading = false;
    });
  }

  Future<void> _konulariYukle({bool preserve = false}) async {
    final temaId = _temaId;
    if (temaId == null) return;
    setState(() => _cascadeLoading = true);
    final konular = await ApiService.getDersKonular(temaId);
    if (!mounted) return;
    setState(() {
      _konular = konular;
      if (!preserve || !_konular.any((k) => k.id == _konuId)) {
        _konuId = null;
        _seciliKonu = null;
      } else {
        _seciliKonu = _konular.firstWhere((k) => k.id == _konuId);
      }
      _cascadeLoading = false;
    });
  }

  Future<void> _dersSecildi(int? id) async {
    setState(() {
      _dersId = id;
      _temaId = null;
      _konuId = null;
      _seciliKonu = null;
      _temalar = [];
      _konular = [];
    });
    if (id != null) await _temalariYukle();
  }

  Future<void> _temaSecildi(int? id) async {
    setState(() {
      _temaId = id;
      _konuId = null;
      _seciliKonu = null;
      _konular = [];
    });
    if (id != null) await _konulariYukle();
  }

  void _konuSecildi(int? id) {
    DersKonu? secili;
    if (id != null) {
      for (final k in _konular) {
        if (k.id == id) {
          secili = k;
          break;
        }
      }
    }
    setState(() {
      _konuId = id;
      _seciliKonu = secili;
    });
  }

  Future<void> _sinifDegisti(int? seviye) async {
    setState(() => _sinifSeviye = seviye);
    if (_dersId != null) await _temalariYukle();
  }

  @override
  void dispose() {
    _aciklamaCtrl.dispose();
    _soruCtrl.dispose();
    _dogruCtrl.dispose();
    _yanlisCtrl.dispose();
    super.dispose();
  }

  String get _saatStr =>
      '${_saat.hour.toString().padLeft(2, '0')}:${_saat.minute.toString().padLeft(2, '0')}';

  int _sayi(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  String? get _dersAdi {
    for (final d in _dersler) {
      if (d.id == _dersId) return d.ad;
    }
    return widget.kayit?.ders;
  }

  String? get _konuAdi => _seciliKonu?.ad ?? widget.kayit?.konu;

  Future<void> _kaydet() async {
    final student = (_studentTckn ?? '').trim();
    if (student.isEmpty ||
        _dersId == null ||
        _temaId == null ||
        _konuId == null) {
      _snack(
        'Öğrenci, ders, öğrenme alanı ve konu zorunludur',
        error: true,
      );
      return;
    }
    if (_etut) {
      final soru = _sayi(_soruCtrl);
      final dogru = _sayi(_dogruCtrl);
      final yanlis = _sayi(_yanlisCtrl);
      if (soru < 0 || dogru < 0 || yanlis < 0) {
        _snack(translateError('ERR_ETUT_SAYI_GECERSIZ', context), error: true);
        return;
      }
      if (soru > 0 && dogru + yanlis > soru) {
        _snack('Doğru + yanlış, soru sayısından büyük olamaz', error: true);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final tarih = DateFormat('yyyy-MM-dd').format(_tarih);
      Map<String, dynamic> result;
      if (_etut) {
        result = await ApiService.saveEtut(
          actorTckn: globals.kullaniciTCKN,
          studentTckn: student,
          tarih: tarih,
          saat: _saatStr,
          dersId: _dersId,
          temaId: _temaId,
          konuId: _konuId,
          ders: _dersAdi,
          konu: _konuAdi,
          aciklama: _aciklamaCtrl.text.trim(),
          id: widget.kayit?.id,
          soruSayisi: _sayi(_soruCtrl),
          dogruSayisi: _sayi(_dogruCtrl),
          yanlisSayisi: _sayi(_yanlisCtrl),
        );
      } else {
        result = await ApiService.saveOzelDers(
          actorTckn: globals.kullaniciTCKN,
          studentTckn: student,
          tarih: tarih,
          saat: _saatStr,
          dersId: _dersId,
          temaId: _temaId,
          konuId: _konuId,
          ders: _dersAdi,
          konu: _konuAdi,
          aciklama: _aciklamaCtrl.text.trim(),
          id: widget.kayit?.id,
        );
      }
      if (!mounted) return;
      final msg = (jsonField(result, 'message') ?? '').toString();
      _snack(
        translateError(
          msg.isEmpty
              ? (_etut
                  ? (_duzenleme ? 'ERR_ETUT_GUNCELLENDI' : 'ERR_ETUT_EKLENDI')
                  : (_duzenleme
                      ? 'ERR_OZELDERS_GUNCELLENDI'
                      : 'ERR_OZELDERS_EKLENDI'))
              : msg,
          context,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack(translateError(e.toString(), context), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      );

  @override
  Widget build(BuildContext context) {
    final kazanimlar = _seciliKonu?.kazanimlar ?? const <DersKazanim>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(_baslik, style: AppStyles.titleLarge),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withValues(alpha: 0.8),
              AppColors.background.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: _ogrenciAraVeSec,
                      child: InputDecorator(
                        decoration: _dec('Öğrenci *').copyWith(
                          suffixIcon: const Icon(Icons.search),
                        ),
                        child: Text(
                          _seciliOgrenciYazi,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _studentTckn == null || _studentTckn!.isEmpty
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _sinifSeviye,
                      decoration: _dec('Sınıf seviyesi *'),
                      items: [
                        for (var i = 1; i <= 12; i++)
                          DropdownMenuItem(value: i, child: Text('$i. Sınıf')),
                      ],
                      onChanged: _sinifDegisti,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _dersler.any((d) => d.id == _dersId)
                          ? _dersId
                          : null,
                      decoration: _dec('Ders *'),
                      items: _dersler
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.ad, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: _dersSecildi,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _temalar.any((t) => t.id == _temaId)
                          ? _temaId
                          : null,
                      decoration: _dec(
                        AppLocalizations.of(context)!.learningAreaRequired,
                      ),
                      items: _temalar
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.ad, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: _dersId == null ? null : _temaSecildi,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _konular.any((k) => k.id == _konuId)
                          ? _konuId
                          : null,
                      decoration: _dec(
                        AppLocalizations.of(context)!.topicRequired,
                      ),
                      items: _konular
                          .map(
                            (k) => DropdownMenuItem(
                              value: k.id,
                              child: Text(k.ad, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: _temaId == null ? null : _konuSecildi,
                    ),
                    if (_cascadeLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (kazanimlar.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Kazanımlar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kazanimlar
                            .map(
                              (k) => Chip(
                                label: Text(k.ad),
                                backgroundColor: Colors.white,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _tarih,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _tarih = d);
                      },
                      child: InputDecorator(
                        decoration: _dec('Tarih *').copyWith(
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('dd.MM.yyyy').format(_tarih)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _saat,
                        );
                        if (t != null) setState(() => _saat = t);
                      },
                      child: InputDecorator(
                        decoration: _dec('Saat *').copyWith(
                          suffixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(_saatStr),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aciklamaCtrl,
                      maxLines: 3,
                      decoration: _dec('Açıklama'),
                    ),
                    if (_etut) ...[
                      const SizedBox(height: 12),
                      _sayiAlani(_soruCtrl, 'Soru sayısı'),
                      const SizedBox(height: 12),
                      _sayiAlani(_dogruCtrl, 'Doğru sayısı'),
                      const SizedBox(height: 12),
                      _sayiAlani(_yanlisCtrl, 'Yanlış sayısı'),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: AppStyles.buttonStyle,
                      onPressed: _saving ? null : _kaydet,
                      child: Text(
                        _saving
                            ? 'Kaydediliyor...'
                            : (_duzenleme ? 'Güncelle' : 'Kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sayiAlani(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _dec(label),
    );
  }
}
