import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/user.dart';
import '../globals.dart' as globals;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String baseUrl = globals.serverAdrr;
  final logger = Logger();

  /// ------------------------------------------------------------
  /// TOKEN YÖNETİMİ
  /// ------------------------------------------------------------
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// ------------------------------------------------------------
  /// ORTAK İSTEK GÖNDERİCİ
  /// ------------------------------------------------------------
  Future<Map<String, dynamic>> _sendRequest(
      String method,
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
      }) async {
    final token = await _getToken();
    final fullHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    final url = Uri.parse('$baseUrl$endpoint');
    http.Response response;

    logger.i('API çağrısı: $method $endpoint');

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response =
          await http.get(url, headers: fullHeaders).timeout(const Duration(seconds: 15));
          break;
        case 'POST':
          response = await http
              .post(url, headers: fullHeaders, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http
              .put(url, headers: fullHeaders, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw Exception('Desteklenmeyen HTTP metodu: $method');
      }

      // Token süresi dolmuşsa, yeniden login veya refresh token tetiklenebilir.
      if (response.statusCode == 401) {
        logger.e('401 - Token geçersiz veya süresi dolmuş.');
        return {'success': false, 'message': 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.'};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonBody =
        response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
        logger.i('Başarılı: ${response.statusCode} ${response.request?.url}');
        return {'success': true, 'data': jsonBody};
      } else {
        logger.e('Hata: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Sunucu hatası: ${response.statusCode}',
          'details': response.body
        };
      }
    } on SocketException {
      logger.e('İnternet bağlantısı yok.');
      return {'success': false, 'message': 'İnternet bağlantısı yok.'};
    } on TimeoutException {
      logger.e('İstek zaman aşımına uğradı.');
      return {'success': false, 'message': 'Sunucu yanıt vermiyor (timeout).'};
    } on FormatException {
      logger.e('JSON parse hatası.');
      return {'success': false, 'message': 'Veri formatı hatalı.'};
    } catch (e) {
      logger.e('Beklenmeyen hata: $e');
      return {'success': false, 'message': 'Beklenmeyen hata: $e'};
    }
  }


  /// ------------------------------------------------------------
  /// ORTAK GET METODU
  /// ------------------------------------------------------------
  Future<Map<String, dynamic>> getRequest(
      String endpoint, {
        Map<String, String>? headers,
      }) async {
    return await _sendRequest('GET', endpoint, headers: headers);
  }

  /// ------------------------------------------------------------
  /// ORTAK POST METODU
  /// ------------------------------------------------------------
  Future<Map<String, dynamic>> postRequest(
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
      }) async {
    return await _sendRequest('POST', endpoint, headers: headers, body: body);
  }

  /// ------------------------------------------------------------
  /// ORTAK PUT METODU
  /// ------------------------------------------------------------
  Future<Map<String, dynamic>> putRequest(
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
      }) async {
    return await _sendRequest('PUT', endpoint, headers: headers, body: body);
  }
/*
* Kullanım örnekleri
1️⃣ GET isteği
final result = await apiService.getRequest('/api/school/get-gallery?tckn=$tckn');

if (result['success']) {
  print(result['data']);
} else {
  print('Hata: ${result['message']}');
}

2️⃣ POST isteği
final result = await apiService.postRequest(
  '/api/Duyuru/SendDuyuru',
  body: {
    'GonderenTckn': globals.kullaniciTCKN,
    'AlanTcknList': ['11111111111', '22222222222'],
    'Baslik': 'Yeni Duyuru',
    'Data': 'Öğrenciler için önemli duyuru!',
  },
);

if (result['success']) {
  print('Bildirim gönderildi.');
} else {
  print('Hata: ${result['message']}');
}

3️⃣ PUT isteği
await apiService.putRequest(
  '/api/user/update',
  body: {'name': 'Yeni Ad', 'email': 'yeni@mail.com'},
);*/
  // Kullanıcı doğrulama
  Future<User> validatePerson(String tckn, String pin) async {
    final url = "${ApiService.baseUrl}/school/validate-person";
    final body = jsonEncode({'tckn': tckn, 'pin': pin});

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    logger.i("validatePerson response"+response.body);
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Giriş başarısız: ${response.body}');
    }
  }

  // Devam durumu listesi
  Future<List<dynamic>> getDevamDurumu(String tckn) async {
    final url = "${ApiService.baseUrl}/api/yoklama/has-month?tckn=$tckn";
    logger.i("getDevamDurumu url: $url");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        logger.i("Devam durumu listesi alındı body: "+response.body);
        return jsonDecode(response.body);
      } else {
        logger.e("API Hatası: ${response.statusCode}");
      //  debugprint("API Hatası: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      logger.e("API çağrı hatası: $e");
     // debugprint("API çağrı hatası: $e");
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
        logger.i("✅ ${decoded['message']}");
        return true;
      } else {
        logger.e("⚠️ Yoklama bulk-add başarısız: ${response.statusCode}, $responseBody");
        return false;
      }
    } catch (e) {
      logger.e("❌ yoklamaBulkAdd hatası: $e");
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
        logger.i("✅ Yoklama kaydı silindi.");
        return true;
      } else {
        logger.e("⚠️ Silme başarısız: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      logger.e("❌ yoklamaSil hatası: $e");
      return false;
    }
  }

  // Kvkk ekleme
  Future<String> kvkkEkle(String tckn) async {
    final url = "${ApiService.baseUrl}/api/kvkk/approve?tckn=$tckn";

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return "ok";
    } else {
      throw Exception('KVKK eklenemedi: ${response.body}');
    }
  }


  // Çoklu öğrenciye/öğretmene bildirim
  Future<void> sendNotificationToKisiler(
      String kullaniciTckn, List<String> tcknList, String title, String message) async {
    final url = "${ApiService.baseUrl}/api/Duyuru/SendDuyuru";

    final body = {
      'GonderenTckn': kullaniciTckn,
      'AlanTcknList': tcknList,
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

// Sınıf bazlı bildirim
  Future<void> sendNotificationToSiniflar(
      String kullaniciTckn, List<int> sinifList, String title, String message) async {
    final url = "${ApiService.baseUrl}/api/Duyuru/SendDuyuruByClass";
    logger.i("URL: $url");

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

    logger.i("sendNotificationToSiniflar body: ${jsonEncode(body)}");
    logger.i("sendNotificationToSiniflar response: ${response.body}");

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
    logger.i("_bildirimGonder çağırıldı");
    //http.Response response = await http.get(uri);
    http.Response response;

    try {
      response = await http
          .get(uri, headers: {"Connection": "keep-alive"})
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      globals.globalStatusCode = "0";
      globals.globalErrMsg = "Bildirim için Sunucuya bağlanılamadı ($e)";
      return globals.globalErrMsg;
    }
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
        logger.i("✅ Bildirim gönderildi: ${decoded['message']}");
        return Future.delayed(const Duration(seconds: 2), () => response.statusCode.toString());
      } else {
        logger.e("⚠️ Bildirim gönderme başarısız: ${response.statusCode}, $responseBody");
        return Future.delayed(const Duration(seconds: 2), () => response.statusCode.toString());
      }
    } catch (e) {
      logger.e("❌ sendStudentNotification hatası: $e");
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
        logger.e("Fotoğraf silme başarısız: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      logger.e("deleteGalleryPhoto hatası: $e");
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
/*
  Future<String> kullaniciBilgileriniCek(String tckn, String pswd) async {
    final String baseUrl = globals.serverAdrr +"/api/school/validate-person?tckn=${tckn}&pin=${pswd}";
    // "https://schoolserver20250719161913-dedagwd7c2hvhag7.canadacentral-01.azurewebsites.net/api/school/validate-person?tckn=${_tcNoController.text}&pin=${_passwordController.text}";
    //   "http://212.154.74.47:5000/api/school/validate-person?tckn=${_tcNoController.text}&pin=${_passwordController.text}";
    // "http://api.exchangeratesapi.io/v1/latest?access_key=";
    logger.i("baseUrl:$baseUrl");
    Uri uri = Uri.parse(baseUrl );
    http.Response response = await http.get(uri);
    logger.i("response:$response");
    logger.i("response.body:${response.body}");

    globals.globalStatusCode =    response.statusCode.toString()??"0";
    logger.i("globalStatusCode"+globals.globalStatusCode);

    globals.globalErrMsg  = response.body.toString()??"";
    if(globals.globalStatusCode!="200"){
      return Future.delayed(Duration(seconds: 2), () => globals.globalErrMsg);
    }
    Map<String, dynamic> parsedResponse =  jsonDecode(response.body);

    //Map<String, dynamic> rates = parsedResponse["rates"];
    logger.i('MAP YAZIYOR DİKKAT$parsedResponse');


    globals.globalKullaniciAdi = parsedResponse["Name"];
    globals.globalOkulAdi = parsedResponse["SchoolName"];
    globals.kullaniciTCKN = parsedResponse["TCKN"];
    globals.globalKullaniciTipi = parsedResponse["Type"];
   logger.i("kullanıcı tipi:"+globals.globalKullaniciTipi );

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
      logger.i("öğrenci listesi DOLU");
    } else {
      logger.i("öğrenci listesi BOŞ");
    }
    //Future.delayed(const Duration(seconds: 5), () => logger.i('Large Latte'));

    globals.globalSinifListesi = [];
    if (parsedResponse.containsKey("Classes") && parsedResponse["Classes"] != null) {
      final classes = parsedResponse["Classes"] as List;
      globals.globalSinifListesi = classes.map((e) => {
        "Id": e["Id"] ?? "",
        "Ad": e["Ad"] ?? "",
      }).toList();
    }

    // Öğretmen listesi parse
    globals.globalOgretmenListesi = [];
    if (parsedResponse.containsKey("Teachers") && parsedResponse["Teachers"] != null) {
      final students = parsedResponse["Teachers"] as List;
      globals.globalOgretmenListesi = students.map((e) => {
        "TeacherName": e["TeacherName"] ?? "",
        "TeacherTCKN": e["TeacherTCKN"] ?? "",
        "StudentTCKN": e["StudentTCKN"] ?? "",
        "StudentName": e["StudentName"] ?? ""
      }).toList();
    }
    if (globals.globalOgretmenListesi != null && globals.globalOgretmenListesi!.isNotEmpty) {
      logger.i("öğretmen listesi DOLU");
    } else {
      logger.i("öğretmen listesi BOŞ");
    }

    globals.menuListesi = [];

    try {
      if (parsedResponse.containsKey("MenuTanim") && parsedResponse["MenuTanim"] != null) {
        String rawMenu = parsedResponse["MenuTanim"].toString();
        globals.menuListesi = rawMenu.split(",").map((e) => e.trim()).toList();
      }
    } catch (e) {
      logger.i("Hata oldu menu listesi $e");
    }

    logger.i("menu listesi uzunluğu "+globals.menuListesi.length.toString());
    logger.i("KULLANICI ADI "+globals.globalKullaniciAdi);
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
 */
  Future<String> kullaniciBilgileriniCek(String tckn, String pswd) async {
    final String baseUrl = "${globals.serverAdrr}/api/school/validate-person?tckn=$tckn&pin=$pswd";
    logger.i("baseUrl:$baseUrl");

    final uri = Uri.parse(baseUrl);
    http.Response response;
    try {
      response = await http
          .get(uri, headers: {"Connection": "keep-alive"})
          .timeout(const Duration(seconds: 12));
      logger.i("kullaniciBilgileriniCek çağırıldı resp:${response.body}");

    } catch (e) {
      globals.globalStatusCode = "0";
      globals.globalErrMsg = "Sunucuya bağlanılamadı ($e)";
      return globals.globalErrMsg;
    }

    globals.globalStatusCode = response.statusCode.toString();
    globals.globalErrMsg = response.body;

    if (response.statusCode != 200) {
      return globals.globalErrMsg;
    }

    final parsedResponse = jsonDecode(response.body);
    globals.globalKullaniciAdi = parsedResponse["Name"];
    globals.globalOkulAdi = parsedResponse["SchoolName"];
    globals.kullaniciTCKN = parsedResponse["TCKN"];
    globals.globalKullaniciTipi = parsedResponse["Type"];
    globals.fotoVersion = parsedResponse["FotoVersion"];

    globals.duyuruVar = ValueNotifier((parsedResponse["UnreadDuyuruCount"] ?? 0) > 0);
    globals.anketVar = ValueNotifier((parsedResponse["SurveyCount"] ?? 0) > 0);
    globals.etkinlikVar = ValueNotifier((parsedResponse["ActivityCount"] ?? 0) > 0);

    globals.globalSchoolId = parsedResponse["SchoolId"].toString();
    globals.globalKonumEnlem = parsedResponse["KonumEnlem"].toString();
    globals.globalKonumBoylam = parsedResponse["KonumBoylam"].toString();
    globals.mesafeLimit = parsedResponse["MesafeLimit"];
    globals.meslek = parsedResponse["Meslek"];
    globals.hobi = parsedResponse["Hobi"];
    globals.kvkk = parsedResponse["Kvkk"].toString()??"0";


    // Öğrenciler
    globals.globalOgrenciListesi = [];
    final students = parsedResponse["Students"] as List?;
    if (students != null) {
      for (var e in students) {
        globals.globalOgrenciListesi.add({
          "Name": e["Name"] ?? "",
          "TCKN": e["TCKN"] ?? "",
          "FotoVersion": e["FotoVersion"] ?? "",
          "Alerji": e["Alerji"] ?? "",
          "Ilac": e["Ilac"] ?? "",
        });
      }
    }

    // Öğretmen listesi parse
    globals.globalOgretmenListesi = [];
    if (parsedResponse.containsKey("Teachers") && parsedResponse["Teachers"] != null) {
      final students = parsedResponse["Teachers"] as List;
      globals.globalOgretmenListesi = students.map((e) => {
        "TeacherName": e["TeacherName"] ?? "",
        "TeacherTCKN": e["TeacherTCKN"] ?? "",
        "StudentTCKN": e["StudentTCKN"] ?? "",
        "StudentName": e["StudentName"] ?? ""
      }).toList();
    }
    if (globals.globalOgretmenListesi != null && globals.globalOgretmenListesi!.isNotEmpty) {
      logger.i("öğretmen listesi DOLU");
    } else {
      logger.i("öğretmen listesi BOŞ");
    }
    // Menü
    globals.menuListesi = [];
    if (parsedResponse["MenuTanim"] != null) {
      globals.menuListesi =
          parsedResponse["MenuTanim"].toString().split(",").map((e) => e.trim()).toList();
    }

    globals.globalSinifListesi = [];
    if (parsedResponse.containsKey("Classes") && parsedResponse["Classes"] != null) {
      final classes = parsedResponse["Classes"] as List;
      globals.globalSinifListesi = classes.map((e) => {
        "Id": e["Id"] ?? "",
        "Ad": e["Ad"] ?? "",
      }).toList();
    }

    return "Veri indirildi!";
  }

  // Duyuruyu okundu olarak işaretleme
  Future<bool> setDuyuruOkundu(int duyuruId) async {
    final url = "${ApiService.baseUrl}/api/Duyuru/MarkAsRead?duyuruId=$duyuruId";
    final response = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'duyuruId': duyuruId}));

    if (response.statusCode == 200) globals.duyuruVar = false as ValueNotifier<bool>;
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
      logger.i("getYoklamaList çağırıldı");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // API'den dönen JSON örneği artık List<dynamic>
        List<dynamic> data = json.decode(response.body);
        logger.i("data: $data");
        return data;
      } else {
        throw Exception("Yoklama listesi alınamadı! StatusCode: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Hata getYoklamaList: $e");
    }
  }

  Future<int> checkCurrentTime(int schoolId, String personType) async {
    final url = "${ApiService.baseUrl}/api/doortime/check-time?schoolId=$schoolId&personType=$personType";

    try {
      final response = await http.get(Uri.parse(url));
      final body = response.body.trim();

      logger.i("checkCurrentTime response body: $body");

      if (response.statusCode == 200) {
        // JSON mu kontrol et
        if (body.startsWith("{")) {
          final jsonBody = jsonDecode(body);
          final isInRange = jsonBody["isInRange"];
          if (isInRange is int) return isInRange;
          if (isInRange is bool) return isInRange ? 1 : 0;
        } else {
          // HTML gelmiş demektir
          logger.e("checkCurrentTime: JSON bekleniyordu ama HTML geldi");
          return 0;
        }
      } else {
        throw Exception(
            "Saat kontrolü başarısız. StatusCode: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      logger.e("checkCurrentTime hatası: $e");
      rethrow;
    }
    return 0;
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
          logger.i("galeri listesi "+body.split(',').map((e) => e.trim()).toList().toString());
          return body.split(',').map((e) => e.trim()).toList();
        }
      } else {
        logger.e("⚠️ GetGallery başarısız: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      logger.e("❌ getGallery hatası: $e");
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
        logger.i("⚠️ GetGallery başarısız: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      logger.i("❌ getGallery hatası: $e");
      return [];
    }
  }*/
  Future<List<Map<String, String>>> getGalleryWithThumbnails(
      String tckn, {int skip = 0, int take = 18}) async {
    final url = "${ApiService.baseUrl}/api/school/get-gallery?tckn=$tckn&skip=$skip&take=$take";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception("StatusCode: ${response.statusCode}, Body: ${response.body}");
      }

      final body = response.body.trim();
      if (body.isEmpty) return [];

      final urls = body.split(',').map((e) => e.trim()).toList();

      // Sadece _K ve _B eşlemesini yap
      final Map<String, String> thumbs = {};
      final Map<String, String> fulls = {};

      for (var url in urls) {
        if (url.contains("_K")) {
          final key = url.split("_K")[0];
          thumbs[key] = url;
        } else if (url.contains("_B")) {
          final key = url.split("_B")[0];
          fulls[key] = url;
        }
      }

      final List<Map<String, String>> images = [];
      for (var key in thumbs.keys) {
        images.add({
          "thumb": thumbs[key]!,
          "full": fulls[key] ?? thumbs[key]!, // _B yoksa _K kullan
        });
      }

      logger.i("getGalleryWithThumbnails images: $images");
      return images;
    } catch (e, st) {
      logger.e("getGalleryWithThumbnails error: $e");
      rethrow;
    }
  }


  // Tamamen yeni fonksiyon: thumbnail + full URL döndürüyor
 /* Future<List<Map<String, String>>> getGalleryWithThumbnails(
      String tckn, {int skip = 0, int take = 18}) async {
    final url = "${ApiService.baseUrl}/api/school/get-gallery?tckn=$tckn&skip=$skip&take=$take";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception(
            "StatusCode: ${response.statusCode}, Body: ${response.body}");
      }

      // JSON decode yok, virgülle ayrılmış string
      final body = response.body.trim();

      if (body.isEmpty) return [];

      final urls = body.split(',');

      final images = urls.map((fullUrl) {
        fullUrl = fullUrl.trim();
        String thumbUrl = fullUrl.contains("?") ? "$fullUrl&width=200" : "$fullUrl?width=200";
        return {
          "thumb": thumbUrl,
          "full": fullUrl,
        };
      }).toList();
      logger.i("getGalleryWithThumbnails images:"+images.toString());
      return images;
    } catch (e, st) {
      logger.e("getGalleryWithThumbnails error: $e");
      rethrow;
    }
  }*/

  // Galeri fotoğraflarını getir
  Future<List<String>> getGalleryImages() async {
    final url = "${ApiService.baseUrl}/gallery";
    logger.i("Galeri fotoğrafları isteniyor: $url");

    try {
      final response = await http.get(Uri.parse(url));

      logger.d("Galeri response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        final images = decoded.cast<String>();
        logger.i("Galeri fotoğrafları başarıyla alındı (${images.length} adet)");
        return images;
      } else {
        logger.e("Galeri isteği başarısız oldu! StatusCode: ${response.statusCode}");
        throw Exception("Fotoğraflar alınamadı! StatusCode: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      logger.e("Galeri fotoğrafları alınırken hata oluştu: $e");
      rethrow;
    }
  }
 /* Future<List<String>> getGalleryImages() async {
    final url = "${ApiService.baseUrl}/gallery";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<String>();
    } else {
      throw Exception("Fotoğraflar alınamadı! StatusCode: ${response.statusCode}");
    }
  }*/

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
      logger.e("Etkinlik oluşturma response:$respStr");
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
    logger.i("baseUrl:$baseUrl");
    Uri uri = Uri.parse(baseUrl );
    //http.Response response = await http.get(uri);
    http.Response response;

    try {
      response = await http
          .get(uri, headers: {"Connection": "keep-alive"})
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      globals.globalStatusCode = "0";
      globals.globalErrMsg = "Kapı açılısı için Sunucuya bağlanılamadı ($e)";
      return globals.globalErrMsg;
    }
    logger.i("gate status:"+response.statusCode.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ana Kapı Kontrol çağrıldı')),
    );
    return Future.delayed(Duration(seconds: 2), () => response.statusCode.toString()??"0");
  }

  Future<String>  onParkingPressed(BuildContext context) async{
    // TODO: API çağrısı buraya eklenecek
    final String baseUrl =
        globals.serverAdrr+"/api/school/open-park/"+globals.globalSchoolId;
    logger.i("baseUrl:$baseUrl");
    Uri uri = Uri.parse(baseUrl );
    //http.Response response = await http.get(uri);
    http.Response response;

    try {
      response = await http
          .get(uri, headers: {"Connection": "keep-alive"})
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      globals.globalStatusCode = "0";
      globals.globalErrMsg = "Park Kapısı için Sunucuya bağlanılamadı ($e)";
      return globals.globalErrMsg;
    }
    logger.i("otopark status:"+response.statusCode.toString());

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
    logger.i("submitSurvey cagirildi");
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
    logger.i("${ApiService.baseUrl}/api/survey/summary?surveyId=$surveyId&tckn=$tckn&classes=$classes");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      throw Exception("Summary alınamadı");
    }
  }


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
        logger.i("✅ Galeriye ${files.length} fotoğraf yüklendi.");
        return true;
      } else {
        logger.e("⚠️ Yükleme başarısız: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      logger.e("❌ uploadGallery hatası: $e");
      return false;
    }
  }
}
