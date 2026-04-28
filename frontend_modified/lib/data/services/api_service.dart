import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_endpoints.dart';

/// HTTP client centralizado com:
///   • Interceptor de JWT automático
///   • Refresh token silencioso (POST /api/auth/refresh)
///   • Mensagens de erro em português
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

  // Controla se já estamos tentando refresh para evitar loop infinito
  bool _isRefreshing = false;

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        // ── Adiciona token em toda requisição ─────────────────────
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

        // ── Refresh token silencioso ao receber 401 ───────────────
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshed = await _tryRefreshToken();
              if (refreshed) {
                // Repete a requisição original com o novo token
                final newToken = await _storage.read(key: _tokenKey);
                final opts     = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';

                final response = await dio.fetch(opts);
                _isRefreshing  = false;
                return handler.resolve(response);
              }
            } catch (_) {}

            _isRefreshing = false;
            await clearToken(); // refresh falhou → faz logout
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Tenta renovar o token chamando POST /api/auth/refresh.
  /// Retorna true se conseguiu, false caso contrário.
  Future<bool> _tryRefreshToken() async {
    try {
      final currentToken = await _storage.read(key: _tokenKey);
      if (currentToken == null) return false;

      // Usa um Dio limpo (sem interceptor) para não entrar em loop
      final tempDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      ));

      final response = await tempDio.post(ApiEndpoints.refreshToken);
      final newToken = response.data['token'] as String?;

      if (newToken != null && newToken.isNotEmpty) {
        await saveToken(newToken);
        debugPrint('ApiService: token renovado com sucesso');
        return true;
      }
    } catch (e) {
      debugPrint('ApiService: refresh falhou — $e');
    }
    return false;
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
      case DioExceptionType.sendTimeout:
        return 'Servidor demorou para responder. Tente novamente.';
      case DioExceptionType.receiveTimeout:
        return 'Resposta demorou muito. Tente novamente.';
      case DioExceptionType.connectionError:
        return 'Sem conexão com a internet.';
      case DioExceptionType.cancel:
        return 'Requisição cancelada.';
      default:
        return e.message ?? 'Erro de rede';
    }
  }
}
