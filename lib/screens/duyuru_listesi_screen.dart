import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:smart_okul_mobile/screens/send_notification_screen.dart';
import 'package:smart_okul_mobile/screens/send_notification_screen_m.dart';
import 'package:smart_okul_mobile/screens/send_notification_screen_p.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class DuyuruListesiScreen extends StatefulWidget {
  @override
  _DuyuruListesiScreenState createState() => _DuyuruListesiScreenState();
}

class _DuyuruListesiScreenState extends State<DuyuruListesiScreen> {
  List<Map<String, dynamic>> duyurular = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDuyurular();
  }

  List<TextSpan> _parseTextWithLinks(String text) {
    final regex = RegExp(
        r'(https?:\/\/[^\s]+)',
        caseSensitive: false);

    final matches = regex.allMatches(text);
    if (matches.isEmpty) return [TextSpan(text: text)];

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      final url = match.group(0)!;

      // Link öncesi metin
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      // Tıklanabilir link
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ),
      );

      lastMatchEnd = match.end;
    }

    // Son kısım
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  Future<void> _loadDuyurular() async {
    try {
      final data = await ApiService().getDuyuruList(globals.kullaniciTCKN);

      bool okunmamisVarMi = false;

      if (data.isNotEmpty) {
        // Okunmamış duyuru var mı kontrol et
        okunmamisVarMi = data.any((duyuru) => duyuru['Okundu'] != 1);
      }

      setState(() {
        duyurular = data;
        isLoading = false;
      });

      // Global değişkeni güncelle (liste boşsa false olur)
     // globals.duyuruVar = okunmamisVarMi as ValueNotifier<bool>;
      globals.duyuruVar.value = okunmamisVarMi;

      print("globals.duyuruVar = ${globals.duyuruVar}");
    } catch (e) {
      print('Hata _loadDuyurular: $e');
      //globals.duyuruVar = false as ValueNotifier<bool>; // hata durumunda da false olsun
      globals.duyuruVar.value = false;
    }
  }
/*
  Future<void> _duyuruyaTiklandi(int duyuruId, String detay, bool okundu) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mesaj Detayı'),
        content: SingleChildScrollView(
          child: GestureDetector(
            // Uzun basarak tamamını kopyalayabilmek için
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: detay));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mesaj kopyalandı')),
              );
            },
            child: Linkify(
              text: detay,
              style: TextStyle(color: Colors.black87, fontSize: 16),
              linkStyle: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              onOpen: (link) async {
                final uri = Uri.parse(link.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bağlantı açılamadı')),
                  );
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );

    if (!okundu) {
      try {
        await ApiService().setDuyuruOkundu(duyuruId);
        _loadDuyurular();
      } catch (e) {
        print('Mesaj okundu güncelleme hatası: $e');
      }
    }
  }
*/

  Future<void> _duyuruyaTiklandi(Map<String, dynamic> duyuru) async {
    final bool okundu = duyuru['Okundu'] == 1;

    // 🔴 Popup açılmadan ÖNCE local state'i güncelle
    if (!okundu) {
      setState(() {
        duyuru['Okundu'] = 1; // ARTIK OKUNMUŞ GİBİ
      });

      // API çağrısı arkadan gitsin
      ApiService().setDuyuruOkundu(duyuru['Id']).catchError((e) {
        print('Mesaj okundu güncelleme hatası: $e');
      });
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mesaj Detayı'),
        content: SingleChildScrollView(
          child: GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: duyuru['Data']));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Mesaj kopyalandı')),
              );
            },
            child: Linkify(
              text: duyuru['Data'],
              style: TextStyle(color: Colors.black87, fontSize: 16),
              linkStyle: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              onOpen: (link) async {
                final uri = Uri.parse(link.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(
            'Mesaj Listesi',
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),
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
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView(
          padding: EdgeInsets.all(8),
          children: [
            // --- EN ÜSTE MESAJ GÖNDER BUTONU ---
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                style: AppStyles.buttonStyle,/*ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),*/
                icon: Icon(Icons.send),
                label: Text(
                  "Mesaj Gönder",
                  style: AppStyles.buttonTextStyle,
                  /*TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),*/
                ),
                onPressed: () {
                  _bildirimGonderSayfasiniAc(context);
                },
              ),
            ),

            // --- DUYURU LİSTESİ ---
            ...duyurular.map((duyuru) {
              var okundu = duyuru['Okundu'] == 1;
              final renk = okundu ? Colors.grey : Colors.blue[900];
              var tarih = DateFormat('dd.MM.yyyy HH:mm')
                  .format(DateTime.parse(duyuru['InsertDate']));

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(
                      duyuru['Baslik'],
                      style: TextStyle(
                        color: renk,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gönderen: ${duyuru['GonderenAdi']}',
                            style: TextStyle(color: renk)),
                        Text('Tarih: $tarih',
                            style: TextStyle(color: renk)),
                      ],
                    ),
                    onTap: () => _duyuruyaTiklandi(duyuru),
                    /*onTap: () => _duyuruyaTiklandi(
                      duyuru['Id'],
                      duyuru['Data'],
                      okundu,
                    ),*/
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }


    void _bildirimGonderSayfasiniAc(BuildContext context) {
      if (["M", "T", "P"].contains(globals.globalKullaniciTipi)) {
        if (globals.globalKullaniciTipi == 'T') {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => SendNotificationScreen()));
        }

        if (globals.globalKullaniciTipi == 'M') {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => SendNotificationScreenM()));
        }

        if (globals.globalKullaniciTipi == 'P') {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => SendNotificationScreenP()));
        }
      } else {
        _pencereAc(context, "Sadece öğretmenler ve yöneticiler velilere bildirim gönderebilir!");
      }
    }

  Future _pencereAc(BuildContext context, String mesaj) {
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(title: Text(mesaj));
      },
    );
  }

}
