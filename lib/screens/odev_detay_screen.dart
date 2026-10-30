import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../globals.dart' as globals;
import '../models/conversation_item.dart';
import '../services/api_service.dart';
import '../utils/chat_attachment.dart';
import '../utils/error_translator.dart';

class OdevDetayScreen extends StatefulWidget {
  final int odevId;

  const OdevDetayScreen({super.key, required this.odevId});

  @override
  State<OdevDetayScreen> createState() => _OdevDetayScreenState();
}

class _OdevDetayScreenState extends State<OdevDetayScreen> {
  Map<String, dynamic>? _odev;
  bool _loading = true;
  bool _busy = false;

  final _cevapCtrl = TextEditingController();
  List<File> _cevapDosyalari = [];

  bool get _ogretmen =>
      globals.globalKullaniciTipi == 'T' ||
      globals.globalKullaniciTipi == 'M';
  bool get _ogrenci => globals.globalKullaniciTipi == 'S';
  bool get _veli => globals.globalKullaniciTipi == 'P';

  String get _tckn => globals.kullaniciTCKN;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _cevapCtrl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getOdevById(
        odevId: widget.odevId,
        tckn: _tckn,
      );
      if (!mounted) return;
      setState(() {
        _odev = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translateError(e.toString(), context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _aciklama(Map odev) {
    final raw = jsonString(odev, 'data') ?? '';
    try {
      if (raw.startsWith('{')) {
        final parsed = jsonDecode(raw);
        if (parsed is Map) return (parsed['aciklama'] ?? '').toString();
      }
    } catch (_) {}
    return raw;
  }

  List<String> _urls(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> get _alicilar {
    final raw = jsonField(_odev ?? {}, 'alicilar') ??
        jsonField(_odev ?? {}, 'alıcılar');
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String get _studentTcknForCevap {
    if (_ogrenci) return globals.kullaniciTCKN;
    final selected = (globals.studentTckn ?? '').trim();
    if (selected.isNotEmpty) return selected;
    if (_alicilar.isNotEmpty) {
      final fromAlici = jsonString(_alicilar.first, 'tckn') ??
          jsonString(_alicilar.first, 'studentTckn');
      if (fromAlici != null && fromAlici.trim().isNotEmpty) {
        return fromAlici.trim();
      }
    }
    if (globals.globalOgrenciListesi.isNotEmpty) {
      final t = (globals.globalOgrenciListesi.first['TCKN'] ??
              globals.globalOgrenciListesi.first['tckn'] ??
              '')
          .toString()
          .trim();
      if (t.isNotEmpty) return t;
    }
    return globals.kullaniciTCKN;
  }

  bool get _cevapGonderebilir => _ogrenci || _veli;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _cevapGonder() async {
    if (_cevapCtrl.text.trim().isEmpty && _cevapDosyalari.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Açıklama veya dosya ekleyiniz')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ApiService().cevapOdev(
        odevId: widget.odevId,
        studentTckn: _studentTcknForCevap,
        schoolId: int.parse(globals.globalSchoolId.toString()),
        aciklama: _cevapCtrl.text.trim(),
        files: _cevapDosyalari,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cevap gönderildi'),
          backgroundColor: Colors.green,
        ),
      );
      _cevapCtrl.clear();
      _cevapDosyalari = [];
      await _yukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translateError(e.toString(), context)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onayla(Map alici, bool onaylandi) async {
    final studentTckn =
        (jsonString(alici, 'tckn') ?? jsonString(alici, 'studentTckn') ?? '')
            .toString();
    if (studentTckn.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ApiService().onayOdev(
        odevId: widget.odevId,
        actorTckn: globals.kullaniciTCKN,
        studentTckn: studentTckn,
        onaylandi: onaylandi,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(onaylandi ? 'Ödev onaylandı' : 'Ödev reddedildi'),
          backgroundColor: Colors.green,
        ),
      );
      await _yukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translateError(e.toString(), context)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _dosyaLink(String url) {
    final segs = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    final name = segs.isNotEmpty ? segs.last : 'Dosya';
    return InkWell(
      onTap: () => _openUrl(url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.download, size: 18, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _satir(String baslik, String deger) {
    if (deger.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$baslik:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(deger)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final odev = _odev;
    return Scaffold(
      appBar: AppBar(
        title: Text('Ödev Detayı', style: AppStyles.titleLarge),
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
        child: _loading || odev == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _yukle,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      decoration: AppStyles.listCardDecoration,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _satir(
                            'Ders',
                            jsonString(odev, 'ders') ??
                                jsonString(odev, 'dersAdi') ??
                                '',
                          ),
                          _satir('Öğrenme Alanı', jsonString(odev, 'tema') ?? ''),
                          _satir('Konu', jsonString(odev, 'konu') ?? ''),
                          if (jsonInt(odev, 'sinifSeviye') != null)
                            _satir(
                              'Sınıf',
                              '${jsonInt(odev, 'sinifSeviye')}. Sınıf',
                            ),
                          _satir(
                            'Son tarih',
                            () {
                              final d = jsonDate(odev, 'expireDate');
                              return d == null
                                  ? ''
                                  : DateFormat('dd.MM.yyyy').format(d);
                            }(),
                          ),
                          const Divider(),
                          const Text(
                            'Açıklama',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(_aciklama(odev).isEmpty ? '-' : _aciklama(odev)),
                          ..._urls(
                            jsonField(odev, 'docPaths') ??
                                jsonField(odev, 'DocPaths'),
                          ).map(_dosyaLink),
                          if (!_ogretmen) ...[
                            Builder(
                              builder: (_) {
                                final alici =
                                    _alicilar.isNotEmpty ? _alicilar.first : null;
                                final onay = jsonString(odev, 'onayDurumText') ??
                                    (alici == null
                                        ? null
                                        : jsonString(alici, 'onayDurumText')) ??
                                    '';
                                final cevap =
                                    jsonString(odev, 'cevapAciklama') ??
                                        (alici == null
                                            ? null
                                            : jsonString(alici, 'cevapAciklama')) ??
                                        '';
                                final cevapDocs = _urls(
                                  alici == null
                                      ? null
                                      : (jsonField(alici, 'cevapDocPaths') ??
                                          jsonField(alici, 'cevapdocpaths')),
                                );
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    _satir('Onay', onay),
                                    _satir(
                                      _veli ? 'Cevap' : 'Cevabım',
                                      cevap,
                                    ),
                                    ...cevapDocs.map(_dosyaLink),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_ogretmen) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Alıcılar (${_alicilar.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._alicilar.map((a) {
                        final name = jsonString(a, 'name') ?? '';
                        final durum =
                            jsonString(a, 'onayDurumText') ?? 'Bekliyor';
                        final cevap = jsonString(a, 'cevapAciklama') ?? '';
                        final cevapDocs = _urls(
                          jsonField(a, 'cevapDocPaths') ??
                              jsonField(a, 'cevapdocpaths'),
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: AppStyles.listCardDecoration,
                          child: ExpansionTile(
                            title: Text(name),
                            subtitle: Text(durum),
                            children: [
                              if (cevap.isNotEmpty)
                                ListTile(
                                  dense: true,
                                  title: const Text('Cevap'),
                                  subtitle: Text(cevap),
                                ),
                              ...cevapDocs.map(_dosyaLink),
                              ButtonBar(
                                children: [
                                  TextButton(
                                    onPressed:
                                        _busy ? null : () => _onayla(a, true),
                                    child: const Text('Onayla'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        _busy ? null : () => _onayla(a, false),
                                    child: const Text(
                                      'Reddet',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (_cevapGonderebilir) ...[
                      const SizedBox(height: 16),
                      Container(
                        decoration: AppStyles.listCardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _veli
                                  ? 'Öğrenci Adına Cevap Gönder'
                                  : 'Cevap Gönder',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _cevapCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Açıklama (isteğe bağlı)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () async {
                                      final files =
                                          await pickMultipleAttachments(context);
                                      if (files.isEmpty || !mounted) return;
                                      setState(
                                        () => _cevapDosyalari.addAll(files),
                                      );
                                    },
                              icon: const Icon(Icons.attach_file),
                              label: Text(
                                _cevapDosyalari.isEmpty
                                    ? 'Dosya ekle'
                                    : 'Dosya ekle (${_cevapDosyalari.length})',
                              ),
                            ),
                            if (_cevapDosyalari.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...List.generate(_cevapDosyalari.length, (i) {
                                final f = _cevapDosyalari[i];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.insert_drive_file,
                                    size: 20,
                                  ),
                                  title: Text(
                                    p.basename(f.path),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: _busy
                                        ? null
                                        : () => setState(
                                              () => _cevapDosyalari.removeAt(i),
                                            ),
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: AppStyles.buttonStyle,
                              onPressed: _busy ? null : _cevapGonder,
                              child: Text(
                                _busy ? 'Gönderiliyor...' : 'Cevabı Gönder',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
