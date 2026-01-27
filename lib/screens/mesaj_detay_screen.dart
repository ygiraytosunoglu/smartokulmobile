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

  const MesajDetayScreen({
    Key? key,
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
      gonderenTckn: globals.kullaniciTCKN,
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
        gonderenTckn: globals.kullaniciTCKN,
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

      _scrollAlta();
    } finally {
      _isRefreshing = false;
    }
  }

  // ------------------ ESKİ MESAJLAR ------------------

  Future<void> _eskiMesajlariYukle() async {
    if (_isLoadingOld || !_hasMore) return;
    _isLoadingOld = true;

    _skip += _take;

    final data = await ApiService.getConversationMessages(
      gonderenTckn: globals.kullaniciTCKN,
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

    _isLoadingOld = false;
  }

  // ------------------ MESAJ GÖNDER ------------------

  void mesajGonder() async {
    final text = _mesajController.text.trim();
    if (text.isEmpty) return;

    _mesajController.clear();
    final now = DateTime.now().toIso8601String();

    final localMesaj = {
      "GonderenTCKN": globals.kullaniciTCKN,
      "Data": text,
      "InsertDate": now,
    };

    setState(() {
     // mesajlar.add(localMesaj);
      _sonMesajTarihi = DateTime.parse(now);
    });

    _scrollAlta();

    await ApiService().sendMesaj(
      globals.kullaniciTCKN,
      [widget.alanTckn],
      "SmartOkul",
      text,
    );
  }

  // ------------------ UI ------------------

  Widget _mesajBalonu(Map<String, dynamic> mesaj) {
    final benim =
        normalizeTckn(mesaj['GonderenTCKN']) ==
            normalizeTckn(globals.kullaniciTCKN);

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


/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../constants.dart';

class MesajDetayScreen extends StatefulWidget {
  final String alanTckn;
  final String alanAdi;

  const MesajDetayScreen({
    Key? key,
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
  bool _isRefreshing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _ilkMesajlariYukle();
    _otomatikRefreshBaslat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _mesajController.dispose();
    super.dispose();
  }

  Future<void> _ilkMesajlariYukle() async {
    final data = await ApiService.getConversationMessages(
      gonderenTckn: globals.kullaniciTCKN,
      alanTckn: widget.alanTckn,
      take: 50,
      skip: 0,
    );

    data.sort((a, b) =>
        DateTime.parse(a['InsertDate'])
            .compareTo(DateTime.parse(b['InsertDate'])));

    setState(() {
      mesajlar.addAll(data.cast<Map<String, dynamic>>());
      if (mesajlar.isNotEmpty) {
        _sonMesajTarihi = DateTime.parse(mesajlar.last['InsertDate']);
      }
      isLoading = false;
    });

    _scrollAlta();
  }

  void _otomatikRefreshBaslat() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _yeniMesajlariKontrolEt();
    });
  }

  Future<void> _yeniMesajlariKontrolEt() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final data = await ApiService.getConversationMessages(
        gonderenTckn: globals.kullaniciTCKN,
        alanTckn: widget.alanTckn,
        take: 50,
        skip: 0,
      );

      data.sort((a, b) =>
          DateTime.parse(a['InsertDate'])
              .compareTo(DateTime.parse(b['InsertDate'])));

      final yeniMesajlar = data.where((m) {
        final t = DateTime.parse(m['InsertDate']);
        return _sonMesajTarihi == null || t.isAfter(_sonMesajTarihi!);
      }).toList();

      if (yeniMesajlar.isNotEmpty) {
        setState(() {
          mesajlar.addAll(yeniMesajlar.cast<Map<String, dynamic>>());
          _sonMesajTarihi =
              DateTime.parse(yeniMesajlar.last['InsertDate']);
        });

        _scrollAlta();
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void mesajGonder() async {
    final text = _mesajController.text.trim();
    if (text.isEmpty) return;

    _mesajController.clear();
    final now = DateTime.now();

    setState(() {
      mesajlar.add({
        "GonderenTCKN": globals.kullaniciTCKN,
        "Data": text,
        "InsertDate": now.toIso8601String(),
      });
      _sonMesajTarihi = now;
    });

    _scrollAlta();

    await ApiService().sendMesaj(
      globals.kullaniciTCKN,
      [widget.alanTckn],
      "YAZISMA",
      text,
    );
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

  String normalizeTckn(dynamic v) {
    if (v == null) return "";
    String t = v.toString().trim();
    if (t.contains('_')) t = t.split('_').first;
    return t;
  }

  Widget _mesajBalonu(Map<String, dynamic> mesaj) {
    final benim =
        normalizeTckn(mesaj['GonderenTCKN']) ==
            normalizeTckn(globals.kullaniciTCKN);

    return Align(
      alignment:
      benim ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: benim ? AppColors.primary : Colors.grey.shade300,
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
              await launchUrl(uri,
                  mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.alanAdi),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              itemCount: mesajlar.length,
              itemBuilder: (context, index) {
                return _mesajBalonu(mesajlar[index]);
              },
            ),
          ),
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
                        borderRadius:
                        BorderRadius.all(Radius.circular(20)),
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
}*/

/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../constants.dart';

class MesajDetayScreen extends StatefulWidget {
  final String alanTckn;
  final String alanAdi;

  const MesajDetayScreen({
    Key? key,
    required this.alanTckn,
    required this.alanAdi,
  }) : super(key: key);

  @override
  State<MesajDetayScreen> createState() => _MesajDetayScreenState();
}

class _MesajDetayScreenState extends State<MesajDetayScreen> {
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> mesajlar = [];
  bool isLoading = true;

  Timer? _refreshTimer;
  DateTime? _sonMesajTarihi;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _mesajlariYukle();
    _otomatikRefreshBaslat();
  }

  Future<void> _mesajlariYukle() async {
    final data = await ApiService.getConversationMessages(
      gonderenTckn: globals.kullaniciTCKN,
      alanTckn: widget.alanTckn,
      take: 50,
      skip: 0,
    );

    data.sort((a, b) =>
        DateTime.parse(a['InsertDate'])
            .compareTo(DateTime.parse(b['InsertDate'])));

    setState(() {
      mesajlar = List<Map<String, dynamic>>.from(data);
      if (mesajlar.isNotEmpty) {
        _sonMesajTarihi =
            DateTime.parse(mesajlar.last['InsertDate']);
      }
      isLoading = false;
    });
  }

  void _otomatikRefreshBaslat() {
    _refreshTimer?.cancel();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
          _yeniMesajlariKontrolEt();
        });
  }

  Future<void> _yeniMesajlariKontrolEt() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final data = await ApiService.getConversationMessages(
        gonderenTckn: globals.kullaniciTCKN,
        alanTckn: widget.alanTckn,
        take: 50,
        skip: 0,
      );

      data.sort((a, b) =>
          DateTime.parse(a['InsertDate'])
              .compareTo(DateTime.parse(b['InsertDate'])));

      final yeni = data.where((m) {
        final t = DateTime.parse(m['InsertDate']);
        return _sonMesajTarihi == null ||
            t.isAfter(_sonMesajTarihi!);
      }).toList();

      if (yeni.isNotEmpty) {
        setState(() {
          mesajlar.addAll(yeni as Iterable<Map<String, dynamic>>);
          _sonMesajTarihi =
              DateTime.parse(yeni.last['InsertDate']);
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void mesajGonder() async {
    final text = _mesajController.text.trim();
    if (text.isEmpty) return;

    _mesajController.clear();
    final now = DateTime.now();

    setState(() {
      mesajlar.add({
        "GonderenTCKN": globals.kullaniciTCKN,
        "Data": text,
        "InsertDate": now.toIso8601String(),
      });
    });

    await ApiService().sendMesaj(
      globals.kullaniciTCKN,
      [widget.alanTckn],
      "YAZISMA",
      text,
    );
  }

  String normalizeTckn(dynamic v) {
    if (v == null) return "";
    String t = v.toString().trim();
    if (t.contains('_')) t = t.split('_').first;
    return t;
  }

  Widget _mesajBalonu(Map<String, dynamic> mesaj) {
    final benim =
        normalizeTckn(mesaj['GonderenTCKN']) ==
            normalizeTckn(globals.kullaniciTCKN);

    return Align(
      alignment:
      benim ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: benim ? AppColors.primary : Colors.grey.shade300,
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
              await launchUrl(uri,
                  mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.alanAdi),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
              controller: _scrollController,
              reverse: true,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final i =
                          mesajlar.length - 1 - index;
                      return _mesajBalonu(mesajlar[i]);
                    },
                    childCount: mesajlar.length,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(color: Colors.white),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mesajController,
                    decoration: const InputDecoration(
                      hintText: "Mesaj yaz...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.all(Radius.circular(20)),
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
*/