import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// HTTP client centralizado com interceptor de JWT
class ApiService {
  static const _tokenKey = 'jwt_token';

  static final _storage = const FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'glamour_agenda', publicKey: 'glamour'),
  );

  // ── Singleton ──────────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupInterceptors();
  }

  final Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 40),
    receiveTimeout: const Duration(seconds: 40),
    headers: {'Content-Type': 'application/json'},
  ));

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _storage.read(key: _tokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            debugPrint('ApiService: erro ao ler token: $e');
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  Future<bool> hasToken() async {
    try {
      final t = await _storage.read(key: _tokenKey);
      return t != null && t.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map) {
        return data['message'] ?? data['error'] ?? 'Erro desconhecido';
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Servidor demorou para responder. Tente novamente em alguns segundos.';
      case DioExceptionType.receiveTimeout:
        return 'Servidor demorou para responder. Tente novamente.';
      case DioExceptionType.connectionError:
        return 'Sem conexão com o servidor.';
      default:
        return e.message ?? 'Erro de rede';
    }
  }
}