import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/appointment_service.dart';
import '../data/models/appointment_model.dart';

// ── Filtros ativos ──────────────────────────
class AppointmentFilters {
  final int?    month;
  final int?    year;
  final String? location;
  final bool?   paid;
  final bool?   confirmed;
  final String? client;

  const AppointmentFilters({
    this.month,
    this.year,
    this.location,
    this.paid,
    this.confirmed,
    this.client,
  });

  AppointmentFilters copyWith({
    int?    month,
    int?    year,
    String? location,
    bool?   paid,
    bool?   confirmed,
    String? client,
    bool    clearLocation  = false,
    bool    clearPaid      = false,
    bool    clearConfirmed = false,
  }) =>
      AppointmentFilters(
        month:     month     ?? this.month,
        year:      year      ?? this.year,
        location:  clearLocation  ? null : location  ?? this.location,
        paid:      clearPaid      ? null : paid       ?? this.paid,
        confirmed: clearConfirmed ? null : confirmed  ?? this.confirmed,
        client:    client    ?? this.client,
      );
}

// ── Estado da lista ──────────────────────────
class AppointmentsState {
  final List<Appointment> appointments;
  final bool              loading;
  final String?           error;
  final AppointmentFilters filters;

  const AppointmentsState({
    this.appointments = const [],
    this.loading      = false,
    this.error,
    this.filters      = const AppointmentFilters(),
  });

  AppointmentsState copyWith({
    List<Appointment>?   appointments,
    bool?                loading,
    String?              error,
    AppointmentFilters?  filters,
  }) =>
      AppointmentsState(
        appointments: appointments ?? this.appointments,
        loading:      loading      ?? this.loading,
        error:        error,
        filters:      filters      ?? this.filters,
      );
}

// ── Notifier ────────────────────────────────
class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final AppointmentService _service;

  AppointmentsNotifier(this._service) : super(const AppointmentsState()) {
    final now = DateTime.now();
    loadMonth(now.month, now.year);
  }

  Future<void> loadMonth(int month, int year, {String? location}) async {
    state = state.copyWith(
      loading: true,
      filters: state.filters.copyWith(month: month, year: year, location: location),
    );
    try {
      final list = await _service.getAll(
        month:    month,
        year:     year,
        location: location,
      );
      state = state.copyWith(appointments: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadToday({String? location}) async {
    state = state.copyWith(loading: true);
    final today = DateTime.now();
    try {
      final list = await _service.getAll(
        date:     '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}',
        location: location,
      );
      state = state.copyWith(appointments: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> create(Appointment apt) async {
    try {
      final created = await _service.create(apt);
      state = state.copyWith(
        appointments: [...state.appointments, created],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> update(String id, Appointment apt) async {
    try {
      final updated = await _service.update(id, apt);
      state = state.copyWith(
        appointments: state.appointments.map((a) => a.id == id ? updated : a).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _service.delete(id);
      state = state.copyWith(
        appointments: state.appointments.where((a) => a.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> markAsPaid(String id, {String? paymentMethod}) async {
    try {
      final updated = await _service.markAsPaid(id, paymentMethod: paymentMethod);
      state = state.copyWith(
        appointments: state.appointments.map((a) => a.id == id ? updated : a).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> confirmAppointment(String id) async {
    try {
      final updated = await _service.confirm(id);
      state = state.copyWith(
        appointments: state.appointments.map((a) => a.id == id ? updated : a).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// ── Provider global ──────────────────────────
final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
  return AppointmentsNotifier(AppointmentService());
});