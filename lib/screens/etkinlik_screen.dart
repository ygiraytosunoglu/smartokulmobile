import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

class EtkinlikScreen extends StatefulWidget {
  @override
  _EtkinlikScreenState createState() => _EtkinlikScreenState();
}

class _EtkinlikScreenState extends State<EtkinlikScreen> {
  List<Map<String, dynamic>> etkinlikler = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEtkinlikler();
  }

  Future<void> _loadEtkinlikler() async {
    try {
      final data = await ApiService().getEtkinlikList(globals.kullaniciTCKN);
      setState(() {
        etkinlikler = data ?? []; // null gelirse boş liste ata
        isLoading = false;
      });
    } catch (e) {
      print('Hata _loadEtkinlikler: $e');
      setState(() {
        etkinlikler = []; // hata olsa bile liste boş kalır
        isLoading = false;
      });
    }
  }

  Future<void> _etkinligeTiklandi(String? detay) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Etkinlik Detayı'),
        content: Text(detay ?? ""), // null ise boş bırak
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEtkinlikForm() async {
    final TextEditingController tarihController = TextEditingController();
    final TextEditingController saatController = TextEditingController();
    final TextEditingController yerController = TextEditingController();
    final TextEditingController aciklamaController = TextEditingController();

    // Sınıflar için seçim listesi (default tümü seçili)
    Map<int, bool> seciliSiniflar = {
      for (var s in globals.globalSinifListesi) s['Id'] as int: true
    };

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni Etkinlik Oluştur'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Etkinlik Günü
                    TextField(
                      controller: tarihController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Etkinlik Günü',
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
                          tarihController.text =
                              DateFormat('dd.MM.yyyy').format(date);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    // Etkinlik Saati
                    TextField(
                      controller: saatController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Etkinlik Saati',
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
                    // Etkinlik Yeri
                    TextField(
                      controller: yerController,
                      decoration: const InputDecoration(
                        labelText: 'Etkinlik Yeri',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Açıklama
                    TextField(
                      controller: aciklamaController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    // Sınıf seçimleri
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Sınıflar:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Column(
                      children: globals.globalSinifListesi.map<Widget>((sinif) {
                        int id = sinif['Id'];
                        String ad = sinif['Ad'] ?? "Sınıf";
                        return CheckboxListTile(
                          title: Text(ad),
                          value: seciliSiniflar[id],
                          onChanged: (value) {
                            setState(() {
                              seciliSiniflar[id] = value ?? false;
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tarihController.text.isEmpty ||
                        saatController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Etkinlik gün ve saati seçiniz.')),
                      );
                      return;
                    }

                    if (yerController.text.isEmpty ||
                        aciklamaController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Etkinlik yeri ve açıklama boş olamaz.')),
                      );
                      return;
                    }

                    // En az 1 sınıf seçili mi?
                    var secilenler = seciliSiniflar.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();
                    if (secilenler.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('En az bir sınıf seçmelisiniz.')),
                      );
                      return;
                    }

                    try {
                      // Tarih ve saati birleştir
                      final selectedDate = DateFormat('dd.MM.yyyy').parse(tarihController.text);
                      final parts = saatController.text.split(':');
                      final selectedTime = TimeOfDay(
                        hour: int.parse(parts[0]),
                        minute: int.parse(parts[1].split(' ')[0]),
                      );

                      final etkinlikTarihi = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      // Seçilen her sınıf için API çağrısı
                      for (var sinifId in secilenler) {
                        await ApiService().createEtkinlik({
                          'ownerTckn': globals.kullaniciTCKN,
                          'sinifId': sinifId.toString(),
                          'data': jsonEncode({
                            'yer': yerController.text,
                            'aciklama': aciklamaController.text,
                          }),
                          'expireDate': etkinlikTarihi.toIso8601String(),
                        });
                      }

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Etkinlik başarıyla oluşturuldu.')),
                      );
                      _loadEtkinlikler(); // listeyi yenile
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Etkinlik oluşturulamadı: $e')),
                      );
                    }
                  },
                  child: const Text('Oluştur'),
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
        title: const Text('Etkinlik Listesi'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
          ),
        ),
        child: Column(
          children: [
            // Öğretmen ise buton göster
            if (globals.globalKullaniciTipi == "T")
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _showEtkinlikForm();
                      _loadEtkinlikler(); // popup kapandıktan sonra liste yenilensin
                    },
                    icon: const Icon(Icons.add, color: Colors.blue),
                    label: const Text(
                      'Yeni Etkinlik Oluştur',
                      style: TextStyle(color: Colors.blue),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (etkinlikler.isEmpty)
                  ? const Center(
                child: Text(
                  "Henüz etkinlik yok.",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: etkinlikler.length,
                itemBuilder: (context, index) {
                  var etkinlik = etkinlikler[index];
                  var renk = Colors.blue[900];

                  // Data alanını parse et
                  String detay = '';
                  String yer = '';
                  String aciklama = '';
                  try {
                    final data = etkinlik['Data'] ?? '';
                    if (data.startsWith('{') || data.startsWith('[')) {
                      final parsed = jsonDecode(data);
                      if (parsed is Map) {
                        yer = parsed['yer'] ?? '';
                        aciklama = parsed['aciklama'] ?? '';
                        detay = '$yer\n$aciklama';
                      } else {
                        detay = data.toString();
                      }
                    } else {
                      detay = data.toString();
                    }
                  } catch (e) {
                    detay = etkinlik['Data'] ?? '';
                  }

                  // Tarih alanı
                  String tarih = "";
                  if (etkinlik['ExpireDate'] != null &&
                      etkinlik['ExpireDate'].toString().isNotEmpty) {
                    try {
                      tarih = DateFormat('dd.MM.yyyy HH:mm').format(
                        DateTime.parse(etkinlik['ExpireDate']),
                      );
                    } catch (e) {
                      tarih = "";
                    }
                  }

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
                          if (yer.isNotEmpty) Text('Yer: $yer', style: TextStyle(color: renk)),
                          if (tarih.isNotEmpty) Text('Tarih: $tarih', style: TextStyle(color: renk)),
                        ],
                      ),
                      onTap: () => _etkinligeTiklandi(etkinlik['Data']),
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


/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

class EtkinlikScreen extends StatefulWidget {
  @override
  _EtkinlikScreenState createState() => _EtkinlikScreenState();
}

class _EtkinlikScreenState extends State<EtkinlikScreen> {
  List<Map<String, dynamic>> etkinlikler = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEtkinlikler();
  }

  Future<void> _loadEtkinlikler() async {
    try {
      final data = await ApiService().getEtkinlikList(globals.kullaniciTCKN);
      setState(() {
        etkinlikler = data ?? [];  // null gelirse boş liste ata
        isLoading = false;
      });
    } catch (e) {
      print('Hata _loadEtkinlikler: $e');
      setState(() {
        etkinlikler = []; // hata olsa bile liste boş kalır
        isLoading = false;
      });
    }
  }

  Future<void> _etkinligeTiklandi(String detay) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Etkinlik Detayı'),
        content: Text(detay ?? "Detay yok"), // null kontrolü
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEtkinlikForm() async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final TextEditingController yerController = TextEditingController();
    final TextEditingController aciklamaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Etkinlik Oluştur'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Etkinlik Günü
                ListTile(
                  title: Text(selectedDate == null
                      ? 'Etkinlik Günü Seç'
                      : 'Tarih: ${DateFormat('dd.MM.yyyy').format(selectedDate!)}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                ),
                const SizedBox(height: 8),
                // Etkinlik Saati
                ListTile(
                  title: Text(selectedTime == null
                      ? 'Etkinlik Saati Seç'
                      : 'Saat: ${selectedTime!.format(context)}'),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) setState(() => selectedTime = time);
                  },
                ),
                const SizedBox(height: 8),
                // Etkinlik Yeri
                TextField(
                  controller: yerController,
                  decoration: const InputDecoration(
                    labelText: 'Etkinlik Yeri',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                // Açıklama
                TextField(
                  controller: aciklamaController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate == null || selectedTime == null || yerController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doldurun.')),
                  );
                  return;
                }

                // Tarih ve saati birleştir
                final etkinlikTarihi = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );

                // API çağrısı
                try {
                  await ApiService().createEtkinlik({
                    'tarih': etkinlikTarihi.toIso8601String(),
                    'yer': yerController.text,
                    'aciklama': aciklamaController.text,
                    'gonderenTCKN': globals.kullaniciTCKN,
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Etkinlik başarıyla oluşturuldu.')),
                  );
                  _loadEtkinlikler(); // Listeyi yenile
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Etkinlik oluşturulamadı: $e')),
                  );
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Listesi'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary.withOpacity(0.6),
            ],
          ),
        ),
        child: Column(
          children: [
            // Öğretmen ise buton göster
            if (globals.globalKullaniciTipi == "T")
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showEtkinlikForm,
                    icon: const Icon(Icons.add, color: Colors.blue),
                    label: const Text(
                      'Yeni Etkinlik Oluştur',
                      style: TextStyle(color: Colors.blue),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : etkinlikler.isEmpty
                  ? const Center(
                child: Text(
                  "Henüz etkinlik yok.",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: etkinlikler.length,
                itemBuilder: (context, index) {
                  var etkinlik = etkinlikler[index];
                  var renk = Colors.blue[900];

                  String tarih = "Tarih yok";
                  if (etkinlik['InsertDate'] != null &&
                      etkinlik['InsertDate'].toString().isNotEmpty) {
                    try {
                      tarih = DateFormat('dd.MM.yyyy HH:mm').format(
                        DateTime.parse(etkinlik['InsertDate']),
                      );
                    } catch (e) {
                      tarih = "Geçersiz tarih";
                    }
                  }

                  return ListTile(
                    title: Text(
                      etkinlik['Baslik'] ?? "",
                      style: TextStyle(color: renk, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gönderen: ${etkinlik['GonderenAdi'] ?? "Bilinmiyor"}', style: TextStyle(color: renk)),
                        Text('Tarih: $tarih', style: TextStyle(color: renk)),
                      ],
                    ),
                    onTap: () => _etkinligeTiklandi(etkinlik['Data']),
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
*/