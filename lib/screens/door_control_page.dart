import 'package:flutter/material.dart';
import 'package:smart_okul_mobile/constants.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/services/api_service.dart';
import '../services/api_service.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class DoorControlPage extends StatelessWidget {
  final bool hasGateAccess;
  final bool hasParkingAccess;

  const DoorControlPage({
    Key? key,
    required this.hasGateAccess,
    required this.hasParkingAccess,
  }) : super(key: key);

  Future<void> anaKapiyiAc(BuildContext context) async {
    try {
      String cevap = await ApiService().onGatePressed(context);

      if (cevap == "200") {
        _pencereAc(context, AppLocalizations.of(context)!.mainGateRequestSent);
      } else {
        _pencereAc(context,AppLocalizations.of(context)!.mainGateRequestFailed);
      }
    } catch (e) {
      _pencereAc(context, AppLocalizations.of(context)!.errorOccurred+": $e");
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
              title: Text(AppLocalizations.of(context)!.notifyArrivalTitle),
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
                  child:  Text(AppLocalizations.of(context)!.cancel),
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
                       SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.attendanceSaved,
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child:  Text(AppLocalizations.of(context)!.notifyArrivalTitle),
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
        _pencereAc(context, AppLocalizations.of(context)!.parkingRequestSent);
      } else {
        _pencereAc(context,AppLocalizations.of(context)!.parkingRequestFailed);
      }
    } catch (e) {
      _pencereAc(context, AppLocalizations.of(context)!.errorOccurred+": $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title:
        Text(
            AppLocalizations.of(context)!.doorControlTitle,
            textAlign: TextAlign.center,
            style: AppStyles.titleLarge
        ),
        //backgroundColor: Colors.blue[700],
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Container(
      width: double.infinity,
      height: double.infinity, // ekranın tamamını kaplasın
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.background,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Column ekranı sarmasın, içerik kadar yer alsın
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasGateAccess)
                _buildControlButton(
                  context: context,
                  icon: Icons.door_front_door,
                  label: AppLocalizations.of(context)!.mainGateControl,
                  enabled: hasGateAccess,
                  onPressed: () => bildirVeKapiAc(context),
                ),
              if (hasGateAccess && hasParkingAccess)
                const SizedBox(height: 16),
              if (hasParkingAccess)
                _buildControlButton(
                  context: context,
                  icon: Icons.local_parking,
                  label: AppLocalizations.of(context)!.parkingControl,
                  enabled: hasParkingAccess,
                  onPressed: () => otoparkKapisiniAc(context),
                ),
              const SizedBox(height: 32), // alt boşluk
            ],
          ),
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
        style: AppStyles.buttonStyle,

        icon: Icon(icon, size: 32, color: AppColors.onPrimary
        ),
        label: Text(
          label,
          style: AppStyles.buttonTextStyle,
        ),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}