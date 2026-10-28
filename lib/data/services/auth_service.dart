import 'package:dio/dio.dart';
import 'api_service.dart';
import 'cache_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/greeting.dart';

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
      // Nome de exibição (opcional): o servidor só envia se configurado.
      final name = response.data['displayName'];
      await _api.saveDisplayName(name is String ? name : null);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Remove o token e limpa o cache local — logout completo
  Future<void> logout() async {
    await _api.clearToken();
    await CacheService.instance.clear();
  }

  /// Nome para a saudação: o nome configurado no servidor, ou, se não
  /// houver, o usuário do login (lido do token). Null se nada disponível.
  Future<String?> displayName() async {
    final saved = await _api.getDisplayName();
    if (saved != null && saved.trim().isNotEmpty) return saved;
    return usernameFromJwt(await _api.getToken());
  }

  /// Verifica se o usuário está autenticado (tem token salvo)
  Future<bool> isLoggedIn() async {
    return await _api.hasToken();
  }
}
