import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import '../services/api_service.dart';
import '../globals.dart' as globals;
import '../constants.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// 📥 İlk yükleme
  Future<void> _mesajlariYukle() async {
    try {
      final data = await ApiService.getConversationMessages(
        gonderenTckn: globals.kullaniciTCKN,
        alanTckn: widget.alanTckn,
        take: 50,
        skip: 0,
      );

      // 🔥 KRİTİK: her zaman eskiden → yeniye sırala
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

      _scrollToBottom();
    } catch (e) {
      debugPrint("İlk yükleme hata: $e");
      setState(() => isLoading = false);
    }
  }

  /// ⏱ Otomatik refresh
  void _otomatikRefreshBaslat() {
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 5), (_) {
          _yeniMesajlariKontrolEt();
        });
  }

  /// 🆕 Yeni mesajları kontrol et
  Future<void> _yeniMesajlariKontrolEt() async {
    if (_isRefreshing || !mounted) return;
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

      final List<Map<String, dynamic>> yeniMesajlar = data
          .where((m) {
        final tarih = DateTime.parse(m['InsertDate']);
        return _sonMesajTarihi == null ||
            tarih.isAfter(_sonMesajTarihi!);
      })
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (yeniMesajlar.isNotEmpty) {
        setState(() {
          mesajlar.addAll(yeniMesajlar);

          _sonMesajTarihi =
              DateTime.parse(yeniMesajlar.last['InsertDate']);
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Refresh hata: $e");
    } finally {
      _isRefreshing = false;
    }
  }

  /// 📤 Mesaj gönder
  void mesajGonder() async {
    final text = _mesajController.text.trim();
    if (text.isEmpty) return;

    _mesajController.clear();

    await ApiService().sendMesaj(
      globals.kullaniciTCKN,
      [widget.alanTckn],
      "YAZISMA",
      text,
    );

    final now = DateTime.now();

    setState(() {
      mesajlar.add({
        "GonderenTCKN": globals.kullaniciTCKN,
        "Data": text,
        "InsertDate": now.toIso8601String(),
      });
      _sonMesajTarihi = now;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  /// 📅 Gün başlığı
  String gunBasligi(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(date.year, date.month, date.day);

    if (msgDay == today) return "Bugün";
    if (msgDay == yesterday) return "Dün";
    return DateFormat('dd MMMM yyyy', 'tr').format(date);
  }

  Widget _gunAyirici(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            gunBasligi(date),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _mesajBalonu(Map<String, dynamic> mesaj) {
    final bool benimMesajim =
        normalizeTckn(mesaj['GonderenTCKN']) ==
            normalizeTckn(globals.kullaniciTCKN);

    return Align(
      alignment:
      benimMesajim ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: benimMesajim
              ? AppColors.primary
              : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
            benimMesajim ? const Radius.circular(16) : Radius.zero,
            bottomRight:
            benimMesajim ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Linkify(
          text: mesaj['Data'] ?? "",
          style: TextStyle(
            color: benimMesajim ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
          linkStyle: TextStyle(
            color: benimMesajim ? Colors.white70 : Colors.blue,
            decoration: TextDecoration.underline,
          ),
          onOpen: (link) async {
            String url = link.url;

            // 🔥 ŞEMA YOKSA EKLE
            if (!url.startsWith('http://') &&
                !url.startsWith('https://')) {
              url = 'https://$url';
            }

            final uri = Uri.parse(url);

            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Link açılamadı: $url")),
              );
            }
          },
        ),


      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              itemCount: mesajlar.length,
              itemBuilder: (context, index) {
                final msg = mesajlar[index];
                final msgDate =
                DateTime.parse(msg['InsertDate']);

                bool gunDegisti = index == 0 ||
                    DateTime.parse(
                        mesajlar[index - 1]['InsertDate'])
                        .day !=
                        msgDate.day;

                return Column(
                  children: [
                    if (gunDegisti) _gunAyirici(msgDate),
                    _mesajBalonu(msg),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mesajController,
                    minLines: 1,
                    maxLines: 4,
                    decoration:
                    const InputDecoration(hintText: "Mesaj yaz..."),
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
