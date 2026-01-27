import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/mesaj_detay_screen.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

class MesajAnaScreen extends StatefulWidget {
  const MesajAnaScreen({Key? key}) : super(key: key);

  @override
  State<MesajAnaScreen> createState() => _MesajAnaScreenState();
}

class _MesajAnaScreenState extends State<MesajAnaScreen> {
  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversationList();
  }

  Future<void> _loadConversationList() async {
    try {
      final data =
      await ApiService.getConversationList(globals.kullaniciTCKN);

      setState(() {
        conversations = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Conversation list error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Mesaj açılınca: okundu yap + detay sayfasına git
  Future<void> mesajSayfasiniGetir(String tckn, String name) async {
    try {
      final index =
      conversations.indexWhere((e) => e['TCKN'] == tckn);

      if (index != -1 && conversations[index]['isRead'] == 0) {
        await ApiService().setMesajOkundu(
          globals.kullaniciTCKN, // gonderenTckn
          tckn // alanTckn
        );

        setState(() {
          conversations[index]['isRead'] = 1;
        });
      }
    } catch (e) {
      debugPrint("Mesaj okundu işaretleme hatası: $e");
    }

    // 👉 Detay ekranına git
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesajDetayScreen(
          alanTckn: tckn,
          alanAdi: name,
        ),
      ),
    );

    // 👉 GERİ GELİNCE otomatik refresh
    _loadConversationList();
  }

  /*Future<void> mesajSayfasiniGetir(String tckn, String name) async {
    try {
      final index =
      conversations.indexWhere((e) => e['TCKN'] == tckn);

      if (index != -1 && conversations[index]['isRead'] == 0) {
        // API çağrısı
        await ApiService().setMesajOkundu(
          tckn, // gonderenTckn
          globals.kullaniciTCKN, // alanTckn
        );

        // UI anında güncelle
        setState(() {
          conversations[index]['isRead'] = 1;
        });
      }
    } catch (e) {
      debugPrint("Mesaj okundu işaretleme hatası: $e");
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesajDetayScreen(
          alanTckn: tckn,
          alanAdi: name,
        ),
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mesajlar",
          style: AppStyles.titleLarge,
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
              AppColors.background.withOpacity(0.8),
              AppColors.background.withOpacity(0.6),
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : conversations.isEmpty
            ? const Center(
          child: Text(
            "Henüz mesaj yok",
            style: TextStyle(fontSize: 16),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final item = conversations[index];
            final bool okunmamis = item['isRead'] == 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => mesajSayfasiniGetir(
                  item['TCKN'],
                  item['Name'],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: okunmamis
                        ? AppColors.primary.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child:
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        item['Name']
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    title: Text(
                      item['Name'],
                      style: TextStyle(
                        fontWeight:
                        okunmamis ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),

                    // 👇 ÖĞRENCİ ADLARI
                    subtitle: item['StudentName'] != null &&
                        item['StudentName'].toString().isNotEmpty
                        ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item['StudentName'],
                        style: TextStyle(
                          fontSize: 13,
                          color: okunmamis
                              ? AppColors.primary
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                        : null,

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (okunmamis)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  )

                  /*ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        item['Name']
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item['Name'],
                      style: TextStyle(
                        fontWeight: okunmamis
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (okunmamis)
                          Container(
                            width: 10,
                            height: 10,
                            margin:
                            const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),*/
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
/*import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/mesaj_detay_screen.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;

class MesajAnaScreen extends StatefulWidget {
  const MesajAnaScreen({Key? key}) : super(key: key);

  @override
  State<MesajAnaScreen> createState() => _MesajAnaScreenState();
}

class _MesajAnaScreenState extends State<MesajAnaScreen> {
  List<Map<String, dynamic>> conversations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversationList();
  }

  Future<void> _loadConversationList() async {
    try {
      final data =
      await ApiService.getConversationList(globals.kullaniciTCKN);

      setState(() {
        conversations = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Conversation list error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Şimdilik boş – ileride mesaj listesi açılacak
  void mesajSayfasiniGetir(String tckn, String name) {
    // TODO: Mesaj detay ekranı burada açılacak
    debugPrint("Mesaj sayfası açılacak: $name ($tckn)");
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MesajDetayScreen(alanTckn: tckn, alanAdi: name)));


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mesajlar",
          style: AppStyles.titleLarge,
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
              AppColors.background.withOpacity(0.8),
              AppColors.background.withOpacity(0.6),
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : conversations.isEmpty
            ? const Center(
          child: Text(
            "Henüz mesaj yok",
            style: TextStyle(fontSize: 16),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final item = conversations[index];
            final bool okunmamis = item['Okundu'] == 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => mesajSayfasiniGetir(
                  item['TCKN'],
                  item['Name'],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        item['Name']
                            .toString()
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item['Name'],
                      style: TextStyle(
                        fontWeight:
                        okunmamis ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          },

        ),
      ),
    );
  }
}
*/