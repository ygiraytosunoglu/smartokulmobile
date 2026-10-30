import 'package:flutter/material.dart';

import '../constants.dart';
import '../globals.dart' as globals;
import '../models/academic_record.dart';
import '../models/conversation_item.dart';
import '../services/api_service.dart';
import '../utils/error_translator.dart';
import 'academic_record_form_screen.dart';

class AcademicRecordListScreen extends StatefulWidget {
  final AcademicRecordType type;

  const AcademicRecordListScreen({super.key, required this.type});

  @override
  State<AcademicRecordListScreen> createState() =>
      _AcademicRecordListScreenState();
}

class _AcademicRecordListScreenState extends State<AcademicRecordListScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<AcademicRecord> _kayitlar = [];

  static const int _take = 20;
  int _skip = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  bool get _etut => widget.type == AcademicRecordType.etut;
  bool get _yazabilir =>
      globals.globalKullaniciTipi == 'T' ||
      globals.globalKullaniciTipi == 'M';

  String get _baslik => _etut ? 'Etüt Listesi' : 'Özel Ders Listesi';
  String get _yeniLabel => _etut ? 'Yeni Etüt' : 'Yeni Özel Ders';
  String get _bos =>
      _etut ? 'Henüz etüt kaydı yok' : 'Henüz özel ders kaydı yok';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _yukle(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore || _loadingMore || _loading) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _yukle(reset: false);
    }
  }

  Future<List<AcademicRecord>> _fetch({required int skip}) {
    if (_etut) {
      return ApiService.listEtut(
        globals.kullaniciTCKN,
        take: _take,
        skip: skip,
      );
    }
    return ApiService.listOzelDers(
      globals.kullaniciTCKN,
      take: _take,
      skip: skip,
    );
  }

  Future<void> _yukle({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _skip = 0;
        _hasMore = true;
      });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }

    final skip = reset ? 0 : _skip;
    try {
      final data = await _fetch(skip: skip);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _kayitlar
            ..clear()
            ..addAll(data);
        } else {
          final existingIds = {
            for (final k in _kayitlar)
              if (k.id != null) k.id!,
          };
          for (final k in data) {
            if (k.id != null && existingIds.contains(k.id)) continue;
            _kayitlar.add(k);
          }
        }
        _skip = skip + data.length;
        _hasMore = data.length == _take;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (reset) _kayitlar.clear();
        _loading = false;
        _loadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translateError(e.toString(), context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _formAc({AcademicRecord? kayit}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AcademicRecordFormScreen(
          type: widget.type,
          kayit: kayit,
        ),
      ),
    );
    if (ok == true) _yukle(reset: true);
  }

  void _detayGoster(AcademicRecord k) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _etut ? 'Etüt Detayı' : 'Özel Ders Detayı',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _satir('Öğrenci', k.studentName),
                _satir('Tarih', k.tarihYazi),
                _satir('Saat', k.saatYazi),
                if (k.sinifSeviye != null)
                  _satir('Sınıf', '${k.sinifSeviye}. Sınıf'),
                _satir('Ders', k.ders),
                if (k.tema.isNotEmpty) _satir('Öğrenme Alanı', k.tema),
                if (k.konu.isNotEmpty) _satir('Konu', k.konu),
                if (k.kazanim.isNotEmpty) _satir('Kazanım', k.kazanim),
                if (k.aciklama.isNotEmpty) _satir('Açıklama', k.aciklama),
                if (_etut && k.etutOzet.isNotEmpty) _satir('Özet', k.etutOzet),
                if (k.createdByName.isNotEmpty)
                  _satir('Kayıt eden', k.createdByName),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _satir(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  Future<void> _sil(AcademicRecord k) async {
    final id = k.id;
    if (id == null) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: Text(
          _etut
              ? 'Bu etüt kaydı silinecek.'
              : 'Bu özel ders kaydı silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (onay != true) return;
    try {
      final result = _etut
          ? await ApiService.deleteEtut(
              actorTckn: globals.kullaniciTCKN,
              id: id,
            )
          : await ApiService.deleteOzelDers(
              actorTckn: globals.kullaniciTCKN,
              id: id,
            );
      if (!mounted) return;
      final msg = (jsonField(result, 'message') ?? '').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            translateError(
              msg.isEmpty
                  ? (_etut ? 'ERR_ETUT_SILINDI' : 'ERR_OZELDERS_SILINDI')
                  : msg,
              context,
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _yukle(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translateError(e.toString(), context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _kart(AcademicRecord k, Color? renk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: AppStyles.listCardDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            onTap: () {
              if (_yazabilir) {
                _formAc(kayit: k);
              } else {
                _detayGoster(k);
              }
            },
            title: Text(
              k.studentName.isEmpty ? k.ders : k.studentName,
              style: TextStyle(
                color: renk,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (k.tarihYazi.isNotEmpty) k.tarihYazi,
                    if (k.saatYazi.isNotEmpty) k.saatYazi,
                    if (k.sinifSeviye != null) '${k.sinifSeviye}. Sınıf',
                    if (k.ders.isNotEmpty) k.ders,
                  ].join('  •  '),
                  style: TextStyle(color: renk),
                ),
                if (k.tema.isNotEmpty)
                  Text(k.tema, style: TextStyle(color: renk)),
                if (k.konu.isNotEmpty)
                  Text(k.konu, style: TextStyle(color: renk)),
                if (k.kazanimSatirlari.isNotEmpty)
                  Text(
                    k.kazanimSatirlari.first,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: renk, fontSize: 12),
                  ),
                if (_etut && k.etutOzet.isNotEmpty)
                  Text(
                    k.etutOzet,
                    style: TextStyle(
                      color: renk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            trailing: _yazabilir
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Düzenle',
                        onPressed: () => _formAc(kayit: k),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Sil',
                        onPressed: () => _sil(k),
                      ),
                    ],
                  )
                : const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final renk = Colors.blue[900];
    final itemCount =
        _kayitlar.length + (_loadingMore && _kayitlar.isNotEmpty ? 1 : 0);

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
        child: Column(
          children: [
            if (_yazabilir)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _formAc(),
                    icon: const Icon(Icons.add, color: AppColors.onPrimary),
                    label: Text(_yeniLabel),
                    style: AppStyles.buttonStyle,
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => _yukle(reset: true),
                      child: _kayitlar.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    _bos,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: itemCount,
                              itemBuilder: (context, index) {
                                if (index >= _kayitlar.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return _kart(_kayitlar[index], renk);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
