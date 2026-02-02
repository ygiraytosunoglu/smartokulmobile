import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/meal_model.dart';
import '../models/user.dart';
import '../globals.dart' as globals;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

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
          'message': '${response.body}',
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
      return {'success': false, 'message': 'Beklenmeyen hata oluştu. '};//$e
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
    final body = jsonEncode({'tckn': tckn, 'pin': pin//, 'personType':
    });

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

  Future<void> sendMesaj(
      String kullaniciTckn, List<String> tcknList, String title, String message) async {
    final url = "${ApiService.baseUrl}/api/Mesaj/SendMesaj";

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
      globals.globalErrMsg = "Bildirim için Sunucuya bağlanılamadı";
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


  Future<bool> deleteGallery({
    required String tckn,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse(
          '${ApiService.baseUrl}/api/school/delete-gallery'
      ).replace(queryParameters: {
        'tckn': tckn,
        'fileName': fileName,
      });

      print('DeleteGallery isteği gönderiliyor: $uri');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // Eğer token kullanıyorsan:
          // 'Authorization': 'Bearer ${globals.token}',
        },
      );

      print(
          'DeleteGallery response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Dosya silindi: ${data['fileName']}');
        return true;
      } else if (response.statusCode == 404) {
        print('Dosya bulunamadı');
        return false;
      } else {
        print(
            'DeleteGallery hata: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stack) {
      print('DeleteGallery exception: $e');
     print(stack.toString());
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

  // Mesaj listesi alma
  Future<List<Map<String, dynamic>>> getMesajList(String kullaniciTCKN) async {
    final url = "${ApiService.baseUrl}/api/Mesaj/GetMesajlar?tckn=$kullaniciTCKN";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List;
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Duyuru listesi alınamadı: ${response.statusCode}");
    }
  }

  Future<List<dynamic>> getAllDersler(int schoolId) async {
    try {
      final uri = Uri.parse(
        "${ApiService.baseUrl}/api/ders/GetAll?schoolId=$schoolId",
      );

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
            "Dersler alınamadı. StatusCode: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("getAllDersler hatası: $e");
    }
  }

  static Future<void> getAllTeachersAndSetGlobal(int schoolId) async {
    final uri = Uri.parse(
      "$baseUrl/api/Teacher/getAll?schoolId=$schoolId",
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer ${globals.token}", // varsa aç
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        globals.globalOgretmenListesi = data.map<Map<String, dynamic>>((e) => {
          "Id": e["Id"],
          "Name": e["Name"],
          "TelNo": e["TelNo"],
          "TCKN": e["TCKN"],
          "TCKNOrig": e["TCKNOrig"],
          "Cinsiyet": e["Cinsiyet"],
          "DogumTarihi": e["DogumTarihi"],
          "OgrenimDurumu": e["OgrenimDurumu"],
        }).toList();
      } else {
        throw Exception(
          "Öğretmenler alınamadı. StatusCode: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("getAllTeachersAndSetGlobal hata: $e");
    }
  }

  Future<int?> addOdev({
    required String gonderenTckn,
    required List<String> alanTcknList,
    required int dersId,
    required int schoolId,
    String? data,
    DateTime? expireDate,
    List<File>? files,
  }) async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/api/odev/add");

      final request = http.MultipartRequest("POST", uri);

      // 🔹 Zorunlu alanlar
      request.fields['gonderenTckn'] = gonderenTckn;
      request.fields['dersId'] = dersId.toString();
      request.fields['schoolId'] = schoolId.toString();

      // 🔹 Liste alanı (alanTcknList)
      for (int i = 0; i < alanTcknList.length; i++) {
        request.fields['alanTcknList[$i]'] = alanTcknList[i];
      }

      // 🔹 Opsiyonel alanlar
      if (data != null) {
        request.fields['data'] = data;
      }

      if (expireDate != null) {
        request.fields['expireDate'] = expireDate.toIso8601String();
      }
      print("gonderenTckn:"+gonderenTckn);
      print("dersId:"+dersId.toString());
      print("schoolId:"+schoolId.toString());
      print("expireDate:"+expireDate.toString());

      // 🔹 Dosyalar
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              file.path,
              filename: path.basename(file.path),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response =
      await http.Response.fromStream(streamedResponse);
      print( "resp:"+response.body);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['id']; // backend’den dönen id
      } else {
        throw Exception(
            "addOdev başarısız. StatusCode: ${response.statusCode} Body: ${response.body}");
      }
    } catch (e) {
      throw Exception("addOdev hatası: $e");
    }
  }

  Future<List<dynamic>> getOdevlerByDersId(int dersId) async {
    try {
      final uri = Uri.parse(
        "${ApiService.baseUrl}/api/odev/getByDers?dersId=$dersId",
      );

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          "getOdevlerByDersId başarısız. "
              "StatusCode: ${response.statusCode}, "
              "Body: ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("getOdevlerByDersId hatası: $e");
    }
  }

  Future<bool> removeOdev({required int odevId}) async {
    try {
      final uri = Uri.parse(
        "${ApiService.baseUrl}/api/odev/remove?odevId=$odevId",
      );

      final response = await http.delete(
        uri,
        headers: {
          "Content-Type": "application/json",
          // Eğer token kullanıyorsan buraya ekle
          // "Authorization": "Bearer ${globals.token}",
        },
      );

      if (response.statusCode == 200) {
        // İstersen response body'yi parse edebilirsin
        // final data = jsonDecode(response.body);
        return true;
      } else if (response.statusCode == 404) {
        return false;
      } else {
        throw Exception(
          "Ödev silinemedi. StatusCode: ${response.statusCode}",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateOdev({
    required int odevId,
    int? dersId,
    String? data,
    DateTime? expireDate,
    required int schoolId,
    List<File>? files,
  }) async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/api/odev/update");

      final request = http.MultipartRequest("POST", uri);

      // 🔹 Zorunlu alanlar
      request.fields['odevId'] = odevId.toString();
      request.fields['schoolId'] = schoolId.toString();

      // 🔹 Opsiyonel alanlar
      if (dersId != null) {
        request.fields['dersId'] = dersId.toString();
      }

      if (data != null) {
        request.fields['data'] = data;
      }

      if (expireDate != null) {
        request.fields['expireDate'] =
            expireDate.toIso8601String(); // DateTime uyumlu
      }

      // 🔹 Dosyalar
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              file.path,
              filename: file.path.split('/').last,
            ),
          );
        }
      }

      // 🔹 Header (token varsa aç)
      request.headers.addAll({
        "Content-Type": "multipart/form-data",
        // "Authorization": "Bearer ${globals.token}",
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        return false;
      } else {
        throw Exception(
          "Ödev güncellenemedi. StatusCode: ${response.statusCode}, Body: $responseBody",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getOdevlerByTckn({
    required String tckn,
    int skip = 0,
    int take = 10,
  }) async {
    print("tckn:"+tckn);
    print("skip:"+skip.toString()+" take:"+take.toString());
    try {
      final uri = Uri.parse(
        "${ApiService.baseUrl}/api/odev/getByTckn"
            "?tckn=$tckn"
            "&skip=$skip"
            "&take=$take",
      );

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          "getOdevlerByTckn başarısız. "
              "StatusCode: ${response.statusCode}, "
              "Body: ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("getOdevlerByTckn hatası: $e");
    }
  }

  Future<bool> updatePin(String tckn, String telNo, String yeniPin) async {
    final url = Uri.parse(
      '${ApiService.baseUrl}/api/school/update-pin?tckn=$tckn&telNo=$telNo&yeniPin=$yeniPin',
    );

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.post(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('PIN güncellenemedi: ${response.body}');
    }
  }

  // Okul logosu getirme servisi
  Future<Uint8List> getLogo(String tckn) async {
    final url = Uri.parse('${ApiService.baseUrl}/api/school/get-logo?tckn=$tckn');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return response.bodyBytes;  // ← LOGO BYTE ARRAY
    } else if (response.statusCode == 404) {
      throw Exception('Logo bulunamadı');
    } else {
      throw Exception('Logo getirilemedi: ${response.statusCode}');
    }
  }

  Future<bool> addStudentBoyKilo({
    required String tckn,
    required String boy,
    required String kilo,
    required DateTime date,
  }) async {
    try {
      debugPrint("addStudentBoyKilo çağrıldı. tckn=$tckn, boy=$boy, kilo=$kilo, date=$date");

      var uri = Uri.parse("${ApiService.baseUrl}/api/StudentBoyKilo/add");

      var request = http.MultipartRequest("POST", uri);

      request.fields["tckn"] = tckn;
      request.fields["boy"] = boy;
      request.fields["kilo"] = kilo;

      // API'nin kabul ettiği format: 2025-12-08T10:30:00
      request.fields["date"] = date.toIso8601String();

      debugPrint("Gönderilen FormData: ${request.fields}");

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint("API Status Code: ${response.statusCode}");
      debugPrint("API Response: $responseBody");

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("Hata: $e");
      return false;
    }
  }

  /// Boy - kilo listeleme servisi
  Future<List<dynamic>> getStudentBoyKilo(String tckn) async {
    try {
      debugPrint("getStudentBoyKilo çağrıldı. TCKN=$tckn");

      final url = Uri.parse("${ApiService.baseUrl}/api/StudentBoyKilo/get?tckn=$tckn");

      final response = await http.get(url);

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        debugPrint("Hata: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("getStudentBoyKilo hata: $e");
      return [];
    }
  }

  Future<bool> uploadPlan({
    required String tckn,
    required int year,
    required int month,
    required int day,
    required File file,
  }) async {
    try {
      debugPrint("uploadPlan çağrıldı. "
          "TCKN=$tckn, Year=$year, Month=$month, Day=$day, File=${file.path}");

      var uri = Uri.parse("${ApiService.baseUrl}/api/Document/uploadPlan");

      var request = http.MultipartRequest("POST", uri);

      // Alanlar
      request.fields["tckn"] = tckn;
      request.fields["year"] = year.toString();
      request.fields["month"] = month.toString();
      request.fields["day"] = day.toString();

      // Dosya mime tipi
      String fileName = path.basename(file.path);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );

      debugPrint("Gönderilen alanlar: ${request.fields}");
      debugPrint("Yüklenen dosya: $fileName");

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint("Status: ${response.statusCode}");
      debugPrint("Response: $responseBody");

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("uploadPlan hata: $e");
      return false;
    }
  }

  Future<List<String>> getPlan({
    required String tckn,
    required int year,
    required int month,
    int day = 0,
  }) async {
    try {
      debugPrint(
          "getPlan çağrıldı -> TCKN=$tckn, Year=$year, Month=$month, Day=$day");

      final url = Uri.parse(
          "${ApiService.baseUrl}/api/Document/getPlan?tckn=$tckn&year=$year&month=$month&day=$day");

      debugPrint("GET URL: $url");

      final response = await http.get(url);

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // urls listesi backend'den geliyor
        List<String> urls =
        (data["urls"] as List).map((e) => e.toString()).toList();

        return urls;
      } else {
        debugPrint("Hata: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("getPlan hata -> $e");
      return [];
    }
  }

  Future<bool> uploadBulten({
    required String tckn,
    required DateTime startDate,
    required DateTime endDate,
    required File file,
  }) async {
    try {
      debugPrint("uploadBulten çağrıldı. "
          "TCKN=$tckn, StartDate=$startDate, EndDate=$endDate, File=${file.path}");

      var uri = Uri.parse("${ApiService.baseUrl}/api/Document/uploadBulten");

      var request = http.MultipartRequest("POST", uri);

      // Form field'lar
      request.fields["tckn"] = tckn;
      request.fields["startDate"] = startDate.toIso8601String();
      request.fields["endDate"] = endDate.toIso8601String();

      // Dosya adı
      String fileName = path.basename(file.path);

      request.files.add(await http.MultipartFile.fromPath(
        "file",
        file.path,
        filename: fileName,
      ));

      debugPrint("Gönderilen FormData: ${request.fields}");
      debugPrint("Yüklenen dosya: $fileName");

      var response = await request.send();
      var body = await response.stream.bytesToString();

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: $body");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("uploadBulten hata: $e");
      return false;
    }
  }

  Future<List<String>> getBulten({
    required String tckn,
    required DateTime date,
  }) async {
    try {
      debugPrint("getBulten çağrıldı -> TCKN=$tckn, Date=$date");

      final url = Uri.parse(
        "${ApiService.baseUrl}/api/Document/getBulten?tckn=$tckn&date=${date.toIso8601String()}",
      );

      debugPrint("GET URL: $url");

      final response = await http.get(url);

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> urls =
        (data["urls"] as List).map((e) => e.toString()).toList();

        return urls;
      } else {
        debugPrint("Hata: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("getBulten hata -> $e");
      return [];
    }
  }

  Future<bool> uploadDocument({
    required String tckn,
    required String docType,
    required File file,
  }) async {
    try {
      debugPrint(
          "uploadDocument çağrıldı. TCKN=$tckn, DocType=$docType, File=${file.path}");

      var uri = Uri.parse("${ApiService.baseUrl}/api/Document/uploadDocument");

      var request = http.MultipartRequest("POST", uri);

      // Form field'lar
      request.fields["tckn"] = tckn;
      request.fields["docType"] = docType;

      String fileName = path.basename(file.path);

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
          filename: fileName,
        ),
      );

      debugPrint("Gönderilen FormData: ${request.fields}");
      debugPrint("Yüklenen dosya: $fileName");

      // Gönderim
      var response = await request.send();
      var body = await response.stream.bytesToString();

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: $body");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("uploadDocument hata: $e");
      return false;
    }
  }

  static Future<List<String>> getDocumentUrls({
    required String tckn,
    required String docType,
  }) async {
    final url = Uri.parse(
        '${ApiService.baseUrl}/api/Document/getDocument?tckn=$tckn&docType=$docType');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> list = data['urls'];
      return list.map((e) => e.toString()).toList();
    } else {
      throw Exception("GetDocument failed: ${response.body}");
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
  //mesafe cinsinden olcer
  double mesafeHesapla(double enlem1, double boylam1, double enlem2, double boylam2) {
    double mesafe = Geolocator.distanceBetween(enlem1, boylam1, enlem2, boylam2);
    return mesafe;
  }

  Future<String> kullaniciBilgileriniCek(
      String tckn, String pswd, String sRole) async {

    final response = await http.get(Uri.parse(
        "${globals.serverAdrr}/api/school/validate-person"
            "?tckn=$tckn&pin=$pswd&personType=$sRole"));

    if (response.statusCode != 200) {
      return response.body;
    }

    final decoded = jsonDecode(response.body);
    final List persons = decoded["Persons"] ?? [];

    if (persons.isEmpty) {
      return "Kullanıcı bulunamadı";
    }

    /// ✅ 1 OKUL → DEVAM
    if (persons.length == 1) {
      parsePerson(persons[0]);
      return "OK";
    }

    /// ⚠️ 1'DEN FAZLA OKUL → SEÇİM GEREKİYOR
    globals.secilebilirOkullar = persons;
    return "SELECT_SCHOOL";
  }

  void parsePerson(Map<String, dynamic> p) {
    globals.globalKullaniciAdi = p["Name"] ?? "";
    globals.globalOkulAdi = p["SchoolName"] ?? "";
    globals.orjKullaniciTCKN = p["TCKN"] ?? "";
    globals.globalKullaniciTipi = p["Type"] ?? "";
    globals.fotoVersion = p["FotoVersion"] ?? 0;
    globals.sinifAdi  = p["ClassName"] ?? "";
    globals.ogrenciOkulNo = p["SchoolNumber"] ?? "";

    globals.duyuruVar = ValueNotifier((p["UnreadDuyuruCount"] ?? 0) > 0);
    globals.anketVar = ValueNotifier((p["SurveyCount"] ?? 0) > 0);
    globals.etkinlikVar = ValueNotifier((p["ActivityCount"] ?? 0) > 0);
    globals.mesajVar = ValueNotifier((p["UnreadMesajCount"] ?? 0) > 0);

    globals.globalSchoolId = p["SchoolId"]?.toString() ?? "";
    globals.kullaniciTCKN = globals.orjKullaniciTCKN+"_"+globals.globalSchoolId+"_"+globals.globalKullaniciTipi;

    globals.globalKonumEnlem = p["KonumEnlem"]?.toString() ?? "";
    globals.globalKonumBoylam = p["KonumBoylam"]?.toString() ?? "";
    globals.mesafeLimit = p["MesafeLimit"] ?? 0;
    globals.meslek = p["Meslek"] ?? "";
    globals.hobi = p["Hobi"] ?? "";
    globals.kvkk = p["Kvkk"]?.toString() ?? "0";

    /// Öğrenciler
    globals.globalOgrenciListesi = [];
    for (var e in (p["Students"] ?? [])) {
      globals.globalOgrenciListesi.add({
        "Name": e["Name"] ?? "",
        "TCKN": e["TCKN"] ?? "",
        "FotoVersion": e["FotoVersion"] ?? 0,
        "Alerji": e["Alerji"] ?? "",
        "Ilac": e["Ilac"] ?? "",
        "ClassName": e["ClassName"] ?? "",
        "SchoolNumber": e["SchoolNumber"] ?? "",
      });
    }

    /// Öğretmenler
    globals.globalOgretmenListesi = (p["Teachers"] ?? []).map<Map<String, dynamic>>((e) => {
      "TeacherName": e["TeacherName"] ?? "",
      "TeacherTCKN": e["TeacherTCKN"] ?? "",
      "StudentTCKN": e["StudentTCKN"] ?? "",
      "StudentName": e["StudentName"] ?? "",
    }).toList();

    /// Menü
    globals.menuListesi = (p["MenuTanim"] ?? "")
        .toString()
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    /// Sınıflar
    globals.globalSinifListesi = (p["Classes"] ?? []).map<Map<String, dynamic>>((e) => {
      "Id": e["Id"],
      "Ad": e["Ad"],
    }).toList();
  }


  /*Future<String> kullaniciBilgileriniCek(String tckn, String pswd, String sRole) async {
    final String baseUrl = "${globals.serverAdrr}/api/school/validate-person?tckn=$tckn&pin=$pswd&personType=$sRole";
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
      globals.globalErrMsg = "Sunucuya bağlanılamadı";
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
  }*/

  //Mesaj  okundu olarak işaretleme
  Future<bool> setMesajOkundu(String gonderenTckn, String alanTckn) async {
    final url = "${ApiService.baseUrl}/api/Mesaj/MarkConversationAsRead?gonderenTckn=$gonderenTckn&alanTckn=$alanTckn";
    final response = await http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'gonderenTckn': gonderenTckn,'alanTckn': alanTckn}));

    if (response.statusCode == 200) globals.duyuruVar = false as ValueNotifier<bool>;
    return response.statusCode == 200;
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
    print("url:"+url);
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

  Future<Uint8List> getProfilePhoto(String tckn) async {
    final response = await http.get(
      Uri.parse("$baseUrl/profile-photo?tckn=$tckn"),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception("Profil fotoğrafı alınamadı");
    }
  }


  Future<Uint8List?> getPhoto(String tckn, String fotoName) async {
    try {
      Directory dir = await getApplicationDocumentsDirectory();
      File localFile = File('${dir.path}/$fotoName.jpg');

      if (await localFile.exists()) {
        return await localFile.readAsBytes();
      }

      try {
        final byteData =
        await rootBundle.load('assets/images/$fotoName.jpg');
        return byteData.buffer.asUint8List();
      } catch (_) {}

      final response = await http.get(Uri.parse(
        '${ApiService.baseUrl}/api/school/get-person-photo?tckn=$tckn',
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

  Future<bool> updateActivity({
    required String ownerTckn,
    required int activityId,
    required String data,
    DateTime? expireDate,
  }) async {
    final uri = Uri.parse("${ApiService.baseUrl}/api/activity/update");

    final request = http.MultipartRequest("POST", uri);

    // ZORUNLU ALANLAR
    request.fields["ownerTckn"] = ownerTckn;
    request.fields["activityId"] = activityId.toString();
    request.fields["data"] = data;

    // OPSİYONEL ALAN
    if (expireDate != null) {
      request.fields["expireDate"] = expireDate.toIso8601String();
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(responseBody);
    }
  }

  //Etkinlik Silme
  Future<bool> deleteActivity({
    required String tckn,
    required int activityId,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/activity/delete'
            '?tckn=$tckn'
            '&activityId=$activityId',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        // Yetkisiz veya bulunamadı
        return false;
      } else {
        throw Exception(
          'DeleteActivity başarısız. StatusCode: ${response.statusCode}',
        );
      }
    } catch (e) {
      Logger().e('❌ deleteActivity hata: $e');
      rethrow;
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

  // İlaç Bilgisi oluşturma
  Future<void> createIlac(Map<String, dynamic> etkinlikData) async {
    final uri = Uri.parse("${ApiService.baseUrl}/api/activity/add");
    final request = http.MultipartRequest('POST', uri);

    etkinlikData.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      final respStr = await response.stream.bytesToString();
      logger.e("İlaç oluşturma response:$respStr");
      throw Exception("İlaç oluşturulamadı: $respStr");
    }
  }

  /// İlaç Takip Ekleme
  Future<Map<String, dynamic>> addIlacTakip({
    required String tckn,
    required String studentTckn,
    required String ilacDateStart,
    required String ilacDateEnd,
    required String ilacTime,
    required String data,
  }) async {
    final url = Uri.parse("${ApiService.baseUrl}/api/IlacTakip/add");

    var request = http.MultipartRequest('POST', url);

    request.fields['tckn'] = tckn;
    request.fields['studentTckn'] = studentTckn;
    request.fields['ilacDateStart'] = ilacDateStart;
    request.fields['ilacDateEnd'] = ilacDateEnd;
    request.fields['ilacTime'] = ilacTime;
    request.fields['data'] = data;

    print("addIlacTakip request: "+request.toString());

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": json.decode(responseData),
        };
      } else {
        return {
          "success": false,
          "message": responseData,
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Hata oluştu: $e",
      };
    }
  }

  // İlaç listesi alma
  Future<List<Map<String, dynamic>>> getIlacList(String ogrenciTCKN) async {

    final url = "${ApiService.baseUrl}/api/IlacTakip/get?studentTckn=$ogrenciTCKN";
    print("ilaç takip:");
    print("${ApiService.baseUrl}/api/IlacTakip/get?studentTckn=$ogrenciTCKN");
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception("İlaç listesi alınamadı: ${response.statusCode}");
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
      globals.globalErrMsg = "Kapı açılısı için Sunucuya bağlanılamadı";
      return globals.globalErrMsg;
    }
    logger.i("gate status:"+response.statusCode.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ana Kapı Kontrol çağrıldı',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
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
      globals.globalErrMsg = "Park Kapısı için Sunucuya bağlanılamadı";
      return globals.globalErrMsg;
    }
    logger.i("otopark status:"+response.statusCode.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Otopark Kontrol çağrıldı',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
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

  // 🔴 Survey Silme
  Future<bool> deleteSurvey({
    required String tckn,
    required int surveyId,
  }) async {
    final uri = Uri.parse(
      "${ApiService.baseUrl}/api/survey/delete"
          "?tckn=$tckn&surveyId=$surveyId",
    );

    final response = await http.delete(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      // İstersen response'u parse edebilirsin
      final data = jsonDecode(response.body);
      debugPrint("Anket silindi: ${data["surveyId"]}");
      return true;
    } else if (response.statusCode == 401) {
      throw Exception("Anket silme yetkiniz yok.");
      return false;
    } else {
      throw Exception(
        "Anket silinirken hata oluştu: ${response.body}",
      );
      return false;
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

  static Future<List<dynamic>> getConversationList(String tckn) async {
    if (tckn.isEmpty) {
      throw Exception("TCKN boş olamaz");
    }

    final Uri url = Uri.parse(
      "${ApiService.baseUrl}/api/Mesaj/GetConversationList?tckn=$tckn",
    );

   print("GetConversationList isteği atılıyor. URL: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print(
        "GetConversationList response: "
            "StatusCode=${response.statusCode}, "
            "Body=${response.body}",
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        throw Exception(
          "Konuşma listesi alınamadı. "
              "StatusCode: ${response.statusCode}",
        );
      }
    } catch (e, stackTrace) {
      throw Exception(
        "GetConversationList hatası"
      );
      rethrow;
    }
  }

  static Future<List<dynamic>> getConversationMessages({
    required String gonderenTckn,
    required String alanTckn,
    int take = 20,
    int skip = 0,
  }) async {
    if (gonderenTckn.isEmpty || alanTckn.isEmpty) {
      throw Exception("Gönderen ve alan TCKN boş olamaz");
    }

    final Uri url = Uri.parse(
      "${ApiService.baseUrl}/api/Mesaj/GetConversationMessages"
          "?gonderenTckn=$gonderenTckn"
          "&alanTckn=$alanTckn"
          "&take=$take"
          "&skip=$skip",
    );

    print(
      "GetConversationMessages isteği atılıyor. "
          "URL=$url",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      print(
        "GetConversationMessages response: "
            "StatusCode=${response.statusCode}, "
            "Body=${response.body}",
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else if (response.statusCode == 400) {
        throw Exception("Geçersiz parametreler gönderildi");
      } else {
        throw Exception(
          "Mesajlar alınamadı. StatusCode=${response.statusCode}",
        );
      }
    } catch (e, stackTrace) {
      throw Exception(
        "GetConversationMessages hatası"
      );
      rethrow;
    }
  }
/*
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
*/

  Future<bool> uploadGallery(String tckn, List<File> files) async {
    try {
      var uri = Uri.parse("${ApiService.baseUrl}/api/school/upload-gallery");
      var request = http.MultipartRequest('POST', uri);
      request.fields['tckn'] = tckn;

      for (var file in files) {
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        final multipartFile = await http.MultipartFile.fromPath(
          'files',
          file.path,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        logger.i("✅ Galeriye ${files.length} medya (video + thumbnail dahil) yüklendi.");
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

  static Future<String?> generateOtp(String tckn, String name) async {
    final url = Uri.parse('${ApiService.baseUrl}/api/otp/generate');
    print("OTP Generate URL: $url");

    try {
      var request = http.MultipartRequest('POST', url)
        ..fields['tckn'] = tckn
        ..fields['name'] = name;

      var response = await request.send();

      if (response.statusCode == 200) {
        var body = await response.stream.bytesToString();
        var data = jsonDecode(body);

        if (data['otp'] != null) {
          print("OTP başarıyla alındı: ${data['otp']}");
          return data['otp'].toString();
        } else {
          print("OTP alanı bulunamadı. Sunucu yanıtı: $data");
          return null;
        }
      } else {
        print("Sunucu hatası: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("GenerateOtp hatası: $e");
      return null;
    }
  }

  // 🔹 OTP doğrulama servisi
  static Future<List<dynamic>?> verifyOtp(String tckn, String otp) async {
    final url = Uri.parse('${ApiService.baseUrl}/api/otp/verify');
    print("OTP Verify URL: $url");

    try {
      var request = http.MultipartRequest('POST', url)
        ..fields['tckn'] = tckn
        ..fields['otp'] = otp;

      var response = await request.send();
      var body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        print("OTP doğrulama sonucu: $data");

        if (data is List) {
          return data; // ✅ Liste döndür
        } else {
          return [data]; // ✅ Tek obje dönerse listeye sar
        }
      } else {
        print("Doğrulama hatası: ${response.statusCode}, Body: $body");
        return [
          {"success": false, "message": "Sunucu hatası: ${response.statusCode}"}
        ];
      }
    } catch (e) {
      print("VerifyOtp hatası: $e");
      return [
        {"success": false, "message": e.toString()}
      ];
    }
  }

  Future<bool> registerFcmToken(String tckn, String fcmToken) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/school/register-fcm-token')
          .replace(queryParameters: {
        'tckn': tckn,
        'fcmToken': fcmToken,
      });

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        print("✅ FCM token başarıyla kaydedildi: ${response.body}");
        return true;
      } else if (response.statusCode == 404) {
        print("⚠️ Kişi bulunamadı: ${response.body}");
        return false;
      } else {
        print("❌ Sunucu hatası: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("🚨 FCM token gönderilirken hata oluştu: $e");
      return false;
    }
  }

  Future<String> konumAlYeni() async {
    String _konumBilgisi = "Konum bilgisi bekleniyor...";

    bool servisAktif = await Geolocator.isLocationServiceEnabled();
    if (!servisAktif) {
      _konumBilgisi = "Konum servisi kapalı.";
      return _konumBilgisi;
    }

    LocationPermission izinDurumu = await Geolocator.checkPermission();
    if (izinDurumu == LocationPermission.denied) {
      izinDurumu = await Geolocator.requestPermission();
      if (izinDurumu == LocationPermission.denied) {
        _konumBilgisi = "Konum izni reddedildi.";
        return _konumBilgisi;
      }
    }

    if (izinDurumu == LocationPermission.deniedForever) {
      _konumBilgisi = "Konum izni kalıcı olarak reddedildi.";
      return _konumBilgisi;
    }

    Position konum = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    globals.mevcutEnlem = konum.latitude.toString();
    globals.mevcutBoylam = konum.longitude.toString();

    _konumBilgisi = "Enlem: ${konum.latitude}, Boylam: ${konum.longitude}";

    return _konumBilgisi;
  }
/*
  Future<List<String>> getPlan({
    required String tckn,
    required int year,
    required int month,
    int day = 0,
  }) async
  {
    try {
      logger.i("getPlan çağrılıyor → TCKN=$tckn, Year=$year, Month=$month, Day=$day");

      final uri = Uri.parse(
        "${ApiService.baseUrl}/api/plan/get?tckn=$tckn&year=$year&month=$month&day=$day",
      );

      final response = await http.get(uri);

      logger.d("API yanıt kodu: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final urls = List<String>.from(data['urls'] ?? []);
        logger.i("getPlan tamamlandı → ${urls.length} URL döndü.");
        return urls;
      } else {
        logger.e("getPlan başarısız → ${response.statusCode}: ${response.body}");
        throw Exception("Sunucu hatası");
        //"Sunucu hatası: ${response.statusCode}"
      }
    } catch (e) {
      logger.e("getPlan hatası: $e");
      rethrow;
    }
  }
*/
  static Future<MealModel?> getMealList(String tckn, String date) async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/api/MealList/get?tckn=$tckn&date=$date");

      final response = await http.get(uri);
      print("GetMealList Status: ${response.statusCode}");
      print("GetMealList Body: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return MealModel.fromJson(data);
      } else {
        print("GetMealList Error: ${response.statusCode} ${response.body}");
        return null;
      }
    } catch (e) {
      print("GetMealList Exception: $e");
      return null;
    }
  }

  /// Yemek listesini çeker
  static Future<Map<String, dynamic>?> getMealList2(String tckn, String date) async {
    final url = Uri.parse("${ApiService.baseUrl}/api/MealList/get?tckn=$tckn&date=$date");

    try {
      final response = await http.get(url);

      print("GET MealList Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      else if (response.statusCode == 404) {
        return {"error": "Belirtilen tarih için yemek bulunamadı."};
      }
      else if (response.statusCode == 400) {
        return {"error": "Eksik parametre gönderildi."};
      }
      else {
        return {"error": "Sunucu hatası: ${response.statusCode}"};
      }
    } catch (e) {
      print("GetMealList exception: $e");
      return null;
    }
  }
}
