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

/// Informação de um slot de horário no dia
class TimeSlot {
  final String  time;
  final bool    available;
  final String? clientName;
  final String? procedure;
  final String? location;
  final String? appointmentId;
  final bool    confirmed;   // ← novo: false = aguardando confirmação

  const TimeSlot({
    required this.time,
    required this.available,
    this.clientName,
    this.procedure,
    this.location,
    this.appointmentId,
    this.confirmed = false,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    final apt = json['appointment'];
    return TimeSlot(
      time:          json['time'],
      available:     json['available'] ?? true,
      clientName:    apt?['clientName'],
      procedure:     apt?['procedure'],
      location:      apt?['location'],
      appointmentId: apt?['id'],
      confirmed:     apt?['confirmed'] ?? false,
    );
  }
}