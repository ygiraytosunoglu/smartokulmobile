import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/meal_model.dart';
import '../models/conversation_item.dart';
import '../models/academic_record.dart';
import '../models/ders_catalog.dart';
import '../models/user.dart';
import '../globals.dart' as globals;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'dio_client.dart';
import '../utils/pin_policy.dart';
import '../utils/media_upload_limit.dart';

/// http.BaseClient wrapper — tüm http.get/post/put/delete çağrılarına
/// otomatik olarak Bearer token ekler (401 yönetimi Dio interceptor'da).
class _AuthHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }
}

class ApiService {
  static final String baseUrl = globals.serverAdrr;
  static final Logger logger = Logger();

  /// Tüm http çağrıları bu client üzerinden geçer → otomatik token eklenir.
  /// Diğer dosyalar da bu client'ı kullanmalı: ApiService.authClient
  static final _http = _AuthHttpClient();
  static _AuthHttpClient get authClient => _http;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'jwt_token';

  /// ------------------------------------------------------------
  /// TOKEN YÖNETİMİ
  /// ------------------------------------------------------------
  static Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    logger.i('JWT token kaydedildi.');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    logger.i('JWT token silindi.');
  }

  /// ------------------------------------------------------------
  /// ORTAK İSTEK GÖNDERİCİ  (Dio tabanlı — token & 401 interceptor'da)
  /// ------------------------------------------------------------
  Future<Map<String, dynamic>> _sendRequest(
      String method,
      String endpoint, {
        Map<String, String>? headers,
        dynamic body,
      }) async {
    final dio = DioClient.instance.dio;

    try {
      final Response response;
      final options = Options(
        method: method.toUpperCase(),
        headers: headers,
      );

      response = await dio.request(
        endpoint,
        data: body,
        options: options,
      );

      final data = response.data;
      return {
        'success': true,
        'data': data is Map<String, dynamic> ? data : <String, dynamic>{},
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {'success': false, 'message': 'Sunucu yanıt vermiyor (timeout).'};
      }
      if (e.type == DioExceptionType.connectionError) {
        return {'success': false, 'message': 'İnternet bağlantısı yok.'};
      }
      final statusCode = e.response?.statusCode;
      final responseBody = e.response?.data?.toString() ?? '';
      logger.e('Dio hatası: $statusCode - $responseBody');
      return {
        'success': false,
        'message': responseBody.isNotEmpty ? responseBody : 'Bir hata oluştu ($statusCode).',
        'details': responseBody,
      };
    } catch (e) {
      logger.e('Beklenmeyen hata: $e');
      return {'success': false, 'message': 'Beklenmeyen hata oluştu.'};
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

    final response = await _http.post(
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
      final response = await _http.get(Uri.parse(url));
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

  /// Person Gallery Listeleme
 /* Future<List<String>> getPersonGallery(
   List<String> tcknOrigList,
   {int take = 18, int skip = 0, String token=""}
  ) async {
    try {
      logger.i("GetPersonGallery başladı");

      /// 🔹 Query oluştur
      final queryParameters = {
        "take": take.toString(),
        "skip": skip.toString(),
      };

      /// personIds query'e tek tek eklenmeli
      final uri = Uri.parse("${ApiService.baseUrl}/api/school/get-person-gallery")
          .replace(queryParameters: queryParameters);

      final finalUri = Uri.parse(
        uri.toString() +
            tcknOrigList.map((e) => "&tcknOrigList=$e").join(),
      );

      logger.d("Request URI: $finalUri");

      final response = await _http.get(
        finalUri,
        headers: {
          "Authorization": "Bearer $token", // varsa
        },
      );

      logger.i("StatusCode: ${response.statusCode}");
      logger.d("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];

        /// Backend text/plain dönüyor:
        /// url1,url2,url3
        final urls = response.body
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .toList();

        return urls;
      }

      throw Exception("Gallery alınamadı");
    } catch (e) {
      logger.e("GetPersonGallery hata: $e");
      rethrow;
    }
  }*/


  Future<List<Map<String, String>>> getPersonGallery(
      List<String> tcknOrigList,
      {int take = 18, int skip = 0, String token=""}
      ) async  {

    try {
      logger.i("GetPersonGallery başladı");

      /// 🔹 Query oluştur
      final queryParameters = {
        "take": take.toString(),
        "skip": skip.toString(),
      };

      /// personIds query'e tek tek eklenmeli
      final uri = Uri.parse("${ApiService.baseUrl}/api/school/get-person-gallery")
          .replace(queryParameters: queryParameters);

      final finalUri = Uri.parse(
        uri.toString() +
            tcknOrigList.map((e) => "&tcknOrigList=$e").join(),
      );

      logger.d("Request URI: $finalUri");

      final response = await _http.get(
        finalUri,
        headers: {
          "Authorization": "Bearer $token", // varsa
        },
      );
     /* final response = await _http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception("StatusCode: ${response.statusCode}, Body: ${response.body}");
      }*/

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

      logger.i("GetPersonGallery images: $images");
      return images;
    } catch (e, st) {
      logger.e("GetPersonGallery error: $e");
      rethrow;
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

      final response = await ApiService._http.send(request);
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

    final response = await _http.post(
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

      final response = await _http.delete(url);

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

    final response = await _http.post(
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

    final response = await _http.post(
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

    final response = await _http.post(
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

    final response = await _http.post(
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
    //http.Response response = await _http.get(uri);
    http.Response response;

    try {
      response = await _http
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
    final uri = Uri.parse("${ApiService.baseUrl}/api/school/send-student-notification");
    final tcknString = studentTcknList.join(',');

    logger.i("sendStudentNotification → $uri");
    logger.i("schoolId=$schoolId senderTckn=$senderTckn studentTcknList=$tcknString durum=$durum");

    try {
      final request = http.MultipartRequest('POST', uri);
      request.fields['schoolId']        = schoolId.toString();
      request.fields['senderTckn']      = senderTckn;
      request.fields['studentTcknList'] = tcknString;
      request.fields['durum']           = durum.toString();

      final streamed     = await ApiService._http.send(request);
      final responseBody = await streamed.stream.bytesToString();

      logger.i("sendStudentNotification ← ${streamed.statusCode}: $responseBody");

      if (streamed.statusCode == 200) {
        return '200';
      } else {
        logger.e("⚠️ Bildirim gönderme başarısız: ${streamed.statusCode}, $responseBody");
        return streamed.statusCode.toString();
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

      final response = await _http.delete(
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
    final response = await _http.get(Uri.parse(url));

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
    final response = await _http.get(Uri.parse(url));

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
        "${ApiService.baseUrl}/api/ders/getAll?schoolId=$schoolId",
      );

      final response = await _http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Ödev ekranları Id/Ad bekliyor; yeni API id/ad dönebilir.
        return data.map((e) {
          if (e is! Map) return e;
          final m = Map<String, dynamic>.from(e);
          final id = jsonInt(m, 'id');
          final ad = jsonString(m, 'ad') ?? '';
          return {
            ...m,
            'Id': id ?? m['Id'],
            'Ad': ad.isNotEmpty ? ad : (m['Ad'] ?? ''),
          };
        }).toList();
      } else {
        throw Exception(
            "Dersler alınamadı. StatusCode: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("getAllDersler hatası: $e");
    }
  }

  static Future<List<DersItem>> getSchoolDersler(int schoolId) async {
    try {
      final response = await DioClient.instance.dio.get(
        '/api/ders/getAll',
        queryParameters: {'schoolId': schoolId},
      );
      final data = response.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((m) => DersItem.fromJson(Map<String, dynamic>.from(m)))
          .where((d) => d.id > 0 && d.ad.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      logger.w('getSchoolDersler: ${e.response?.statusCode}');
      return [];
    }
  }

  static Future<List<DersItem>> getCatalogAvailable(int schoolId) async {
    try {
      final response = await DioClient.instance.dio.get(
        '/api/ders/catalog-available',
        queryParameters: {'schoolId': schoolId},
      );
      final data = response.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((m) => DersItem.fromJson(Map<String, dynamic>.from(m)))
          .where((d) => d.id > 0)
          .toList();
    } on DioException catch (e) {
      logger.w('catalog-available: ${e.response?.statusCode}');
      return [];
    }
  }

  static Future<void> assignDersToSchool({
    required int schoolId,
    required int dersId,
  }) async {
    try {
      await DioClient.instance.dio.post(
        '/api/ders/assign',
        data: {'schoolId': schoolId, 'dersId': dersId},
      );
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'Ders atanamadı');
    }
  }

  static Future<void> removeDersFromSchool({
    required int schoolId,
    required int dersId,
  }) async {
    try {
      await DioClient.instance.dio.delete(
        '/api/ders/remove',
        queryParameters: {'schoolId': schoolId, 'dersId': dersId},
      );
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'Ders kaldırılamadı');
    }
  }

  static Future<List<DersTema>> getDersTemalar({
    required int dersId,
    int? sinifSeviye,
  }) async {
    try {
      final response = await DioClient.instance.dio.get(
        '/api/ders/temalar',
        queryParameters: {
          'dersId': dersId,
          if (sinifSeviye != null) 'sinifSeviye': sinifSeviye,
        },
      );
      final data = response.data;
      if (data is! List) return [];
      final list = data
          .whereType<Map>()
          .map((m) => DersTema.fromJson(Map<String, dynamic>.from(m)))
          .where((t) => t.id > 0)
          .toList();
      // Aynı tema (id veya ad) birden fazla sınıf seviyesinde gelebilir.
      final byId = <int, DersTema>{};
      for (final t in list) {
        byId.putIfAbsent(t.id, () => t);
      }
      final byAd = <String, DersTema>{};
      for (final t in byId.values) {
        final key = t.ad.trim().toLowerCase();
        byAd.putIfAbsent(key.isEmpty ? 'id_${t.id}' : key, () => t);
      }
      return byAd.values.toList();
    } on DioException catch (e) {
      logger.w('temalar: ${e.response?.statusCode}');
      return [];
    }
  }

  static Future<List<DersKonu>> getDersKonular(int temaId) async {
    try {
      final response = await DioClient.instance.dio.get(
        '/api/ders/konular',
        queryParameters: {'temaId': temaId},
      );
      final data = response.data;
      if (data is! List) return [];
      final list = data
          .whereType<Map>()
          .map((m) => DersKonu.fromJson(Map<String, dynamic>.from(m)))
          .where((k) => k.id > 0)
          .toList();
      final byId = <int, DersKonu>{};
      for (final k in list) {
        byId.putIfAbsent(k.id, () => k);
      }
      final byAd = <String, DersKonu>{};
      for (final k in byId.values) {
        final key = k.ad.trim().toLowerCase();
        byAd.putIfAbsent(key.isEmpty ? 'id_${k.id}' : key, () => k);
      }
      return byAd.values.toList();
    } on DioException catch (e) {
      logger.w('konular: ${e.response?.statusCode}');
      return [];
    }
  }

  static Future<void> getAllTeachersAndSetGlobal(int schoolId) async {
    final uri = Uri.parse(
      "$baseUrl/api/Teacher/getAll?schoolId=$schoolId",
    );

    try {
      final response = await _http.get(
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

  static String? _plainStudentTckn(String? tckn) {
    if (tckn == null || tckn.isEmpty) return tckn;
    final parts = tckn.split('_');
    if (parts.length >= 3) return parts.first;
    return tckn;
  }

  static Map<String, dynamic>? _nestedClass(Map map) {
    for (final key in ['class', 'sinif', 'classroom', 'classInfo']) {
      final nested = jsonField(map, key);
      if (nested is Map) return Map<String, dynamic>.from(nested);
    }
    return null;
  }

  static Map<String, dynamic> _normalizeStudent(
    Map json, {
    int? classId,
    String? className,
  }) {
    final map = Map<String, dynamic>.from(json);
    final nested = _nestedClass(map);
    return {
      'Name': jsonString(map, 'name') ??
          jsonString(map, 'ad') ??
          jsonString(map, 'adi') ??
          '',
      'TCKN': jsonString(map, 'tcknOrig') ??
          _plainStudentTckn(jsonString(map, 'tckn')) ??
          '',
      'FotoVersion': jsonInt(map, 'fotoVersion') ?? 0,
      'Alerji': jsonString(map, 'alerji') ?? '',
      'Ilac': jsonString(map, 'ilac') ?? '',
      'ClassId': jsonInt(map, 'classId') ??
          jsonInt(map, 'sinifId') ??
          jsonInt(map, 'classID') ??
          jsonInt(map, 'class_id') ??
          jsonInt(map, 'sinif_id') ??
          (nested == null
              ? null
              : jsonInt(nested, 'id') ?? jsonInt(nested, 'classId')) ??
          classId,
      'ClassName': jsonString(map, 'className') ??
          jsonString(map, 'sinifAdi') ??
          jsonString(map, 'sinifAd') ??
          jsonString(map, 'classAd') ??
          (nested == null
              ? null
              : jsonString(nested, 'ad') ??
                  jsonString(nested, 'name') ??
                  jsonString(nested, 'className')) ??
          className ??
          '',
      'SchoolNumber': jsonString(map, 'schoolNumber') ??
          jsonString(map, 'okulNo') ??
          '',
    };
  }

  static List<Map<String, dynamic>> _asStudentMaps(dynamic data) {
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      dynamic inner;
      for (final key in ['data', 'items', 'students', 'result', 'ogrenciler']) {
        inner = jsonField(map, key);
        if (inner is List) break;
      }
      list = inner is List ? inner : [];
    } else {
      list = [];
    }

    final maps = list.whereType<Map>().toList();
    if (maps.isNotEmpty) {
      final first = Map<String, dynamic>.from(maps.first);
      final hasTckn = (jsonString(first, 'tckn') ?? '').isNotEmpty;
      dynamic nestedKids;
      for (final key in ['students', 'ogrenciler', 'uyeler', 'members']) {
        nestedKids = jsonField(first, key);
        if (nestedKids is List) break;
      }
      if (!hasTckn && nestedKids is List) {
        final flattened = <Map<String, dynamic>>[];
        for (final item in maps) {
          final m = Map<String, dynamic>.from(item);
          dynamic kids;
          for (final key in ['students', 'ogrenciler', 'uyeler', 'members']) {
            kids = jsonField(m, key);
            if (kids is List) break;
          }
          if (kids is! List) continue;
          final classId = jsonInt(m, 'id') ?? jsonInt(m, 'classId');
          final className = jsonString(m, 'ad') ??
              jsonString(m, 'className') ??
              jsonString(m, 'name');
          for (final k in kids.whereType<Map>()) {
            flattened.add(_normalizeStudent(
              Map<String, dynamic>.from(k),
              classId: classId,
              className: className,
            ));
          }
        }
        return flattened
            .where((e) => (e['TCKN'] ?? '').toString().isNotEmpty)
            .toList();
      }
    }

    return maps
        .map((e) => _normalizeStudent(Map<String, dynamic>.from(e)))
        .where((e) => (e['TCKN'] ?? '').toString().isNotEmpty)
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getTeacherStudents({
    String? tckn,
    int? schoolId,
  }) async {
    final response = await DioClient.instance.dio.get(
      '/api/Teacher/getStudents',
      queryParameters: {
        if (tckn != null && tckn.isNotEmpty) 'tckn': tckn,
        if (schoolId != null) 'schoolId': schoolId,
      },
    );
    return _asStudentMaps(response.data);
  }

  static int? _parseClassId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().split('.').first);
  }

  static String _classNameForId(dynamic id) {
    final cid = _parseClassId(id);
    if (cid == null) return '';
    for (final s in globals.globalSinifListesi) {
      if (_parseClassId(s['Id']) == cid) {
        return (s['Ad'] ?? '').toString().trim();
      }
    }
    return '';
  }

  static Future<List<Map<String, dynamic>>> getStudentsByClass({
    required int schoolId,
    required int classId,
    String? className,
  }) async {
    final response = await DioClient.instance.dio.get(
      '/api/Student/getAll',
      queryParameters: {
        'schoolId': schoolId,
        'classId': classId,
        'ClassId': classId,
        'sinifId': classId,
      },
    );
    return _asStudentMaps(response.data);
  }

  /// Öğretmenin tüm sınıflarındaki öğrenciler (ödev / gelişim seçimi).
  static Future<List<Map<String, dynamic>>> loadHomeworkStudents() async {
    final schoolId = int.tryParse(globals.globalSchoolId.toString());
    final merged = <String, Map<String, dynamic>>{};

    void upsert(
      Map<String, dynamic> s, {
      int? forceClassId,
      String? forceClassName,
    }) {
      final tckn = s['TCKN']?.toString() ?? '';
      if (tckn.isEmpty) return;
      final prev = merged[tckn];
      var classId = forceClassId ?? s['ClassId'] ?? prev?['ClassId'];
      var className = (forceClassName ?? '').trim();
      if (className.isEmpty) {
        className = _classNameForId(classId);
      }
      if (className.isEmpty) {
        className = (s['ClassName'] ?? prev?['ClassName'] ?? '').toString().trim();
      }
      merged[tckn] = {
        ...?prev,
        ...s,
        'ClassId': classId,
        'ClassName': className,
      };
    }

    for (final s in globals.globalOgrenciListesi) {
      upsert(s);
    }

    try {
      final fromTeacher = await getTeacherStudents(
        tckn: globals.kullaniciTCKN,
        schoolId: schoolId,
      );
      for (final s in fromTeacher) {
        upsert(s);
      }
    } catch (e) {
      logger.w('getTeacherStudents: $e');
    }

    if (schoolId != null && globals.globalSinifListesi.isNotEmpty) {
      final perClass = <int, List<Map<String, dynamic>>>{};
      for (final sinif in globals.globalSinifListesi) {
        final classId = _parseClassId(sinif['Id']);
        if (classId == null) continue;
        try {
          perClass[classId] = await getStudentsByClass(
            schoolId: schoolId,
            classId: classId,
            className: (sinif['Ad'] ?? '').toString(),
          );
        } catch (e) {
          logger.w('getStudentsByClass($classId): $e');
        }
      }

      var leaky = false;
      if (perClass.length >= 2) {
        final sets = perClass.values
            .map((l) => l
                .map((s) => s['TCKN']?.toString() ?? '')
                .where((t) => t.isNotEmpty)
                .toSet())
            .toList();
        final union = <String>{};
        for (final s in sets) {
          union.addAll(s);
        }
        leaky = sets.every(
              (s) => s.length == sets.first.length && s.containsAll(sets.first),
            ) ||
            (union.isNotEmpty &&
                sets.any((s) => s.length >= union.length));
      }

      if (leaky) {
        for (final list in perClass.values) {
          for (final s in list) {
            upsert(s);
          }
        }
      } else {
        for (final sinif in globals.globalSinifListesi) {
          final classId = _parseClassId(sinif['Id']);
          if (classId == null) continue;
          final className = (sinif['Ad'] ?? '').toString().trim();
          for (final s in perClass[classId] ?? const []) {
            upsert(s, forceClassId: classId, forceClassName: className);
          }
        }
      }
    }

    for (final s in merged.values) {
      final fromId = _classNameForId(s['ClassId']);
      if (fromId.isNotEmpty) {
        s['ClassName'] = fromId;
      }
    }

    final list = merged.values.toList();
    list.sort((a, b) {
      final c = (a['ClassName'] ?? '')
          .toString()
          .compareTo((b['ClassName'] ?? '').toString());
      if (c != 0) return c;
      return (a['Name'] ?? '')
          .toString()
          .compareTo((b['Name'] ?? '').toString());
    });
    return list;
  }

  Future<int?> addOdev({
    required String gonderenTckn,
    required List<String> alanTcknList,
    required int dersId,
    required int schoolId,
    String? data,
    DateTime? expireDate,
    List<File>? files,
    int? temaId,
    int? konuId,
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
      if (temaId != null) {
        request.fields['temaId'] = temaId.toString();
      }
      if (konuId != null) {
        request.fields['konuId'] = konuId.toString();
      }

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

      final streamedResponse = await ApiService._http.send(request);
      final response =
      await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['id'] ?? jsonInt(body is Map ? body : {}, 'id');
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

      final response = await _http.get(
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

      final response = await _http.delete(
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
    int? temaId,
    int? konuId,
    String? actorTckn,
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
      if (temaId != null) {
        request.fields['temaId'] = temaId.toString();
      }
      if (konuId != null) {
        request.fields['konuId'] = konuId.toString();
      }
      if (actorTckn != null && actorTckn.isNotEmpty) {
        request.fields['actorTckn'] = actorTckn;
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

      final response = await ApiService._http.send(request);
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

  Future<Map<String, dynamic>> getOdevById({
    required int odevId,
    required String tckn,
  }) async {
    try {
      final response = await DioClient.instance.dio.get(
        '/api/odev/getById',
        queryParameters: {'odevId': odevId, 'tckn': tckn},
      );
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw Exception('Ödev detayı alınamadı');
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'Ödev detayı alınamadı');
    }
  }

  Future<void> cevapOdev({
    required int odevId,
    required String studentTckn,
    required int schoolId,
    String? aciklama,
    List<File>? files,
  }) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/odev/cevap');
      final request = http.MultipartRequest('POST', uri);
      request.fields['odevId'] = odevId.toString();
      request.fields['studentTckn'] = fullStudentTckn(studentTckn);
      request.fields['schoolId'] = schoolId.toString();
      if (aciklama != null && aciklama.isNotEmpty) {
        request.fields['aciklama'] = aciklama;
      }
      if (files != null) {
        for (final file in files) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'files',
              file.path,
              filename: path.basename(file.path),
            ),
          );
        }
      }
      final streamed = await ApiService._http.send(request);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception(
          'Cevap gönderilemedi. StatusCode: ${response.statusCode} Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('cevapOdev hatası: $e');
    }
  }

  Future<void> onayOdev({
    required int odevId,
    required String actorTckn,
    required String studentTckn,
    required bool onaylandi,
  }) async {
    try {
      await DioClient.instance.dio.post(
        '/api/odev/onay',
        data: {
          'odevId': odevId,
          'actorTckn': actorTckn,
          'studentTckn': fullStudentTckn(studentTckn),
          'onaylandi': onaylandi,
        },
      );
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'Onay işlemi başarısız');
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

      final response = await _http.get(
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

  Future<Map<String, dynamic>> changePin({
    required String tckn,
    required String currentPin,
    required String yeniPin,
  }) async {
    final response = await _http.post(
      Uri.parse('${ApiService.baseUrl}/api/school/change-pin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tckn': tckn,
        'currentPin': currentPin,
        'yeniPin': yeniPin,
      }),
    );

    Map<String, dynamic> decoded = {};
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map) decoded = Map<String, dynamic>.from(raw);
    } catch (_) {}

    final code = (jsonField(decoded, 'message') ?? response.body).toString();
    final info = (jsonField(decoded, 'info') ?? '').toString();

    if (response.statusCode == 200) {
      globals.mustChangePin = jsonBool(decoded, 'mustChangePin');
      return decoded;
    }

    if (code.startsWith('ERR_PIN_POLICY') && info.isNotEmpty) {
      throw Exception(info);
    }
    throw Exception(code.isNotEmpty ? code : 'PIN güncellenemedi');
  }

  Future<bool> updatePin(String tckn, String telNo, String yeniPin) async {
    final url = Uri.parse(
      '${ApiService.baseUrl}/api/school/update-pin?tckn=$tckn&telNo=$telNo&yeniPin=$yeniPin',
    );

    final headers = {
      'Content-Type': 'application/json',
    };

    final response = await _http.post(url, headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('PIN güncellenemedi: ${response.body}');
    }
  }

  // Okul logosu getirme servisi. Yoksa / hata olursa null döner (ekran dönmez).
  Future<Uint8List?> getLogo(String tckn) async {
    try {
      final url =
          Uri.parse('${ApiService.baseUrl}/api/school/get-logo?tckn=$tckn');
      final response = await _http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final bytes = response.bodyBytes;
      if (bytes.isEmpty || bytes.length < 32) return null;
      final ctype = response.headers['content-type'] ?? '';
      if (ctype.contains('html') || ctype.contains('json')) return null;
      return bytes;
    } catch (e) {
      logger.w('getLogo: $e');
      return null;
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

      var response = await ApiService._http.send(request);
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

      final response = await _http.get(url);

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

      var response = await ApiService._http.send(request);
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

      final response = await _http.get(url);

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

      var response = await ApiService._http.send(request);
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

      final response = await _http.get(url);

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
      var response = await ApiService._http.send(request);
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

    final response = await _http.get(url);

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
    http.Response response = await _http.get(uri);
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
    globals.duyuruVar.value = (parsedResponse["UnreadDuyuruCount"] ?? 0) != 0;

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

    final response = await _http.post(
      Uri.parse("${globals.serverAdrr}/api/school/validate-person"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Tckn': tckn, 'Pin': pswd, 'PersonType': sRole}),
    );

    if (response.statusCode != 200) {
      return response.body;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // JWT token'ı secure storage'a kaydet (PascalCase / camelCase)
    final token = (jsonField(decoded, 'token') ?? '').toString();
    if (token.isNotEmpty) {
      await _saveToken(token);
    }

    final personsRaw = jsonField(decoded, 'persons');
    final List persons = personsRaw is List ? personsRaw : [];

    if (persons.isEmpty) {
      return "Kullanıcı bulunamadı";
    }

    /// ✅ 1 OKUL → DEVAM
    if (persons.length == 1) {
      parsePerson(Map<String, dynamic>.from(persons[0] as Map));
      _applyMustChangePin(decoded, Map<String, dynamic>.from(persons[0] as Map), pswd);
      unawaited(fetchLoginCounts());
      if (globals.mustChangePin) return "MUST_CHANGE_PIN";
      return "OK";
    }

    /// ⚠️ 1'DEN FAZLA OKUL → SEÇİM GEREKİYOR
    globals.secilebilirOkullar = persons;
    if (isDefaultPin(pswd) || jsonBool(decoded, 'mustChangePin')) {
      globals.mustChangePin = true;
    }
    return "SELECT_SCHOOL";
  }

  void _applyMustChangePin(
    Map<String, dynamic> decoded,
    Map<String, dynamic> person,
    String pswd,
  ) {
    final fromPerson = jsonBool(person, 'mustChangePin');
    final fromRoot = jsonBool(decoded, 'mustChangePin');
    globals.mustChangePin = fromPerson || fromRoot || isDefaultPin(pswd);
    logger.i(
      'mustChangePin person=$fromPerson root=$fromRoot '
      'defaultPin=${isDefaultPin(pswd)} keys=${person.keys.toList()}',
    );
  }

  /// get-login-counts endpoint'inden bildirim sayaçlarını çeker ve
  /// ilgili global ValueNotifier'ları günceller.
  /// Login sonrası ve gerektiğinde (ör. uygulama ön plana geldiğinde) çağrılabilir.
  static Future<void> fetchLoginCounts() async {
    try {
      final response = await DioClient.instance.dio.get(
        '/api/school/get-login-counts',
      );
      final data = response.data as Map<String, dynamic>;
      globals.mesajVar.value   = ((data['UnreadMesajCount']  ?? 0) as int) > 0;
      globals.duyuruVar.value  = ((data['UnreadDuyuruCount'] ?? 0) as int) > 0;
      globals.anketVar.value   = ((data['SurveyCount']       ?? 0) as int) > 0;
      globals.etkinlikVar.value= ((data['ActivityCount']     ?? 0) as int) > 0;
      logger.i('fetchLoginCounts: $data');
    } on DioException catch (e) {
      logger.e('fetchLoginCounts hatası: ${e.response?.statusCode} ${e.message}');
    } catch (e) {
      logger.e('fetchLoginCounts beklenmeyen hata: $e');
    }
  }

  void parsePerson(Map<String, dynamic> p) {
    globals.globalKullaniciAdi = p["Name"] ?? "";
    globals.globalOkulAdi = p["SchoolName"] ?? "";
    globals.orjKullaniciTCKN = p["TCKN"] ?? "";
    globals.globalKullaniciTipi = p["Type"] ?? "";
    globals.fotoVersion = p["FotoVersion"] ?? 0;
    globals.sinifAdi  = p["ClassName"] ?? "";
    globals.ogrenciOkulNo = p["SchoolNumber"] ?? "";

    // Bildirim sayaçları artık parsePerson'dan gelmiyor;
    // fetchLoginCounts() ile ayrıca alınıyor.

    globals.globalSchoolId = p["SchoolId"]?.toString() ?? "";
    globals.kullaniciTCKN = globals.orjKullaniciTCKN+"_"+globals.globalSchoolId+"_"+globals.globalKullaniciTipi;

    globals.globalKonumEnlem = p["KonumEnlem"]?.toString() ?? "";
    globals.globalKonumBoylam = p["KonumBoylam"]?.toString() ?? "";
    globals.mesafeLimit = p["MesafeLimit"] ?? 0;
    globals.meslek = p["Meslek"] ?? "";
    globals.hobi = p["Hobi"] ?? "";
    globals.kvkk = p["Kvkk"]?.toString() ?? "0";
    globals.mustChangePin =
        jsonBool(p, 'mustChangePin') || globals.mustChangePin;

    /// Öğrenciler
    globals.globalOgrenciListesi = [];
    final studentsRaw = jsonField(p, 'students') ?? p['Students'] ?? [];
    if (studentsRaw is List) {
      for (var e in studentsRaw) {
        if (e is! Map) continue;
        final s = Map<String, dynamic>.from(e);
        globals.globalOgrenciListesi.add(_normalizeStudent(s));
      }
    }

    print("ogrenci listesi:"+globals.globalOgrenciListesi.toString());

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
    final classesRaw = jsonField(p, 'classes') ?? p['Classes'] ?? [];
    globals.globalSinifListesi = (classesRaw is List)
        ? classesRaw.whereType<Map>().map<Map<String, dynamic>>((e) {
            final m = Map<String, dynamic>.from(e);
            return {
              'Id': jsonInt(m, 'id') ?? m['Id'],
              'Ad': jsonString(m, 'ad') ?? m['Ad'] ?? '',
            };
          }).toList()
        : [];

    print("sinif listesi:"+globals.globalSinifListesi.toString());
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
    final response = await _http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'gonderenTckn': gonderenTckn,'alanTckn': alanTckn}));

    if (response.statusCode == 200) globals.mesajVar.value = false;
    return response.statusCode == 200;
  }

  // Duyuruyu okundu olarak işaretleme
  Future<bool> setDuyuruOkundu(int duyuruId) async {
    final url = "${ApiService.baseUrl}/api/Duyuru/MarkAsRead?duyuruId=$duyuruId";
    final response = await _http.post(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'duyuruId': duyuruId}));

    if (response.statusCode == 200) globals.duyuruVar.value = false;
    return response.statusCode == 200;
  }

  /// Günlük yoklama listesini getirir
  Future<List<dynamic>> getYoklamaList(List<String> tcknList, String date) async {
    if (tcknList.isEmpty) return [];
    try {
      final tcknQuery = tcknList.join(',');
      final uri = Uri.parse(
        "${ApiService.baseUrl}/api/yoklama/bulk-has?tcknList=$tcknQuery&date=$date",
      );
      logger.i("getYoklamaList çağırıldı");

      final response = await _http.get(uri);
      if (response.statusCode != 200) {
        logger.w("Yoklama listesi alınamadı. StatusCode: ${response.statusCode}");
        return [];
      }

      final body = response.body.trim();
      if (body.isEmpty || body.startsWith('<')) return [];

      final decoded = json.decode(body);
      if (decoded is List) return decoded;
      if (decoded is Map) {
        for (final key in ['data', 'items', 'result']) {
          final inner = decoded[key];
          if (inner is List) return inner;
        }
      }
      return [];
    } catch (e) {
      logger.w("Hata getYoklamaList: $e");
      return [];
    }
  }

  Future<int> checkCurrentTime(int schoolId, String personType) async {
    final url = "${ApiService.baseUrl}/api/doortime/check-time?schoolId=$schoolId&personType=$personType";

    try {
      final response = await _http.get(Uri.parse(url));
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

      final response = await _http.get(uri);

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

      final response = await _http.get(uri);

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
      final response = await _http.get(Uri.parse(url));
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
      final response = await _http.get(Uri.parse(url));

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
      final response = await _http.get(Uri.parse(url));

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
    final response = await _http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<String>();
    } else {
      throw Exception("Fotoğraflar alınamadı! StatusCode: ${response.statusCode}");
    }
  }*/

  Future<Uint8List> getProfilePhoto(String tckn) async {
    final response = await _http.get(
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

      final response = await _http.get(Uri.parse(
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

    final response = await ApiService._http.send(request);
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

    final response = await ApiService._http.send(request);
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

    final response = await ApiService._http.send(request);
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

      final response = await _http.delete(
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
    final response = await _http.get(Uri.parse(url));

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

    final response = await ApiService._http.send(request);
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
      final response = await ApiService._http.send(request);
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
    final response = await _http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      return (decoded as List).cast<Map<String, dynamic>>();
    } else {
      throw Exception("İlaç listesi alınamadı: ${response.statusCode}");
    }
  }

  /// İlaç takip kaydını pasife alır (siler).
  /// [id]   → silinecek kaydın Id'si
  /// [tckn] → işlemi yapan kullanıcının TCKN'si
  Future<void> deactivateIlacTakip({
    required int id,
    required String tckn,
  }) async {
    final url = Uri.parse("${ApiService.baseUrl}/api/IlacTakip/deactivate");

    final request = http.MultipartRequest('POST', url);
    request.fields['id'] = id.toString();
    request.fields['tckn'] = tckn;

    final streamedResponse = await ApiService._http.send(request).timeout(const Duration(seconds: 10));
    final statusCode = streamedResponse.statusCode;

    if (statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      logger.e("deactivateIlacTakip hata: $statusCode - $body");
      throw Exception("İlaç kaydı silinemedi: $statusCode");
    }
  }

  Future<String> onGatePressed(BuildContext context) async{
    // TODO: API çağrısı buraya eklenecek
    final String baseUrl =
        globals.serverAdrr+"/api/school/open-door/"+globals.globalSchoolId;
    logger.i("baseUrl:$baseUrl");
    Uri uri = Uri.parse(baseUrl );
    //http.Response response = await _http.get(uri);
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
    //http.Response response = await _http.get(uri);
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
    final response = await _http.get(
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
    final response = await _http.post(
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

    final response = await _http.delete(
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
    final response = await _http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      throw Exception("Summary alınamadı");
    }
  }

  static Future<List<Map<String, dynamic>>> getParents({
    required String studentTckn,
    String? schoolId,
  }) async {
    if (studentTckn.isEmpty) return [];
    try {
      final response = await DioClient.instance.dio.get(
        '/api/student/getParents',
        queryParameters: {
          'tckn': studentTckn,
          if (schoolId != null && schoolId.isNotEmpty) 'schoolId': schoolId,
        },
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (e) {
      logger.w('getParents($studentTckn): $e');
      return [];
    }
  }

  static Future<List<dynamic>> getConversationList(String tckn) async {
    if (tckn.isEmpty) throw Exception("TCKN boş olamaz");

    logger.i("GetConversationList isteği atılıyor. URL: $tckn");

    try {
      final response = await DioClient.instance.dio.get(
        '/api/Mesaj/GetConversationList',
        queryParameters: {'tckn': tckn},
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      logger.e("GetConversationList hatası: ${e.response?.statusCode} ${e.message}");
      throw Exception("GetConversationList hatası: ${e.response?.statusCode}");
    }
  }

  /// T/M için yazışılabilir veliler (tek istek; client N×getParents yerine).
  static Future<List<ConversationItem>> getMessageableContacts(
    String tckn,
  ) async {
    if (tckn.isEmpty) return [];
    try {
      final response = await DioClient.instance.dio.get(
        '/api/Mesaj/GetMessageableContacts',
        queryParameters: {'tckn': tckn},
      );
      final data = response.data;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((m) => ConversationItem.fromContactJson(
                Map<String, dynamic>.from(m),
              ))
          .where((c) => (c.tckn ?? '').isNotEmpty)
          .toList();
    } on DioException catch (e) {
      logger.w(
        'GetMessageableContacts: ${e.response?.statusCode} ${e.message}',
      );
      return [];
    } catch (e) {
      logger.w('GetMessageableContacts: $e');
      return [];
    }
  }

  static List<dynamic> _normalizeMessageList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((m) => normalizeChatMessage(Map<String, dynamic>.from(m)))
        .toList();
  }

  static String _extractApiMessage(dynamic data) {
    if (data == null) return '';
    if (data is String) return data.trim();
    if (data is Map) {
      return (jsonField(data, 'message') ?? data['message'] ?? '').toString().trim();
    }
    return data.toString();
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

    try {
      final response = await DioClient.instance.dio.get(
        '/api/Mesaj/GetConversationMessages',
        queryParameters: {
          'gonderenTckn': gonderenTckn,
          'alanTckn': alanTckn,
          'take': take,
          'skip': skip,
        },
      );
      return _normalizeMessageList(response.data);
    } on DioException catch (e) {
      logger.e("GetConversationMessages hatası: ${e.response?.statusCode} ${e.message}");
      if (e.response?.statusCode == 400) {
        throw Exception("Geçersiz parametreler gönderildi");
      }
      throw Exception("GetConversationMessages hatası: ${e.response?.statusCode}");
    }
  }

  static Future<List<dynamic>> getGroupMessages({
    required int grupId,
    required String tckn,
    int take = 50,
    int skip = 0,
  }) async {
    if (tckn.isEmpty) throw Exception("TCKN boş olamaz");

    try {
      final response = await DioClient.instance.dio.get(
        '/api/Mesaj/GetGroupMessages',
        queryParameters: {
          'grupId': grupId,
          'tckn': tckn,
          'take': take.clamp(1, 100),
          'skip': skip,
        },
      );
      return _normalizeMessageList(response.data);
    } on DioException catch (e) {
      logger.e("GetGroupMessages hatası: ${e.response?.statusCode} ${e.message}");
      throw Exception("GetGroupMessages hatası: ${e.response?.statusCode}");
    }
  }

  static bool _isJsonBody(dynamic data) => data is List || data is Map;

  static Future<dynamic> _getJsonOrNull(
    String path,
    Map<String, dynamic> query,
  ) async {
    try {
      final response = await DioClient.instance.dio.get(
        path,
        queryParameters: query,
      );
      final ctype = response.headers.value('content-type') ?? '';
      if (ctype.contains('html') || !_isJsonBody(response.data)) {
        return null;
      }
      return response.data;
    } on DioException catch (e) {
      logger.w('$path → ${e.response?.statusCode}');
      return null;
    }
  }

  /// Grup üyeleri. Web ile aynı kaynak: GET /api/mesaj-grup/members
  static Future<List<dynamic>> getGroupMembers({
    required int grupId,
    required String tckn,
  }) async {
    final query = {
      'grupId': grupId,
      'groupId': grupId,
      'id': grupId,
      'tckn': tckn,
      'schoolId': globals.globalSchoolId,
    };

    final membersBody = await _getJsonOrNull('/api/mesaj-grup/members', query);
    if (membersBody != null) {
      final members = extractMemberList(membersBody);
      if (members.isNotEmpty) {
        logger.i('Grup üyeleri members endpoint: ${members.length}');
        return members;
      }
      if (membersBody is List) return membersBody;
    }

    final listBody = await _getJsonOrNull('/api/mesaj-grup/list', query);
    if (listBody != null) {
      final fromList = extractMembersFromGroupList(listBody, grupId);
      if (fromList.isNotEmpty) {
        logger.i('Grup üyeleri list endpoint: ${fromList.length}');
        return fromList;
      }
    }

    throw Exception('Grup üyeleri alınamadı');
  }

  static final _chatUploadOptions = Options(
    sendTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
  );

  static Future<MultipartFile> _chatMultipartFile(File file) async {
    final filename = file.path.split(Platform.pathSeparator).last;
    final mime = lookupMimeType(file.path);
    return MultipartFile.fromFile(
      file.path,
      filename: filename,
      contentType: mime == null ? null : MediaType.parse(mime),
    );
  }

  static Future<Map<String, dynamic>> sendMesajWithFile({
    required String gonderenTckn,
    required String alanTckn,
    String? data,
    String baslik = 'SmartOkul',
    File? file,
  }) async {
    try {
      final form = FormData.fromMap({
        'gonderenTckn': gonderenTckn,
        'alanTckn': alanTckn,
        'baslik': baslik,
        if (data != null && data.isNotEmpty) 'data': data,
        if (file != null) 'file': await _chatMultipartFile(file),
      });
      final response = await DioClient.instance.dio.post(
        '/api/Mesaj/SendMesajWithFile',
        data: form,
        options: _chatUploadOptions,
      );
      final body = response.data;
      if (body is Map) return Map<String, dynamic>.from(body);
      return {'message': body?.toString() ?? 'ERR_MESAJ_GONDERILDI'};
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'ERR_MESAJ_EK_YUKLENEMEDI');
    }
  }

  static Future<Map<String, dynamic>> sendGroupMesajWithFile({
    required int grupId,
    required String gonderenTckn,
    String? data,
    String baslik = 'SmartOkul',
    File? file,
  }) async {
    try {
      final form = FormData.fromMap({
        'grupId': grupId.toString(),
        'gonderenTckn': gonderenTckn,
        'baslik': baslik,
        if (data != null && data.isNotEmpty) 'data': data,
        if (file != null) 'file': await _chatMultipartFile(file),
      });
      final response = await DioClient.instance.dio.post(
        '/api/Mesaj/SendGroupMesajWithFile',
        data: form,
        options: _chatUploadOptions,
      );
      final body = response.data;
      if (body is Map) return Map<String, dynamic>.from(body);
      return {'message': body?.toString() ?? 'ERR_MESAJ_GONDERILDI'};
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'ERR_MESAJ_EK_YUKLENEMEDI');
    }
  }

  static Future<Map<String, dynamic>?> getAttachmentUrl({
    required int mesajId,
    required String tckn,
    required bool isGroup,
  }) async {
    try {
      final response = await DioClient.instance.dio.get(
        '/api/Mesaj/GetAttachmentUrl',
        queryParameters: {
          'mesajId': mesajId,
          'tckn': tckn,
          'isGroup': isGroup,
        },
      );
      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        return {
          'url': jsonString(map, 'url') ?? '',
          'dosyaAdi': jsonString(map, 'dosyaAdi') ?? '',
          'dosyaTipi': jsonString(map, 'dosyaTipi') ?? '',
          'ekTuru': jsonString(map, 'ekTuru') ?? '',
        };
      }
      return null;
    } on DioException catch (e) {
      logger.w('GetAttachmentUrl: ${e.response?.statusCode}');
      return null;
    }
  }

  Future<void> sendGroupMesaj({
    required int grupId,
    required String gonderenTckn,
    required String data,
    String baslik = 'SmartOkul',
  }) async {
    try {
      final response = await DioClient.instance.dio.post(
        '/api/Mesaj/SendGroupMesaj',
        data: {
          'grupId': grupId,
          'gonderenTckn': gonderenTckn,
          'baslik': baslik,
          'data': data,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Grup mesajı gönderilemedi: ${response.data}');
      }
    } on DioException catch (e) {
      logger.e("SendGroupMesaj hatası: ${e.response?.statusCode} ${e.response?.data}");
      throw Exception('Grup mesajı gönderilemedi: ${e.response?.data ?? e.message}');
    }
  }

  Future<bool> markGroupAsRead({
    required int grupId,
    required String tckn,
  }) async {
    try {
      final response = await DioClient.instance.dio.post(
        '/api/Mesaj/MarkGroupAsRead',
        queryParameters: {
          'grupId': grupId,
          'tckn': tckn,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      logger.e("MarkGroupAsRead hatası: ${e.response?.statusCode} ${e.message}");
      return false;
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

      var response = await ApiService._http.send(request);

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
    if (anyFileOverMediaLimit(files)) {
      logger.w('uploadGallery: 1 GB üzeri dosya, yükleme iptal');
      return false;
    }
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

      var response = await ApiService._http.send(request);

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

  static Future<Map<String, dynamic>> uploadPersonGallery({
    required List<String> tcknOrigList,
    required List<File> files,
  }) async {
    if (anyFileOverMediaLimit(files)) {
      logger.w('uploadPersonGallery: 1 GB üzeri dosya, yükleme iptal');
      return {"success": false, "message": mediaUploadLimitMessage};
    }
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/api/school/upload-person-gallery");

      var request = http.MultipartRequest("POST", uri);

      /// PERSON IDS
      for (var students in tcknOrigList) {
        request.files.add(
          http.MultipartFile.fromString(
            'tcknOrigList',
            students.toString(),
          ),
        );
      }

      /// FILES
      for (var file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            file.path,
          ),
        );
      }

   /* ????  request.headers.addAll({
        "Authorization": "Bearer ${globals.token}",
      });*/

      final streamed = await ApiService._http.send(request);
      final response = await http.Response.fromStream(streamed);

      logger.i("Response Code: ${response.statusCode}");
      logger.d("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return {"success": true};
      }

      return {"success": false, "message": response.body};
    } catch (e) {
      logger.e(e);
      return {"success": false, "message": e.toString()};
    }
  }



  static Future<String?> generateOtp(String tckn, String name) async {
    final url = Uri.parse('${ApiService.baseUrl}/api/otp/generate');
    print("OTP Generate URL: $url");

    try {
      var request = http.MultipartRequest('POST', url)
        ..fields['tckn'] = tckn
        ..fields['name'] = name;

      var response = await ApiService._http.send(request);

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

      var response = await ApiService._http.send(request);
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

      final response = await _http.post(uri);

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

      final response = await _http.get(uri);

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

      final response = await _http.get(uri);
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
      final response = await _http.get(url);

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

  Future<List<dynamic>> getOkulaTanimliOlcekler({
    required String tckn,
  }) async {

    final url = Uri.parse("${ApiService.baseUrl}/api/degerlendirme-olcegi/okula-tanimli?tckn=$tckn");


      final response = await _http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Okula tanımlı ölçekler alınamadı");
    }
  }

  Future<Map<String, dynamic>> getOlcekAyrinti({
    required int olcekId,
    String? tckn,
  }) async {
    final query = tckn != null ? "?tckn=$tckn" : "";

    final url = Uri.parse(
      "${ApiService.baseUrl}/api/degerlendirme-olcegi/ayrinti/$olcekId$query",
    );

    final response = await _http.get(url);

    /// ✅ BAŞARILI
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    /// ⚠️ DAHA ÖNCE DOLDURULMUŞ
    else if (response.statusCode == 400) {
      throw Exception("Bu ölçeği daha önce doldurdunuz");
    }

    /// ❌ BULUNAMADI
    else if (response.statusCode == 404) {
      throw Exception("Ölçek bulunamadı");
    }

    /// ❌ DİĞER HATALAR
    else {
      throw Exception("Ölçek detay alınamadı: ${response.body}");
    }
  }

  Future<void> submitOlcek({
    required String tckn,
    required int olcekId,
    required List<Map<String, dynamic>> cevaplar,
  }) async {
    final url = Uri.parse(
      "${ApiService.baseUrl}/api/degerlendirme-olcegi/cevaplari-kaydet",
    );

    final body = {
      "tckn": tckn,
      "olcekId": olcekId,
      "cevaplar": cevaplar,
    };

    final response = await _http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        return;
      } else {
        throw Exception("Kayıt başarısız");
      }
    } else {
      throw Exception("Hata: ${response.body}");
    }
  }

  Future<dynamic> getKisiSonuclari({
    String? tckn,
    int? olcekId,
    int? personId ,
    int? okulId,
  }) async {
    Map<String, String> queryParams = {};

    if (tckn != null && olcekId != null) {
      queryParams["tckn"] = tckn;
      queryParams["olcekId"] = olcekId.toString();
    } else if (personId != null && okulId != null && olcekId != null) {
      queryParams["personId"] = personId.toString();
      queryParams["okulId"] = okulId.toString();
      queryParams["olcekId"] = olcekId.toString();
    } else {
      throw Exception("Parametre hatası");
    }

    final uri = Uri.parse(
      "${ApiService.baseUrl}/api/degerlendirme-olcegi/kisi-sonuclari",
    ).replace(queryParameters: queryParams);

    final response = await _http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Sonuçlar alınamadı: ${response.body}");
    }
  }

  Future<List<int>> getOlcekSonucPdf({
    required String tckn,
    required int olcekId,
  }) async {
    final uri = Uri.parse(
      "${ApiService.baseUrl}/api/document/olcek-sonuc-dosyasi?tckn=$tckn&olcekId=$olcekId",
    );

    final response = await _http.get(uri);

    if (response.statusCode == 200) {
      return response.bodyBytes; // ✅ PDF byte
    } else {
      //throw Exception("PDF indirilemedi");
      throw Exception(response.body);

    }
  }

////GELISIM
  Future<List<dynamic>?> getGelisimTipleri(int schoolId) async {
    final url = Uri.parse('${ApiService.baseUrl}/api/gelisim/getGelisimTipleri?okulId='+schoolId.toString());

    final response = await _http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gelisim tipleri alınamadı");
    }
  }

  Future<Map<String, dynamic>> addGelisim({
    required String tckn,
    required String deger,
    required int tipId,
  }) async {

    final url = Uri.parse('${ApiService.baseUrl}/api/gelisim/addGelisim');

    final request = http.MultipartRequest("POST", url);

    request.fields['tckn'] = tckn;
    request.fields['deger'] = deger;
    request.fields['tipId'] = tipId.toString();

    final streamed = await ApiService._http.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gelisim eklenemedi");
    }
  }

  Future<List<dynamic>?> getGelisimByTip({
    required String tckn,
    required int tipId,
    String? startDate,
    String? endDate,
  }) async {

    final queryParams = {
      'tckn': tckn,
      'tipId': tipId.toString(),
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    };

    final url = Uri.parse('${ApiService.baseUrl}/api/gelisim/getGelisimByTip')
        .replace(queryParameters: queryParams);

    final response = await _http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gelisim kayıtları alınamadı");
    }
  }

  Future<List<dynamic>?> getGelisimOzet(String tckn) async {

    final url = Uri.parse(
        '$baseUrl/api/gelisim/getGelisimOzet?tckn=$tckn');

    final response = await _http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gelisim özeti alınamadı");
    }
  }

  Future<Map<String, dynamic>> updateGelisim({
    required int id,
    String? deger,
    String? insertDate,
  }) async {

    final url = Uri.parse('${ApiService.baseUrl}/api/gelisim/updateGelisim');

    final request = http.MultipartRequest("PUT", url);

    request.fields['id'] = id.toString();

    if (deger != null) {
      request.fields['deger'] = deger;
    }

    if (insertDate != null) {
      request.fields['insertDate'] = insertDate;
    }

    final streamed = await ApiService._http.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gelisim güncellenemedi");
    }
  }

  Future<Map<String, dynamic>> removeGelisim(int id) async {

    final url = Uri.parse(
        '${ApiService.baseUrl}/api/gelisim/removeGelisim?id=$id');

    final response = await _http.delete(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gelisim silinemedi");
    }
  }

  static String fullStudentTckn(String raw) {
    final t = raw.trim();
    if (t.isEmpty || t.contains('_')) return t;
    var schoolId = globals.globalSchoolId.toString();
    if (schoolId.isEmpty) {
      final parts = globals.kullaniciTCKN.split('_');
      if (parts.length >= 2) schoolId = parts[1];
    }
    return '${t}_${schoolId}_S';
  }

  static List<AcademicRecord> _parseAcademicList(dynamic data) {
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      dynamic inner;
      for (final key in ['data', 'items', 'result', 'kayitlar']) {
        inner = jsonField(data, key);
        if (inner is List) break;
      }
      list = inner is List ? inner : const [];
    } else {
      list = const [];
    }
    final records = list
        .whereType<Map>()
        .map((m) => AcademicRecord.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    records.sort((a, b) {
      final ta = a.tarih ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.tarih ?? DateTime.fromMillisecondsSinceEpoch(0);
      final byDate = tb.compareTo(ta);
      if (byDate != 0) return byDate;
      return b.saatYazi.compareTo(a.saatYazi);
    });
    return records;
  }

  static Future<List<AcademicRecord>> listOzelDers(
    String tckn, {
    int take = 20,
    int skip = 0,
  }) async {
    try {
      final response = await DioClient.instance.dio.get(
        '/api/ozel-ders/list-by-tckn',
        queryParameters: {
          'tckn': tckn,
          'take': take.clamp(1, 100),
          'skip': skip < 0 ? 0 : skip,
        },
      );
      return _parseAcademicList(response.data);
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'ERR_OZELDERS_ETUT_YETKI_YOK');
    }
  }

  static Future<List<AcademicRecord>> listEtut(
    String tckn, {
    int take = 20,
    int skip = 0,
  }) async {
    try {
      final response = await DioClient.instance.dio.get(
        '/api/etut/list-by-tckn',
        queryParameters: {
          'tckn': tckn,
          'take': take.clamp(1, 100),
          'skip': skip < 0 ? 0 : skip,
        },
      );
      return _parseAcademicList(response.data);
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'ERR_OZELDERS_ETUT_YETKI_YOK');
    }
  }

  static Map<String, dynamic> _academicBody({
    required String actorTckn,
    required String studentTckn,
    required String tarih,
    required String saat,
    String? ders,
    String? konu,
    String? aciklama,
    int? id,
    int? dersId,
    int? temaId,
    int? konuId,
    int? soruSayisi,
    int? dogruSayisi,
    int? yanlisSayisi,
    required bool etut,
  }) {
    return {
      'actorTckn': actorTckn,
      'studentTckn': fullStudentTckn(studentTckn),
      'tarih': tarih,
      'saat': saat,
      if (dersId != null) 'dersId': dersId,
      if (temaId != null) 'temaId': temaId,
      if (konuId != null) 'konuId': konuId,
      if (ders != null && ders.isNotEmpty) 'ders': ders,
      if (konu != null && konu.isNotEmpty) 'konu': konu,
      if (aciklama != null) 'aciklama': aciklama,
      if (id != null) 'id': id,
      if (etut) 'soruSayisi': soruSayisi ?? 0,
      if (etut) 'dogruSayisi': dogruSayisi ?? 0,
      if (etut) 'yanlisSayisi': yanlisSayisi ?? 0,
    };
  }

  static Future<Map<String, dynamic>> saveOzelDers({
    required String actorTckn,
    required String studentTckn,
    required String tarih,
    required String saat,
    String? ders,
    String? konu,
    String? aciklama,
    int? id,
    int? dersId,
    int? temaId,
    int? konuId,
  }) async {
    final path = id == null ? '/api/ozel-ders/add' : '/api/ozel-ders/update';
    return _postAcademic(
      path,
      _academicBody(
        actorTckn: actorTckn,
        studentTckn: studentTckn,
        tarih: tarih,
        saat: saat,
        ders: ders,
        konu: konu,
        aciklama: aciklama,
        id: id,
        dersId: dersId,
        temaId: temaId,
        konuId: konuId,
        etut: false,
      ),
    );
  }

  static Future<Map<String, dynamic>> saveEtut({
    required String actorTckn,
    required String studentTckn,
    required String tarih,
    required String saat,
    String? ders,
    String? konu,
    String? aciklama,
    int? id,
    int? dersId,
    int? temaId,
    int? konuId,
    int? soruSayisi,
    int? dogruSayisi,
    int? yanlisSayisi,
  }) async {
    final path = id == null ? '/api/etut/add' : '/api/etut/update';
    return _postAcademic(
      path,
      _academicBody(
        actorTckn: actorTckn,
        studentTckn: studentTckn,
        tarih: tarih,
        saat: saat,
        ders: ders,
        konu: konu,
        aciklama: aciklama,
        id: id,
        dersId: dersId,
        temaId: temaId,
        konuId: konuId,
        soruSayisi: soruSayisi,
        dogruSayisi: dogruSayisi,
        yanlisSayisi: yanlisSayisi,
        etut: true,
      ),
    );
  }

  static Future<Map<String, dynamic>> _postAcademic(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await DioClient.instance.dio.post(path, data: body);
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'message': data?.toString() ?? ''};
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'ERR_IC_SUNUCU_HATASI');
    }
  }

  static Future<Map<String, dynamic>> deleteOzelDers({
    required String actorTckn,
    required int id,
  }) async {
    return _deleteAcademic('/api/ozel-ders/delete', actorTckn, id);
  }

  static Future<Map<String, dynamic>> deleteEtut({
    required String actorTckn,
    required int id,
  }) async {
    return _deleteAcademic('/api/etut/delete', actorTckn, id);
  }

  static Future<Map<String, dynamic>> _deleteAcademic(
    String path,
    String actorTckn,
    int id,
  ) async {
    try {
      final response = await DioClient.instance.dio.delete(
        path,
        queryParameters: {'actorTckn': actorTckn, 'id': id},
      );
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'message': data?.toString() ?? ''};
    } on DioException catch (e) {
      final msg = _extractApiMessage(e.response?.data);
      throw Exception(msg.isNotEmpty ? msg : 'ERR_OZELDERS_ETUT_YETKI_YOK');
    }
  }

}
