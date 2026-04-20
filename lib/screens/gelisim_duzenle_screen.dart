import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../globals.dart' as globals;
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class GelisimDuzenleScreen extends StatefulWidget {
  const GelisimDuzenleScreen({Key? key}) : super(key: key);

  @override
  State<GelisimDuzenleScreen> createState() => _GelisimDuzenleScreenState();
}

class _GelisimDuzenleScreenState extends State<GelisimDuzenleScreen> {
  List<dynamic> gelisimTipleri = [];
  bool tipiLoading = true;
  bool kayitLoading = false;

  dynamic seciliGelisimTipi;
  String? seciliOgrenciTckn;

  List<dynamic> kayitlar = [];

  @override
  void initState() {
    super.initState();

    if (globals.globalOgrenciListesi.isNotEmpty) {
      seciliOgrenciTckn =
          globals.globalOgrenciListesi.first['TCKN'].toString();
    } else {
      seciliOgrenciTckn = globals.orjKullaniciTCKN;
    }

    _loadGelisimTipleri();
  }

  Future<void> _loadGelisimTipleri() async {
    try {
      final schoolId = int.parse(globals.globalSchoolId.toString());
      final data = await ApiService().getGelisimTipleri(schoolId);
      setState(() {
        gelisimTipleri = data ?? [];
        tipiLoading = false;
      });
    } catch (_) {
      setState(() {
        gelisimTipleri = [];
        tipiLoading = false;
      });
    }
  }

  Future<void> _getir() async {
    if (seciliGelisimTipi == null || seciliOgrenciTckn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fillRequiredFields),
        ),
      );
      return;
    }

    setState(() {
      kayitLoading = true;
      kayitlar = [];
    });

    try {
      final data = await ApiService().getGelisimByTip(
        tckn: seciliOgrenciTckn!,
        tipId: seciliGelisimTipi['Id'],
      );

      final result = data ?? [];
      result.sort((a, b) => DateTime.parse(b['InsertDate'])
          .compareTo(DateTime.parse(a['InsertDate'])));

      setState(() {
        kayitlar = result;
        kayitLoading = false;
      });
    } catch (e) {
      setState(() {
        kayitlar = [];
        kayitLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.recordsFetchError)),
      );
    }
  }

  Future<void> _guncelle(dynamic kayit) async {
    final ctrl = TextEditingController(text: kayit['Deger'].toString());

    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.edit),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.value,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (onaylandi != true) return;
    if (ctrl.text.trim().isEmpty) return;

    try {
      await ApiService().updateGelisim(
        id: kayit['Id'],
        deger: ctrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.savedAll)),
      );
      await _getir();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saveError)),
      );
    }
  }

  Future<void> _sil(dynamic kayit) async {
    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConfirmTitle),
        content: Text(AppLocalizations.of(context)!.gelisimDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.yes),
          ),
        ],
      ),
    );

    if (onaylandi != true) return;

    try {
      await ApiService().removeGelisim(kayit['Id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.recordDeleted)),
      );
      await _getir();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deleteError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.editGelisimTitle,
          style: AppStyles.titleLarge,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Column(
        children: [
          _buildFiltrePaneli(),
          const SizedBox(height: 4),
          Expanded(child: _buildListe()),
        ],
      ),
    );
  }

  Widget _buildFiltrePaneli() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          /// Gelişim Tipi
          tipiLoading
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<dynamic>(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.growtType,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: seciliGelisimTipi,
                  items: gelisimTipleri
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('${d['Ad']} (${d['Birim']})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    seciliGelisimTipi = v;
                    kayitlar = [];
                  }),
                ),

          const SizedBox(height: 8),

          /// Öğrenci
          if (globals.globalOgrenciListesi.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.students,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              value: seciliOgrenciTckn,
              items: globals.globalOgrenciListesi
                  .map((ogr) => DropdownMenuItem<String>(
                        value: ogr['TCKN'].toString(),
                        child: Text(ogr['Name'] ?? ''),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                seciliOgrenciTckn = v;
                kayitlar = [];
              }),
            ),

          const SizedBox(height: 10),

          /// Getir Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search, color: AppColors.onPrimary),
              label: Text(AppLocalizations.of(context)!.getResult),
              style: AppStyles.buttonStyle,
              onPressed: kayitLoading ? null : _getir,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListe() {
    if (kayitLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kayitlar.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noRecordFound,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: kayitlar.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final k = kayitlar[i];
        final tarih = DateTime.tryParse(k['InsertDate'] ?? '');
        final tarihStr = tarih != null ? fmt.format(tarih) : '-';
        final birim = seciliGelisimTipi?['Birim'] ?? '';

        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${k['Deger']} $birim',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(tarihStr),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: AppLocalizations.of(context)!.edit,
                  onPressed: () => _guncelle(k),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: AppLocalizations.of(context)!.delete,
                  onPressed: () => _sil(k),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
