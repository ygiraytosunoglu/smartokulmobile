import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

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

  Future<void> _loadDuyurular() async {
    try {
      final data = await ApiService().getDuyuruList(globals.kullaniciTCKN);
      setState(() {
        duyurular = data;
        isLoading = false;
      });
    } catch (e) {
      print('Hata _loadDuyurular: $e');
    }
  }

  Future<void> _duyuruyaTiklandi(int duyuruId, String detay, bool okundu) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Duyuru Detayı'),
        content: Text(detay),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
    print("_duyuruyaTiklandi  dialog sonrası");
    if (!okundu) {
      try {
        print("setDuyuruOkundu oncesi");
        bool okunduMu = await ApiService().setDuyuruOkundu(duyuruId);
        _loadDuyurular();
      } catch (e) {
        print('Duyuru okundu güncelleme hatası: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Duyuru Listesi'),
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
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: duyurular.length,
          itemBuilder: (context, index) {
            var duyuru = duyurular[index];
            var okundu = duyuru['Okundu'] == 1;
            final renk = okundu ? Colors.grey : Colors.blue[900];
            var tarih = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(duyuru['InsertDate']));

            return ListTile(
              title: Text(
                duyuru['Baslik'],
                style: TextStyle(color: renk, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gönderen: ${duyuru['GonderenAdi']}', style: TextStyle(color: renk)),
                  Text('Tarih: $tarih', style: TextStyle(color: renk)),
                ],
              ),
              onTap: () => _duyuruyaTiklandi(
                duyuru['Id'],
                duyuru['Data'],
                okundu,
              ),
            );
          },
        ),
      ),
    );
  }
}
