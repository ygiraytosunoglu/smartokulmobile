import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlamak için
import 'package:smart_okul_mobile/constants.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/services/api_service.dart';

class DevamDurumuScreen extends StatefulWidget {
  final String tckn; // parametre

  const DevamDurumuScreen({super.key, required this.tckn});

  @override
  State<DevamDurumuScreen> createState() => _DevamDurumuScreenState();
}

class _DevamDurumuScreenState extends State<DevamDurumuScreen> {
  List<dynamic> _devamListesi = [];
  bool _loading = true;
  String _ogrenciAdi = "";
  int _selectedIndex = -1; // Seçilen satırın indexi

  @override
  void initState() {
    super.initState();
    _getOgrenciAdi();
    _getDevamDurumu();
  }

  void _getOgrenciAdi() {
    final ogrenci = globals.globalOgrenciListesi.firstWhere(
          (e) => e['TCKN'] == widget.tckn,
      orElse: () => {"Name": "Bilinmeyen"},
    );
    _ogrenciAdi = ogrenci['Name'] ?? "Bilinmeyen";
  }

  Future<void> _getDevamDurumu() async {
    setState(() => _loading = true);

    _devamListesi = await ApiService().getDevamDurumu(widget.tckn);

    // Tarihe göre güncelden geçmişe sıralama
    _devamListesi.sort((a, b) {
      final dateA = DateTime.parse(a['Date']);
      final dateB = DateTime.parse(b['Date']);
      return dateB.compareTo(dateA); // Büyükten küçüğe
    });

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title:
        Text(
            "Devam Durumu",
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // Öğrenci adı AppBar'ın hemen altında
          Container(
            width: double.infinity,
            color: AppColors.background,//Colors.grey[200],
            padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              _ogrenciAdi,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Devam durumu listesi
          Expanded(
            child: _devamListesi.isEmpty
                ? const Center(child: Text("Devam durumu bulunamadı."))
                : ListView.builder(
              itemCount: _devamListesi.length,
              itemBuilder: (context, index) {
                final item = _devamListesi[index];
                final bool devam = item['Has'] == 1;
                final DateTime date = DateTime.parse(item['Date']);
                final String formattedDate =
                dateFormat.format(date);

                final bool isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Card(
                    elevation: 6,
                    shadowColor: AppColors.background,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isSelected ? Colors.blue[50] : null,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tıklanmışsa tik işareti göster
                          if (isSelected)
                            const Icon(Icons.check, color: Colors.blue),
                          if (isSelected) const SizedBox(width: 4),
                          Icon(
                            devam
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: devam
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        devam ? "Devam etti" : "Devamsız",
                        style: TextStyle(
                          color:
                          isSelected ? Colors.blue : Colors.black,
                          fontWeight:
                          isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
