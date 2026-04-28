import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache local simples usando SharedPreferences.
/// Salva JSON com timestamp; expira após [ttlMinutes].
class CacheService {
  static const int _defaultTtl = 60; // 60 minutos

  static CacheService? _instance;
  static CacheService get instance => _instance!;

  final SharedPreferences _prefs;
  CacheService._(this._prefs);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = CacheService._(prefs);
  }

  // ── Chaves de cache ──────────────────────────────────────────────
  static String keyAppointments(int month, int year, [String? location]) =>
      'apts_${year}_${month}${location != null ? '_${location.hashCode}' : ''}';

  static String keyAvailabilityMonth(int month, int year, [String? location]) =>
      'avail_month_${year}_${month}${location != null ? '_${location.hashCode}' : ''}';

  static String keyAvailabilityDay(String date, [String? location]) =>
      'avail_day_${date}${location != null ? '_${location.hashCode}' : ''}';

  static String keyStats(int month, int year) =>
      'stats_${year}_${month}';

  static String keyTrend(int year) =>
      'trend_$year';

  // ── Operações ────────────────────────────────────────────────────

  /// Salva [data] (qualquer objeto serializável) com TTL em minutos.
  Future<void> set(String key, dynamic data, {int ttlMinutes = _defaultTtl}) async {
    final payload = jsonEncode({
      'data':      data,
      'expiresAt': DateTime.now()
          .add(Duration(minutes: ttlMinutes))
          .millisecondsSinceEpoch,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await _prefs.setString(key, payload);
  }

  /// Lê o valor armazenado. Retorna null se expirado ou inexistente.
  T? get<T>(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;

    try {
      final map       = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = map['expiresAt'] as int;

      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        _prefs.remove(key); // limpa expirado
        return null;
      }

      return map['data'] as T;
    } catch (_) {
      return null;
    }
  }

  /// Retorna o timestamp de quando o dado foi salvo (para exibir "atualizado às X").
  DateTime? savedAt(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ms  = map['savedAt'] as int?;
      return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    } catch (_) {
      return null;
    }
  }

  /// Remove uma chave específica.
  Future<void> remove(String key) => _prefs.remove(key);

  /// Limpa todo o cache do app (útil ao fazer logout).
  Future<void> clear() async {
    final keys = _prefs.getKeys().where((k) =>
        k.startsWith('apts_')  ||
        k.startsWith('avail_') ||
        k.startsWith('stats_') ||
        k.startsWith('trend_'));
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
