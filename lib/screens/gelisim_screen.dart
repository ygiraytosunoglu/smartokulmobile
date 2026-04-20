import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_okul_mobile/screens/gelisim_duzenle_screen.dart';
import 'package:smart_okul_mobile/screens/yeni_gelisim_screen.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import 'package:smart_okul_mobile/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
class GelisimScreen extends StatefulWidget {
  @override
  _GelisimScreenState createState() => _GelisimScreenState();
}

class _GelisimScreenState extends State<GelisimScreen> {
 // List<Map<String, dynamic>> odevler = [];
  //bool isLoading = true;

  //List<dynamic> dersListesi = [];
  //bool dersLoading = true;

  List<dynamic> gelisimTipleri = [];
  dynamic seciliGelisimTipi;
  List<dynamic> gelisimKayitlari = [];
  bool gelisimLoading = false;
  dynamic seciliOgrenci;
  List<FlSpot> chartData = [];
  @override
  void initState() {
    super.initState();
    _loadGelisimTipleri();
   // _loadGelisimler();
    //_loadDersler();
  }

  Future<void> _getGelisimKayitlari() async {
    if (seciliGelisimTipi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen gelişim tipi seçin")),
      );
      return;
    }

    String aktifTckn = globals.orjKullaniciTCKN;

    if (seciliOgrenci != null) {
      aktifTckn = seciliOgrenci['TCKN'];
    } else if (globals.globalKullaniciTipi == "P" ||
        globals.globalKullaniciTipi == "S") {
      aktifTckn = globals.studentTckn!;
    }

    setState(() {
      gelisimLoading = true;
      chartData = []; // 🔥 eski grafiği temizle
    });

    try {
      final data = await ApiService().getGelisimByTip(
        tckn: aktifTckn,
        tipId: seciliGelisimTipi['Id'],
      );

      List<dynamic> result = data ?? [];
      print("RESULT RAW: $result");
      print("DEGER LIST: ${result.map((e) => e['Deger']).toList()}");
      if (result.isEmpty) {
        setState(() {
          gelisimKayitlari = [];
          chartData = [];
          gelisimLoading = false;

        });
        return;
      }

      // 🔥 sırala
      result.sort((a, b) =>
          DateTime.parse(a['InsertDate'])
              .compareTo(DateTime.parse(b['InsertDate'])));

      // 🔥 chart oluştur
      print("API RESULT: $result");
      print(result.map((e) => e['Deger']).toList());
      List<FlSpot> tempChart = [];

      for (int i = 0; i < result.length; i++) {
        final raw = result[i]['Deger'];

        final val = double.tryParse(
          raw.toString()
              .replaceAll(',', '.')
              .replaceAll('%', '')
              .replaceAll(RegExp(r'[^0-9.\-]'), ''),
        ) ?? 0;

        tempChart.add(FlSpot(i.toDouble(), val));
      }
      print("CHART LENGTH: ${tempChart.length}");
      print("CHART DATA: $tempChart");

      if (!mounted) return;

      setState(() {
        gelisimKayitlari = result;
        chartData = List.from(tempChart);
        gelisimLoading = false;
      });
    } catch (e) {
      setState(() {
        gelisimKayitlari = [];
        chartData = [];
        gelisimLoading = false;
      });
    }
  }

  Future<void> _loadGelisimTipleri() async {
    try {
      final schoolId = int.parse(globals.globalSchoolId.toString());
      final data = await ApiService().getGelisimTipleri(schoolId);

      setState(() {
        gelisimTipleri = data ?? [];
      });
    } catch (_) {
      setState(() {
        gelisimTipleri = [];
      });
    }
  }
/*
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


  String getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : AppLocalizations.of(context)!.file;
  }

  void _showGelisimDetayPopup(Map<String, dynamic> odev) {
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
  */
/*
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
      _loadGelisimler(); // liste yenilenir
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


  Future<void> _showYeniGelisimDialog() async {
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
                    _loadGelisimler();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.gelisim,
          style: AppStyles.titleLarge,
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
        child: Column(
          children: [

            /// ➕ YENİ GELİŞİM EKLE  /  ✏️ KAYIT DÜZENLE-SİL
            if (globals.globalKullaniciTipi == "T" ||
                globals.globalKullaniciTipi == "M")
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    /// Yeni Kayıt
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: AppColors.onPrimary),
                        label: Text(AppLocalizations.of(context)!.createGelisim),
                        style: AppStyles.buttonStyle,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const YeniGelisimScreen(),
                            ),
                          );
                          if (mounted) {
                            _getGelisimKayitlari();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    /// Kayıt Düzenle / Sil
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_note, color: AppColors.onPrimary),
                        label: Text(AppLocalizations.of(context)!.editGelisimButton),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.newAppBar,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GelisimDuzenleScreen(),
                            ),
                          );
                          if (mounted) {
                            _getGelisimKayitlari();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

            /// 📊 GELİŞİM TİPİ DROPDOWN
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: DropdownButtonFormField<dynamic>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.growtType,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: seciliGelisimTipi,
                items: gelisimTipleri.map((d) {
                  return DropdownMenuItem(
                    value: d,
                    child: Text("${d['Ad']} (${d['Birim']})"),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    seciliGelisimTipi = v;
                  });
                },
              ),
            ),

            const SizedBox(height: 8),

            /// 👨‍🎓 ÖĞRENCİ SEÇ
            if (globals.globalOgrenciListesi.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonFormField<dynamic>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.students,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: seciliOgrenci,
                  items: globals.globalOgrenciListesi.map((ogr) {
                    return DropdownMenuItem(
                      value: ogr,
                      child: Text(ogr['Name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      seciliOgrenci = v;
                    });
                  },
                ),
              ),

            const SizedBox(height: 8),

            /// 🔎 GETİR BUTONU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.buttonStyle,
                  onPressed: _getGelisimKayitlari,
                  child: Text(AppLocalizations.of(context)!.getResult),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 📊 GRAFİK ALANI
            Expanded(
              child: gelisimLoading
                  ? const Center(child: CircularProgressIndicator())
                  : chartData.isEmpty
                  ? Center(
                child: Text(
                  AppLocalizations.of(context)!.noData,
                  style: const TextStyle(color: Colors.white),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      titlesData: FlTitlesData(
                        /// Sol eksen — ölçüm değerleri
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 46,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                meta.formattedValue,
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        /// Alt eksen — tarihler
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= gelisimKayitlari.length) {
                                return const SizedBox.shrink();
                              }
                              final raw = gelisimKayitlari[idx]['InsertDate'];
                              try {
                                final dt = DateTime.parse(raw.toString());
                                final label = DateFormat('dd.MM\nyyyy').format(dt);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                );
                              } catch (_) {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                        /// Sağ ve üst eksenler gizli
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData,
                          isCurved: true,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}