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
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

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
             SnackBar(content: Text(AppLocalizations.of(context)!.fileOpenError)),
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
        : AppLocalizations.of(context)!.file;
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
          title:  Text(AppLocalizations.of(context)!.lessonDetail),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dersAdi.isNotEmpty)
                  _detaySatir(AppLocalizations.of(context)!.lesson, dersAdi),

                if (tarih.isNotEmpty)
                  _detaySatir(AppLocalizations.of(context)!.dueDate, tarih),
                const Divider(),
                 Text(
                   AppLocalizations.of(context)!.description,
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
              child:  Text(AppLocalizations.of(context)!.close),
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
          title:  Text(AppLocalizations.of(context)!.deleteHomeworkTitle),
          content:  Text(AppLocalizations.of(context)!.deleteHomeworkConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:  Text(AppLocalizations.of(context)!.no),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child:  Text(AppLocalizations.of(context)!.yes),
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
           SnackBar(content: Text(AppLocalizations.of(context)!.homeworkDeleted)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.homeworkNotFound)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(AppLocalizations.of(context)!.deleteError)),
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
              title:  Text(AppLocalizations.of(context)!.newHomeworkTitle),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    dersLoading
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<dynamic>(
                      decoration:  InputDecoration(
                        labelText:AppLocalizations.of(context)!.lessonRequired,
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
                      decoration:  InputDecoration(
                        labelText:AppLocalizations.of(context)!.descriptionRequired,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: expireCtrl,
                      readOnly: true,
                      decoration:  InputDecoration(
                        labelText: AppLocalizations.of(context)!.dueDateRequired,
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
                      title:  Text(AppLocalizations.of(context)!.selectAll),
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
                      label:  Text(AppLocalizations.of(context)!.addFile),
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
                    child:  Text(AppLocalizations.of(context)!.cancel)),
                ElevatedButton(
                  child:  Text(AppLocalizations.of(context)!.save),
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
                         SnackBar(
                            content: Text(AppLocalizations.of(context)!.fillRequiredFields)),
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
        title:  Text(AppLocalizations.of(context)!.homeworkTitle, style: AppStyles.titleLarge),
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
                    label:  Text(AppLocalizations.of(context)!.createHomework),
                    style: AppStyles.buttonStyle,
                  ),
                ),
              ),

            // 📋 ÖDEV LİSTESİ
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : odevler.isEmpty
                  ?  Center(
                child: Text(
                  AppLocalizations.of(context)!.noHomeworkYet,
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
                      title: Text( getDersAdi(odev['DersId']),
                        style: const TextStyle( fontWeight: FontWeight.bold,
                          fontSize: 16, ), ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          odev['ExpireDate'] != null
                              ? AppLocalizations.of(context)!.dueDate+": ${DateFormat('dd.MM.yyyy').format(DateTime.parse(odev['ExpireDate']))}"
                              : AppLocalizations.of(context)!.dueDate+": -",
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
                            tooltip: AppLocalizations.of(context)!.update,
                            onPressed: () {
                              odevGuncelle(odev);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: AppLocalizations.of(context)!.delete,
                            onPressed: () {
                              odevSil(odev['Id']);
                            },
                          ),
                        ],
                      )
                          : null,
                    ),
                  );

                 },
              ),
            ),
          ],
        ),
      ),
    );
  }

}