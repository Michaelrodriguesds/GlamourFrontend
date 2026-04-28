import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/appointment_service.dart';
import '../data/services/cache_service.dart';
import '../data/services/connectivity_service.dart';
import '../data/services/offline_queue_service.dart';
import '../data/models/appointment_model.dart';

// ── Filtros ativos ──────────────────────────────────────────────

class AppointmentFilters {
  final int?    month;
  final int?    year;
  final String? location;
  final bool?   paid;
  final bool?   confirmed;
  final String? client;

  const AppointmentFilters({
    this.month, this.year, this.location,
    this.paid, this.confirmed, this.client,
  });

  AppointmentFilters copyWith({
    int?    month, int? year, String? location,
    bool?   paid, bool? confirmed, String? client,
    bool clearLocation = false, bool clearPaid = false,
    bool clearConfirmed = false,
  }) => AppointmentFilters(
    month:     month     ?? this.month,
    year:      year      ?? this.year,
    location:  clearLocation  ? null : location  ?? this.location,
    paid:      clearPaid      ? null : paid       ?? this.paid,
    confirmed: clearConfirmed ? null : confirmed  ?? this.confirmed,
    client:    client    ?? this.client,
  );
}

// ── Estado ──────────────────────────────────────────────────────

class AppointmentsState {
  final List<Appointment>  appointments;
  final bool               loading;
  final String?            error;
  final AppointmentFilters filters;
  final bool               fromCache;
  final DateTime?          cachedAt;
  final int                pendingSyncCount; // agendamentos na fila offline

  const AppointmentsState({
    this.appointments    = const [],
    this.loading         = false,
    this.error,
    this.filters         = const AppointmentFilters(),
    this.fromCache       = false,
    this.cachedAt,
    this.pendingSyncCount = 0,
  });

  AppointmentsState copyWith({
    List<Appointment>?  appointments,
    bool?               loading,
    String?             error,
    AppointmentFilters? filters,
    bool?               fromCache,
    DateTime?           cachedAt,
    int?                pendingSyncCount,
  }) => AppointmentsState(
    appointments:     appointments     ?? this.appointments,
    loading:          loading          ?? this.loading,
    error:            error,
    filters:          filters          ?? this.filters,
    fromCache:        fromCache        ?? this.fromCache,
    cachedAt:         cachedAt         ?? this.cachedAt,
    pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
  );
}

// ── Notifier ────────────────────────────────────────────────────

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  final AppointmentService _service;
  final _queue        = OfflineQueueService();
  final _connectivity = ConnectivityService();

  AppointmentsNotifier(this._service) : super(const AppointmentsState()) {
    _init();
  }

  Future<void> _init() async {
    await _queue.init();
    _updatePendingCount();

    // Quando voltar online, sincroniza automaticamente
    _connectivity.onStatusChange.listen((online) {
      if (online && _queue.hasPending) {
        debugPrint('AppointmentsProvider: voltou online — iniciando sync...');
        _syncQueue();
      }
    });

    final now = DateTime.now();
    await loadMonth(now.month, now.year);
  }

  void _updatePendingCount() {
    if (mounted) {
      state = state.copyWith(pendingSyncCount: _queue.pendingCount);
    }
  }

  // ── Carregamento com cache ─────────────────────────────────────

  Future<void> loadMonth(int month, int year, {String? location}) async {
    state = state.copyWith(
      loading: true,
      filters: state.filters.copyWith(month: month, year: year, location: location),
    );

    final cacheKey = CacheService.keyAppointments(month, year, location);

    try {
      final list = await _service.getAll(month: month, year: year, location: location);

      await CacheService.instance.set(
        cacheKey,
        list.map((a) => a.toJson()).toList(),
      );

      if (mounted) {
        state = state.copyWith(
          appointments:     list,
          loading:          false,
          fromCache:        false,
          cachedAt:         DateTime.now(),
          pendingSyncCount: _queue.pendingCount,
        );
      }
    } catch (e) {
      // Fallback: cache local
      final cached = CacheService.instance.get<List>(cacheKey);
      if (cached != null && mounted) {
        final savedAt = CacheService.instance.savedAt(cacheKey);
        final list    = cached
            .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          appointments:     list,
          loading:          false,
          fromCache:        true,
          cachedAt:         savedAt,
          pendingSyncCount: _queue.pendingCount,
          error:            'Sem conexão — exibindo dados salvos',
        );
      } else if (mounted) {
        state = state.copyWith(
          loading:          false,
          error:            e.toString(),
          pendingSyncCount: _queue.pendingCount,
        );
      }
    }
  }

  Future<void> loadToday({String? location}) async {
    state = state.copyWith(loading: true);
    final today  = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    try {
      final list = await _service.getAll(date: dateStr, location: location);
      if (mounted) state = state.copyWith(appointments: list, loading: false);
    } catch (e) {
      if (mounted) state = state.copyWith(loading: false, error: e.toString());
    }
  }

  // ── CRIAR ─────────────────────────────────────────────────────
  //
  // Se online → envia direto.
  // Se offline → salva na fila e adiciona à lista local com ID temporário.

  Future<void> create(Appointment apt) async {
    if (_connectivity.isOnline) {
      try {
        final created = await _service.create(apt);
        if (mounted) {
          state = state.copyWith(
            appointments: [...state.appointments, created],
          );
        }
        _invalidateCache();
      } catch (e) {
        if (mounted) state = state.copyWith(error: e.toString());
        rethrow;
      }
    } else {
      // ── Modo offline: enfileira e otimisticamente adiciona na UI ──
      final tempId = await _queue.enqueueCreate(apt);

      // Cria cópia com ID temporário para aparecer na lista imediatamente
      final optimistic = Appointment(
        id:            tempId,
        clientName:    apt.clientName,
        procedures:    apt.procedures,
        date:          apt.date,
        time:          apt.time,
        location:      apt.location,
        price:         apt.price,
        paymentMethod: apt.paymentMethod,
        paid:          apt.paid,
        confirmed:     apt.confirmed,
        notes:         apt.notes,
        createdAt:     apt.createdAt,
      );

      if (mounted) {
        state = state.copyWith(
          appointments:     [...state.appointments, optimistic],
          pendingSyncCount: _queue.pendingCount,
          error:            '📶 Sem internet — agendamento salvo e será enviado quando a conexão voltar.',
        );
      }
    }
  }

  // ── ATUALIZAR ─────────────────────────────────────────────────

  Future<void> update(String id, Appointment apt) async {
    if (_connectivity.isOnline) {
      try {
        final updated = await _service.update(id, apt);
        if (mounted) {
          state = state.copyWith(
            appointments: state.appointments
                .map((a) => a.id == id ? updated : a)
                .toList(),
          );
        }
        _invalidateCache();
      } catch (e) {
        if (mounted) state = state.copyWith(error: e.toString());
        rethrow;
      }
    } else {
      await _queue.enqueueUpdate(id, apt);
      // Atualização otimista na UI
      if (mounted) {
        state = state.copyWith(
          appointments: state.appointments
              .map((a) => a.id == id ? apt.copyWith(id: id) : a)
              .toList(),
          pendingSyncCount: _queue.pendingCount,
          error: '📶 Sem internet — alteração salva e será enviada quando a conexão voltar.',
        );
      }
    }
  }

  // ── DELETAR ───────────────────────────────────────────────────

  Future<void> delete(String id) async {
    if (_connectivity.isOnline) {
      try {
        await _service.delete(id);
        if (mounted) {
          state = state.copyWith(
            appointments: state.appointments.where((a) => a.id != id).toList(),
          );
        }
        _invalidateCache();
      } catch (e) {
        if (mounted) state = state.copyWith(error: e.toString());
        rethrow;
      }
    } else {
      await _queue.enqueueDelete(id);
      if (mounted) {
        state = state.copyWith(
          appointments:     state.appointments.where((a) => a.id != id).toList(),
          pendingSyncCount: _queue.pendingCount,
        );
      }
    }
  }

  // ── PAGAR / CONFIRMAR ─────────────────────────────────────────

  Future<void> markAsPaid(String id, {String? paymentMethod}) async {
    try {
      final updated = await _service.markAsPaid(id, paymentMethod: paymentMethod);
      if (mounted) {
        state = state.copyWith(
          appointments: state.appointments
              .map((a) => a.id == id ? updated : a)
              .toList(),
        );
      }
      _invalidateCache();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> confirmAppointment(String id) async {
    try {
      final updated = await _service.confirm(id);
      if (mounted) {
        state = state.copyWith(
          appointments: state.appointments
              .map((a) => a.id == id ? updated : a)
              .toList(),
        );
      }
      _invalidateCache();
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // ── SINCRONIZAR FILA ─────────────────────────────────────────

  Future<int> _syncQueue() async {
    if (!_queue.hasPending || !_connectivity.isOnline) return 0;

    final synced = await _queue.sync(
      createFn: (data) async {
        await _service.create(Appointment.fromJson(data));
      },
      updateFn: (id, data) async {
        await _service.update(id, Appointment.fromJson(data));
      },
      deleteFn: (id) async {
        await _service.delete(id);
      },
    );

    _updatePendingCount();

    if (synced > 0) {
      // Recarrega a lista do servidor para refletir os dados reais
      final f = state.filters;
      if (f.month != null && f.year != null) {
        await loadMonth(f.month!, f.year!, location: f.location);
      }
    }

    return synced;
  }

  /// Força sincronização manual (chamado pelo botão "Sincronizar")
  Future<int> forcSync() => _syncQueue();

  // ── AUXILIARES ────────────────────────────────────────────────

  void _invalidateCache() {
    final f = state.filters;
    if (f.month != null && f.year != null) {
      CacheService.instance.remove(
        CacheService.keyAppointments(f.month!, f.year!, f.location),
      );
    }
  }
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>((ref) {
  return AppointmentsNotifier(AppointmentService());
});
