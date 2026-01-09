import 'dart:async';
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
