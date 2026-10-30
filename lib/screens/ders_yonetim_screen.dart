import 'package:flutter/material.dart';

import '../constants.dart';
import '../globals.dart' as globals;
import '../models/ders_catalog.dart';
import '../services/api_service.dart';
import '../utils/error_translator.dart';

/// Okula katalogdan ders atama / kaldırma (T/M).
class DersYonetimScreen extends StatefulWidget {
  const DersYonetimScreen({super.key});

  @override
  State<DersYonetimScreen> createState() => _DersYonetimScreenState();
}

class _DersYonetimScreenState extends State<DersYonetimScreen> {
  List<DersItem> _okulDersleri = [];
  List<DersItem> _katalog = [];
  bool _loading = true;
  bool _busy = false;

  int get _schoolId =>
      int.tryParse(globals.globalSchoolId.toString()) ?? 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _loading = true);
    try {
      final okul = await ApiService.getSchoolDersler(_schoolId);
      final cat = await ApiService.getCatalogAvailable(_schoolId);
      if (!mounted) return;
      setState(() {
        _okulDersleri = okul;
        _katalog = cat;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(translateError(e.toString(), context), error: true);
    }
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _dersEkle() async {
    if (_katalog.isEmpty) {
      _snack('Atanabilecek katalog dersi yok', error: true);
      return;
    }
    int? secilen = _katalog.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialog) {
            return AlertDialog(
              title: const Text('Katalogdan ders ekle'),
              content: DropdownButtonFormField<int>(
                value: secilen,
                decoration: const InputDecoration(
                  labelText: 'Ders',
                  border: OutlineInputBorder(),
                ),
                items: _katalog
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.ad),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialog(() => secilen = v),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || secilen == null) return;
    setState(() => _busy = true);
    try {
      await ApiService.assignDersToSchool(
        schoolId: _schoolId,
        dersId: secilen!,
      );
      if (!mounted) return;
      _snack('Ders okula atandı');
      await _yukle();
    } catch (e) {
      if (!mounted) return;
      _snack(translateError(e.toString(), context), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dersKaldir(DersItem d) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: Text('"${d.ad}" okuldan kaldırılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (onay != true) return;
    setState(() => _busy = true);
    try {
      await ApiService.removeDersFromSchool(
        schoolId: _schoolId,
        dersId: d.id,
      );
      if (!mounted) return;
      _snack('Ders kaldırıldı');
      await _yukle();
    } catch (e) {
      if (!mounted) return;
      _snack(translateError(e.toString(), context), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Okul Dersleri', style: AppStyles.titleLarge),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withValues(alpha: 0.8),
              AppColors.background.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _dersEkle,
                  icon: const Icon(Icons.add, color: AppColors.onPrimary),
                  label: const Text('Katalogdan ders ekle'),
                  style: AppStyles.buttonStyle,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _yukle,
                      child: _okulDersleri.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    'Okula atanmış ders yok',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _okulDersleri.length,
                              itemBuilder: (context, index) {
                                final d = _okulDersleri[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Container(
                                    decoration: AppStyles.listCardDecoration,
                                    child: ListTile(
                                      title: Text(
                                        d.ad,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            _busy ? null : () => _dersKaldir(d),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
