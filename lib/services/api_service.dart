import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../globals.dart' as globals;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  static String baseUrl = globals.serverAdrr;

  // Kullanıcı doğrulama
  Future<User> validatePerson(String tckn, String pin) async {
    final url = "${ApiService.baseUrl}/school/validate-person";
    final body = jsonEncode({'tckn': tckn, 'pin': pin});

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Giriş başarısız: ${response.body}');
    }
  }

  // Devam durumu listesi
  Future<List<dynamic>> getDevamDurumu(String tckn) async {
    final url = "${ApiService.baseUrl}/api/yoklama/has-month?tckn=$tckn";
    print("getDevamDurumu url: $url");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print("Devam durumu listesi alındı body: "+response.body);
        return jsonDecode(response.body);
      } else {
        print("API Hatası: ${response.statusCode}");
        debugPrint("API Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("API çağrı hatası: $e");
      debugPrint("API çağrı hatası: $e");
      return [];
    }
  }


  Future<bool> yoklamaBulkAdd(List<String> tcknList, DateTime date) async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/api/yoklama/bulk-add");

      // TCKN listesini virgül ile birleştiriyoruz
      final tcknString = tcknList.join(',');

      final request = http.MultipartRequest('POST', uri);
      request.fields['tcknList'] = tcknString;
      request.fields['date'] = date.toIso8601String();

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        print("✅ ${decoded['message']}");
        return true;
      } else {
        print("⚠️ Yoklama bulk-add başarısız: ${response.statusCode}, $responseBody");
        return false;
      }
    } catch (e) {
      print("❌ yoklamaBulkAdd hatası: $e");
      return false;
    }
  }

  // Yoklama ekleme
  Future<void> yoklamaEkle(String tckn, DateTime gun) async {
    final url = "${ApiService.baseUrl}/api/yoklama/add";
    final body = {'tckn': tckn, 'date': gun.toIso8601String()};

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Yoklama eklenemedi: ${response.body}');
    }
  }



  Future<bool> yoklamaSil(String tckn, DateTime date) async {
    try {
      final formattedDate =
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final url = Uri.parse(
          "${ApiService.baseUrl}/api/yoklama/delete?tckn=$tckn&date=$formattedDate");

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        print("✅ Yoklama kaydı silindi.");
        return true;
      } else {
        print("⚠️ Silme başarısız: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ yoklamaSil hatası: $e");
      return false;
    }
  }


  // Çoklu öğrenciye bildirim
  Future<void> sendNotificationToOgrenciler(
      String kullaniciTckn, List<String> ogrenciTcknList, String title, String message) async {
    final url = "${ApiService.baseUrl}/api/Duyuru/SendDuyuru";

    final body = {
      'GonderenTckn': kullaniciTckn,
      'AlanTcknList': ogrenciTcknList,
      'Baslik': title,
      'Data': message,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Bildirim gönderilemedi: ${response.body}');
    }
  }

/*
  // Sınıf bazlı bildirim
  Future<void> sendNotificationToSiniflar(
      String kullaniciTckn, List<String> sinifList, String title, String message) async {
    final url = "${ApiService.baseUrl}/api/Duyuru/SendDuyuruByClass";
   print("${ApiService.baseUrl}/api/Duyuru/SendDuyuruByClass");
    final body = {
      'GonderenTckn': kullaniciTckn,
      'AlanSinifList': sinifList,
      'Baslik': title,
      'Data': message,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print("sendNotificationToSiniflar url: $url");
    print("sendNotificationToSiniflar body: $body");
    print("sendNotificationToSiniflar response: $response.body");
    if (response.statusCode != 200) {
      throw Exception('Bildirim gönderilemedi: ${response.body}');
    }
  }*/
// Sınıf bazlı bildirim
  Future<void> sendNotificationToSiniflar(
      String kullaniciTckn, List<int> sinifList, String title, String message) async {
    final url = "${ApiService.baseUrl}/api/Duyuru/SendDuyuruByClass";
    print("URL: $url");

    final body = {
      'GonderenTckn': kullaniciTckn,
      'AlanSinifList': sinifList, // int list gönderiliyor
      'Baslik': title,
      'Data': message,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print("sendNotificationToSiniflar body: ${jsonEncode(body)}");
    print("sendNotificationToSiniflar response: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Bildirim gönderilemedi: ${response.body}');
    }
  }

  Future<String> bildirimGonder() async {
    final String baseUrl = "${ApiService.baseUrl}/api/school/send-notification?schoolId=" +
        globals.globalSchoolId +
        "&TCKN=" +
        globals.kullaniciTCKN;
    Uri uri = Uri.parse(baseUrl);
    print("_bildirimGonder çağırıldı");
    http.Response response = await http.get(uri);
    return Future.delayed(const Duration(seconds: 2), () => response.statusCode.toString());
  }

  Future<String> sendStudentNotification({
    required int schoolId,
    required String senderTckn,
    required List<String> studentTcknList,
    required int durum,
  }) async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/api/school/send-student-notification");

      // Öğrenci TCKN listesini virgül ile birleştir
      final tcknString = studentTcknList.join(',');

      final request = http.MultipartRequest('POST', uri);
      request.fields['schoolId'] = schoolId.toString();
      request.fields['senderTckn'] = senderTckn;
      request.fields['studentTcknList'] = tcknString;
      request.fields['durum'] = durum.toString();

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody);
        print("✅ Bildirim gönderildi: ${decoded['message']}");
        return Future.delayed(const Duration(seconds: 2), () => response.statusCode.toString());
      } else {
        print("⚠️ Bildirim gönderme başarısız: ${response.statusCode}, $responseBody");
        return Future.delayed(const Duration(seconds: 2), () => response.statusCode.toString());
      }
    } catch (e) {
      print("❌ sendStudentNotification hatası: $e");
      return "";
    }
  }

  Future<bool> deleteGalleryPhoto(String imageUrl) async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/api/school/delete-gallery-photo")
          .replace(queryParameters: {"imageUrl": imageUrl});
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Fotoğraf silme başarısız: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("deleteGalleryPhoto hatası: $e");
      return false;
    }
  }
  // Duyuru listesi alma
  Future<List<Map<String, dynamic>>> getDuyuruList(String kullaniciTCKN) async {
    final url = "${ApiService.baseUrl}/api/Duyuru/GetDuyurular?tckn=$kullaniciTCKN";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List;
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Duyuru listesi alınamadı: ${response.statusCode}");
    }
  }

  Future<String> kullaniciBilgileriniCek(String tckn, String pswd) async {
    final String baseUrl = globals.serverAdrr +"/api/school/validate-person?tckn=${tckn}&pin=${pswd}";
    // "https://schoolserver20250719161913-dedagwd7c2hvhag7.canadacentral-01.azurewebsites.net/api/school/validate-person?tckn=${_tcNoController.text}&pin=${_passwordController.text}";
    //   "http://212.154.74.47:5000/api/school/validate-person?tckn=${_tcNoController.text}&pin=${_passwordController.text}";
    // "http://api.exchangeratesapi.io/v1/latest?access_key=";
    print("baseUrl:$baseUrl");
    Uri uri = Uri.parse(baseUrl );
    http.Response response = await http.get(uri);
    print("response:$response");
    print("response.body:${response.body}");

    globals.globalStatusCode =    response.statusCode.toString()??"0";
    print("globalStatusCode"+globals.globalStatusCode);

    globals.globalErrMsg  = response.body.toString()??"";
    if(globals.globalStatusCode!="200"){
      return Future.delayed(Duration(seconds: 2), () => globals.globalErrMsg);
    }
    Map<String, dynamic> parsedResponse =  jsonDecode(response.body);

    //Map<String, dynamic> rates = parsedResponse["rates"];
    print('MAP YAZIYOR DİKKAT$parsedResponse');


    globals.globalKullaniciAdi = parsedResponse["Name"];
    globals.globalOkulAdi = parsedResponse["SchoolName"];
    globals.kullaniciTCKN = parsedResponse["TCKN"];
    globals.globalKullaniciTipi = parsedResponse["Type"];
    globals.fotoVersion     = parsedResponse["FotoVersion"];
    if (parsedResponse["UnreadDuyuruCount"]==0){
      globals.duyuruVar= false;
    } else{
      globals.duyuruVar= true;
    }

    globals.globalSchoolId = parsedResponse["SchoolId"].toString();
    globals.globalKonumEnlem = parsedResponse["KonumEnlem"].toString();
    globals.globalKonumBoylam= parsedResponse["KonumBoylam"].toString();
    globals.mesafeLimit = parsedResponse["MesafeLimit"];
    globals.meslek= parsedResponse["Meslek"];
    globals.hobi= parsedResponse["Hobi"];
    // Eğer yalnızca tek bir öğrenci adı dönerse eski field'ı yedekliyoruz
    globals.globalOgrenciAdi = parsedResponse["StudentName"] ?? "";

// Öğrenci listesi parse
    globals.globalOgrenciListesi = [];
    if (parsedResponse.containsKey("Students") && parsedResponse["Students"] != null) {
      final students = parsedResponse["Students"] as List;
      globals.globalOgrenciListesi = students.map((e) => {
        "Name": e["Name"] ?? "",
        "TCKN": e["TCKN"] ?? "",
        "FotoVersion": e["FotoVersion"] ?? "",
        "Alerji": e["Alerji"] ?? "",
        "Ilac": e["Ilac"] ?? "",
      }).toList();
    }
    if (globals.globalOgrenciListesi != null && globals.globalOgrenciListesi!.isNotEmpty) {
      print("öğrenci listesi DOLU");
    } else {
      print("öğrenci listesi BOŞ");
    }
    //Future.delayed(const Duration(seconds: 5), () => print('Large Latte'));

    globals.globalSinifListesi = [];
    if (parsedResponse.containsKey("Classes") && parsedResponse["Classes"] != null) {
      final classes = parsedResponse["Classes"] as List;
      globals.globalSinifListesi = classes.map((e) => {
        "Id": e["Id"] ?? "",
        "Ad": e["Ad"] ?? "",
      }).toList();
    }

    globals.menuListesi = [];

    try {
      if (parsedResponse.containsKey("MenuTanim") && parsedResponse["MenuTanim"] != null) {
        String rawMenu = parsedResponse["MenuTanim"].toString();
        globals.menuListesi = rawMenu.split(",").map((e) => e.trim()).toList();
      }
    } catch (e) {
      print("Hata oldu menu listesi $e");
    }

    print("menu listesi uzunluğu "+globals.menuListesi.length.toString());
    print("KULLANICI ADI "+globals.globalKullaniciAdi);
    return Future.delayed(Duration(seconds: 2), () => "Veri indirildi!");


    /*if (baseTlKuru != null) {
      for (String ulkeKuru in rates.keys) {
        double? baseKur = double.tryParse(rates[ulkeKuru].toString());
        if (baseKur != null) {
          double tlKuru = baseTlKuru / baseKur;
         // _oranlar[ulkeKuru] = tlKuru;
        }
      }
    }*/

  }
  // Duyuruyu okundu olarak işaretleme
  Future<bool> setDuyuruOkundu(int duyuruId) async {
    final url = "${ApiService.baseUrl}/api/Duyuru/MarkAsRead?duyuruId=$duyuruId";
    final response = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'duyuruId': duyuruId}));

    if (response.statusCode == 200) globals.duyuruVar = false;
    return response.statusCode == 200;
  }

  /// Günlük yoklama listesini getirir
  Future<List<dynamic>> getYoklamaList(List<String> tcknList, String date) async {
    try {
      // TCKN listesini virgülle birleştir
      final tcknQuery = tcknList.join(',');

      // API URL'sini oluştur
      final uri = Uri.parse(
        "${ApiService.baseUrl}/api/yoklama/bulk-has?tcknList=$tcknQuery&date=$date",
      );
      print("getYoklamaList çağırıldı");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // API'den dönen JSON örneği artık List<dynamic>
        List<dynamic> data = json.decode(response.body);
        print("data: $data");
        return data;
      } else {
        throw Exception("Yoklama listesi alınamadı! StatusCode: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Hata getYoklamaList: $e");
    }
  }

  /// Galeri listesini alır
  /// take: kaç fotoğraf alınacak, skip: kaç fotoğraf atlanacak
  Future<List<String>> getGallery(String tckn, {int take = 18, int skip = 0}) async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/api/school/get-gallery").replace(queryParameters: {
        "tckn": tckn,
        "take": take.toString(),
        "skip": skip.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = response.body.trim();

        if (body.isEmpty) return [];

        // JSON mi yoksa virgülle ayrılmış string mi kontrol et
        if (body.startsWith('[') && body.endsWith(']')) {
          // JSON array olarak dönmüş
          final List<dynamic> jsonList = json.decode(body);
          return jsonList.map((e) => e.toString()).toList();
        } else {
          // Virgülle ayrılmış string
          return body.split(',').map((e) => e.trim()).toList();
        }
      } else {
        print("⚠️ GetGallery başarısız: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ getGallery hatası: $e");
      return [];
    }
  }
  /* Future<List<String>> getGallery(String tckn, {int take = 18, int skip = 0}) async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/api/school/get-gallery")
          .replace(queryParameters: {
        "tckn": tckn,
        "take": take.toString(),
        "skip": skip.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Virgülle ayrılmış stringi listeye çevir
        final body = response.body;
        if (body.isEmpty) return [];
        return body.split(',');
      } else {
        print("⚠️ GetGallery başarısız: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ getGallery hatası: $e");
      return [];
    }
  }*/
  // Galeri fotoğraflarını getir
  Future<List<String>> getGalleryImages() async {
    final url = "${ApiService.baseUrl}/gallery";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<String>();
    } else {
      throw Exception("Fotoğraflar alınamadı! StatusCode: ${response.statusCode}");
    }
  }

  // Çoklu fotoğraf yükleme
  Future<void> uploadGalleryImages(List<dynamic> images) async {
    final uri = Uri.parse("${ApiService.baseUrl}/gallery/upload");
    final request = http.MultipartRequest('POST', uri);

    for (var image in images) {
      request.files.add(await http.MultipartFile.fromPath('photos', image.path));
    }

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Fotoğraf yüklenemedi! StatusCode: ${response.statusCode}");
    }
  }

  // Etkinlik oluşturma
  Future<void> createEtkinlik(Map<String, dynamic> etkinlikData) async {
    final uri = Uri.parse("${ApiService.baseUrl}/api/activity/add");
    final request = http.MultipartRequest('POST', uri);

    etkinlikData.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      final respStr = await response.stream.bytesToString();
      throw Exception("Etkinlik oluşturulamadı: $respStr");
    }
  }

  // Etkinlik listesi alma
  Future<List<Map<String, dynamic>>> getEtkinlikList(String kullaniciTCKN) async {
    final url = "${ApiService.baseUrl}/api/activity/list-by-tckn?tckn=$kullaniciTCKN";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception("Etkinlik listesi alınamadı: ${response.statusCode}");
    }
  }

  Future<String> onGatePressed(BuildContext context) async{
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

  Future<String>  onParkingPressed(BuildContext context) async{
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

  // Anket listesini çek
  Future<List<dynamic>> getSurveysByTckn(String tckn) async {
    final response = await http.get(
      Uri.parse("${ApiService.baseUrl}/api/survey/list-by-tckn?tckn=$tckn"),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Anketler alınamadı!");
    }
  }

  // Anket cevaplama
  Future<void> submitSurvey({
    required String tckn,
    required int surveyId,
    required String answer,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiService.baseUrl}/api/survey/submit"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "tckn": tckn,
        "surveyId": surveyId.toString(),
        "answer": answer,
      },
    );
    print("submitSurvey cagirildi");
    if (response.statusCode != 200) {
      throw Exception("Cevap gönderilemedi");
    }
  }

  // Öğretmen/Müdür için anket summary alır
  Future<Map<String, dynamic>> getSurveySummary({
    required int surveyId,
    required String tckn,
    required String classes, // comma-separated class IDs
  }) async {
    final uri = Uri.parse("${ApiService.baseUrl}/api/survey/summary?surveyId=$surveyId&tckn=$tckn&classes=$classes");
    print("${ApiService.baseUrl}/api/survey/summary?surveyId=$surveyId&tckn=$tckn&classes=$classes");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      throw Exception("Summary alınamadı");
    }
  }
/*  Future<bool> uploadGallery(String tckn, List<XFile> files) async {
    try {
      var uri = Uri.parse("${ApiService.baseUrl}/api/school/upload-gallery");
      var request = http.MultipartRequest('POST', uri);
      request.fields['tckn'] = tckn;

      for (var xfile in files) {
        final mimeType = lookupMimeType(xfile.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            xfile.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        print("✅ Galeriye ${files.length} fotoğraf yüklendi.");
        return true;
      } else {
        print("⚠️ Yükleme başarısız: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ uploadGallery hatası: $e");
      return false;
    }
  }*/

  Future<bool> uploadGallery(String tckn, List<File> files) async {
    try {
      var uri = Uri.parse("${ApiService.baseUrl}/api/school/upload-gallery");
      var request = http.MultipartRequest('POST', uri);
      request.fields['tckn'] = tckn;

      for (var file in files) {
        final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            file.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        print("✅ Galeriye ${files.length} fotoğraf yüklendi.");
        return true;
      } else {
        print("⚠️ Yükleme başarısız: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ uploadGallery hatası: $e");
      return false;
    }
  }
}
/*import 'dart:convert';
import 'dart:ffi';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../globals.dart' as globals;
import 'package:flutter/material.dart';


class ApiService {
  static String baseUrl = globals.serverAdrr;//'http://212.154.74.47:5000/api';

  Future<User> validatePerson(String tckn, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/school/validate-person'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tckn': tckn,
          'pin': pin,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Giriş başarısız: ${response.body}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  Future<void> sendNotification(String title, String message) async {
    // TODO: Implement actual API call to send notification
    await Future.delayed(const Duration(seconds: 2)); // Simulating API call
  }

  Future<void> sendNotification2(String title, String message, {required String tckn}) async {
    final url = Uri.parse('$baseUrl/notification/send'); // Gerçek endpoint burada olmalı

    final body = {
      'title': title,
      'message': message,
      'tckn': tckn, // Hedef öğrenci TCKN'si
    };

    final headers = {
      'Content-Type': 'application/json',
      // Eğer token gerekiyorsa:
      // 'Authorization': 'Bearer your_token',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Bildirim gönderilemedi (TCKN: $tckn): ${response.body}');
    }
  }

  Future<void> sendNotificationToOgrenci(String ogrenciId, String baslik, String mesaj) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notification/send'),
      body: jsonEncode({
        'ogrenciId': ogrenciId,
        'title': baslik,
        'message': mesaj,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Bildirim gönderilemedi');
    }
  }

  Future<void> sendNotificationToOgrenciler(
      String kullaniciTckn,
      List<String> ogrenciTcknList,
      String title,
      String message,
      ) async {
    final url = Uri.parse(globals.serverAdrr+'/api/Duyuru/SendDuyuru');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'GonderenTckn': kullaniciTckn,
        'AlanTcknList': ogrenciTcknList,
        'Baslik': title,
        'Data': message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Bildirim gönderilemedi: ${response.body}');
    }
  }

  Future<void> sendNotificationToSiniflar(
      String kullaniciTckn,
      List<String> sinifList,
      String title,
      String message,
      ) async {
    final url = Uri.parse(globals.serverAdrr+'/api/Duyuru/SendDuyuruByClass');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'GonderenTckn': kullaniciTckn,
        'AlanSinifList': sinifList,
        'Baslik': title,
        'Data': message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Bildirim gönderilemedi: ${response.body}');
    }
  }

  // Devam durumu listesi çekme
  Future<List<dynamic>> getDevamDurumu(String tckn) async {
    try {
      final response = await http.get(
        Uri.parse("${globals.serverAdrr}/has-month?tckn=$tckn"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("API Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("API çağrı hatası: $e");
      return [];
    }
  }
}

  // Duyuru listesi alma
  Future<List<Map<String, dynamic>>> getDuyuruList(String kullaniciTCKN) async {
    try {
      final response = await http.get(Uri.parse(globals.serverAdrr+"/api/Duyuru/GetDuyurular?tckn="+kullaniciTCKN));
      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Duyuru listesi alınamadı: ${response.statusCode}");
      }
    } catch (e) {
      print("Hata: $e");
      return [];
    }
  }

  // Duyuruyu okundu olarak işaretleme
  Future<bool> setDuyuruOkundu(int duyuruId) async {
    try {
      final response = await http.post(
        Uri.parse(globals.serverAdrr+"/api/Duyuru/MarkAsRead?duyuruId="+duyuruId.toString()),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"duyuruId": duyuruId}),
      );

      if (response.statusCode == 200){
        globals.duyuruVar = false;
      }
      return response.statusCode == 200;
    } catch (e) {
      print("Hata: $e");
      return false;
    }
  }
  /// Galeri fotoğraflarını getirir
  Future<List<String>> getGalleryImages() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/gallery"));

      if (response.statusCode == 200) {
        // API'den dönen JSON örneği: ["https://.../image1.jpg", "https://.../image2.jpg"]
        List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        throw Exception("Fotoğraflar alınamadı! StatusCode: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Hata getGalleryImages: $e");
    }
  }

  /// Çoklu fotoğraf yükleme örneği
  Future<void> uploadGalleryImages(List<dynamic> images) async {
    var uri = Uri.parse("$baseUrl/gallery/upload");
    var request = http.MultipartRequest('POST', uri);

    for (var image in images) {
      // image.path XFile'dan geliyor
      request.files.add(await http.MultipartFile.fromPath('photos', image.path));
    }

    var response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Fotoğraf yüklenemedi! StatusCode: ${response.statusCode}");
    }
  }

  Future<void> createEtkinlik(Map<String, dynamic> etkinlikData) async {
    final uri = Uri.parse('$baseUrl/api/activity/add');

    final request = http.MultipartRequest('POST', uri);

    // Form verilerini ekle
    etkinlikData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    try {
      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        print("Etkinlik başarıyla eklendi: $respStr");
      } else {
        final respStr = await response.stream.bytesToString();
        print("Etkinlik oluşturulamadı: $respStr");
        throw Exception('Etkinlik oluşturulamadı: $respStr');
      }
    } catch (e) {
      print("API Hatası: $e");
      throw Exception('API Hatası: $e');
    }
  }

  // Etkinlik listesi alma
  Future<List<Map<String, dynamic>>> getEtkinlikList(String kullaniciTCKN) async {
    try {
      final response = await http.get(
        Uri.parse("${globals.serverAdrr}/api/activity/list-by-tckn?tckn=$kullaniciTCKN"),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print("etkinlik listesi geldi");
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        } else {
          throw Exception("Beklenmeyen JSON formatı: ${decoded.runtimeType}");
        }
      } else {
        throw Exception("Etkinlik listesi alınamadı: ${response.statusCode}");
      }
    } catch (e) {
      print("Hata getEtkinlikList: $e");
      return [];
    }
  }


  Future<void> yoklamaEkle(String tckn, DateTime gun) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/yoklama/add'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'tckn': tckn,
          'date': gun.toIso8601String(), // string olarak gönder
        },
      );

      if (response.statusCode == 200) {
        print('Yoklama eklendi.');
      } else {
        throw Exception('Giriş başarısız: ${response.body}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  /// Günlük yoklama listesini getirir
  Future<List<dynamic>> getYoklamaList(List<String> tcknList, String date) async {
    try {
      // TCKN listesini virgülle birleştir
      final tcknQuery = tcknList.join(',');

      // API URL'sini oluştur
      final uri = Uri.parse(
        "$baseUrl/api/yoklama/bulk-has?tcknList=$tcknQuery&date=$date",
      );
      print("getYoklamaList çağırıldı");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // API'den dönen JSON örneği artık List<dynamic>
        List<dynamic> data = json.decode(response.body);
        print("data: $data");
        return data;
      } else {
        throw Exception("Yoklama listesi alınamadı! StatusCode: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Hata getYoklamaList: $e");
    }
  }


  Future<String> kullaniciBilgileriniCek(String tckn, String pswd) async {
    final String baseUrl = globals.serverAdrr +"/api/school/validate-person?tckn=${tckn}&pin=${pswd}";
    // "https://schoolserver20250719161913-dedagwd7c2hvhag7.canadacentral-01.azurewebsites.net/api/school/validate-person?tckn=${_tcNoController.text}&pin=${_passwordController.text}";
    //   "http://212.154.74.47:5000/api/school/validate-person?tckn=${_tcNoController.text}&pin=${_passwordController.text}";
    // "http://api.exchangeratesapi.io/v1/latest?access_key=";
    print("baseUrl:$baseUrl");
    Uri uri = Uri.parse(baseUrl );
    http.Response response = await http.get(uri);
    print("response:$response");
    print("response.body:${response.body}");

    globals.globalStatusCode =    response.statusCode.toString()??"0";
    print("globalStatusCode"+globals.globalStatusCode);

    globals.globalErrMsg  = response.body.toString()??"";
    if(globals.globalStatusCode!="200"){
      return Future.delayed(Duration(seconds: 2), () => globals.globalErrMsg);
    }
    Map<String, dynamic> parsedResponse =  jsonDecode(response.body);

    //Map<String, dynamic> rates = parsedResponse["rates"];
    print('MAP YAZIYOR DİKKAT$parsedResponse');


    globals.globalKullaniciAdi = parsedResponse["Name"];
    globals.globalOkulAdi = parsedResponse["SchoolName"];
    globals.kullaniciTCKN = parsedResponse["TCKN"];
    globals.globalKullaniciTipi = parsedResponse["Type"];
    globals.fotoVersion     = parsedResponse["FotoVersion"];
    if (parsedResponse["UnreadDuyuruCount"]==0){
      globals.duyuruVar= false;
    } else{
      globals.duyuruVar= true;
    }

    globals.globalSchoolId = parsedResponse["SchoolId"].toString();
    globals.globalKonumEnlem = parsedResponse["KonumEnlem"].toString();
    globals.globalKonumBoylam= parsedResponse["KonumBoylam"].toString();
    globals.mesafeLimit = parsedResponse["MesafeLimit"];
    globals.meslek= parsedResponse["Meslek"];
    globals.hobi= parsedResponse["Hobi"];
    // Eğer yalnızca tek bir öğrenci adı dönerse eski field'ı yedekliyoruz
    globals.globalOgrenciAdi = parsedResponse["StudentName"] ?? "";

// Öğrenci listesi parse
    globals.globalOgrenciListesi = [];
    if (parsedResponse.containsKey("Students") && parsedResponse["Students"] != null) {
      final students = parsedResponse["Students"] as List;
      globals.globalOgrenciListesi = students.map((e) => {
        "Name": e["Name"] ?? "",
        "TCKN": e["TCKN"] ?? "",
        "FotoVersion": e["FotoVersion"] ?? "",
        "Alerji": e["Alerji"] ?? "",
        "Ilac": e["Ilac"] ?? "",
      }).toList();
    }
    if (globals.globalOgrenciListesi != null && globals.globalOgrenciListesi!.isNotEmpty) {
      print("öğrenci listesi DOLU");
    } else {
      print("öğrenci listesi BOŞ");
    }
    //Future.delayed(const Duration(seconds: 5), () => print('Large Latte'));

    globals.globalSinifListesi = [];
    if (parsedResponse.containsKey("Classes") && parsedResponse["Classes"] != null) {
      final classes = parsedResponse["Classes"] as List;
      globals.globalSinifListesi = classes.map((e) => {
        "Id": e["Id"] ?? "",
        "Ad": e["Ad"] ?? "",
      }).toList();
    }

    print("KULLANICI ADI "+globals.globalKullaniciAdi);
    return Future.delayed(Duration(seconds: 2), () => "Veri indirildi!");


    /*if (baseTlKuru != null) {
      for (String ulkeKuru in rates.keys) {
        double? baseKur = double.tryParse(rates[ulkeKuru].toString());
        if (baseKur != null) {
          double tlKuru = baseTlKuru / baseKur;
         // _oranlar[ulkeKuru] = tlKuru;
        }
      }
    }*/

  }

  Future<void> registerToken(String tckn, String? token) async{
    String tokenRequest ;

    FirebaseMessaging.instance.getToken().then((token){
      print("token:"+token.toString());
      tokenRequest = globals.serverAdrr+"/api/school/register-fcm-token?tckn="+tckn+"&fcmToken="+token.toString();
      print("tokenRequest "+tokenRequest);
      http.post(Uri.parse(tokenRequest) as Uri);
    });
  }

  Future<String> onGatePressed(BuildContext context) async{
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

  Future<String>  onParkingPressed(BuildContext context) async{
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

}*/