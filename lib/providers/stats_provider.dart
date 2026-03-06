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
  }) => StatsState(
    stats:   stats   ?? this.stats,
    loading: loading ?? this.loading,
    error:   error,
    month:   month   ?? this.month,
    year:    year    ?? this.year,
  );
}

class StatsNotifier extends StateNotifier<StatsState> {
  final StatsService _service;

  StatsNotifier(this._service)
      : super(StatsState(month: DateTime.now().month, year: DateTime.now().year)) {
    load(DateTime.now().month, DateTime.now().year);
  }

  Future<void> load(int month, int year) async {
    state = state.copyWith(loading: true, month: month, year: year, error: null);
    try {
      final stats = await _service.getMonthly(month, year);
      state = state.copyWith(stats: stats, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(StatsService());
});