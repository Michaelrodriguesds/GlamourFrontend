import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider simples de refresh — cada vez que é incrementado,
/// as telas que o assistem recarregam os dados.
/// O main.dart chama refresh() ao trocar de aba.
final refreshProvider = StateProvider<int>((ref) => 0);

extension RefreshExt on Ref {
  void triggerRefresh() {
    // Incrementa para notificar todas as telas que assistem este provider
  }
}