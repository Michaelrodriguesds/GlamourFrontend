/// Resumo agregado de um cliente, vindo direto do endpoint
/// GET /api/clients (agregação no MongoDB — nunca truncado por volume
/// de agendamentos, ao contrário da antiga abordagem que montava essa
/// lista no app a partir de GET /appointments sem filtro).
class ClientSummary {
  final String   clientName;
  final int      count;
  final double   totalRevenue;
  final double   receivedRevenue;
  final double   pendingRevenue;
  final int      pendingCount;
  final int      unconfirmedCount;
  final DateTime? lastAppointment;

  const ClientSummary({
    required this.clientName,
    required this.count,
    required this.totalRevenue,
    required this.receivedRevenue,
    required this.pendingRevenue,
    required this.pendingCount,
    required this.unconfirmedCount,
    this.lastAppointment,
  });

  factory ClientSummary.fromJson(Map<String, dynamic> j) => ClientSummary(
    clientName:       j['clientName']       ?? '',
    count:            j['count']            ?? 0,
    totalRevenue:     (j['totalRevenue']    as num? ?? 0).toDouble(),
    receivedRevenue:  (j['receivedRevenue'] as num? ?? 0).toDouble(),
    pendingRevenue:   (j['pendingRevenue']  as num? ?? 0).toDouble(),
    pendingCount:     j['pendingCount']      ?? 0,
    unconfirmedCount: j['unconfirmedCount']  ?? 0,
    lastAppointment:  j['lastAppointment'] != null
        ? DateTime.parse(j['lastAppointment'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'clientName':       clientName,
    'count':            count,
    'totalRevenue':     totalRevenue,
    'receivedRevenue':  receivedRevenue,
    'pendingRevenue':   pendingRevenue,
    'pendingCount':     pendingCount,
    'unconfirmedCount': unconfirmedCount,
    'lastAppointment':  lastAppointment?.toIso8601String(),
  };
}
