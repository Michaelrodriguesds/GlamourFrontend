import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/stats_service.dart';
import '../data/services/cache_service.dart';
import '../data/models/stats_model.dart';

class StatsState {
  final MonthlyStats? stats;
  final bool          loading;
  final String?       error;
  final int           month;
  final int           year;
  final bool          fromCache;
  final DateTime?     cachedAt;

  const StatsState({
    this.stats,
    this.loading   = false,
    this.error,
    required this.month,
    required this.year,
    this.fromCache = false,
    this.cachedAt,
  });

  StatsState copyWith({
    MonthlyStats? stats,
    bool?         loading,
    String?       error,
    int?          month,
    int?          year,
    bool          clearError = false,
    bool?         fromCache,
    DateTime?     cachedAt,
  }) => StatsState(
    stats:     stats     ?? this.stats,
    loading:   loading   ?? this.loading,
    error:     clearError ? null : (error ?? this.error),
    month:     month     ?? this.month,
    year:      year      ?? this.year,
    fromCache: fromCache ?? this.fromCache,
    cachedAt:  cachedAt  ?? this.cachedAt,
  );
}

class StatsNotifier extends StateNotifier<StatsState> {
  final StatsService _service;

  StatsNotifier(this._service)
      : super(StatsState(month: DateTime.now().month, year: DateTime.now().year)) {
    load(DateTime.now().month, DateTime.now().year);
  }

  Future<void> load(int month, int year) async {
    if (state.loading && state.month == month && state.year == year) return;

    final cacheKey = CacheService.keyStats(month, year);

    state = state.copyWith(loading: true, month: month, year: year, clearError: true);

    // Mostra o cache salvo imediatamente (se houver) enquanto busca a
    // versão atual no servidor por trás (stale-while-revalidate).
    final cachedFirst = CacheService.instance.get<Map<String, dynamic>>(cacheKey);
    if (cachedFirst != null) {
      try {
        final stats   = MonthlyStats.fromJson(cachedFirst);
        final savedAt = CacheService.instance.savedAt(cacheKey);
        state = state.copyWith(
          stats: stats, loading: true, // segue carregando: buscando por trás
          fromCache: true, cachedAt: savedAt,
        );
      } catch (_) {
        // cache corrompido/formato antigo — ignora e segue para a busca normal
      }
    }

    try {
      final stats = await _service.getMonthly(month, year);

      // Cache de stats: 30 min
      await CacheService.instance.set(
        cacheKey,
        json.decode(json.encode({
          'period': {'month': month, 'year': year},
          'summary': {
            'totalAppointments':       stats.summary.totalAppointments,
            'paidAppointments':        stats.summary.paidAppointments,
            'unpaidAppointments':      stats.summary.unpaidAppointments,
            'confirmedAppointments':   stats.summary.confirmedAppointments,
            'unconfirmedAppointments': stats.summary.unconfirmedAppointments,
          },
          'revenue': {
            'total':              stats.revenue.total,
            'received':           stats.revenue.received,
            'pending':            stats.revenue.pending,
            'receivedPercentage': stats.revenue.receivedPercentage,
          },
          'procedures':     stats.procedures.map((p) => {'procedure': p.procedure, 'count': p.count, 'revenue': p.revenue, 'percentage': p.percentage, 'shareOfTotal': p.shareOfTotal}).toList(),
          'locations':      stats.locations.map((l) => {'location': l.location, 'count': l.count, 'revenue': l.revenue, 'percentage': l.percentage}).toList(),
          'paymentMethods': stats.paymentMethods.map((m) => {'method': m.method, 'count': m.count, 'total': m.total, 'percentage': m.percentage}).toList(),
          'topClients':     stats.topClients.map((c) => {'_id': c.clientName, 'count': c.count, 'revenue': c.revenue, 'paid': c.paid}).toList(),
          'pendingPayments': [],
          'unconfirmed':    [],
        })),
        ttlMinutes: 30,
      );

      if (mounted) {
        state = state.copyWith(
          stats: stats, loading: false,
          fromCache: false, cachedAt: DateTime.now(),
        );
      }
    } catch (e) {
      final cached = CacheService.instance.get<Map<String, dynamic>>(cacheKey);
      if (cached != null && mounted) {
        try {
          final stats   = MonthlyStats.fromJson(cached);
          final savedAt = CacheService.instance.savedAt(cacheKey);
          state = state.copyWith(
            stats: stats, loading: false,
            fromCache: true, cachedAt: savedAt,
            error: 'Sem conexão — dados salvos',
          );
        } catch (_) {
          state = state.copyWith(loading: false, error: e.toString());
        }
      } else if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  Future<void> refresh() => load(state.month, state.year);
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(StatsService());
});
