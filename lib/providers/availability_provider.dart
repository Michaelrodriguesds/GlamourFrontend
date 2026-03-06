import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/availability_service.dart';
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

  const AvailabilityState({
    this.monthDays      = const [],
    this.daySlots       = const [],
    this.loading        = false,
    this.error,
    this.selectedDay    = 1,
    required this.month,
    required this.year,
    this.locationFilter,
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
  }) =>
      AvailabilityState(
        monthDays:      monthDays      ?? this.monthDays,
        daySlots:       daySlots       ?? this.daySlots,
        loading:        loading        ?? this.loading,
        error:          error,
        selectedDay:    selectedDay    ?? this.selectedDay,
        month:          month          ?? this.month,
        year:           year           ?? this.year,
        locationFilter: clearLocation
            ? null
            : locationFilter ?? this.locationFilter,
      );
}

class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  final AvailabilityService _service;

  AvailabilityNotifier(this._service)
      : super(AvailabilityState(
          month: DateTime.now().month,
          year:  DateTime.now().year,
        )) {
    final now = DateTime.now();
    loadMonth(now.month, now.year);
  }

  Future<void> loadMonth(int month, int year, {String? location}) async {
    state = state.copyWith(
        loading: true, month: month, year: year, locationFilter: location);
    try {
      final days = await _service.getMonthStatus(month, year, location: location);
      state = state.copyWith(monthDays: days, loading: false);

      // Determina qual dia carregar automaticamente:
      // → se estiver vendo o mês atual, carrega o dia de hoje
      // → caso contrário, carrega o dia 1
      final now        = DateTime.now();
      final isThisMonth = now.month == month && now.year == year;
      final dayToLoad  = isThisMonth ? now.day : 1;

      await loadDaySlots(dayToLoad, month, year, location: location);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadDaySlots(
      int day, int month, int year, {String? location}) async {
    final date =
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    state = state.copyWith(selectedDay: day, loading: true);
    try {
      final slots = await _service.getDaySlots(
          date, location: location ?? state.locationFilter);
      state = state.copyWith(daySlots: slots, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
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