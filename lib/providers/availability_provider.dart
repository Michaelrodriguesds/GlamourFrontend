import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/availability_service.dart';
import '../data/services/cache_service.dart';
import '../data/models/availability_model.dart';

class AvailabilityState {
  final List<DayAvailability> monthDays;
  final List<TimeSlot>        daySlots;
  final bool                  loading;
  final String?               error;
  final int                   selectedDay;
  final int                   month;
  final int                   year;
  final String?               locationFilter;
  final bool                  fromCache;

  const AvailabilityState({
    this.monthDays      = const [],
    this.daySlots       = const [],
    this.loading        = false,
    this.error,
    this.selectedDay    = 1,
    required this.month,
    required this.year,
    this.locationFilter,
    this.fromCache      = false,
  });

  AvailabilityState copyWith({
    List<DayAvailability>? monthDays,
    List<TimeSlot>?        daySlots,
    bool?                  loading,
    String?                error,
    int?                   selectedDay,
    int?                   month,
    int?                   year,
    String?                locationFilter,
    bool                   clearLocation = false,
    bool?                  fromCache,
  }) => AvailabilityState(
    monthDays:      monthDays      ?? this.monthDays,
    daySlots:       daySlots       ?? this.daySlots,
    loading:        loading        ?? this.loading,
    error:          error,
    selectedDay:    selectedDay    ?? this.selectedDay,
    month:          month          ?? this.month,
    year:           year           ?? this.year,
    locationFilter: clearLocation ? null : locationFilter ?? this.locationFilter,
    fromCache:      fromCache      ?? this.fromCache,
  );
}

class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  final AvailabilityService _service;

  AvailabilityNotifier(this._service)
      : super(AvailabilityState(month: DateTime.now().month, year: DateTime.now().year)) {
    final now = DateTime.now();
    loadMonth(now.month, now.year);
  }

  Future<void> loadMonth(int month, int year, {String? location}) async {
    final cacheKey = CacheService.keyAvailabilityMonth(month, year, location);

    state = state.copyWith(loading: true, month: month, year: year, locationFilter: location);

    // Mostra o cache salvo imediatamente enquanto busca a versão atual
    // no servidor por trás (stale-while-revalidate).
    final cachedFirst = CacheService.instance.get<List>(cacheKey);
    if (cachedFirst != null) {
      final days = cachedFirst.map((e) {
        final m = e as Map<String, dynamic>;
        return DayAvailability.fromJson(m);
      }).toList();
      state = state.copyWith(monthDays: days, loading: true, fromCache: true);
    }

    try {
      final days = await _service.getMonthStatus(month, year, location: location);

      // Salva com TTL curto (15 min) — disponibilidade muda com frequência
      await CacheService.instance.set(
        cacheKey,
        days.map((d) => {
          'day':         d.day,
          'status':      d.status.name,
          'freeSlots':   d.freeSlots,
          'bookedSlots': d.bookedSlots,
        }).toList(),
        ttlMinutes: 15,
      );

      if (mounted) {
        state = state.copyWith(monthDays: days, loading: false, fromCache: false);
        final now        = DateTime.now();
        final isThisMonth = now.month == month && now.year == year;
        await loadDaySlots(
          isThisMonth ? now.day : 1, month, year, location: location,
        );
      }
    } catch (e) {
      // Fallback para cache
      final cached = CacheService.instance.get<List>(cacheKey);
      if (cached != null && mounted) {
        final days = cached.map((e) {
          final m = e as Map<String, dynamic>;
          return DayAvailability.fromJson(m);
        }).toList();
        state = state.copyWith(
          monthDays: days, loading: false,
          fromCache: true, error: 'Sem conexão — calendário em cache',
        );
      } else if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  Future<void> loadDaySlots(int day, int month, int year, {String? location}) async {
    final date = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    final cacheKey = CacheService.keyAvailabilityDay(date, location);

    state = state.copyWith(selectedDay: day, loading: true);

    final cachedFirst = CacheService.instance.get<List>(cacheKey);
    if (cachedFirst != null) {
      final slots = cachedFirst.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(daySlots: slots, loading: true, fromCache: true);
    }

    try {
      final slots = await _service.getDaySlots(date, location: location ?? state.locationFilter);

      await CacheService.instance.set(
        cacheKey,
        slots.map((s) => {
          'time':         s.time,
          'available':    s.available,
          'occupancy':    s.occupancy,
          'maxCapacity':  s.maxCapacity,
          'appointments': s.appointments.map((a) => {
            'id':         a.id,
            'clientName': a.clientName,
            'procedures': a.procedures,
            'location':   a.location,
            'confirmed':  a.confirmed,
          }).toList(),
        }).toList(),
        ttlMinutes: 10,
      );

      if (mounted) state = state.copyWith(daySlots: slots, loading: false, fromCache: false);
    } catch (e) {
      final cached = CacheService.instance.get<List>(cacheKey);
      if (cached != null && mounted) {
        // reconstrói TimeSlot a partir do JSON cacheado
        final slots = cached.map((e) => TimeSlot.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(daySlots: slots, loading: false, fromCache: true);
      } else if (mounted) {
        state = state.copyWith(loading: false, error: e.toString());
      }
    }
  }

  void setLocationFilter(String? location) {
    loadMonth(state.month, state.year, location: location);
  }
}

final availabilityProvider =
    StateNotifierProvider<AvailabilityNotifier, AvailabilityState>((ref) {
  return AvailabilityNotifier(AvailabilityService());
});
