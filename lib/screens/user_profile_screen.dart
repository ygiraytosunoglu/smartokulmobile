import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/services/api_service.dart';
import '../constants.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final Map<String, Uint8List?> studentPhotos = {};
  Uint8List? kullaniciPhoto;
  List<dynamic> yoklamaBilgileri = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await _fetchYoklamaList();
    await _fetchAllPhotos();
    setState(() {});
  }

  Future<void> _fetchYoklamaList() async {
    try {
      final tcknList = globals.globalOgrenciListesi
          .map<String>((e) => e['TCKN'] as String)
          .toList();

      final today = DateTime.now();
      final formattedDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      yoklamaBilgileri =
      await ApiService().getYoklamaList(tcknList, formattedDate);
    } catch (e) {
      print("⚠️ Yoklama listesi alınamadı: $e");
    }
  }

  Future<void> _fetchAllPhotos() async {
    kullaniciPhoto = await _getPhoto(
      globals.kullaniciTCKN,
      "${globals.kullaniciTCKN}_${globals.fotoVersion}",
    );

    for (var ogrenci in globals.globalOgrenciListesi) {
        final tckn = ogrenci['TCKN'];

      final fotoVersion = ogrenci['FotoVersion'].toString();

      print("tckn:"+tckn+" fotoversion:"+fotoVersion);
      studentPhotos[tckn] =
      await _getPhoto(tckn, "${tckn}_$fotoVersion");
    }
  }

  Future<Uint8List?> _getPhoto(String tckn, String fotoName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/$fotoName.jpg');

      if (await localFile.exists()) {
        return await localFile.readAsBytes();
      }

      try {
        final byteData =
        await rootBundle.load('assets/images/$fotoName.jpg');
        return byteData.buffer.asUint8List();
      } catch (_) {}

      final response = await http.get(Uri.parse(
        '${globals.serverAdrr}/api/school/get-person-photo?tckn=$tckn',
      ));

      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
        return response.bodyBytes;
      }
    } catch (e) {
      print("⚠️ Fotoğraf alma hatası: $e");
    }
    return null;
  }

  Future<void> _updatePhoto(String tckn, bool isKullanici) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse('${globals.serverAdrr}/api/school/upload-person-photo'),
      );

      request.fields['tckn'] = tckn;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: "$tckn.jpg"),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        setState(() {
          if (isKullanici) {
            kullaniciPhoto = bytes;
            globals.fotoVersion++;
          } else {
            studentPhotos[tckn] = bytes;
            for (var ogrenci in globals.globalOgrenciListesi) {
              if (ogrenci['TCKN'] == tckn) {
                ogrenci['FotoVersion'] =
                    (ogrenci['FotoVersion'] ?? 0) + 1;
              }
            }
          }
        });
      }
    } catch (e) {
      print("⚠️ Fotoğraf güncelleme hatası: $e");
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final sanitized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$sanitized');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _getParents(String studentTckn) async {
    final url = Uri.parse(
      '${globals.serverAdrr}/api/student/getParents'
          '?tckn=$studentTckn&schoolId=${globals.globalSchoolId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        _showParentsListPopup(json.decode(response.body));
      }
    } catch (e) {
      print("⚠️ Veli servisi hatası: $e");
    }
  }

  void _showParentsListPopup(List<dynamic> parents) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text(AppLocalizations.of(context)!.parentInfoTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: parents.map<Widget>((p) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.labelFullName+" ${p['Name']}"),
                  Text(AppLocalizations.of(context)!.labelProfession+" ${p['Meslek']}"),
                  Text(AppLocalizations.of(context)!.labelHobby+" ${p['Hobi']}"),
                  if ((p['TelNo'] ?? '').isNotEmpty &&
                      globals.menuListesi.contains("VeliTel") &&
                      globals.globalKullaniciTipi != 'T')
                    GestureDetector(
                      onTap: () => _makePhoneCall(p['TelNo']),
                      child: Text(
                        AppLocalizations.of(context)!.labelPhone+" ${p['TelNo']}",
                        style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  const Divider(),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(AppLocalizations.of(context)!.close),
          )
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String name,
    required String tckn,
    required Uint8List? photo,
    required bool isKullanici,
    String? alerji,
    String? ilac,
    String? sinifAdi,
    int? ogrOkulNo
  }) {
    bool isTeacher = globals.globalKullaniciTipi == 'T';
    int? yoklama;

    if (!isKullanici) {
      final index =
      yoklamaBilgileri.indexWhere((e) => e['TCKN'] == tckn);
      yoklama = index != -1 ? yoklamaBilgileri[index]['Has'] : 0;
    }

    return Card(
      child: ListTile(
        onTap: !isKullanici ? () => _getParents(tckn) : null,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
              photo != null ? MemoryImage(photo) : null,
              child:
              photo == null ? const Icon(Icons.person) : null,
            ),
            if (!(isTeacher && !isKullanici))
              Positioned(
                bottom: -2,
                right: -2,
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _updatePhoto(tckn, isKullanici),
                ),
              )
          ],
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           //Text("TCKN: $tckn"),
            if ((alerji ?? '').isNotEmpty)
              Text(AppLocalizations.of(context)!.labelAllergy+" $alerji",
                  style: const TextStyle(color: Colors.red)),
            if ((ilac ?? '').isNotEmpty)
              Text(AppLocalizations.of(context)!.labelMedicine+" $ilac",
                  style: const TextStyle(color: Colors.red)),
            if ((sinifAdi ?? '').isNotEmpty)
              Text(AppLocalizations.of(context)!.labelClass+" $sinifAdi",
                  style: const TextStyle(color: Colors.black)),
            if ((ogrOkulNo ?? 0) > 0)
              Text(AppLocalizations.of(context)!.labelSchoolNumber+" $ogrOkulNo",
                  style: const TextStyle(color: Colors.black)),
          ],
        ),
        trailing: (!isKullanici && yoklama != null)
            ? Checkbox(
          value: yoklama == 1,
          onChanged: isTeacher
              ? (v) async {
            final newValue = v == true ? 1 : 0;
            setState(() {
              yoklama = newValue;
            });

            try {
              if (newValue == 1) {
                await ApiService()
                    .yoklamaEkle(tckn, DateTime.now());
              } else {
                await ApiService()
                    .yoklamaSil(tckn, DateTime.now());
              }
            } catch (e) {
              print("⚠️ Yoklama hatası: $e");
            }
          }
              : null,
        )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:  Text(AppLocalizations.of(context)!.profileTitle, style: AppStyles.titleLarge),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white, // 👈 geri butonu + title beyaz olur

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(AppLocalizations.of(context)!.userInfoTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            _buildPhotoCard(
              name: globals.globalKullaniciAdi,
              tckn: globals.kullaniciTCKN,
              photo: kullaniciPhoto,
              isKullanici: true,
            ),
            const SizedBox(height: 20),
            if (globals.globalOgrenciListesi.isNotEmpty)
               Text(AppLocalizations.of(context)!.studentsTitle,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...globals.globalOgrenciListesi.map((o) => _buildPhotoCard(
              name: o['Name'],
              tckn: o['TCKN'],
              photo: studentPhotos[o['TCKN']],
              isKullanici: false,
              alerji: o['Alerji'],
              ilac: o['Ilac'],
                sinifAdi: o['ClassName'],
                ogrOkulNo:  o['SchoolNumber']
            )),
          ],
        ),
      ),
    );
  }
}