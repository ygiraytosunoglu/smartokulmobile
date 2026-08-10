import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../main.dart' show navigatorKey;
import '../screens/login_screen.dart';
import 'api_service.dart';

class AuthInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final Logger _logger = Logger();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    _logger.i('[Dio] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('[Dio] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      _logger.w('[Dio] 401 — token geçersiz, oturum kapatılıyor.');
      await ApiService.clearToken();

      // NavigatorKey üzerinden login ekranına yönlendir
      final context = navigatorKey.currentContext;
      if (context != null) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
    _logger.e('[Dio] Hata: ${err.message}');
    handler.next(err);
  }
}

/// Singleton Dio istemcisi — uygulamanın tamamında bu kullanılır.
class DioClient {
  DioClient._();
  static final DioClient _instance = DioClient._();
  static DioClient get instance => _instance;

  late final Dio dio;

  void init(String baseUrl) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    )..interceptors.addAll([
        AuthInterceptor(),
        LogInterceptor(
          requestBody: true,
          responseBody: false, // prod'da false bırak
          logPrint: (o) => Logger().d(o.toString()),
        ),
      ]);
  }
}
