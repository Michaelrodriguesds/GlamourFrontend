import 'package:intl/intl.dart';

/// Utilitários de data para o app
class AppDateUtils {
  AppDateUtils._();

  static final _dayMonth      = DateFormat('dd/MM', 'pt_BR');
  static final _fullDate      = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _monthYear     = DateFormat('MMMM yyyy', 'pt_BR');
  static final _weekday       = DateFormat('EEEE', 'pt_BR');
  static final _apiFormat     = DateFormat('yyyy-MM-dd');

  /// "01/03"
  static String toDayMonth(DateTime d)  => _dayMonth.format(d);

  /// "01/03/2025"
  static String toFullDate(DateTime d)  => _fullDate.format(d);

  /// "março 2025"
  static String toMonthYear(DateTime d) => _monthYear.format(d);

  /// "sábado"
  static String toWeekday(DateTime d)   => _weekday.format(d);

  /// "2025-03-01" — formato da API
  static String toApi(DateTime d)       => _apiFormat.format(d);

  /// Parse do formato da API
  static DateTime fromApi(String s)     => DateTime.parse(s);

  /// Verifica se é domingo (folga)
  static bool isRestDay(DateTime d)     => d.weekday == DateTime.sunday;

  /// Primeiro dia do mês
  static DateTime firstOfMonth(int month, int year) =>
      DateTime(year, month, 1);

  /// Último dia do mês
  static DateTime lastOfMonth(int month, int year) =>
      DateTime(year, month + 1, 0);

  /// "Hoje", "Amanhã" ou a data formatada
  static String toRelative(DateTime d) {
    final today    = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    if (_isSameDay(d, today))    return 'Hoje';
    if (_isSameDay(d, tomorrow)) return 'Amanhã';
    return toFullDate(d);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}