import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/constants.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/services/api_service.dart';
import '../services/api_service.dart';

class DoorControlPage extends StatelessWidget {
  final bool hasGateAccess;
  final bool hasParkingAccess;

  const DoorControlPage({
    Key? key,
    required this.hasGateAccess,
    required this.hasParkingAccess,
  }) : super(key: key);

  /*void anaKapiyiAc(BuildContext context){
    Future<String> cevap = _onGatePressed(context);
    _onGatePressed(context).then((cevap){
      if (cevap =="200" )   {
        _pencereAc(context,"Ana Kapı açılma isteği gönderdildi");
      } else {
        _pencereAc(context, "İstek gönderilemedi ");
      }
    });
  }*/

  Future<void> anaKapiyiAc(BuildContext context) async {
    try {
      String cevap = await ApiService().onGatePressed(context);

      if (cevap == "200") {
        _pencereAc(context, "Ana Kapı açılma isteği gönderildi");
      } else {
        _pencereAc(context, "Otopark için istek gönderilemedi");
      }
    } catch (e) {
      _pencereAc(context, "Bir hata oluştu: $e");
    }
  }

  void bildirVeKapiAc(BuildContext context) async {
    if (["M", "T"].contains(globals.globalKullaniciTipi)) {
      anaKapiyiAc(context);
    } else {
      if (["P", "H"].contains(globals.globalKullaniciTipi)) {
        if (globals.globalOgrenciListesi.length == 1) {
          // Tek öğrenci varsa yoklama ekle
          String tckn = globals.globalOgrenciListesi.first['TCKN'];
          await ApiService().yoklamaEkle(tckn, DateTime.now());
          anaKapiyiAc(context);
        } else if (globals.globalOgrenciListesi.length > 1) {
          _showGeldiPopup(context);
        }
      }
    }
  }

  void _showGeldiPopup(BuildContext context) {
    final Map<String, bool> selectedOgrenciler = {
      for (var ogr in globals.globalOgrenciListesi) ogr['TCKN']: true
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Geldiğimizi Bildir"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: globals.globalOgrenciListesi.map((ogrenci) {
                    String tckn = ogrenci['TCKN'];
                    String name = ogrenci['Name'];
                    return CheckboxListTile(
                      title: Text(name),
                      value: selectedOgrenciler[tckn],
                      onChanged: (val) {
                        setState(() {
                          selectedOgrenciler[tckn] = val ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    for (var entry in selectedOgrenciler.entries) {
                      if (entry.value) {
                        await ApiService().yoklamaEkle(entry.key, DateTime.now());
                      }
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Yoklamalar Kaydedildi',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text("Geldiğimizi Bildir"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> otoparkKapisiniAc(BuildContext context) async {
    try {
      String cevap = await ApiService().onParkingPressed(context);

      if (cevap == "200") {
        _pencereAc(context, "Otopark Kapısı açılma isteği gönderildi");
      } else {
        _pencereAc(context, "Otopark için istek gönderilemedi");
      }
    } catch (e) {
      _pencereAc(context, "Bir hata oluştu: $e");
    }
  }

  Future _pencereAc(BuildContext context, String mesaj) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(title: Text(mesaj));
      },
    );
  }

 /* Future<String> _onGatePressed(BuildContext context) async{
    // TODO: API çağrısı buraya eklenecek
    final String baseUrl =
         globals.serverAdrr+"/api/school/open-door/"+globals.globalSchoolId;
    print("baseUrl:$baseUrl");
    Uri uri = Uri.parse(baseUrl );
    http.Response response = await http.get(uri);
    print("gate status:"+response.statusCode.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ana Kapı Kontrol çağrıldı')),
    );
    return Future.delayed(Duration(seconds: 2), () => response.statusCode.toString()??"0");
  }

  Future<String>  _onParkingPressed(BuildContext context) async{
    // TODO: API çağrısı buraya eklenecek
    final String baseUrl =
       globals.serverAdrr+"/api/school/open-park/"+globals.globalSchoolId;
    print("baseUrl:$baseUrl");
    Uri uri = Uri.parse(baseUrl );
    http.Response response = await http.get(uri);
    print("otopark status:"+response.statusCode.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Otopark Kontrol çağrıldı')),
    );
    return Future.delayed(Duration(seconds: 2), () => response.statusCode.toString()??"0");
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Kapı Kontrol Paneli',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
       ),
        //backgroundColor: Colors.blue[700],
        elevation: 0,
        centerTitle: true,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasGateAccess==true)
                  _buildControlButton(
                    context: context,
                    icon: Icons.door_front_door,
                    label: 'Ana Kapı Kontrol',
                    enabled: hasGateAccess,
                    onPressed: () => bildirVeKapiAc(context),
                  ),
                const SizedBox(height: 32),
                if (hasParkingAccess==true)
                  _buildControlButton(
                    context: context,
                    icon: Icons.local_parking,
                    label: 'Otopark Kontrol',
                    enabled: hasParkingAccess,
                    onPressed: () => otoparkKapisiniAc(context),
                  ),
              ],
            ),
          ),
      )

    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 64),
          /*shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),*/
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.onPrimary,
          foregroundColor: AppColors.primary,

        ),
        icon: Icon(icon, size: 32, color: AppColors.primary//Colors.white
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,//Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}