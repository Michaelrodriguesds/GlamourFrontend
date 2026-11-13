// Modelos da aba "Clientes & Marketing" (Estatísticas).
// Os dados vêm de /api/marketing/* — veja docs/MARKETING.md.

int _int(dynamic v) => v is num ? v.toInt() : 0;
double _double(dynamic v) => v is num ? v.toDouble() : 0;
String _str(dynamic v) => v is String ? v : '';

/// Um lembrete da lista "Para enviar hoje".
/// [type] = 'appointment' (agendada para amanhã) ou 'return' (hora de refazer).
class ReminderItem {
  final String key;
  final String type;
  final String clientName;
  final String procedure;
  // Agendada para amanhã
  final String date;      // AAAA-MM-DD
  final String time;      // HH:MM
  final String location;
  // Hora de refazer
  final String lastDate;  // AAAA-MM-DD
  final int    daysSince;
  final int    returnDays;
  final bool   sent;

  const ReminderItem({
    required this.key,
    required this.type,
    required this.clientName,
    required this.procedure,
    this.date = '',
    this.time = '',
    this.location = '',
    this.lastDate = '',
    this.daysSince = 0,
    this.returnDays = 0,
    this.sent = false,
  });

  bool get isAppointment => type == 'appointment';

  factory ReminderItem.fromJson(Map<String, dynamic> j) => ReminderItem(
        key:        _str(j['key']),
        type:       _str(j['type']),
        clientName: _str(j['clientName']),
        procedure:  _str(j['procedure']),
        date:       _str(j['date']),
        time:       _str(j['time']),
        location:   _str(j['location']),
        lastDate:   _str(j['lastDate']),
        daysSince:  _int(j['daysSince']),
        returnDays: _int(j['returnDays']),
        sent:       j['sent'] == true,
      );
}

class RemindersData {
  final String today;
  final String tomorrow;
  final List<ReminderItem> appointments;
  final List<ReminderItem> returns;

  const RemindersData({
    required this.today,
    required this.tomorrow,
    required this.appointments,
    required this.returns,
  });

  factory RemindersData.fromJson(Map<String, dynamic> j) => RemindersData(
        today:        _str(j['today']),
        tomorrow:     _str(j['tomorrow']),
        appointments: _list(j['appointments']).map(ReminderItem.fromJson).toList(),
        returns:      _list(j['returns']).map(ReminderItem.fromJson).toList(),
      );
}

class WeekdayStat {
  final int    weekday; // 0 = domingo … 6 = sábado
  final String label;
  final int    count;
  final double average;

  const WeekdayStat({required this.weekday, required this.label, required this.count, required this.average});

  factory WeekdayStat.fromJson(Map<String, dynamic> j) => WeekdayStat(
        weekday: _int(j['weekday']),
        label:   _str(j['label']),
        count:   _int(j['count']),
        average: _double(j['average']),
      );
}

class PeriodStat {
  final String key;
  final String label;
  final int    count;
  final int    percent;

  const PeriodStat({required this.key, required this.label, required this.count, required this.percent});

  factory PeriodStat.fromJson(Map<String, dynamic> j) => PeriodStat(
        key:     _str(j['key']),
        label:   _str(j['label']),
        count:   _int(j['count']),
        percent: _int(j['percent']),
      );
}

class MovementData {
  final int days;
  final int total;
  final List<WeekdayStat> weekdays;
  final WeekdayStat? weakest;
  final WeekdayStat? strongest;
  final int? differencePercent;
  final List<PeriodStat> periods;

  const MovementData({
    required this.days,
    required this.total,
    required this.weekdays,
    required this.weakest,
    required this.strongest,
    required this.differencePercent,
    required this.periods,
  });

  factory MovementData.fromJson(Map<String, dynamic> j) => MovementData(
        days:     _int(j['days']),
        total:    _int(j['total']),
        weekdays: _list(j['weekdays']).map(WeekdayStat.fromJson).toList(),
        weakest:  j['weakest'] is Map ? WeekdayStat.fromJson(Map<String, dynamic>.from(j['weakest'])) : null,
        strongest: j['strongest'] is Map ? WeekdayStat.fromJson(Map<String, dynamic>.from(j['strongest'])) : null,
        differencePercent: j['differencePercent'] is num ? (j['differencePercent'] as num).toInt() : null,
        periods:  _list(j['periods']).map(PeriodStat.fromJson).toList(),
      );
}

/// Cliente de um grupo (fiéis, sumidas ou novas). Nem todo campo vem
/// em todo grupo: [visits]/[revenue] nas fiéis, [daysSince] nas sumidas
/// e novas.
class SegmentClient {
  final String clientName;
  final int    visits;
  final double revenue;
  final int    daysSince;
  final String lastDate;
  final String firstDate;

  const SegmentClient({
    required this.clientName,
    this.visits = 0,
    this.revenue = 0,
    this.daysSince = 0,
    this.lastDate = '',
    this.firstDate = '',
  });

  factory SegmentClient.fromJson(Map<String, dynamic> j) => SegmentClient(
        clientName: _str(j['clientName']),
        visits:     _int(j['visits']),
        revenue:    _double(j['revenue']),
        daysSince:  _int(j['daysSince']),
        lastDate:   _str(j['lastDate']),
        firstDate:  _str(j['firstDate']),
      );
}

class SegmentsData {
  final List<SegmentClient> loyal;
  final List<SegmentClient> inactive;
  final List<SegmentClient> newClients;

  const SegmentsData({required this.loyal, required this.inactive, required this.newClients});

  factory SegmentsData.fromJson(Map<String, dynamic> j) => SegmentsData(
        loyal:      _list(j['loyal']).map(SegmentClient.fromJson).toList(),
        inactive:   _list(j['inactive']).map(SegmentClient.fromJson).toList(),
        newClients: _list(j['newClients']).map(SegmentClient.fromJson).toList(),
      );
}

/// Caixinhas da ficha da cliente.
class ClientPrefs {
  final String clientName;
  final bool   remindAppointment;
  final bool   remindReturn;

  const ClientPrefs({required this.clientName, required this.remindAppointment, required this.remindReturn});

  factory ClientPrefs.fromJson(Map<String, dynamic> j) => ClientPrefs(
        clientName:        _str(j['clientName']),
        remindAppointment: j['remindAppointment'] != false,
        remindReturn:      j['remindReturn'] != false,
      );
}

List<Map<String, dynamic>> _list(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];
