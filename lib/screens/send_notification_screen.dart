import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../globals.dart' as globals;

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
  bool _isSending = false; // 👈 Yeni eklendi

  void _toggleAll(bool? value) {
    setState(() {
      isAllSelected = value ?? false;
      if (isAllSelected) {
        selectedOgrenciler = globals.globalOgrenciListesi
            .map<String>((e) => e["TCKN"].toString()+"_"+globals.globalSchoolId+'_S')
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
      setState(() => _isSending = true); // 👈 Buton devre dışı

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

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      } finally {
        setState(() => _isSending = false); // 👈 Buton tekrar aktif
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen tüm alanları doldurun ve öğrenci seçin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const
        Text(
            'Mesaj Gönder',
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
                                  'Yeni Mesaj',
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
                                  decoration: const InputDecoration(
                                    labelText: 'Bildirim Başlığı',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.title),
                                  ),
                                  validator: (value) => value == null ||
                                      value.isEmpty
                                      ? 'Başlık gerekli'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    labelText: 'Bildirim Mesajı',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.message),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 5,
                                  validator: (value) => value == null ||
                                      value.isEmpty
                                      ? 'Mesaj gerekli'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                CheckboxListTile(
                                  title: const Text('Hepsi'),
                                  value: isAllSelected,
                                  onChanged: _isSending ? null : _toggleAll, // 👈 Devre dışı
                                  controlAffinity:
                                  ListTileControlAffinity.leading,
                                ),
                                ...globals.globalOgrenciListesi.map((ogrenci) {
                                  final tckn = ogrenci['TCKN'].toString();
                                  final fullTckn = tckn + "_" + globals.globalSchoolId + "_S";
                                  final name = ogrenci['Name'];

                                  return CheckboxListTile(
                                    title: Text(name),
                                    value: selectedOgrenciler.contains(fullTckn),
                                    onChanged: _isSending
                                        ? null
                                        : (value) => _toggleOgrenci(fullTckn, value),
                                    controlAffinity: ListTileControlAffinity.leading,
                                  );
                                }).toList(),


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
                                        ? 'Mesajınız Gönderiliyor...' // 👈 Değişen yazı
                                        : 'Mesaj Gönder',
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
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen tüm alanları doldurun ve öğrenci seçin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesaj Gönder'),
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
                                  decoration: const InputDecoration(
                                    labelText: 'Bildirim Başlığı',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.title),
                                  ),
                                  validator: (value) => value == null ||
                                      value.isEmpty
                                      ? 'Başlık gerekli'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                // Mesaj
                                TextFormField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    labelText: 'Bildirim Mesajı',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.message),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 5,
                                  validator: (value) => value == null ||
                                      value.isEmpty
                                      ? 'Mesaj gerekli'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Öğrenci listesi
                                CheckboxListTile(
                                  title: const Text('Hepsi'),
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
                                  child: const Text(
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
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun ve öğrenci seçin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesaj Gönder'),
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
                          labelText: 'Bildirim Başlığı',
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
                          labelText: 'Bildirim Mesajı',
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
                        title: const Text('Hepsi'),
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

                      // Bildirim Gönder butonu
                      ElevatedButton(
                        onPressed: _sendNotification,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: const Text(
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
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun ve öğrenci seçin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyuru Gönder'),
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
                        'Yeni Duyuru',
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
                          labelText: 'Bildirim Başlığı',
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
                          labelText: 'Bildirim Mesajı',
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
                        title: const Text('Hepsi'),
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

                      // Bildirim Gönder butonu
                      ElevatedButton(
                        onPressed: _sendNotification,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: const Text(
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