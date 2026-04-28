import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/auth_service.dart';

// ── Estados possíveis ──────────────────────
enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String?    error;

  const AuthState({required this.status, this.error});

  AuthState copyWith({AuthStatus? status, String? error}) =>
      AuthState(status: status ?? this.status, error: error);
}

// ── Notifier ────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service)
      : super(const AuthState(status: AuthStatus.checking)) {
    _check();
  }

  /// Verifica se já está logado ao abrir o app
  Future<void> _check() async {
    final logged = await _service.isLoggedIn();
    state = AuthState(
      status: logged ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> login(String username, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.checking, error: null);
      await _service.login(username, password);
      state = state.copyWith(status: AuthStatus.authenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Provider global ──────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});