/// URLs de todos os endpoints da API
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base URL ────────────────────────────────────────────────────
  static const _base = 'https://glamourbackend-1.onrender.com';
  // static const _base = 'http://localhost:5000'; // dev local

  // ── Auth ────────────────────────────────────────────────────────
  static String get login        => '$_base/api/auth/login';
  static String get verify       => '$_base/api/auth/verify';
  static String get refreshToken => '$_base/api/auth/refresh'; // ← NOVO

  // ── Agendamentos ─────────────────────────────────────────────────
  static String get appointments => '$_base/api/appointments';
  static String appointmentById(String id)     => '$_base/api/appointments/$id';
  static String payAppointment(String id)      => '$_base/api/appointments/$id/pay';
  static String confirmAppointment(String id)  => '$_base/api/appointments/$id/confirm';

  // ── Disponibilidade ───────────────────────────────────────────────
  static String get availability      => '$_base/api/availability';
  static String get monthAvailability => '$_base/api/availability/month';

  // ── Estatísticas ──────────────────────────────────────────────────
  static String get monthlyStats => '$_base/api/stats/monthly';
  static String get trendStats   => '$_base/api/stats/trend';

  // ── Anotações Gerais ──────────────────────────────────────────────
  static String get notes           => '$_base/api/notes';
  static String noteById(String id) => '$_base/api/notes/$id';
  static String pinNote(String id)  => '$_base/api/notes/$id/pin';
}
