import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../globals.dart' as globals;

class SendNotificationScreenP extends StatefulWidget {
  const SendNotificationScreenP({Key? key}) : super(key: key);

  @override
  _SendNotificationScreenStateP createState() =>
      _SendNotificationScreenStateP();
}

class _SendNotificationScreenStateP extends State<SendNotificationScreenP> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  String? selectedOgretmen;
  List<Map<String, dynamic>> uniqueOgretmenList = [];
  bool _isSending = false; // 🔹 butonun aktiflik durumunu kontrol etmek için eklendi

  @override
  void initState() {
    super.initState();
    _prepareOgretmenList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (uniqueOgretmenList.isNotEmpty && selectedOgretmen == null) {
        setState(() {
          selectedOgretmen =
          '${uniqueOgretmenList.first['TeacherTCKN'] ?? ''}';
        });
      }
    });
  }

  void _prepareOgretmenList() {
    final seen = <String>{};
    uniqueOgretmenList = globals.globalOgretmenListesi
        .where((ogrenci) {
      final tckn = '${ogrenci['TeacherTCKN'] ?? ''}';
      if (tckn.isEmpty) return false;
      if (seen.contains(tckn)) return false;
      seen.add(tckn);
      return true;
    })
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _sendNotification() async {
    if (_isSending) return; // 🔹 Çift tıklamayı engelle
    setState(() => _isSending = true); // 🔹 butonu devre dışı yap

    if (selectedOgretmen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir öğretmen seçin')),
      );
      setState(() => _isSending = false);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen başlık ve mesaj girin')),
      );
      setState(() => _isSending = false);
      return;
    }

    try {
      await _apiService.sendNotificationToKisiler(
        globals.kullaniciTCKN,
        [selectedOgretmen!],
        _titleController.text,
        _messageController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mesaj başarıyla gönderildi',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      _titleController.clear();
      _messageController.clear();

      if (mounted) {
        setState(() {
          _isSending = false;
          if (uniqueOgretmenList.length > 1) {
            selectedOgretmen = null;
          }
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
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
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
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
          ),
          SafeArea(
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

                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Bildirim Başlığı',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) =>
                          value == null || value.isEmpty
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
                          validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Mesaj gerekli'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        if (uniqueOgretmenList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Öğretmen bulunamadı.'),
                          )
                        else
                          ...uniqueOgretmenList.map((ogrenci) {
                            final tckn = '${ogrenci['TeacherTCKN'] ?? ''}';
                            final teacherName = ogrenci['TeacherName'] ?? "";
                            return RadioListTile<String>(
                              title: Text(teacherName),
                              value: tckn,
                              groupValue: selectedOgretmen,
                              onChanged: (value) {
                                setState(() {
                                  selectedOgretmen = value;
                                });
                              },
                            );
                          }).toList(),

                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: _isSending ? null : _sendNotification, // 🔹 Buton devre dışı
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                          ),
                          child: Text(
                            _isSending
                                ? 'Mesaj Gönderiliyor...' // 🔹 Buton metni değişiyor
                                : 'Mesaj Gönder',
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
        ],
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

class SendNotificationScreenP extends StatefulWidget {
  const SendNotificationScreenP({Key? key}) : super(key: key);

  @override
  _SendNotificationScreenStateP createState() =>
      _SendNotificationScreenStateP();
}

class _SendNotificationScreenStateP extends State<SendNotificationScreenP> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  String? selectedOgretmen; // sadece 1 kişi seçilecek
  List<Map<String, dynamic>> uniqueOgretmenList = [];

  @override
  void initState() {
    super.initState();
    _prepareOgretmenList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (uniqueOgretmenList.isNotEmpty && selectedOgretmen == null) {
        setState(() {
          selectedOgretmen =
          '${uniqueOgretmenList.first['TeacherTCKN'] ?? ''}';
        });
      }
    });
  }

  void _prepareOgretmenList() {
    final seen = <String>{};
    uniqueOgretmenList = globals.globalOgretmenListesi
        .where((ogrenci) {
      final tckn = '${ogrenci['TeacherTCKN'] ?? ''}';
      if (tckn.isEmpty) return false;
      if (seen.contains(tckn)) return false;
      seen.add(tckn);
      return true;
    })
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _sendNotification() async {
    if (selectedOgretmen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir öğretmen seçin')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen başlık ve mesaj girin')),
      );
      return;
    }

    try {
      await _apiService.sendNotificationToKisiler(
        globals.kullaniciTCKN,
        [selectedOgretmen!],
        _titleController.text,
        _messageController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mesaj başarıyla gönderildi',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      _titleController.clear();
      _messageController.clear();

      if (mounted) {
        setState(() {
          if (uniqueOgretmenList.length > 1) {
            selectedOgretmen = null;
          }
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
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
      body: Stack(
        children: [
          // 🔹 Ekranın tamamını kaplayan gradient arka plan
          Container(
            width: double.infinity,
            height: double.infinity,
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
          ),

          // 🔹 İçerik
          SafeArea(
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

                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Bildirim Başlığı',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) => value == null || value.isEmpty
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
                          validator: (value) => value == null || value.isEmpty
                              ? 'Mesaj gerekli'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        if (uniqueOgretmenList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Öğretmen bulunamadı.'),
                          )
                        else
                          ...uniqueOgretmenList.map((ogrenci) {
                            final tckn = '${ogrenci['TeacherTCKN'] ?? ''}';
                            final teacherName = ogrenci['TeacherName'] ?? "";
                            return RadioListTile<String>(
                              title: Text(teacherName),
                              value: tckn,
                              groupValue: selectedOgretmen,
                              onChanged: (value) {
                                setState(() {
                                  selectedOgretmen = value;
                                });
                              },
                            );
                          }).toList(),

                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: _sendNotification,
                          style: ElevatedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}*/

/*import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/home_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../globals.dart' as globals;

class SendNotificationScreenP extends StatefulWidget {
  const SendNotificationScreenP({Key? key}) : super(key: key);

  @override
  _SendNotificationScreenStateP createState() =>
      _SendNotificationScreenStateP();
}

class _SendNotificationScreenStateP extends State<SendNotificationScreenP> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  String? selectedOgretmen; // sadece 1 kişi seçilecek
  List<Map<String, dynamic>> uniqueOgretmenList =  [];

  @override
  void initState() {
    super.initState();
    _prepareOgretmenList();

    // İlk frame çizildikten sonra otomatik seçim yap (build içinde setState yapmak yerine)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (uniqueOgretmenList.isNotEmpty && selectedOgretmen == null) {
        setState(() {
          selectedOgretmen =
          '${uniqueOgretmenList.first['TeacherTCKN'] ?? ''}';
        });
        debugPrint(
            'postFrame -> selectedOgretmen set to $selectedOgretmen (stateHash: ${hashCode})');
      } else {
        debugPrint(
            'postFrame -> no auto-select (listEmpty=${uniqueOgretmenList.isEmpty}, selected=$selectedOgretmen) (stateHash: ${hashCode})');
      }
    });

    debugPrint('initState -> stateHash: ${hashCode}');
    debugPrint('initState -> uniqueOgretmenList: $uniqueOgretmenList');
    debugPrint('initState -> selectedOgretmen: $selectedOgretmen');
  }

  void _prepareOgretmenList() {
    final seen = <String>{};
    uniqueOgretmenList = globals.globalOgretmenListesi.where((ogrenci) {
      final tckn = '${ogrenci['TeacherTCKN'] ?? ''}';
      if (tckn.isEmpty) return false;
      if (seen.contains(tckn)) return false;
      seen.add(tckn);
      return true;
    }).map<Map<String, dynamic>>((e) {
      // garanti bir Map<String, dynamic> elde etmek iyi olur
      return Map<String, dynamic>.from(e);
    }).toList();
    debugPrint(
        '_prepareOgretmenList -> ${uniqueOgretmenList.length} items (stateHash: ${hashCode})');
  }

  Future<void> _sendNotification() async {
    debugPrint('_sendNotification called (stateHash: ${hashCode})');
    debugPrint('uniqueOgretmenList: $uniqueOgretmenList');
    debugPrint('selectedOgretmen (before validation): $selectedOgretmen');

    if (selectedOgretmen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir öğretmen seçin')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen başlık ve mesaj girin')),
      );
      return;
    }

    try {
      await _apiService.sendNotificationToKisiler(
        globals.kullaniciTCKN,
        [selectedOgretmen!], // tek seçim olduğu için listeye sarıyoruz
        _titleController.text,
        _messageController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mesaj başarıyla gönderildi',
            style: TextStyle(color: Colors.white), // Beyaz yazı
          ),
          backgroundColor: Colors.green,
        ),
      );

      _titleController.clear();
      _messageController.clear();
      if (mounted) {
        setState(() {
          // Eğer birden fazla öğretmen varsa gönderim sonrası seçim temizlenir
          if (uniqueOgretmenList.length > 1) {
            selectedOgretmen = null;
          }
        });

        Navigator.push(context,
            MaterialPageRoute(builder: (context) => HomeScreen()));

      }
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('API error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
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

                      // Başlık alanı
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Bildirim Başlığı',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Başlık gerekli'
                            : null,
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
                        value == null || value.isEmpty
                            ? 'Mesaj gerekli'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Eğer liste boşsa gösterilecek mesaj
                      if (uniqueOgretmenList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Öğretmen bulunamadı.'),
                        )
                      else
                      // Radio buton listesi (sadece TeacherName, tekrarsız)
                        ...uniqueOgretmenList.map((ogrenci) {
                          final tckn = '${ogrenci['TeacherTCKN'] ?? ''}';
                          final teacherName = ogrenci['TeacherName'] ?? "";

                          return RadioListTile<String>(
                            title: Text(teacherName),
                            value: tckn,
                            groupValue: selectedOgretmen,
                            onChanged: (value) {
                              setState(() {
                                selectedOgretmen = value;
                                debugPrint(
                                    'Radio seçildi -> $selectedOgretmen (stateHash: ${hashCode})');
                              });
                            },
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
import '../globals.dart' as globals;

class SendNotificationScreenP extends StatefulWidget {
  const SendNotificationScreenP({Key? key}) : super(key: key);

  @override
  _SendNotificationScreenStateP createState() =>
      _SendNotificationScreenStateP();
}

class _SendNotificationScreenStateP extends State<SendNotificationScreenP> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _apiService = ApiService();

  String? selectedOgretmen; // sadece 1 kişi seçilecek
  List<Map<String, dynamic>> uniqueOgretmenList = [];

  @override
  void initState() {
    super.initState();
    // Tekrarlayan öğretmenleri kaldır
    final seen = <String>{};
    uniqueOgretmenList = globals.globalOgretmenListesi.where((ogrenci) {
      final tckn = ogrenci['TeacherTCKN'].toString();
      if (seen.contains(tckn)) {
        return false;
      } else {
        seen.add(tckn);
        return true;
      }
    }).toList();

    // Eğer listede sadece 1 öğretmen varsa otomatik seçili yap
   // if (uniqueOgretmenList.length == 1) {
      selectedOgretmen = uniqueOgretmenList.first['TeacherTCKN'].toString();
    //}

    print("initState -> uniqueOgretmenList: $uniqueOgretmenList");
    print("initState -> selectedOgretmen: $selectedOgretmen");
  }

  Future<void> _sendNotification() async {
    print('API çağrısı öncesi selectedOgretmen: $selectedOgretmen');

    if (_formKey.currentState!.validate() && selectedOgretmen != null) {
      try {
        await _apiService.sendNotificationToKisiler(
          globals.kullaniciTCKN,
          [selectedOgretmen!], // tek seçim olduğu için listeye sarıyoruz
          _titleController.text,
          _messageController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duyuru başarıyla gönderildi')),
        );

        _titleController.clear();
        _messageController.clear();
        setState(() {
          // Eğer tek öğretmen varsa seçili kalsın, diğer durumda sıfırlansın
          if (uniqueOgretmenList.length > 1) {
            selectedOgretmen = null;
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lütfen tüm alanları doldurun ve bir öğretmen seçin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Eğer tek öğretmen varsa ve selectedOgretmen boşsa otomatik set et
    if (//uniqueOgretmenList.length == 1 &&
        selectedOgretmen == null) {
      selectedOgretmen = uniqueOgretmenList.first['TeacherTCKN'].toString();
      print("build -> Tek öğretmen bulundu, otomatik seçildi: $selectedOgretmen");
    }

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
                      const Icon(Icons.campaign,
                          size: 64, color: AppColors.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Yeni Duyuru',
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

                      // Başlık alanı
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Bildirim Başlığı',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Başlık gerekli'
                            : null,
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
                        value == null || value.isEmpty
                            ? 'Mesaj gerekli'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Radio buton listesi (sadece TeacherName, tekrarsız)
                      ...uniqueOgretmenList.map((ogrenci) {
                        final tckn = ogrenci['TeacherTCKN'].toString();
                        final teacherName = ogrenci['TeacherName'] ?? "";

                        return RadioListTile<String>(
                          title: Text(teacherName),
                          value: tckn,
                          groupValue: selectedOgretmen,
                          onChanged: (value) {
                            setState(() {
                              selectedOgretmen = value;
                              print("Radio seçildi -> $selectedOgretmen");
                            });
                          },
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