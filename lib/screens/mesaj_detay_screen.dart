import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../constants.dart';

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
    return mesajlar.any((x) {
      final sameSender =
          normalizeTckn(x['GonderenTCKN']) ==
              normalizeTckn(m['GonderenTCKN']);

      final sameText = x['Data'] == m['Data'];

      final t1 = DateTime.parse(x['InsertDate']);
      final t2 = DateTime.parse(m['InsertDate']);

      final closeTime =
          t1.difference(t2).inSeconds.abs() <= 2;

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
        gonderenTckn: widget.tckn,// globals.kullaniciTCKN,
        alanTckn: widget.alanTckn,
        take: _take,
        skip: 0,
      );

      data.sort((a, b) =>
          DateTime.parse(a['InsertDate'])
              .compareTo(DateTime.parse(b['InsertDate'])));

      setState(() {
        for (var m in data) {
          if (!_mesajZatenVar(m)) {
            mesajlar.add(m);
            _sonMesajTarihi =
                DateTime.parse(m['InsertDate']);
          }
        }
      });

      final altaYakin = _kullaniciAltaYakinMi();

      setState(() {
        for (var m in data) {
          if (!_mesajZatenVar(m)) {
            mesajlar.add(m);
            _sonMesajTarihi = DateTime.parse(m['InsertDate']);
          }
        }
      });

      if (altaYakin) {
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

  void mesajGonder() async {
    final text = _mesajController.text.trim();
    if (text.isEmpty) return;

    _mesajController.clear();
    final now = DateTime.now().toIso8601String();

    final localMesaj = {
      "GonderenTCKN": widget.tckn,//globals.kullaniciTCKN,
      "Data": text,
      "InsertDate": now,
    };

    setState(() {
     // mesajlar.add(localMesaj);
      _sonMesajTarihi = DateTime.parse(now);
    });

    _scrollAlta();

    await ApiService().sendMesaj(
     widget.tckn,// globals.kullaniciTCKN,
      [widget.alanTckn],
      "SmartOkul",
      text,
    );
  }

  bool get _mesajYazabilirMi {
    return normalizeTckn(globals.kullaniciTCKN) ==
        normalizeTckn(widget.tckn);
  }

  // ------------------ UI ------------------

  Widget _mesajBalonu(Map<String, dynamic> mesaj) {
    final benim =
        normalizeTckn(mesaj['GonderenTCKN']) ==
            normalizeTckn(widget.tckn,//globals.kullaniciTCKN
            );

    return Align(
      alignment:
      benim ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
            vertical: 4, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: benim
              ? AppColors.primary
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Linkify(
          text: mesaj['Data'] ?? "",
          style: TextStyle(
            color: benim ? Colors.white : Colors.black87,
          ),
          onOpen: (link) async {
            final uri = Uri.parse(
              link.url.startsWith('http')
                  ? link.url
                  : 'https://${link.url}',
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            }
          },
        ),
      ),
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
            child: isLoading
                ? const Center(
                child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              itemCount: mesajlar.length,
              itemBuilder: (context, index) =>
                  _mesajBalonu(mesajlar[index]),
            ),
          ),
          if (_mesajYazabilirMi)
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mesajController,
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
                  onPressed: mesajGonder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}