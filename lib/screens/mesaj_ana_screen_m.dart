import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/screens/mesaj_ana_screen.dart';
import 'package:smart_okul_mobile/screens/mesaj_detay_screen.dart';
import '../constants.dart';
import '../services/api_service.dart';
import '../globals.dart' as globals;
import 'package:smart_okul_mobile/l10n/app_localizations.dart';
class MesajAnaScreenM extends StatefulWidget {
  const MesajAnaScreenM({Key? key}) : super(key: key);

  @override
  State<MesajAnaScreenM> createState() => _MesajAnaScreenMState();
}

class _MesajAnaScreenMState extends State<MesajAnaScreenM> {
  bool isLoading = true;
  final TextEditingController _aramaCtrl = TextEditingController();
  String _arama = '';

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _gorunenOgretmenler {
    final q = _arama.trim().toLowerCase();
    final list = globals.globalOgretmenListesi;
    if (q.isEmpty) return list;
    return list.where((o) {
      final name = (o['Name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  Future<void> _loadTeachers() async {
    try {
      final schoolId =
      int.tryParse(globals.globalSchoolId.toString());

      if (schoolId == null) {
        debugPrint("SchoolId parse edilemedi");
        return;
      }

      await ApiService.getAllTeachersAndSetGlobal(schoolId);
    } catch (e) {
      debugPrint("Öğretmen listesi hata: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

 /* void _mesajDetayAc(Map<String, dynamic> ogretmen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesajAnaScreen(
          tckn: ogretmen["TCKN"], // 👈 hangi öğretmen/veli ise
        ),
      ),
    );

  }*/
  void _ogretmenleMesajAc(Map<String, dynamic> ogretmen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesajDetayScreen(
          tckn: globals.kullaniciTCKN,
          alanTckn: ogretmen["TCKN"],
          alanAdi: ogretmen["Name"],
        ),
      ),
    );
  }


  void _ogretmenVeliMesajlariAc(Map<String, dynamic> ogretmen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesajAnaScreen(
          tckn: ogretmen["TCKN"],
        ),
      ),
    );
  }

  String _avatarLetter(String? name) {
    if (name == null || name.trim().isEmpty) return "?";
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.teachersTitle, style: AppStyles.titleLarge),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                controller: _aramaCtrl,
                onChanged: (v) => setState(() => _arama = v),
                decoration: InputDecoration(
                  hintText: 'Ara',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _arama.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _aramaCtrl.clear();
                            setState(() => _arama = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : globals.globalOgretmenListesi.isEmpty
            ?  Center(
          child: Text(
            AppLocalizations.of(context)!.teacherNotFound,
            style: TextStyle(fontSize: 16),
          ),
        )
            : _gorunenOgretmenler.isEmpty
            ? const Center(
                child: Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _gorunenOgretmenler.length,
          itemBuilder: (context, index) {
            final ogretmen =
            _gorunenOgretmenler[index];

            return Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () =>
                          _ogretmenleMesajAc(ogretmen),
                      leading: CircleAvatar(
                        backgroundColor:
                        AppColors.primary,
                        child: Text(
                          _avatarLetter(
                              ogretmen["Name"]),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        ogretmen["Name"] ??
                            AppLocalizations.of(context)!.unnamedTeacher,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      subtitle:
                      ogretmen["TelNo"] != null
                          ? Text(
                        ogretmen["TelNo"],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors
                              .grey.shade600,
                        ),
                      )
                          : null,
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(
                          16, 0, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                              Icons.message),
                          label:  Text(
                              AppLocalizations.of(context)!.parentMessages,),
                          style: OutlinedButton
                              .styleFrom(
                            foregroundColor:
                            AppColors.primary,
                            side: BorderSide(
                                color:
                                AppColors.primary),
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(12),
                            ),
                          ),
                          onPressed: () =>
                              _ogretmenVeliMesajlariAc(ogretmen),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
            ),
          ],
        ),
      ),
    );
  }
}
