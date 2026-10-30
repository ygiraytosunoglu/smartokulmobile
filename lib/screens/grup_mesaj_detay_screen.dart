import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../constants.dart';
import '../globals.dart' as globals;
import '../models/conversation_item.dart';
import '../services/api_service.dart';
import '../utils/chat_attachment.dart';
import '../utils/error_translator.dart';
import '../widgets/chat_message_bubble.dart';

class GrupMesajDetayScreen extends StatefulWidget {
  final int groupId;
  final String groupName;
  final String tckn;

  const GrupMesajDetayScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.tckn,
  }) : super(key: key);

  @override
  State<GrupMesajDetayScreen> createState() => _GrupMesajDetayScreenState();
}

class _GrupMesajDetayScreenState extends State<GrupMesajDetayScreen> {
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> mesajlar = [];
  List<GroupMember> _uyeler = [];
  bool _uyelerYukleniyor = false;

  Timer? _timer;
  int _skip = 0;
  final int _take = 50;

  bool isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingOld = false;
  bool _hasMore = true;
  bool _gonderiliyor = false;

  bool get _mesajYazabilirMi =>
      _normalizeTckn(globals.kullaniciTCKN) == _normalizeTckn(widget.tckn);

  String _normalizeTckn(dynamic v) {
    if (v == null) return '';
    final t = v.toString().trim();
    if (t.contains('_')) return t.split('_').first;
    return t;
  }

  bool _benimMesajim(Map<String, dynamic> m) {
    final full = (m['GonderenTCKNFull'] ?? '').toString();
    final raw = (m['GonderenTCKN'] ?? '').toString();
    final meFull = widget.tckn;
    final meRaw = _normalizeTckn(widget.tckn);
    if (full.isNotEmpty &&
        (full == meFull || _normalizeTckn(full) == meRaw)) {
      return true;
    }
    return _normalizeTckn(raw) == meRaw;
  }

  int? _mesajId(Map<String, dynamic> m) {
    final id = m['Id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  bool _mesajZatenVar(Map<String, dynamic> m) {
    final incomingId = _mesajId(m);
    return mesajlar.any((x) {
      final existingId = _mesajId(x);
      if (incomingId != null && existingId != null && incomingId == existingId) {
        return true;
      }
      if (x['_isLocal'] == true) {
        return _benimMesajim(x) &&
            x['Data'] == m['Data'] &&
            (x['DosyaAdi'] ?? '') == (m['DosyaAdi'] ?? '') &&
            _benimMesajim(m);
      }
      return false;
    });
  }

  bool _kullaniciAltaYakinMi() {
    if (!_scrollController.hasClients) return true;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    return (max - current) < 100;
  }

  void _scrollAlta() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  DateTime _parseDate(dynamic v) {
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<Map<String, dynamic>> _normalizeList(List<dynamic> data) {
    return data
        .whereType<Map>()
        .map((m) => normalizeGroupMessage(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => _parseDate(a['InsertDate']).compareTo(_parseDate(b['InsertDate'])));
  }

  @override
  void initState() {
    super.initState();
    unawaited(_markRead());
    unawaited(_uyeleriYukle());
    _ilkMesajlariYukle();
    _otomatikRefreshBaslat();
    _scrollController.addListener(() {
      if (_scrollController.offset <=
          _scrollController.position.minScrollExtent + 20) {
        _eskiMesajlariYukle();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _mesajController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    await ApiService().markGroupAsRead(
      grupId: widget.groupId,
      tckn: widget.tckn,
    );
  }

  List<GroupMember> _uyelerFromMessages() {
    final seen = <String>{};
    final list = <GroupMember>[];
    for (final m in mesajlar) {
      if (m['_isLocal'] == true) continue;
      final name = (m['GonderenAdi'] ?? '').toString().trim();
      final tckn = (m['GonderenTCKNFull'] ?? m['GonderenTCKN'] ?? '')
          .toString()
          .trim();
      final key = tckn.isNotEmpty ? _normalizeTckn(tckn) : name;
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      list.add(GroupMember(
        name: name.isEmpty ? 'Üye' : name,
        tckn: tckn.isEmpty ? null : tckn,
      ));
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<void> _uyeleriYukle() async {
    setState(() => _uyelerYukleniyor = true);
    try {
      final data = await ApiService.getGroupMembers(
        grupId: widget.groupId,
        tckn: widget.tckn,
      );
      final parsed = data
          .whereType<Map>()
          .map((m) => GroupMember.fromJson(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (!mounted) return;
      debugPrint('Grup üye sayısı: ${parsed.length}');
      setState(() {
        _uyeler = parsed;
        _uyelerYukleniyor = false;
      });
    } catch (e) {
      debugPrint('Grup üyeleri yüklenemedi: $e');
      if (!mounted) return;
      setState(() {
        _uyeler = _uyelerFromMessages();
        _uyelerYukleniyor = false;
      });
    }
  }

  void _uyeleriGoster() {
    final list = _uyeler.isNotEmpty ? _uyeler : _uyelerFromMessages();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
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
                  child: Row(
                    children: [
                      const Icon(Icons.groups, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.groupName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _uyelerYukleniyor
                            ? '...'
                            : '${list.length} üye',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _uyelerYukleniyor
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                          ? const Center(child: Text('Üye bilgisi yok'))
                          : ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final uye = list[index];
                                final letter = uye.name.isNotEmpty
                                    ? uye.name[0].toUpperCase()
                                    : '?';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      letter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(uye.name),
                                  subtitle: uye.typeLabel.isEmpty
                                      ? null
                                      : Text(uye.typeLabel),
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
  }

  Future<void> _ilkMesajlariYukle() async {
    _skip = 0;
    try {
      final data = await ApiService.getGroupMessages(
        grupId: widget.groupId,
        tckn: widget.tckn,
        take: _take,
        skip: _skip,
      );
      final sorted = _normalizeList(data);
      if (!mounted) return;
      setState(() {
        mesajlar
          ..clear()
          ..addAll(sorted);
        isLoading = false;
        _hasMore = data.length == _take;
        if (_uyeler.isEmpty) {
          _uyeler = _uyelerFromMessages();
        }
      });
      _scrollAlta();
    } catch (e) {
      debugPrint('Grup mesaj yükleme hatası: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _otomatikRefreshBaslat() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _yeniMesajlariKontrolEt(),
    );
  }

  Future<void> _yeniMesajlariKontrolEt() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final data = await ApiService.getGroupMessages(
        grupId: widget.groupId,
        tckn: widget.tckn,
        take: _take,
        skip: 0,
      );
      final sorted = _normalizeList(data);
      bool yeniMesajVar = false;
      if (!mounted) return;
      setState(() {
        for (final m in sorted) {
          final localIdx = mesajlar.indexWhere((x) =>
              x['_isLocal'] == true &&
              _benimMesajim(x) &&
              x['Data'] == m['Data'] &&
              (x['DosyaAdi'] ?? '') == (m['DosyaAdi'] ?? ''));
          if (localIdx >= 0) {
            mesajlar[localIdx] = m;
            yeniMesajVar = true;
          } else if (!_mesajZatenVar(m)) {
            mesajlar.add(m);
            yeniMesajVar = true;
          }
        }
        mesajlar.removeWhere((x) {
          if (x['_isLocal'] != true) return false;
          return sorted.any((m) =>
              m['Data'] == x['Data'] &&
              (m['DosyaAdi'] ?? '') == (x['DosyaAdi'] ?? ''));
        });
      });
      if (yeniMesajVar && _kullaniciAltaYakinMi()) {
        _scrollAlta();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _eskiMesajlariYukle() async {
    if (_isLoadingOld || !_hasMore) return;
    _isLoadingOld = true;
    final eskiScrollY =
        _scrollController.hasClients ? _scrollController.position.pixels : 0.0;
    _skip += _take;
    try {
      final data = await ApiService.getGroupMessages(
        grupId: widget.groupId,
        tckn: widget.tckn,
        take: _take,
        skip: _skip,
      );
      if (data.isEmpty) {
        _hasMore = false;
        _isLoadingOld = false;
        return;
      }
      final sorted = _normalizeList(data);
      if (!mounted) return;
      setState(() {
        for (final m in sorted.reversed) {
          if (!_mesajZatenVar(m)) {
            mesajlar.insert(0, m);
          }
        }
        _hasMore = data.length == _take;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(eskiScrollY + 120);
        }
      });
    } catch (e) {
      debugPrint('Eski grup mesajları hatası: $e');
      _skip -= _take;
    } finally {
      _isLoadingOld = false;
    }
  }

  void _hataGoster(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(translateError(e.toString(), context))),
    );
  }

  Future<void> _ekSec() async {
    if (_gonderiliyor) return;
    final file = await pickChatAttachment(context);
    if (file == null || !mounted) return;
    final err = validateChatAttachment(file);
    if (err != null) {
      _hataGoster(err);
      return;
    }
    final payload = await confirmChatAttachment(
      context: context,
      file: file,
      initialCaption: _mesajController.text.trim(),
    );
    if (payload == null || !mounted) return;
    _mesajController.clear();
    await _mesajGonder(text: payload.caption, file: payload.file);
  }

  Future<void> mesajGonder() async {
    final text = _mesajController.text.trim();
    if (text.isEmpty) return;
    _mesajController.clear();
    await _mesajGonder(text: text);
  }

  Future<void> _mesajGonder({String text = '', File? file}) async {
    if (_gonderiliyor) return;
    if (text.isEmpty && file == null) {
      _hataGoster('ERR_MESAJ_BOS');
      return;
    }
    _gonderiliyor = true;
    final now = DateTime.now();
    final dosyaAdi = file == null ? '' : p.basename(file.path);
    final localMesaj = {
      'GonderenTCKN': _normalizeTckn(widget.tckn),
      'GonderenTCKNFull': widget.tckn,
      'GonderenAdi': '',
      'Data': text,
      'InsertDate': now.toIso8601String(),
      'Saat':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      '_isLocal': true,
      '_uploading': file != null,
      'HasAttachment': file != null,
      'DosyaAdi': dosyaAdi,
      'EkTuru': file == null ? '' : ekTuruFromPath(file.path),
      '_localPath': file?.path ?? '',
    };

    setState(() => mesajlar.add(localMesaj));
    _scrollAlta();

    try {
      await ApiService.sendGroupMesajWithFile(
        grupId: widget.groupId,
        gonderenTckn: widget.tckn,
        data: text.isEmpty ? null : text,
        file: file,
      );
      _isRefreshing = false;
      await _yeniMesajlariKontrolEt();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        mesajlar.removeWhere(
          (m) =>
              m['_isLocal'] == true &&
              m['Data'] == text &&
              (m['DosyaAdi'] ?? '') == dosyaAdi,
        );
      });
      _hataGoster(e);
    } finally {
      _gonderiliyor = false;
    }
  }

  Widget _mesajBalonu(Map<String, dynamic> mesaj, int index) {
    final benim = _benimMesajim(mesaj);
    final showDate =
        index == 0 || !chatAyniGun(mesaj, mesajlar[index - 1]);
    return ChatMessageBubble(
      mesaj: mesaj,
      benim: benim,
      tckn: widget.tckn,
      isGroup: true,
      showDateHeader: showDate,
      showSenderName: !benim,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _uyeleriGoster,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.groupName),
              Text(
                _uyelerYukleniyor
                    ? 'Üyeler yükleniyor...'
                    : '${(_uyeler.isNotEmpty ? _uyeler : _uyelerFromMessages()).length} üye',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.groups),
            tooltip: 'Grup üyeleri',
            onPressed: _uyeleriGoster,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.red.withOpacity(0.08),
            child: const Text(
              '* Konuşma metni okul yönetimi gözetimindedir',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _ilkMesajlariYukle,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: mesajlar.length,
                      itemBuilder: (context, index) =>
                          _mesajBalonu(mesajlar[index], index),
                    ),
                  ),
          ),
          if (_mesajYazabilirMi)
            SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _gonderiliyor ? null : _ekSec,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _mesajController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => mesajGonder(),
                      decoration: const InputDecoration(
                        hintText: 'Mesaj yaz...',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _gonderiliyor ? null : mesajGonder,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
