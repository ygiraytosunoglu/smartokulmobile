import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlamak için
import 'package:smart_okul_mobile/constants.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/models/conversation_item.dart';
import 'package:smart_okul_mobile/services/api_service.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class DevamDurumuScreen extends StatefulWidget {
  final String tckn; // parametre

  const DevamDurumuScreen({super.key, required this.tckn});

  @override
  State<DevamDurumuScreen> createState() => _DevamDurumuScreenState();
}

class _DevamDurumuScreenState extends State<DevamDurumuScreen> {
  List<Map<String, dynamic>> _devamListesi = [];
  bool _loading = true;
  String _ogrenciAdi = "";
  int _selectedIndex = -1; // Seçilen satırın indexi

  @override
  void initState() {
    super.initState();
    _getOgrenciAdi();
    _getDevamDurumu();
  }

  String _plainTckn(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    return t.contains('_') ? t.split('_').first : t;
  }

  void _getOgrenciAdi() {
    final hedef = _plainTckn(widget.tckn);
    if (globals.globalKullaniciTipi == 'S' &&
        globals.globalKullaniciAdi.trim().isNotEmpty) {
      _ogrenciAdi = globals.globalKullaniciAdi;
      return;
    }
    for (final e in globals.globalOgrenciListesi) {
      final t = _plainTckn((e['TCKN'] ?? e['tckn'] ?? '').toString());
      if (t == hedef) {
        _ogrenciAdi = (e['Name'] ?? e['name'] ?? '').toString();
        if (_ogrenciAdi.isNotEmpty) return;
      }
    }
    _ogrenciAdi = globals.globalKullaniciAdi.trim().isNotEmpty
        ? globals.globalKullaniciAdi
        : 'Öğrenci';
  }

  Future<void> _getDevamDurumu() async {
    setState(() => _loading = true);

    final raw = await ApiService().getDevamDurumu(_plainTckn(widget.tckn));
    final list = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final date = jsonDate(m, 'date') ?? jsonDate(m, 'tarih');
      if (date == null) continue;
      final has = jsonInt(m, 'has') ??
          (jsonBool(m, 'has') ? 1 : 0);
      list.add({'Date': date, 'Has': has});
    }

    list.sort((a, b) {
      final dateA = a['Date'] as DateTime;
      final dateB = b['Date'] as DateTime;
      return dateB.compareTo(dateA);
    });

    if (!mounted) return;
    setState(() {
      _devamListesi = list;
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
            AppLocalizations.of(context)!.attendanceStatusTitle,
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
                ?  Center(child: Text(AppLocalizations.of(context)!.attendanceNotFound))
                : ListView.builder(
              itemCount: _devamListesi.length,
              itemBuilder: (context, index) {
                final item = _devamListesi[index];
                final bool devam = item['Has'] == 1;
                final DateTime date = item['Date'] as DateTime;
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
                        devam ? AppLocalizations.of(context)!.attended : AppLocalizations.of(context)!.absent,
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
