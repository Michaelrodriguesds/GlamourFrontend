/// Status de disponibilidade de um dia no calendário
enum DayStatus { free, partial, full, rest }

/// Informação de um dia do mês para pintar o calendário
class DayAvailability {
  final int       day;
  final DayStatus status;
  final int       freeSlots;
  final int       bookedSlots;

  const DayAvailability({
    required this.day,
    required this.status,
    required this.freeSlots,
    required this.bookedSlots,
  });

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    return DayAvailability(
      day:         json['day'],
      status:      _parseStatus(json['status']),
      freeSlots:   json['freeSlots']   ?? 0,
      bookedSlots: json['bookedSlots'] ?? 0,
    );
  }

  static DayStatus _parseStatus(String s) {
    switch (s) {
      case 'free':    return DayStatus.free;
      case 'partial': return DayStatus.partial;
      case 'full':    return DayStatus.full;
      default:        return DayStatus.rest;
    }
  }
}

// ── Info de um agendamento dentro do slot ────────────────────────

class AppointmentInfo {
  final String       id;
  final String       clientName;
  final List<String> procedures;
  final String?      location;
  final bool         confirmed;

  const AppointmentInfo({
    required this.id,
    required this.clientName,
    required this.procedures,
    this.location,
    required this.confirmed,
  });

  /// String de exibição: "Cílios + Sobrancelha"
  String get procedure =>
      procedures.isNotEmpty ? procedures.join(' + ') : '';

  factory AppointmentInfo.fromJson(Map<String, dynamic> json) {
    List<String> procs = const [];
    final rawProcs = json['procedures'];
    if (rawProcs != null && rawProcs is List && rawProcs.isNotEmpty) {
      procs = List<String>.from(rawProcs);
    } else {
      final legacy = json['procedure']?.toString() ?? '';
      if (legacy.isNotEmpty) {
        procs = legacy
            .split(' + ')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    return AppointmentInfo(
      id:         json['id']?.toString()  ?? '',
      clientName: json['clientName']      ?? '',
      procedures: procs,
      location:   json['location'],
      confirmed:  json['confirmed']       ?? false,
    );
  }
}

// ── Slot de horário — agora suporta múltiplos agendamentos ────────

class TimeSlot {
  final String                time;
  final bool                  available;
  final int                   occupancy;    // quantos agendamentos há
  final int                   maxCapacity;  // capacidade máxima (2)
  final List<AppointmentInfo> appointments; // lista real de agendamentos

  const TimeSlot({
    required this.time,
    required this.available,
    this.occupancy    = 0,
    this.maxCapacity  = 2,
    this.appointments = const [],
  });

  // ── Getters backward-compat (primeiro agendamento do slot) ────

  /// Retorna true se há pelo menos um agendamento no slot
  bool get isBooked => appointments.isNotEmpty;

  /// Retorna true se há exatamente 2 agendamentos (slot duplo completo)
  bool get isDouble => appointments.length >= 2;

  String?      get clientName    => appointments.isNotEmpty ? appointments[0].clientName : null;
  List<String> get procedures    => appointments.isNotEmpty ? appointments[0].procedures : const [];
  String       get procedure     => appointments.isNotEmpty ? appointments[0].procedure  : '';
  String?      get location      => appointments.isNotEmpty ? appointments[0].location   : null;
  String?      get appointmentId => appointments.isNotEmpty ? appointments[0].id         : null;
  bool         get confirmed     => appointments.isNotEmpty ? appointments[0].confirmed  : false;

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    List<AppointmentInfo> apts = const [];

    // Formato novo: campo `appointments` (array)
    final rawApts = json['appointments'];
    if (rawApts != null && rawApts is List && rawApts.isNotEmpty) {
      apts = rawApts
          .map((e) => AppointmentInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      // Backward compat: campo `appointment` (objeto único)
      final apt = json['appointment'];
      if (apt != null) {
        apts = [AppointmentInfo.fromJson(apt as Map<String, dynamic>)];
      }
    }

    return TimeSlot(
      time:         json['time'],
      available:    json['available']   ?? true,
      occupancy:    json['occupancy']   ?? apts.length,
      maxCapacity:  json['maxCapacity'] ?? 2,
      appointments: apts,
    );
  }
}
