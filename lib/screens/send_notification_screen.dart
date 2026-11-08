import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../globals.dart' as globals;
import '../utils/error_translator.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({Key? key}) : super(key: key);

  @override
  _SendNotificationScreenState createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  List<Map<String, dynamic>> _ogrenciler = [];
  bool _ogrenciLoading = true;
  List<String> selectedOgrenciler = [];
  bool isAllSelected = false;
  bool _isSending = false; // 👈 Yeni eklendi

  @override
  void initState() {
    super.initState();
    _loadOgrenciler();
  }

  String _fullTckn(Map ogr) =>
      '${ogr['TCKN']}_${globals.globalSchoolId}_S';

  int? _sinifId(Map ogr) {
    final v = ogr['ClassId'] ?? ogr['classId'] ?? ogr['SinifId'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString().split('.').first ?? '');
  }

  String _sinifAdi(Map ogr) =>
      (ogr['ClassName'] ??
              ogr['className'] ??
              ogr['sinifAd'] ??
              ogr['SinifAd'] ??
              '')
          .toString()
          .trim();

  List<MapEntry<String, List<Map<String, dynamic>>>> get _sinifKirilim {
    final byKey = <String, List<Map<String, dynamic>>>{};
    final titles = <String, String>{};
    for (final o in _ogrenciler) {
      final id = _sinifId(o);
      final ad = _sinifAdi(o);
      final key = id != null
          ? 'id_$id'
          : (ad.isNotEmpty ? 'ad_${ad.toLowerCase()}' : 'none');
      titles.putIfAbsent(
        key,
        () => ad.isNotEmpty
            ? ad
            : (id != null
                ? '${AppLocalizations.of(context)!.labelClass} $id'
                : '—'),
      );
      byKey.putIfAbsent(key, () => []).add(o);
    }
    final entries = byKey.entries.toList()
      ..sort((a, b) {
        if (a.key == 'none') return 1;
        if (b.key == 'none') return -1;
        return (titles[a.key] ?? '')
            .toLowerCase()
            .compareTo((titles[b.key] ?? '').toLowerCase());
      });
    return [
      for (final e in entries) MapEntry(titles[e.key] ?? e.key, e.value),
    ];
  }

  Future<void> _loadOgrenciler() async {
    try {
      final data = await ApiService.loadHomeworkStudents();
      if (!mounted) return;
      setState(() {
        _ogrenciler = data;
        selectedOgrenciler = data.map(_fullTckn).toList();
        isAllSelected = data.isNotEmpty;
        _ogrenciLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ogrenciler = [];
        selectedOgrenciler = [];
        isAllSelected = false;
        _ogrenciLoading = false;
      });
    }
  }

  void _syncHepsi() {
    isAllSelected = _ogrenciler.isNotEmpty &&
        _ogrenciler.every((o) => selectedOgrenciler.contains(_fullTckn(o)));
  }

  void _toggleAll(bool? value) {
    setState(() {
      isAllSelected = value ?? false;
      if (isAllSelected) {
        selectedOgrenciler = _ogrenciler.map(_fullTckn).toList();
      } else {
        selectedOgrenciler.clear();
      }
    });
  }

  void _toggleSinif(List<Map<String, dynamic>> liste, bool? value) {
    setState(() {
      final ids = liste.map(_fullTckn).toList();
      if (value == true) {
        for (final id in ids) {
          if (!selectedOgrenciler.contains(id)) selectedOgrenciler.add(id);
        }
      } else {
        selectedOgrenciler.removeWhere(ids.contains);
      }
      _syncHepsi();
    });
  }

  void _toggleOgrenci(String tckn, bool? value) {
    setState(() {
      if (value == true) {
        if (!selectedOgrenciler.contains(tckn)) selectedOgrenciler.add(tckn);
      } else {
        selectedOgrenciler.remove(tckn);
      }
      _syncHepsi();
    });
  }

  Future<void> _sendNotification() async {
    if (_formKey.currentState!.validate() && selectedOgrenciler.isNotEmpty) {
      setState(() => _isSending = true); // 👈 Buton devre dışı

      try {
        await _apiService.sendNotificationToKisiler(
          globals.kullaniciTCKN,
          selectedOgrenciler,
          _titleController.text,
          _messageController.text,
        );

        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.announcementSentSuccess,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        _titleController.clear();
        _messageController.clear();
        setState(() {
          selectedOgrenciler.clear();
          isAllSelected = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translateError(e.toString(), context))),
        );
      } finally {
        setState(() => _isSending = false); // 👈 Buton tekrar aktif
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillFieldsSelectStudent)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            l10n.sendAnnouncement,
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        height: screenHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(Icons.campaign,
                                    size: 64, color: AppColors.onPrimary),
                                const SizedBox(height: 24),
                                Text(
                                  l10n.newAnnouncement,
                                  style: AppStyles.buttonTextStyle,
                                  /*Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,*/
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    labelText: l10n.announcementTitleLabel,
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.title),
                                  ),
                                  validator: (value) => value == null ||
                                      value.isEmpty
                                      ? l10n.titleRequired
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    labelText: l10n.announcementMessageLabel,
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.message),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 5,
                                  validator: (value) => value == null ||
                                      value.isEmpty
                                      ? l10n.messageRequired
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                if (_ogrenciLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  )
                                else if (_ogrenciler.isEmpty)
                                  Text(
                                    l10n.noStudentsFound,
                                    style: TextStyle(color: Colors.grey.shade700),
                                  )
                                else ...[
                                  CheckboxListTile(
                                    title: Text(l10n.allOfThem),
                                    subtitle: Text(
                                      '${selectedOgrenciler.length} / ${_ogrenciler.length}',
                                    ),
                                    value: isAllSelected,
                                    onChanged:
                                        _isSending ? null : _toggleAll,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                  ..._sinifKirilim.map((entry) {
                                    final sinifAdi = entry.key;
                                    final liste = entry.value;
                                    final sinifIds = liste.map(_fullTckn).toList();
                                    final hepsiSecili = sinifIds.isNotEmpty &&
                                        sinifIds.every(
                                            selectedOgrenciler.contains);
                                    final kismi = !hepsiSecili &&
                                        sinifIds.any(
                                            selectedOgrenciler.contains);
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ExpansionTile(
                                        initiallyExpanded: true,
                                        title: Text(
                                          '$sinifAdi  (${liste.length})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        children: [
                                          CheckboxListTile(
                                            dense: true,
                                            title: Text(l10n.allOfThem),
                                            tristate: true,
                                            value: hepsiSecili
                                                ? true
                                                : (kismi ? null : false),
                                            onChanged: _isSending
                                                ? null
                                                : (v) => _toggleSinif(
                                                      liste,
                                                      v ?? false,
                                                    ),
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                          ),
                                          ...liste.map((ogrenci) {
                                            final fullTckn = _fullTckn(ogrenci);
                                            return CheckboxListTile(
                                              dense: true,
                                              title: Text(
                                                ogrenci['Name']?.toString() ??
                                                    '',
                                              ),
                                              value: selectedOgrenciler
                                                  .contains(fullTckn),
                                              onChanged: _isSending
                                                  ? null
                                                  : (value) => _toggleOgrenci(
                                                        fullTckn,
                                                        value,
                                                      ),
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                            );
                                          }),
                                        ],
                                      ),
                                    );
                                  }),
                                ],

                                const SizedBox(height: 16),

                                ElevatedButton(
                                  onPressed: _isSending
                                      ? null // 👈 Devre dışı
                                      : _sendNotification,
                                  style: AppStyles.buttonStyle,/*ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                  ),*/
                                  child: Text(
                                    _isSending
                                        ? l10n.sendingAnnouncement
                                        : l10n.sendAnnouncement,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),

                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

/*import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../globals.dart' as globals;
import '../utils/error_translator.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({Key? key}) : super(key: key);

  @override
  _SendNotificationScreenState createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  List<String> selectedOgrenciler = [];
  bool isAllSelected = false;

  void _toggleAll(bool? value) {
    setState(() {
      isAllSelected = value ?? false;
      if (isAllSelected) {
        selectedOgrenciler = globals.globalOgrenciListesi
            .map<String>((e) => e["TCKN"].toString())
            .toList();
      } else {
        selectedOgrenciler.clear();
      }
    });
  }

  void _toggleOgrenci(String tckn, bool? value) {
    setState(() {
      if (value == true) {
        selectedOgrenciler.add(tckn);
        if (selectedOgrenciler.length == globals.globalOgrenciListesi.length) {
          isAllSelected = true;
        }
      } else {
        selectedOgrenciler.remove(tckn);
        isAllSelected = false;
      }
    });
  }

  Future<void> _sendNotification() async {
    if (_formKey.currentState!.validate() && selectedOgrenciler.isNotEmpty) {
      try {
        await _apiService.sendNotificationToKisiler(
          globals.kullaniciTCKN,
          selectedOgrenciler,
          _titleController.text,
          _messageController.text,
        );


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mesaj(lar) başarıyla gönderildi',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        _titleController.clear();
        _messageController.clear();
        setState(() {
          selectedOgrenciler.clear();
          isAllSelected = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translateError(e.toString(), context))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillFieldsSelectStudent)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesaj Gönder'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
        height: screenHeight, // 👈 Tüm ekran yüksekliği
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primary.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight, // 👈 Scroll olsa bile tam yükseklik
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(Icons.campaign,
                                    size: 64, color: AppColors.primary),
                                const SizedBox(height: 24),
                                Text(
                                  'Yeni Mesaj',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),

                                // Başlık
                                TextFormField(
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    labelText: l10n.announcementTitleLabel,
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.title),
                                  ),
                                  validator: (value) => value == null ||
                                      value.isEmpty
                                      ? l10n.titleRequired
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Mesaj
                                TextFormField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    labelText: l10n.announcementMessageLabel,
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.message),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 5,
                                  validator: (value) => value == null ||
                                      value.isEmpty
                                      ? l10n.messageRequired
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Öğrenci listesi
                                CheckboxListTile(
                                  title: Text(l10n.allOfThem),
                                  value: isAllSelected,
                                  onChanged: _toggleAll,
                                  controlAffinity:
                                  ListTileControlAffinity.leading,
                                ),
                                ...globals.globalOgrenciListesi.map((ogrenci) {
                                  final tckn = ogrenci['TCKN'].toString();
                                  final name = ogrenci['Name'];
                                  return CheckboxListTile(
                                    title: Text(name),
                                    value: selectedOgrenciler.contains(tckn),
                                    onChanged: (value) =>
                                        _toggleOgrenci(tckn, value),
                                    controlAffinity:
                                    ListTileControlAffinity.leading,
                                  );
                                }).toList(),

                                const SizedBox(height: 16),

                                // Gönder butonu
                                ElevatedButton(
                                  onPressed: _sendNotification,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                  ),
                                  child: Text(
                                    'Mesaj Gönder',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),

                                const Spacer(), // 👈 Boş alan, Card altını doldurur
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
*/

/*import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart' as globals;
import '../utils/error_translator.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({Key? key}) : super(key: key);

  @override
  _SendNotificationScreenState createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  List<String> selectedOgrenciler = [];
  bool isAllSelected = false;

  void _toggleAll(bool? value) {
    setState(() {
      isAllSelected = value ?? false;
      if (isAllSelected) {
        selectedOgrenciler = globals.globalOgrenciListesi
            .map<String>((e) => e["TCKN"].toString())
            .toList();
      } else {
        selectedOgrenciler.clear();
      }
    });
  }

  void _toggleOgrenci(String tckn, bool? value) {
    setState(() {
      if (value == true) {
        selectedOgrenciler.add(tckn);
        if (selectedOgrenciler.length == globals.globalOgrenciListesi.length) {
          isAllSelected = true;
        }
      } else {
        selectedOgrenciler.remove(tckn);
        isAllSelected = false;
      }
    });
  }

  Future<void> _sendNotification() async {
    if (_formKey.currentState!.validate() && selectedOgrenciler.isNotEmpty) {
      try {
        await _apiService.sendNotificationToKisiler(
          globals.kullaniciTCKN,
          selectedOgrenciler,
          _titleController.text,
          _messageController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesaj(lar) başarıyla gönderildi')),
        );



        _titleController.clear();
        _messageController.clear();
        setState(() {
          selectedOgrenciler.clear();
          isAllSelected = false;
        });

        Navigator.push(context,
            MaterialPageRoute(builder: (context) => HomeScreen()));

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translateError(e.toString(), context))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillFieldsSelectStudent)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mesaj Gönder'),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.campaign, size: 64, color: AppColors.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Yeni Mesaj',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Başlık alanı
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Duyuru Başlığı',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Başlık gerekli' : null,
                      ),
                      const SizedBox(height: 16),

                      // Mesaj alanı
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Duyuru Mesajı',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Mesaj gerekli' : null,
                      ),
                      const SizedBox(height: 20),

                      // Checkbox listesi butonun hemen üzerinde
                      CheckboxListTile(
                        title: Text(l10n.allOfThem),
                        value: isAllSelected,
                        onChanged: _toggleAll,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      ...globals.globalOgrenciListesi.map((ogrenci) {
                        final tckn = ogrenci['TCKN'].toString();
                        final name = ogrenci['Name'];
                        return CheckboxListTile(
                          title: Text(name),
                          value: selectedOgrenciler.contains(tckn),
                          onChanged: (value) => _toggleOgrenci(tckn, value),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList(),

                      const SizedBox(height: 16),

                      // Duyuru Gönder butonu
                      ElevatedButton(
                        onPressed: _sendNotification,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: Text(
                          'Mesaj Gönder',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
*/

/*import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../globals.dart' as globals;
import '../utils/error_translator.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({Key? key}) : super(key: key);

  @override
  _SendNotificationScreenState createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  List<String> selectedOgrenciler = [];
  bool isAllSelected = false;

  void _toggleAll(bool? value) {
    setState(() {
      isAllSelected = value ?? false;
      if (isAllSelected) {
        selectedOgrenciler = globals.globalOgrenciListesi
            .map<String>((e) => e["TCKN"].toString())
            .toList();
      } else {
        selectedOgrenciler.clear();
      }
    });
  }

  void _toggleOgrenci(String id, bool? value) {
    setState(() {
      if (value == true) {
        selectedOgrenciler.add(id);
        if (selectedOgrenciler.length == globals.globalOgrenciListesi.length) {
          isAllSelected = true;
        }
      } else {
        selectedOgrenciler.remove(id);
        isAllSelected = false;
      }
    });
  }

  Future<void> _sendNotification() async {
    if (_formKey.currentState!.validate() && selectedOgrenciler.isNotEmpty) {
      try {
        for (String id in selectedOgrenciler) {
          await _apiService.sendNotificationToOgrenci(
            id,
            _titleController.text,
            _messageController.text,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duyuru(lar) başarıyla gönderildi')),
        );

        _titleController.clear();
        _messageController.clear();
        setState(() {
          selectedOgrenciler.clear();
          isAllSelected = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translateError(e.toString(), context))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillFieldsSelectStudent)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Duyuru Gönder'),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.campaign, size: 64, color: AppColors.primary),
                      const SizedBox(height: 24),
                      Text(
                        l10n.newAnnouncement,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Başlık alanı
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Duyuru Başlığı',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Başlık gerekli' : null,
                      ),
                      const SizedBox(height: 16),

                      // Mesaj alanı
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Duyuru Mesajı',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Mesaj gerekli' : null,
                      ),
                      const SizedBox(height: 20),

                      // Checkbox listesi butonun hemen üzerinde
                      CheckboxListTile(
                        title: Text(l10n.allOfThem),
                        value: isAllSelected,
                        onChanged: _toggleAll,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      ...globals.globalOgrenciListesi.map((ogrenci) {
                        final tckn = ogrenci['TCKN'].toString();
                        final name = ogrenci['Name'];
                        return CheckboxListTile(
                          title: Text(name),
                          value: selectedOgrenciler.contains(tckn),
                          onChanged: (value) => _toggleOgrenci(tckn, value),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList(),

                      const SizedBox(height: 16),

                      // Duyuru Gönder butonu
                      ElevatedButton(
                        onPressed: _sendNotification,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: Text(
                          'Duyuru Gönder',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
*/