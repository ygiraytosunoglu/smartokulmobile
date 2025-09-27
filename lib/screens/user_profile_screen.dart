import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/services/api_service.dart';
import '../constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/api_service.dart';

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
          .map<String>((ogrenci) => ogrenci['TCKN'] as String)
          .toList();

      final today = DateTime.now();
      final formattedDate =
          "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      yoklamaBilgileri = await ApiService().getYoklamaList(tcknList, formattedDate);
      setState(() {});
    } catch (e) {
      print("⚠️ Yoklama listesi alınamadı: $e");
    }
  }

  Future<void> _fetchAllPhotos() async {
    kullaniciPhoto = await _getPhoto(
        globals.kullaniciTCKN, "${globals.kullaniciTCKN}_${globals.fotoVersion}");

    for (var ogrenci in globals.globalOgrenciListesi) {
      String tckn = ogrenci['TCKN'];
      String fotoVersion = ogrenci['FotoVersion'].toString();
      Uint8List? photo = await _getPhoto(tckn, "${tckn}_$fotoVersion");
      studentPhotos[tckn] = photo;
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
        final byteData = await rootBundle.load('assets/images/$fotoName.jpg');
        return byteData.buffer.asUint8List();
      } catch (_) {}

      final response = await http.get(Uri.parse(
        '${globals.serverAdrr}/api/school/get-person-photo?tckn=$tckn',
      ));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await localFile.writeAsBytes(bytes);
        return bytes;
      }
    } catch (e) {
      print('⚠️ Fotoğraf getirme hatası: $e');
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
          "POST", Uri.parse('${globals.serverAdrr}/api/school/upload-person-photo'));
      request.fields['tckn'] = tckn;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: "$tckn.jpg"),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        if (isKullanici) {
          kullaniciPhoto = bytes;
          globals.fotoVersion++;
        } else {
          studentPhotos[tckn] = bytes;
          for (var ogrenci in globals.globalOgrenciListesi) {
            if (ogrenci['TCKN'] == tckn) {
              ogrenci['FotoVersion'] = (ogrenci['FotoVersion'] ?? 0) + 1;
            }
          }
        }
        setState(() {});
      }
    } catch (e) {
      print("Fotoğraf güncelleme hatası: $e");
    }
  }

  Future<void> _getParents(String studentTckn) async {
    final url = Uri.parse(
      '${globals.serverAdrr}/api/student/getParents?tckn=$studentTckn&schoolId=${globals.globalSchoolId}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _showParentsListPopup(data);
      } else {
        print("Veli servisi hatası: ${response.statusCode}");
      }
    } catch (e) {
      print("Veli servisi istisnası: $e");
    }
  }

  void _showParentsListPopup(List<dynamic> parents) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("👪 Veli Bilgileri"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: parents.length,
              itemBuilder: (context, index) {
                final parent = parents[index];
                String name = parent['Name'] ?? 'Bilinmiyor';
                String meslek = parent['Meslek'] ?? 'Bilinmiyor';
                String hobi = parent['Hobi'] ?? 'Yok';
                String tel = parent['TelNo'] ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ad Soyad: $name"),
                      Text("Meslek: $meslek"),
                      Text("Hobi: $hobi"),
                      if (tel.isNotEmpty) Text("Telefon: $tel"),
                      const Divider(),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Kapat"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoCard({
    required String name,
    required String tckn,
    required Uint8List? photo,
    required bool isKullanici,
    String? alerji,
    String? ilac,
  }) {
    bool isTeacher = globals.globalKullaniciTipi == 'T';
    int? yoklama;

    if (!isKullanici) {
      final item = yoklamaBilgileri.firstWhere(
              (e) => e['TCKN'] == tckn,
          orElse: () => null);
      if (item != null) yoklama = item['Has'] as int?;
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        onTap: !isKullanici ? () => _getParents(tckn) : null,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: photo != null ? MemoryImage(photo) : null,
              child: photo == null ? const Icon(Icons.person, size: 30) : null,
            ),
            if (!(isTeacher && !isKullanici))
              Positioned(
                bottom: -2,
                right: -2,
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _updatePhoto(tckn, isKullanici),
                ),
              ),
          ],
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("TCKN: $tckn"),
            if (alerji != null && alerji.isNotEmpty)
              Text("Alerji: $alerji", style: const TextStyle(color: Colors.red)),
            if (ilac != null && ilac.isNotEmpty)
              Text("İlaç: $ilac", style: const TextStyle(color: Colors.red)),
          ],
        ),
        trailing: yoklama != null
            ? Checkbox(
          value: yoklama == 1,
          onChanged: globals.globalKullaniciTipi == 'T'
              ? (bool? value) async {
            setState(() {
              yoklama = value == true ? 1 : 0;

              // yoklamaBilgileri listesi güncelle
              final index =
              yoklamaBilgileri.indexWhere((e) => e['TCKN'] == tckn);
              if (index != -1) {
                yoklamaBilgileri[index]['Has'] = yoklama;
              }
            });

            try {
              if (value == true) {
                // yeni yoklama ekle
                await ApiService().yoklamaEkle(tckn, DateTime.now());
              } else {
                // yoklamayı kaldır
                await ApiService().yoklamaSil(tckn, DateTime.now());
              }
            } catch (e) {
              print("⚠️ Yoklama servisi hatası: $e");
            }
          }
              : null, // öğretmen değilse değiştirilemez
        )
            : null,

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      appBar: AppBar(
        title: const Text("Profil Sayfası"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("👤 Kullanıcı Bilgileri",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildPhotoCard(
              name: globals.globalKullaniciAdi,
              tckn: globals.kullaniciTCKN,
              photo: kullaniciPhoto,
              isKullanici: true,
            ),
            const SizedBox(height: 20),
            if (globals.globalOgrenciListesi.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "👧 Öğrenciler",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Yoklama",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ...globals.globalOgrenciListesi.map((ogrenci) {
              String name = ogrenci['Name'];
              String tckn = ogrenci['TCKN'];
              String alerji = ogrenci['Alerji'];
              String ilac = ogrenci['Ilac'];
              Uint8List? photo = studentPhotos[tckn];

              return _buildPhotoCard(
                name: name,
                tckn: tckn,
                photo: photo,
                isKullanici: false,
                alerji: alerji,
                ilac: ilac,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
