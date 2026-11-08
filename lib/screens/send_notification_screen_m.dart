import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../globals.dart' as globals;
import '../utils/error_translator.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart'; // LoginScreen import edildi

class SendNotificationScreenM extends StatefulWidget {
  const SendNotificationScreenM({Key? key}) : super(key: key);

  @override
  _SendNotificationScreenStateM createState() => _SendNotificationScreenStateM();
}

class _SendNotificationScreenStateM extends State<SendNotificationScreenM> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  List<int> selectedSiniflar = [];
  bool isAllSelected = true; // başlangıçta hepsi seçili
  bool _isSending = false;   // gönderim durumu

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında tüm sınıfları seç
    selectedSiniflar = globals.globalSinifListesi
        .map<int>((e) => e["Id"] as int)
        .toList();
  }

  void _toggleAll(bool? value) {
    setState(() {
      isAllSelected = value ?? false;
      if (isAllSelected) {
        selectedSiniflar = globals.globalSinifListesi
            .map<int>((e) => e["Id"] as int)
            .toList();
      } else {
        selectedSiniflar.clear();
      }
    });
  }

  void _toggleSinif(int id, bool? value) {
    setState(() {
      if (value == true) {
        if (!selectedSiniflar.contains(id)) {
          selectedSiniflar.add(id);
        }
        if (selectedSiniflar.length == globals.globalSinifListesi.length) {
          isAllSelected = true;
        }
      } else {
        selectedSiniflar.remove(id);
        isAllSelected = false;
      }
    });
  }
  Future<void> _sendNotificationM() async {
    if (_formKey.currentState!.validate() && selectedSiniflar.isNotEmpty) {
      setState(() {
        _isSending = true; // buton pasifleşsin
      });

      try {
        await _apiService.sendNotificationToSiniflar(
          globals.kullaniciTCKN,
          selectedSiniflar,
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

        // HomeScreen'e yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translateError(e.toString(), context))),
        );
      } finally {
        setState(() {
          _isSending = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.fillFieldsSelectClass,
          ),
        ),
      );
    }
  }

 /* Future<void> _sendNotificationM() async {
    if (_formKey.currentState!.validate() && selectedSiniflar.isNotEmpty) {
      setState(() {
        _isSending = true; // buton pasifleşsin
      });

      try {
        await _apiService.sendNotificationToSiniflar(
          globals.kullaniciTCKN,
          selectedSiniflar,
          _titleController.text,
          _messageController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duyuru(lar) başarıyla gönderildi')),
        );

        _titleController.clear();
        _messageController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translateError(e.toString(), context))),
        );
      } finally {
        setState(() {
          _isSending = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun ve sınıf seçin')),
      );
    }
  }
*/
  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: 16),

                      // Başlık alanı
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: l10n.announcementTitleLabel,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? l10n.titleRequired : null,
                      ),
                      const SizedBox(height: 16),

                      // Mesaj alanı
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: l10n.announcementMessageLabel,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) =>
                        value == null || value.isEmpty ? l10n.messageRequired : null,
                      ),
                      const SizedBox(height: 20),

                      // Checkbox listesi
                      CheckboxListTile(
                        title: Text(l10n.allOfThem),
                        value: isAllSelected,
                        onChanged: _isSending ? null : _toggleAll,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      ...globals.globalSinifListesi.map((sinif) {
                        final id = sinif['Id'] as int;
                        final ad = sinif['Ad'] as String;
                        return CheckboxListTile(
                          title: Text(ad),
                          value: selectedSiniflar.contains(id),
                          onChanged:
                          _isSending ? null : (value) => _toggleSinif(id, value),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      }).toList(),

                      const SizedBox(height: 16),

                      // Mesaj Gönder butonu
                      ElevatedButton(
                        onPressed: _isSending ? null : _sendNotificationM,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                          _isSending ? Colors.grey : AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: Text(
                          _isSending
                              ? l10n.sendingAnnouncement
                              : l10n.sendAnnouncement,
                          style: const TextStyle(fontSize: 16),
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
