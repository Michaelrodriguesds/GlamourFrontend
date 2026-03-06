import 'package:flutter_dotenv/flutter_dotenv.dart';

/// URLs de todos os endpoints da API
class ApiEndpoints {
  ApiEndpoints._();

  /// Base URL lida do .env
  static String get base => dotenv.env['API_URL'] ?? 'http://localhost:5000';

  // ── Auth ───────────────────────────────────
  static String get login        => '$base/api/auth/login';
  static String get verify       => '$base/api/auth/verify';

  // ── Agendamentos ───────────────────────────
  static String get appointments => '$base/api/appointments';
  static String appointmentById(String id) => '$base/api/appointments/$id';
  static String payAppointment(String id)  => '$base/api/appointments/$id/pay';
  static String confirmAppointment(String id) => '$base/api/appointments/$id/confirm';

  // ── Disponibilidade ────────────────────────
  static String get availability      => '$base/api/availability';
  static String get monthAvailability => '$base/api/availability/month';

  // ── Estatísticas ───────────────────────────
  static String get monthlyStats => '$base/api/stats/monthly';
}