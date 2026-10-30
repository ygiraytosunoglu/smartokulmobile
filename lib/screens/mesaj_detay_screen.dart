import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../constants.dart';
import '../utils/chat_attachment.dart';
import '../utils/error_translator.dart';
import '../widgets/chat_message_bubble.dart';

class MesajDetayScreen extends StatefulWidget {
  final String alanTckn;
  final String alanAdi;
  final String tckn; // 👈 PARAMETRE


  const MesajDetayScreen({
    Key? key,
    required this.tckn,
    required this.alanTckn,
    required this.alanAdi,
  }) : super(key: key);

  @override
  State<MesajDetayScreen> createState() => _MesajDetayScreenState();
}

class _MesajDetayScreenState extends State<MesajDetayScreen> {
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> mesajlar = [];

  Timer? _timer;
  DateTime? _sonMesajTarihi;

  int _skip = 0;
  final int _take = 50;

  bool isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingOld = false;
  bool _hasMore = true;
  bool _gonderiliyor = false;

  bool _kullaniciAltaYakinMi() {
    if (!_scrollController.hasClients) return true;

    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    return (max - current) < 100;
  }

  // ------------------ UTIL ------------------

  String normalizeTckn(dynamic v) {
    if (v == null) return "";
    String t = v.toString().trim();
    if (t.contains('_')) t = t.split('_').first;
    return t;
  }

  bool _mesajZatenVar(Map<String, dynamic> m) {
    final incomingId = m['Id'];
    if (incomingId != null &&
        mesajlar.any((x) => x['Id'] != null && x['Id'] == incomingId)) {
      return true;
    }
    return mesajlar.any((x) {
      final sameSender =
          normalizeTckn(x['GonderenTCKN']) ==
              normalizeTckn(m['GonderenTCKN']);

      final sameText = x['Data'] == m['Data'];

      // Yerel (henüz sunucu onayı olmayan) mesajla eşleşme: zaman farkına bakma
      if (x['_isLocal'] == true) {
        return sameSender &&
            sameText &&
            (x['DosyaAdi'] ?? '') == (m['DosyaAdi'] ?? '');
      }

      final t1 = DateTime.parse(x['InsertDate']);
      final t2 = DateTime.parse(m['InsertDate']);

      final closeTime =
          t1.difference(t2).inSeconds.abs() <= 5;

      return sameSender && sameText && closeTime;
    });
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

  // ------------------ INIT ------------------

  @override
  void initState() {
    super.initState();
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

  // ------------------ İLK MESAJLAR ------------------

  Future<void> _ilkMesajlariYukle() async {
    _skip = 0;

    final data = await ApiService.getConversationMessages(
      gonderenTckn: widget.tckn,//globals.kullaniciTCKN,
      alanTckn: widget.alanTckn,
      take: _take,
      skip: _skip,
    );

    data.sort((a, b) =>
        DateTime.parse(a['InsertDate'])
            .compareTo(DateTime.parse(b['InsertDate'])));

    setState(() {
      mesajlar.clear();

      for (var m in data) {
        if (!_mesajZatenVar(m)) {
          mesajlar.add(m);
        }
      }

      if (mesajlar.isNotEmpty) {
        _sonMesajTarihi =
            DateTime.parse(mesajlar.last['InsertDate']);
      }

      isLoading = false;
      _hasMore = data.length == _take;
    });

    _scrollAlta();
  }

  // ------------------ YENİ MESAJLAR ------------------

  void _otomatikRefreshBaslat() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _yeniMesajlariKontrolEt(),
    );
  }

  Future<void> _yeniMesajlariKontrolEt() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final data = await ApiService.getConversationMessages(
        gonderenTckn: widget.tckn,
        alanTckn: widget.alanTckn,
        take: _take,
        skip: 0,
      );

      data.sort((a, b) =>
          DateTime.parse(a['InsertDate'])
              .compareTo(DateTime.parse(b['InsertDate'])));

      bool yeniMesajVar = false;

      setState(() {
        for (var m in data) {
          // Sunucu yanıtıyla eşleşen local placeholder varsa yerine koy
          final localIdx = mesajlar.indexWhere((x) =>
              x['_isLocal'] == true &&
              normalizeTckn(x['GonderenTCKN']) == normalizeTckn(m['GonderenTCKN']) &&
              x['Data'] == m['Data'] &&
              (x['DosyaAdi'] ?? '') == (m['DosyaAdi'] ?? ''));

          if (localIdx >= 0) {
            mesajlar[localIdx] = m;
            yeniMesajVar = true;
          } else if (!_mesajZatenVar(m)) {
            mesajlar.add(m);
            _sonMesajTarihi = DateTime.parse(m['InsertDate']);
            yeniMesajVar = true;
          }
        }

        // Eşleşemeyen stale local mesajları kaldır:
        // Sunucu bu mesajları döndürdü ama local placeholder hâlâ varsa
        // (TCKN format farkı, saat kayması vb.) listeye girmeli, duplicat kalmamalı.
        mesajlar.removeWhere((x) {
          if (x['_isLocal'] != true) return false;
          return data.any((m) =>
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

  // ------------------ ESKİ MESAJLAR ------------------

  Future<void> _eskiMesajlariYukle() async {
    if (_isLoadingOld || !_hasMore) return;
    _isLoadingOld = true;

    final eskiScrollY = _scrollController.position.pixels;

    _skip += _take;

    final data = await ApiService.getConversationMessages(
      gonderenTckn: widget.tckn,//globals.kullaniciTCKN,
      alanTckn: widget.alanTckn,
      take: _take,
      skip: _skip,
    );

    if (data.isEmpty) {
      _hasMore = false;
      _isLoadingOld = false;
      return;
    }

    data.sort((a, b) =>
        DateTime.parse(a['InsertDate'])
            .compareTo(DateTime.parse(b['InsertDate'])));

    setState(() {
      for (var m in data.reversed) {
        if (!_mesajZatenVar(m)) {
          mesajlar.insert(0, m);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(eskiScrollY + 120);
    });

    _isLoadingOld = false;
  }

  // ------------------ MESAJ GÖNDER ------------------

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
      'GonderenTCKN': widget.tckn,
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

    setState(() {
      mesajlar.add(localMesaj);
      _sonMesajTarihi = now;
    });
    _scrollAlta();

    try {
      await ApiService.sendMesajWithFile(
        gonderenTckn: widget.tckn,
        alanTckn: widget.alanTckn,
        data: text.isEmpty ? null : text,
        file: file,
      );
      _isRefreshing = false;
      await _yeniMesajlariKontrolEt();
    } catch (e) {
      if (mounted) {
        setState(() {
          mesajlar.removeWhere(
            (m) =>
                m['_isLocal'] == true &&
                m['Data'] == text &&
                (m['DosyaAdi'] ?? '') == dosyaAdi,
          );
        });
        _hataGoster(e);
      }
    } finally {
      _gonderiliyor = false;
    }
  }

  bool get _mesajYazabilirMi {
    return normalizeTckn(globals.kullaniciTCKN) ==
        normalizeTckn(widget.tckn);
  }

  // ------------------ UI ------------------

  Widget _mesajBalonu(Map<String, dynamic> mesaj, int index) {
    final benim = normalizeTckn(mesaj['GonderenTCKN']) ==
        normalizeTckn(widget.tckn);
    final showDate = index == 0 ||
        !chatAyniGun(mesaj, mesajlar[index - 1]);
    return ChatMessageBubble(
      mesaj: mesaj,
      benim: benim,
      tckn: widget.tckn,
      showDateHeader: showDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alanAdi),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [

                /// ✅ STICKY WARNING
                _konusmaUyariBanner(),

                /// ✅ MESAJ LİSTESİ
                Expanded(
                  child: isLoading
                      ? const Center(
                      child: CircularProgressIndicator())
                      : ListView.builder(
                    controller: _scrollController,
                    itemCount: mesajlar.length,
                    itemBuilder: (context, index) =>
                        _mesajBalonu(mesajlar[index], index),
                  ),
                ),
              ],
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
                      hintText: "Mesaj yaz...",
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(20)),
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
Widget _konusmaUyariBanner() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
        vertical: 8, horizontal: 12),
    color: Colors.red.withOpacity(0.08),
    child: Text(
      "* Konuşma metni okul yönetimi gözetimindedir",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.red,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}