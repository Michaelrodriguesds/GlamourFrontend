import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/connectivity_service.dart';

/// Provider que expõe o estado atual de internet (true = online).
/// Atualiza automaticamente quando a conexão muda.
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  final _service = ConnectivityService();
  StreamSubscription<bool>? _sub;

  ConnectivityNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    await _service.init();
    state = _service.isOnline;

    _sub = _service.onStatusChange.listen((online) {
      if (mounted) state = online;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
