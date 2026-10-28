import 'dart:convert';

/// Saudação por horário + nome amigável do usuário.
///
/// Tudo aqui é lógica pura (sem Flutter, sem rede), para poder ser
/// testada com `flutter test` (veja test/greeting_test.dart).

/// "Bom dia" (05h–11h59), "Boa tarde" (12h–17h59), "Boa noite" (18h–04h59).
String greetingForHour(int hour) {
  if (hour >= 5 && hour < 12) return 'Bom dia';
  if (hour >= 12 && hour < 18) return 'Boa tarde';
  return 'Boa noite';
}

String greetingEmojiForHour(int hour) {
  if (hour >= 5 && hour < 12) return '🌸';
  if (hour >= 12 && hour < 18) return '✨';
  return '🌙';
}

/// Transforma o texto bruto (nome configurado ou usuário do login) em um
/// primeiro nome apresentável: "maria.silva" -> "Maria", "ANA" -> "Ana",
/// "joana@email.com" -> "Joana". Retorna null se não sobrar nada útil.
String? friendlyName(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;

  final at = s.indexOf('@');
  if (at > 0) s = s.substring(0, at);

  s = s.replaceAll(RegExp(r'[._\-]+'), ' ');
  s = s.replaceAll(RegExp(r'\d+$'), '').trim();
  if (s.isEmpty) return null;

  var first = s.split(RegExp(r'\s+')).firstWhere((p) => p.isNotEmpty, orElse: () => '');
  // Tira símbolos soltos do começo (ex.: "@maria" -> "maria").
  first = first.replaceAll(RegExp(r'^[^\p{L}]+', unicode: true), '');
  if (first.isEmpty) return null;

  return first[0].toUpperCase() + first.substring(1).toLowerCase();
}

/// Lê o campo `username` do payload de um token JWT (sem validar
/// assinatura — a validação é feita pelo servidor; aqui é só para exibir).
String? usernameFromJwt(String? token) {
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = jsonDecode(payload);
    if (map is Map && map['username'] is String) return map['username'] as String;
  } catch (_) {}
  return null;
}

/// Texto final da saudação. Ex.: "Bom dia, Maria! 🌸" ou, sem nome,
/// "Bom dia! 🌸".
String buildGreeting(DateTime now, String? name) {
  final base  = greetingForHour(now.hour);
  final emoji = greetingEmojiForHour(now.hour);
  final n     = friendlyName(name);
  return n == null ? '$base! $emoji' : '$base, $n! $emoji';
}
