import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_okul_mobile/screens/update_odev_screen.dart';
import 'package:smart_okul_mobile/screens/yeni_odev_screen.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

class OdevScreen extends StatefulWidget {
  @override
  _OdevScreenState createState() => _OdevScreenState();
}

class _OdevScreenState extends State<OdevScreen> {
  List<Map<String, dynamic>> odevler = [];
  bool isLoading = true;

  List<dynamic> dersListesi = [];
  bool dersLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOdevler();
    _loadDersler();
  }

  Widget _detaySatir(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$baslik: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(deger)),
        ],
      ),
    );
  }

  Widget _dosyaSatiri(String url) {
    final ad = getFileNameFromUrl(url);

    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);

        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication, // download başlatır
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Dosya açılamadı")),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.download, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ad,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*Widget _dosyaSatiri(String ad, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.attach_file, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                ad,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
*/
  String getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : "Dosya";
  }

  void _showOdevDetayPopup(Map<String, dynamic> odev) {
    String aciklama = '';
    String dersAdi = odev['DersAdi'] ?? '';
    String tarih = '';

    List<String> dosyalar = [];

    if (odev['DocPaths'] != null && odev['DocPaths'] is List) {
      dosyalar = List<String>.from(odev['DocPaths']);
    }


    try {
      final dataStr = odev['Data'] ?? '';
      if (dataStr.isNotEmpty) {
        final parsed = jsonDecode(dataStr);
        aciklama = parsed['aciklama'] ?? '';
      }
    } catch (_) {
      aciklama = odev['Data'] ?? '';
    }

    try {
      if (odev['ExpireDate'] != null) {
        tarih = DateFormat('dd.MM.yyyy').format(
          DateTime.parse(odev['ExpireDate']),
        );
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ödev Detayı"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dersAdi.isNotEmpty)
                  _detaySatir("Ders", dersAdi),

                if (tarih.isNotEmpty)
                  _detaySatir("Son Teslim", tarih),

                const Divider(),

                const Text(
                  "Açıklama",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                //Text(aciklama.isNotEmpty ? aciklama : "-"),
        Linkify(
        text: aciklama.isNotEmpty ? aciklama : "-",
        onOpen: (link) async {
        final uri = Uri.parse(link.url);
        if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        },
        style: const TextStyle(color: Colors.black87),
        linkStyle: const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
        ),
        ),
        if (dosyalar.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const Text(
                    "Ekli Dosyalar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  ...dosyalar.map((url) => _dosyaSatiri(url)).toList(),

                ]



              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadDersler() async {
    try {
      final schoolId = int.parse(globals.globalSchoolId.toString());
      final data = await ApiService().getAllDersler(schoolId);

      setState(() {
        dersListesi = data ?? [];
        dersLoading = false;
      });
    } catch (_) {
      setState(() {
        dersListesi = [];
        dersLoading = false;
      });
    }
  }

  Future<void> _loadOdevler() async {
    try {
      String aktifTckn = globals.orjKullaniciTCKN;

      if (globals.globalKullaniciTipi == "P" ||
          globals.globalKullaniciTipi == "S") {
        aktifTckn = globals.studentTckn!;
      }

      final data = await ApiService().getOdevlerByTckn(
        tckn: aktifTckn,
        skip: 0,
        take: 20,
      );

      setState(() {
        odevler = List<Map<String, dynamic>>.from(data ?? []);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        odevler = [];
        isLoading = false;
      });
    }
  }

  Future<void> odevSil(int odevId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ödev Sil"),
          content: const Text("Bu ödev silinecek. Emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hayır"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Evet"),
            ),
          ],
        );
      },
    );

    // ❌ Hayır denmişse
    if (result != true) return;

    // ✅ Evet denmişse → API çağrısı
    try {
      final success = await ApiService().removeOdev(odevId: odevId);

      if (success) {
        setState(() {
          odevler.removeWhere((x) => x['Id'] == odevId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ödev silindi")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ödev bulunamadı")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silme sırasında hata oluştu")),
      );
    }
  }


  Future<void> odevGuncelle(Map<String, dynamic> odev) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateOdevScreen(odev: odev),
      ),
    );

    if (result == true) {
      _loadOdevler(); // liste yenilenir
    }
  }


/*
  Future<void> _loadOdevler() async {
    try {
      List<Map<String, dynamic>> tumOdevler = [];
       String aktifTckn = globals.orjKullaniciTCKN;

      if(globals.globalKullaniciTipi=="T"){
        aktifTckn = globals.orjKullaniciTCKN;
      } else if (globals.globalKullaniciTipi=="P") {
        aktifTckn =globals.studentTckn!;
      }
      /*for (var ogr in globals.globalOgrenciListesi) {
        final tckn = ogr['TCKN'];
        final ad = ogr['Name'] ?? '';

        if (tckn == null) continue;

        final data = await ApiService().getOdevlerByTckn(
          tckn: tckn,
          skip: 0,
          take: 10,
        );

        if (data != null) {
          for (var item in data) {
            item['OgrenciAd'] = ad;
            tumOdevler.add(item);
          }
        }
      }*/

      final data = await ApiService().getOdevlerByTckn(
        tckn: aktifTckn,
        skip: 0,
        take: 10,
      );
      setState(() {
        odevler = tumOdevler;
        isLoading = false;
      });
    } catch (_) {
      setState(() {
        odevler = [];
        isLoading = false;
      });
    }
  }
*/
  String getDersAdi(int? dersId) {
    if (dersId == null) return "-";

    final ders = dersListesi.firstWhere(
          (d) => d['Id'] == dersId,
      orElse: () => null,
    );

    return ders != null ? ders['Ad'] ?? "-" : "-";
  }

  bool isGecmisTarih(String? expireDate) {
    if (expireDate == null) return false;

    final teslimTarihi = DateTime.parse(expireDate);
    final bugun = DateTime.now();

    // Saat farklarını yok saymak için sadece tarih karşılaştırıyoruz
    final teslimGun = DateTime(
      teslimTarihi.year,
      teslimTarihi.month,
      teslimTarihi.day,
    );

    final bugunGun = DateTime(
      bugun.year,
      bugun.month,
      bugun.day,
    );

    return teslimGun.isBefore(bugunGun);
  }


  Future<void> _showYeniOdevDialog() async {
    dynamic seciliDers;
    final aciklamaCtrl = TextEditingController();
    final expireCtrl = TextEditingController();

    Map<String, bool> ogrenciSecim = {
      for (var o in globals.globalOgrenciListesi) o['TCKN']: true
    };

    bool hepsiSecili = true;
    List<File> selectedFiles = [];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void hepsiDurumunuGuncelle() {
              hepsiSecili = ogrenciSecim.values.every((v) => v);
            }

            return AlertDialog(
              title: const Text("Yeni Ödev Oluştur"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    dersLoading
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<dynamic>(
                      decoration: const InputDecoration(
                        labelText: "Ders *",
                        border: OutlineInputBorder(),
                      ),
                      items: dersListesi
                          .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d['Ad'] ?? ''),
                      ))
                          .toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          seciliDers = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: aciklamaCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Açıklama *",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: expireCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Son Teslim Tarihi *",
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) {
                          expireCtrl.text =
                              DateFormat('yyyy-MM-dd').format(d);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text("Hepsi"),
                      value: hepsiSecili,
                      onChanged: (v) {
                        setDialogState(() {
                          hepsiSecili = v!;
                          ogrenciSecim
                              .updateAll((key, value) => hepsiSecili);
                        });
                      },
                    ),
                    ...globals.globalOgrenciListesi.map((ogr) {
                      return CheckboxListTile(
                        title: Text(ogr['Name'] ?? ''),
                        value: ogrenciSecim[ogr['TCKN']],
                        onChanged: (v) {
                          setDialogState(() {
                            ogrenciSecim[ogr['TCKN']] = v!;
                            hepsiDurumunuGuncelle();
                          });
                        },
                      );
                    }),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Dosya Ekle"),
                      onPressed: () async {
                        final result =
                        await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                        );
                        if (result != null) {
                          setDialogState(() {
                            selectedFiles = result.paths
                                .whereType<String>()
                                .map((e) => File(e))
                                .toList();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal")),
                ElevatedButton(
                  child: const Text("Kaydet"),
                  onPressed: () async {
                    final secilenOgrenciler = ogrenciSecim.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();

                    if (seciliDers == null ||
                        aciklamaCtrl.text.trim().isEmpty ||
                        expireCtrl.text.isEmpty ||
                        secilenOgrenciler.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Zorunlu alanları doldurun")),
                      );
                      return;
                    }
                    print("secilenOgrenciler:"+secilenOgrenciler.toString());
                    await ApiService().addOdev(
                      gonderenTckn: globals.kullaniciTCKN,
                      alanTcknList: secilenOgrenciler,
                      dersId: seciliDers['Id'],
                      schoolId:
                      int.parse(globals.globalSchoolId.toString()),
                      data: jsonEncode(
                          {"aciklama": aciklamaCtrl.text}),
                      expireDate:
                      DateTime.parse(expireCtrl.text),
                      files: selectedFiles,
                    );

                    Navigator.pop(context);
                    _loadOdevler();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödevler', style: AppStyles.titleLarge),
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
        child: Column(
          children: [
            // ✅ YENİ ÖDEV EKLE BUTONU
            if (globals.globalKullaniciTipi == "T")
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: dersLoading
                        ? null
                        : () async {
                      /*await _showYeniOdevDialog();
                      _loadOdevler();*/
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const YeniOdevScreen(),
                        ),
                      );

                      if (result == true) {
                        _loadOdevler(); // geri dönünce listeyi yenile
                      }
                    },
                    icon: const Icon(Icons.add, color: AppColors.onPrimary),
                    label: const Text('Yeni Ödev Oluştur'),
                    style: AppStyles.buttonStyle,
                  ),
                ),
              ),

            // 📋 ÖDEV LİSTESİ
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : odevler.isEmpty
                  ? const Center(
                child: Text(
                  "Henüz ödev yok.",
                  style:
                  TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: odevler.length,
                itemBuilder: (context, index) {
                  final odev = odevler[index];

                  final ogrenciAd = odev['OgrenciAd'] ?? '';
                  final dataStr = odev['Data'] ?? '';
                  String aciklama = '';

                  try {
                    final parsed = jsonDecode(dataStr);
                    aciklama = parsed['aciklama'] ?? '';
                  } catch (_) {
                    aciklama = dataStr;
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: ListTile(
                      onTap: () {
                        _showOdevDetayPopup(odev);
                      },

                     /* title: Text(
                        odev['DersAdi'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),*/
                      title: Text( getDersAdi(odev['DersId']),
                        style: const TextStyle( fontWeight: FontWeight.bold,
                          fontSize: 16, ), ),

                      /*subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          odev['ExpireDate'] != null
                              ? "Son Teslim: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(odev['ExpireDate']))}"
                              : "Son Teslim: -",
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),*/
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          odev['ExpireDate'] != null
                              ? "Son Teslim: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(odev['ExpireDate']))}"
                              : "Son Teslim: -",
                          style: TextStyle(
                            color: isGecmisTarih(odev['ExpireDate'])
                                ? Colors.red
                                : Colors.black87,
                            fontWeight: isGecmisTarih(odev['ExpireDate'])
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),

                      // 👉 SAĞ TARAF BUTONLAR
                      trailing: globals.globalKullaniciTipi == "T"
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: "Güncelle",
                            onPressed: () {
                              odevGuncelle(odev);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Sil",
                            onPressed: () {
                              odevSil(odev['Id']);
                            },
                          ),
                        ],
                      )
                          : null,
                    ),
                  );

                  /* return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: ListTile(
                      onTap: () {
                        _showOdevDetayPopup(odev); // 👈 SATIRA TIKLANINCA
                      },
                      title: Text(
                        "$ogrenciAd\n$aciklama",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      // 👉 SAĞ TARAF BUTONLAR
                      trailing: globals.globalKullaniciTipi == "T"
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: "Güncelle",
                            onPressed: () {
                              odevGuncelle(odev);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Sil",
                            onPressed: () {
                              odevSil(odev['Id']);
                            },
                          ),
                        ],
                      )
                          : null,
                    ),
                  );
*/
                /*  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: ListTile(
                      title: Text(
                        "$ogrenciAd\n$aciklama",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                */},
              ),
            ),
          ],
        ),
      ),
    );
  }

}