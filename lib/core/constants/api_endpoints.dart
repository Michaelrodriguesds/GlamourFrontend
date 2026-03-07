/// URLs de todos os endpoints da API
class ApiEndpoints {
  ApiEndpoints._();

  // ── Base URL ────────────────────────────────────────────────────
  // 🌐 Produção (Render):
  static const _base = 'https://glamourbackend-bd05.onrender.com';

  // 💻 Desenvolvimento local (descomente para testar no PC):
  // static const _base = 'http://localhost:5000';

  // ── Auth ────────────────────────────────────────────────────────
  static String get login        => '$_base/api/auth/login';
  static String get verify       => '$_base/api/auth/verify';

  // ── Agendamentos ─────────────────────────────────────────────────
  static String get appointments => '$_base/api/appointments';
  static String appointmentById(String id) => '$_base/api/appointments/$id';
  static String payAppointment(String id)  => '$_base/api/appointments/$id/pay';
  static String confirmAppointment(String id) => '$_base/api/appointments/$id/confirm';

  // ── Disponibilidade ───────────────────────────────────────────────
  static String get availability      => '$_base/api/availability';
  static String get monthAvailability => '$_base/api/availability/month';

  // ── Estatísticas ──────────────────────────────────────────────────
  static String get monthlyStats => '$_base/api/stats/monthly';
}