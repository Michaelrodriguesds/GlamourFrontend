import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/client_service.dart';
import '../data/services/cache_service.dart';
import '../data/models/client_summary_model.dart';

class ClientsState {
  final List<ClientSummary> clients;
  final bool                loading;
  final String?             error;
  final bool                fromCache;
  final DateTime?           cachedAt;

  const ClientsState({
    this.clients   = const [],
    this.loading   = false,
    this.error,
    this.fromCache = false,
    this.cachedAt,
  });

  ClientsState copyWith({
    List<ClientSummary>? clients,
    bool?                 loading,
    String?               error,
    bool?                 fromCache,
    DateTime?             cachedAt,
  }) => ClientsState(
    clients:   clients   ?? this.clients,
    loading:   loading   ?? this.loading,
    error:     error,
    fromCache: fromCache ?? this.fromCache,
    cachedAt:  cachedAt  ?? this.cachedAt,
  );
}

class ClientsNotifier extends StateNotifier<ClientsState> {
  final ClientService _service;

  ClientsNotifier(this._service) : super(const ClientsState()) {
    load();
  }

  /// Carregamento cache-first (stale-while-revalidate):
  /// 1) Mostra o que já estiver salvo em cache IMEDIATAMENTE.
  /// 2) Busca a versão atual no servidor em paralelo, atualizando a
  ///    tela e o cache quando a resposta chegar.
  Future<void> load() async {
    final cacheKey = CacheService.keyClients();

    state = state.copyWith(loading: true, error: null);

    final cached = CacheService.instance.get<List>(cacheKey);
    if (cached != null) {
      final list = cached
          .map((e) => ClientSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        clients:   list,
        loading:   true, // continua carregando: buscando a versão atual
        fromCache: true,
        cachedAt:  CacheService.instance.savedAt(cacheKey),
      );
    }

    try {
      final list = await _service.getAll();
      await CacheService.instance.set(
        cacheKey,
        list.map((c) => c.toJson()).toList(),
        ttlMinutes: 30,
      );
      if (mounted) {
        state = state.copyWith(
          clients:   list,
          loading:   false,
          fromCache: false,
          cachedAt:  DateTime.now(),
        );
      }
    } catch (e) {
      if (cached != null && mounted) {
        state = state.copyWith(loading: false, error: 'Sem conexão — exibindo dados salvos');
      } else if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  Future<void> refresh() => load();
}

final clientsProvider =
    StateNotifierProvider<ClientsNotifier, ClientsState>((ref) {
  return ClientsNotifier(ClientService());
});
