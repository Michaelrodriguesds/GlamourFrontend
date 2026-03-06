import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/stats_service.dart';
import '../data/models/stats_model.dart';

class StatsState {
  final MonthlyStats? stats;
  final bool          loading;
  final String?       error;
  final int           month;
  final int           year;

  const StatsState({
    this.stats,
    this.loading = false,
    this.error,
    required this.month,
    required this.year,
  });

  StatsState copyWith({
    MonthlyStats? stats,
    bool?         loading,
    String?       error,
    int?          month,
    int?          year,
    bool          clearError = false,
  }) =>
      StatsState(
        stats:   stats   ?? this.stats,
        loading: loading ?? this.loading,
        error:   clearError ? null : (error ?? this.error),
        month:   month   ?? this.month,
        year:    year    ?? this.year,
      );
}

class StatsNotifier extends StateNotifier<StatsState> {
  final StatsService _service;

  StatsNotifier(this._service)
      : super(StatsState(
            month: DateTime.now().month,
            year:  DateTime.now().year)) {
    // Carrega ao inicializar
    load(DateTime.now().month, DateTime.now().year);
  }

  Future<void> load(int month, int year) async {
    // Evita recarregar enquanto já está carregando o mesmo mês
    if (state.loading &&
        state.month == month &&
        state.year  == year) {
      return;
    }

    state = state.copyWith(
        loading:    true,
        month:      month,
        year:       year,
        clearError: true);

    try {
      final stats = await _service.getMonthly(month, year);
      if (mounted) {
        state = state.copyWith(stats: stats, loading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  /// Força recarregamento mesmo que seja o mesmo mês (ex: ao trocar de aba)
  Future<void> refresh() => load(state.month, state.year);
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(StatsService());
});