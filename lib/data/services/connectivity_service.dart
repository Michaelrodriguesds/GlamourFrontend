import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Serviço que monitora o estado da conexão com a internet.
/// Uso: singleton — instanciar uma vez e ouvir [onStatusChange].
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  final _controller   = StreamController<bool>.broadcast();

  /// Stream de true (online) / false (offline)
  Stream<bool> get onStatusChange => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Deve ser chamado uma vez em main() ou no widget raiz.
  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _hasConnection(results);

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = _hasConnection(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi   ||
        r == ConnectivityResult.ethernet);
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
