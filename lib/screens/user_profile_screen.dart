import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // MultipartRequest için tutuluyor
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:smart_okul_mobile/globals.dart' as globals;
import 'package:smart_okul_mobile/services/api_service.dart';
import '../constants.dart';
import 'package:smart_okul_mobile/l10n/app_localizations.dart';
import '../utils/media_upload_limit.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final Map<String, Uint8List?> studentPhotos = {};
  Uint8List? kullaniciPhoto;
  List<dynamic> yoklamaBilgileri = [];
  List<Map<String, dynamic>> ogrenciler = [];
  bool ogrenciLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await _loadOgrenciler();
    await _fetchYoklamaList();
    await _fetchAllPhotos();
    if (mounted) setState(() {});
  }

  int? _ogrenciSinifId(Map ogr) {
    final classId = ogr['ClassId'] ?? ogr['classId'] ?? ogr['SinifId'];
    if (classId is int) return classId;
    if (classId is num) return classId.toInt();
    return int.tryParse(classId?.toString().split('.').first ?? '');
  }

  String _ogrenciSinifAdi(Map ogr) {
    return (ogr['ClassName'] ??
            ogr['className'] ??
            ogr['sinifAd'] ??
            ogr['SinifAd'] ??
            ogr['sinifAdi'] ??
            '')
        .toString()
        .trim();
  }

  /// classId öncelikli sınıf kırılımı.
  List<MapEntry<String, List<Map<String, dynamic>>>> get _ogrenciSinifKirilim {
    final byKey = <String, List<Map<String, dynamic>>>{};
    final titles = <String, String>{};

    for (final o in ogrenciler) {
      final id = _ogrenciSinifId(o);
      final ad = _ogrenciSinifAdi(o);
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

  /// Veliye ait çocuklar (okul geneli değil): login Students + Teachers.StudentTCKN
  List<Map<String, dynamic>> _veliCocuklari() {
    final byTckn = <String, Map<String, dynamic>>{};

    for (final e in globals.globalOgrenciListesi) {
      final m = Map<String, dynamic>.from(e);
      final tckn = m['TCKN']?.toString() ?? '';
      if (tckn.isEmpty) continue;
      byTckn[tckn] = m;
    }

    // Aynı okulda veli-çocuk bağından gelenler (Teachers[].StudentTCKN)
    for (final t in globals.globalOgretmenListesi) {
      final tckn = (t['StudentTCKN'] ?? '').toString().trim();
      if (tckn.isEmpty) continue;
      byTckn.putIfAbsent(
        tckn,
        () => {
          'Name': (t['StudentName'] ?? '').toString(),
          'TCKN': tckn,
          'FotoVersion': 0,
          'Alerji': '',
          'Ilac': '',
          'ClassId': null,
          'ClassName': '',
          'SchoolNumber': '',
        },
      );
    }

    return byTckn.values.toList();
  }

  Future<void> _loadOgrenciler() async {
    try {
      List<Map<String, dynamic>> data;
      if (globals.globalKullaniciTipi == 'T') {
        // Öğretmen: SinifPerson bağlı sınıflar
        final schoolId = int.tryParse(globals.globalSchoolId.toString());
        data = await ApiService.getTeacherStudents(
          tckn: globals.kullaniciTCKN,
          schoolId: schoolId,
        );
      } else if (globals.globalKullaniciTipi == 'P') {
        // Veli: sadece kendi çocukları (getStudents/getAll yok)
        data = _veliCocuklari();
      } else {
        data = await ApiService.loadHomeworkStudents();
      }
      data.sort((a, b) {
        final c = _ogrenciSinifAdi(a)
            .toLowerCase()
            .compareTo(_ogrenciSinifAdi(b).toLowerCase());
        if (c != 0) return c;
        return (a['Name'] ?? '')
            .toString()
            .compareTo((b['Name'] ?? '').toString());
      });
      if (!mounted) return;
      setState(() {
        ogrenciler = data;
        ogrenciLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        ogrenciler = globals.globalKullaniciTipi == 'T'
            ? <Map<String, dynamic>>[]
            : (globals.globalKullaniciTipi == 'P'
                ? _veliCocuklari()
                : List<Map<String, dynamic>>.from(
                    globals.globalOgrenciListesi));
        ogrenciLoading = false;
      });
    }
  }

  Future<void> _fetchYoklamaList() async {
    try {
      final tcknList = ogrenciler
          .map((e) => e['TCKN']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
      if (tcknList.isEmpty) return;

      final today = DateTime.now();
      final formattedDate =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final raw =
          await ApiService().getYoklamaList(tcknList, formattedDate);
      yoklamaBilgileri = raw.map((e) {
        if (e is! Map) return <String, dynamic>{};
        final m = Map<String, dynamic>.from(e);
        return {
          'TCKN': (m['TCKN'] ?? m['tckn'] ?? '').toString(),
          'Has': (m['Has'] == true ||
                  m['Has'] == 1 ||
                  m['has'] == true ||
                  m['has'] == 1)
              ? 1
              : 0,
        };
      }).toList();
    } catch (e) {
      print("⚠️ Yoklama listesi alınamadı: $e");
    }
  }

  int _yoklamaDurum(String tckn) {
    final i = yoklamaBilgileri.indexWhere(
      (e) => (e['TCKN']?.toString() ?? '') == tckn,
    );
    if (i < 0) return 0;
    return yoklamaBilgileri[i]['Has'] == 1 ? 1 : 0;
  }

  void _yoklamaDurumGuncelle(String tckn, int has) {
    final i = yoklamaBilgileri.indexWhere(
      (e) => (e['TCKN']?.toString() ?? '') == tckn,
    );
    if (i >= 0) {
      yoklamaBilgileri[i] = {'TCKN': tckn, 'Has': has};
    } else {
      yoklamaBilgileri.add({'TCKN': tckn, 'Has': has});
    }
  }

  Future<void> _yoklamaToggle(String tckn, bool? value) async {
    final newValue = value == true ? 1 : 0;
    final prev = _yoklamaDurum(tckn);
    setState(() => _yoklamaDurumGuncelle(tckn, newValue));

    try {
      if (newValue == 1) {
        await ApiService().yoklamaEkle(tckn, DateTime.now());
      } else {
        await ApiService().yoklamaSil(tckn, DateTime.now());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _yoklamaDurumGuncelle(tckn, prev));
      print("⚠️ Yoklama hatası: $e");
    }
  }

  Future<void> _fetchAllPhotos() async {
    kullaniciPhoto = await _getPhoto(
      globals.kullaniciTCKN,
      "${globals.kullaniciTCKN}_${globals.fotoVersion}",
    );

    for (var ogrenci in ogrenciler) {
      final tckn = ogrenci['TCKN']?.toString() ?? '';
      if (tckn.isEmpty) continue;

      final fotoVersion = ogrenci['FotoVersion']?.toString() ?? '0';

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

      final response = await ApiService.authClient.get(Uri.parse(
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

    final size = await picked.length();
    if (size > maxMediaUploadBytes) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Dosya Çok Büyük'),
          content: const Text(mediaUploadLimitMessage),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
      return;
    }

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

      final response = await ApiService.authClient.send(request);
      if (response.statusCode == 200) {
        setState(() {
          if (isKullanici) {
            kullaniciPhoto = bytes;
            globals.fotoVersion++;
          } else {
            studentPhotos[tckn] = bytes;
            for (var ogrenci in ogrenciler) {
              if (ogrenci['TCKN']?.toString() == tckn) {
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
      final response = await ApiService.authClient.get(url);
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
                  if ((p['TelNo']?.toString() ?? '').isNotEmpty &&
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
    final isTeacher = globals.globalKullaniciTipi == 'T';
    final yoklama = isKullanici ? null : _yoklamaDurum(tckn);

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
                    ? (v) => _yoklamaToggle(tckn, v)
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
            if (ogrenciLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              Text(AppLocalizations.of(context)!.studentsTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (ogrenciler.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    AppLocalizations.of(context)!.noStudentsFound,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                )
              else
                ..._ogrenciSinifKirilim.map((entry) {
                  final sinifAdi = entry.key;
                  final liste = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(top: 10),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      tilePadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(
                        '$sinifAdi  (${liste.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      children: liste
                          .map(
                            (o) => _buildPhotoCard(
                              name: o['Name']?.toString() ?? '',
                              tckn: o['TCKN']?.toString() ?? '',
                              photo: studentPhotos[o['TCKN']?.toString()],
                              isKullanici: false,
                              alerji: o['Alerji']?.toString(),
                              ilac: o['Ilac']?.toString(),
                              sinifAdi: _ogrenciSinifAdi(o),
                              ogrOkulNo: int.tryParse(
                                  '${o['SchoolNumber'] ?? ''}'),
                            ),
                          )
                          .toList(),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}