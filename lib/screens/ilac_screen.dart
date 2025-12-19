import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

class IlacScreen extends StatefulWidget {
  @override
  _IlacScreenState createState() => _IlacScreenState();
}

class _IlacScreenState extends State<IlacScreen> {
  List<Map<String, dynamic>> ilaclar = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIlaclar();
  }
  Future<void> _loadIlaclar() async {
    try {
      List<Map<String, dynamic>> tumIlaclar = [];

      // Tüm öğrenciler için döngü
      for (var ogr in globals.globalOgrenciListesi) {
        final studentTckn = ogr['TCKN'] ?? ogr['tckn'];
        final studentAd = ogr['Name'] ?? ogr['name'] ?? "";

        if (studentTckn == null) continue;

        final data = await ApiService().getIlacList(studentTckn);

        // Gelen liste null değilse ekle
        if (data != null) {
          for (var item in data) {
            // → İlaç hangi öğrenciye ait? Ekleyelim
            item['OgrenciTCKN'] = studentTckn;
            item['OgrenciAd'] = studentAd;

            tumIlaclar.add(item);
          }
        }
      }

      setState(() {
        ilaclar = tumIlaclar;
        isLoading = false;
      });

      print("Tüm öğrencilerden gelen ilaç kayıtları:");
      for (var ilac in ilaclar) {
        print("Öğrenci: ${ilac['OgrenciAd']} (${ilac['OgrenciTCKN']})");
        ilac.forEach((k, v) => print("$k: $v"));
      }

    } catch (e) {
      print('Hata _loadIlaclar: $e');
      setState(() {
        ilaclar = [];
        isLoading = false;
      });
    }
  }

  /* Future<void> _loadIlaclar() async {
    try {
      final data = await ApiService().getIlacList(globals.kullaniciTCKN);
      setState(() {
        ilaclar = data ?? []; // null gelirse boş liste ata
        print("etkinlikler:");
        for (var ilac in ilaclar) {
          ilac.forEach((key, value) {
            print("$key: $value");
          });
        }
         isLoading = false;
      });
    } catch (e) {
      print('Hata _loadIlaclar: $e');
      setState(() {
        ilaclar = []; // hata olsa bile liste boş kalır
        isLoading = false;
      });
    }
  }*/

  Future<void> _ilacaTiklandi(String? data) async {
    String aciklamaMetni = "";

    try {
      if (data != null && (data.startsWith('{') || data.startsWith('['))) {
        final parsed = jsonDecode(data);
        if (parsed is Map && parsed.containsKey('aciklama')) {
          aciklamaMetni = parsed['aciklama'] ?? "";
        } else {
          aciklamaMetni = data.toString();
        }
      } else {
        aciklamaMetni = data ?? "";
      }
    } catch (e) {
      aciklamaMetni = data ?? "";
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('İlaç Detayı'),
        content: Text(
          "Açıklama: ${aciklamaMetni.isNotEmpty ? aciklamaMetni : 'Yok'}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
  Future<void> _showIlacForm() async {
    final TextEditingController tarihBasController = TextEditingController();
    final TextEditingController tarihBitController = TextEditingController();
    final TextEditingController saatController = TextEditingController();
    final TextEditingController aciklamaController = TextEditingController();

    String? seciliOgrenciTckn;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni İlaç Bilgisi Oluştur'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // 📅 İlaç Başlangıç
                    TextField(
                      controller: tarihBasController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'İlaç Başlangıç Günü',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          tarihBasController.text =
                              DateFormat('dd.MM.yyyy').format(date);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // 📅 İlaç Bitiş
                    TextField(
                      controller: tarihBitController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'İlaç Bitiş Günü',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          tarihBitController.text =
                              DateFormat('dd.MM.yyyy').format(date);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // ⏰ Saat
                    TextField(
                      controller: saatController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'İlaç Saati',
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          saatController.text = time.format(context);
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // 📝 Açıklama
                    TextField(
                      controller: aciklamaController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // 👦 Öğrenci Seçimi
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Öğrenci Seçin:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    Column(
                      children: globals.globalOgrenciListesi.map<Widget>((ogrenci) {
                        String adSoyad = ogrenci['Name'] ?? "Öğrenci";
                        String tckn = ogrenci['TCKN'] ?? "";

                        return RadioListTile<String>(
                          title: Text(adSoyad),
                          value: tckn,
                          groupValue: seciliOgrenciTckn,
                          onChanged: (value) {
                            setState(() {
                              seciliOgrenciTckn = value;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    if (tarihBasController.text.isEmpty ||
                        tarihBitController.text.isEmpty ||
                        saatController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Tüm tarih alanlarını doldurunuz.')),
                      );
                      return;
                    }

                    if (seciliOgrenciTckn == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Bir öğrenci seçmelisiniz.')),
                      );
                      return;
                    }

                    setState(() {
                      isSubmitting = true;
                    });

                    try {
                     /* await ApiService().addIlacTakip({
                        'tckn': globals.kullaniciTCKN,
                        'studentTckn': seciliOgrenciTckn,
                        'ilacDateStart': tarihBasController.text,
                        'ilacDateEnd': tarihBitController.text,
                        'ilacTime': saatController.text,
                        'data': jsonEncode({
                          'aciklama': aciklamaController.text,
                        }),
                      });*/
                      final DateFormat inputFormat = DateFormat('dd.MM.yyyy'); // TextField’den gelen format
                      final DateFormat isoFormat = DateFormat('yyyy-MM-dd');  // API formatı
                      final result = await ApiService().addIlacTakip(
                        tckn: globals.kullaniciTCKN,   // ilacı ekleyen veli tckn
                        studentTckn: seciliOgrenciTckn!, // öğrencinin tckn
                        ilacDateStart: isoFormat.format(inputFormat.parse(tarihBasController.text)), // "dd.MM.yyyy"
                        ilacDateEnd: isoFormat.format(inputFormat.parse(tarihBitController.text)),   // "dd.MM.yyyy"
                        ilacTime: saatController.text,          // "HH:mm"
                        data: jsonEncode({
                          "aciklama": aciklamaController.text,
                        }),
                      );


                      print("addIlacTakip result:"+result.toString());

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('İlaç bilgisi başarıyla oluşturuldu.')),
                      );
                      _loadIlaclar();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                      setState(() {
                        isSubmitting = false;
                      });
                    }
                  },
                  child: Text(
                    isSubmitting ? 'Oluşturuluyor...' : 'Oluştur',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const
        Text(
            'İlaç Listesi',
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
        child: Column(
          children: [
            // Öğretmen ise buton göster
            if (globals.globalKullaniciTipi == "P" )
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _showIlacForm();
                      _loadIlaclar(); // popup kapandıktan sonra liste yenilensin
                    },
                    icon: const Icon(Icons.add, color: AppColors.onPrimary),
                    label:  Text(
                      'Yeni İlaç Oluştur',
                      //style: TextStyle(color: Colors.blue),
                    ),
                    style: AppStyles.buttonStyle,
                    /*ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),*/
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (ilaclar.isEmpty)
                  ? const Center(
                child: Text(
                  "Henüz ilaç bilgisi yok.",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: ilaclar.length,
                itemBuilder: (context, index) {
                  var ilac = ilaclar[index];
                  var renk = Colors.blue[900];

                  // Data alanını parse et
                  String ogrenciAd = ilac['OgrenciAd'];
                  String baslangicTar =   DateFormat('dd/MM/yyyy').format(DateTime.parse(ilac['IlacDateStart']));
                  String bitisTar =   DateFormat('dd/MM/yyyy').format(DateTime.parse(ilac['IlacDateEnd']));

                  String zaman = DateFormat('HH:mm').format(DateTime.parse(ilac['IlacTime']) );
                  String aciklama = '';
                  String detay ='';

                  try {
                    final data = ilac['Data'] ?? '';

                    if (data.startsWith('{') || data.startsWith('[')) {
                      final parsed = jsonDecode(data);
                      if (parsed is Map) {
                        aciklama = parsed['aciklama'] ?? '';
                        detay = '$aciklama';
                      } else {
                        detay = data.toString();
                      }
                    } else {
                      detay = data.toString();
                    }
                  } catch (e) {
                    detay = ilac['Data'] ?? '';
                  }
                  aciklama =ogrenciAd + '\n'+detay + '\n$baslangicTar'+' - '+bitisTar+ '\n'+ zaman;
                  // Tarih alanı
                 /* String tarih = "";
                  if (ilac['ExpireDate'] != null &&
                      iaciklamalac['ExpireDate'].toString().isNotEmpty) {
                    try {
                      tarih = DateFormat('dd.MM.yyyy HH:mm').format(
                        DateTime.parse(ilac['ExpireDate']),
                      );
                    } catch (e) {
                      tarih = "";
                    }
                  }*/
                  String tarih = "";
                  try {
                    String bas = ilac['IlacDateStart'] ?? "";
                    String tim = ilac['IlacTime'] ?? "";

                    if (bas.isNotEmpty && tim.isNotEmpty) {
                      // ISO date: 2025-11-27
                      DateTime dt = DateTime.parse("$bas $tim");

                      tarih = DateFormat("dd.MM.yyyy HH:mm").format(dt);
                    }
                  } catch (_) {
                    tarih = "";
                  }


                 /* String sinifAdlari='';
                  if (ilac['SinifAdlari'] != null &&
                      ilac['SinifAdlari'].toString().isNotEmpty) {
                    try {
                      sinifAdlari = ilac['SinifAdlari'].toString();
                    } catch (e) {
                      sinifAdlari = "";
                    }
                  }*/

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: ListTile(
                      title: Text(
                        aciklama.isNotEmpty ? aciklama : detay,
                        style: TextStyle(color: renk, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         // if (sinifAdlari.isNotEmpty) Text('Sınıf/lar: $sinifAdlari', style: TextStyle(color: renk)),
                         // if (yer.isNotEmpty) Text('Yer: $yer', style: TextStyle(color: renk)),
                          if (tarih.isNotEmpty) Text('Tarih: $tarih', style: TextStyle(color: renk)),
                        ],
                      ),
                      onTap: () => null,//_etkinligeTiklandi(etkinlik['Data']),
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

