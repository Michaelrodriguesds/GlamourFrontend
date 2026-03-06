import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../core/constants/api_endpoints.dart';

class AuthService {
  final _api = ApiService();

  /// Faz login e salva o token JWT no armazenamento seguro
  Future<void> login(String username, String password) async {
    try {
      final response = await _api.dio.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );
      final token = response.data['token'] as String;
      await _api.saveToken(token);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Remove o token — efetua logout
  Future<void> logout() async {
    await _api.clearToken();
  }

  /// Verifica se o usuário está autenticado
  Future<bool> isLoggedIn() async {
    return await _api.hasToken();
  }
}