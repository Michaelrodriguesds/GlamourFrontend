import 'appointment_model.dart';

/// Estatísticas completas do mês
class MonthlyStats {
  final int    month;
  final int    year;
  final Summary summary;
  final Revenue revenue;
  final List<ProcedureStat>   procedures;
  final List<LocationStat>    locations;
  final List<PaymentMethodStat> paymentMethods;
  final List<ClientStat>      topClients;
  final List<Appointment>     pendingPayments;
  final List<Appointment>     unconfirmed;

  const MonthlyStats({
    required this.month,
    required this.year,
    required this.summary,
    required this.revenue,
    required this.procedures,
    required this.locations,
    required this.paymentMethods,
    required this.topClients,
    required this.pendingPayments,
    required this.unconfirmed,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      month:          json['period']['month'],
      year:           json['period']['year'],
      summary:        Summary.fromJson(json['summary']),
      revenue:        Revenue.fromJson(json['revenue']),
      procedures:     (json['procedures'] as List)
          .map((e) => ProcedureStat.fromJson(e)).toList(),
      locations:      (json['locations'] as List)
          .map((e) => LocationStat.fromJson(e)).toList(),
      paymentMethods: (json['paymentMethods'] as List)
          .map((e) => PaymentMethodStat.fromJson(e)).toList(),
      topClients:     (json['topClients'] as List)
          .map((e) => ClientStat.fromJson(e)).toList(),
      pendingPayments:(json['pendingPayments'] as List)
          .map((e) => Appointment.fromJson(e)).toList(),
      unconfirmed:    (json['unconfirmed'] as List)
          .map((e) => Appointment.fromJson(e)).toList(),
    );
  }
}

class Summary {
  final int totalAppointments;
  final int paidAppointments;
  final int unpaidAppointments;
  final int confirmedAppointments;
  final int unconfirmedAppointments;

  const Summary({
    required this.totalAppointments,
    required this.paidAppointments,
    required this.unpaidAppointments,
    required this.confirmedAppointments,
    required this.unconfirmedAppointments,
  });

  factory Summary.fromJson(Map<String, dynamic> j) => Summary(
    totalAppointments:       j['totalAppointments'],
    paidAppointments:        j['paidAppointments'],
    unpaidAppointments:      j['unpaidAppointments'],
    confirmedAppointments:   j['confirmedAppointments'],
    unconfirmedAppointments: j['unconfirmedAppointments'],
  );
}

class Revenue {
  final double total;
  final double received;
  final double pending;
  final int    receivedPercentage;

  const Revenue({
    required this.total,
    required this.received,
    required this.pending,
    required this.receivedPercentage,
  });

  factory Revenue.fromJson(Map<String, dynamic> j) => Revenue(
    total:               (j['total']    as num).toDouble(),
    received:            (j['received'] as num).toDouble(),
    pending:             (j['pending']  as num).toDouble(),
    receivedPercentage:  j['receivedPercentage'] ?? 0,
  );
}

class ProcedureStat {
  final String procedure;
  final int    count;
  final double revenue;
  final int    percentage;
  final int    shareOfTotal;

  const ProcedureStat({
    required this.procedure,
    required this.count,
    required this.revenue,
    required this.percentage,
    required this.shareOfTotal,
  });

  factory ProcedureStat.fromJson(Map<String, dynamic> j) => ProcedureStat(
    procedure:    j['procedure']    ?? '',
    count:        j['count']        ?? 0,
    revenue:      (j['revenue'] as num).toDouble(),
    percentage:   j['percentage']   ?? 0,
    shareOfTotal: j['shareOfTotal'] ?? 0,
  );
}

class LocationStat {
  final String location;
  final int    count;
  final double revenue;
  final int    percentage;

  const LocationStat({
    required this.location,
    required this.count,
    required this.revenue,
    required this.percentage,
  });

  factory LocationStat.fromJson(Map<String, dynamic> j) => LocationStat(
    location:   j['location']   ?? '',
    count:      j['count']      ?? 0,
    revenue:    (j['revenue'] as num).toDouble(),
    percentage: j['percentage'] ?? 0,
  );
}

class PaymentMethodStat {
  final String method;
  final int    count;
  final double total;
  final int    percentage;

  const PaymentMethodStat({
    required this.method,
    required this.count,
    required this.total,
    required this.percentage,
  });

  factory PaymentMethodStat.fromJson(Map<String, dynamic> j) => PaymentMethodStat(
    method:     j['method']     ?? '',
    count:      j['count']      ?? 0,
    total:      (j['total'] as num).toDouble(),
    percentage: j['percentage'] ?? 0,
  );
}

class ClientStat {
  final String clientName;
  final int    count;
  final double revenue;
  final double paid;

  const ClientStat({
    required this.clientName,
    required this.count,
    required this.revenue,
    required this.paid,
  });

  factory ClientStat.fromJson(Map<String, dynamic> j) => ClientStat(
    clientName: j['_id']     ?? '',
    count:      j['count']   ?? 0,
    revenue:    (j['revenue'] as num).toDouble(),
    paid:       (j['paid']    as num).toDouble(),
  );
}