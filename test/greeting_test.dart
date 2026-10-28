import 'dart:convert';

import 'package:agenda_flutter/core/utils/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

String _jwt(Map<String, dynamic> payload) {
  String b64(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');
  return '${b64('{"alg":"HS256","typ":"JWT"}')}.${b64(jsonEncode(payload))}.assinatura';
}

void main() {
  group('greetingForHour', () {
    test('manhã, tarde e noite', () {
      expect(greetingForHour(5),  'Bom dia');
      expect(greetingForHour(11), 'Bom dia');
      expect(greetingForHour(12), 'Boa tarde');
      expect(greetingForHour(17), 'Boa tarde');
      expect(greetingForHour(18), 'Boa noite');
      expect(greetingForHour(23), 'Boa noite');
    });

    test('madrugada é "Boa noite"', () {
      expect(greetingForHour(0), 'Boa noite');
      expect(greetingForHour(4), 'Boa noite');
    });
  });

  group('friendlyName', () {
    test('formata nomes comuns', () {
      expect(friendlyName('maria'), 'Maria');
      expect(friendlyName('ANA'), 'Ana');
      expect(friendlyName('maria.silva'), 'Maria');
      expect(friendlyName('joana@email.com'), 'Joana');
      expect(friendlyName('  Beatriz Souza  '), 'Beatriz');
      expect(friendlyName('lucia123'), 'Lucia');
      expect(friendlyName('érica'), 'Érica');
      expect(friendlyName('@maria'), 'Maria');
    });

    test('devolve null quando não há nome útil', () {
      expect(friendlyName(null), isNull);
      expect(friendlyName(''), isNull);
      expect(friendlyName('   '), isNull);
      expect(friendlyName('123'), isNull);
      expect(friendlyName('@@@'), isNull);
    });
  });

  group('usernameFromJwt', () {
    test('lê o username do token', () {
      expect(usernameFromJwt(_jwt({'username': 'maria', 'exp': 1})), 'maria');
    });

    test('token inválido ou sem username devolve null', () {
      expect(usernameFromJwt(null), isNull);
      expect(usernameFromJwt('abc'), isNull);
      expect(usernameFromJwt('a.b.c'), isNull);
      expect(usernameFromJwt(_jwt({'outro': 'x'})), isNull);
    });
  });

  group('buildGreeting', () {
    test('com nome', () {
      expect(buildGreeting(DateTime(2026, 10, 27, 9), 'maria'), 'Bom dia, Maria! 🌸');
      expect(buildGreeting(DateTime(2026, 10, 27, 15), 'maria'), 'Boa tarde, Maria! ✨');
      expect(buildGreeting(DateTime(2026, 10, 27, 20), 'maria'), 'Boa noite, Maria! 🌙');
    });

    test('sem nome mantém o formato antigo', () {
      expect(buildGreeting(DateTime(2026, 10, 27, 9), null), 'Bom dia! 🌸');
      expect(buildGreeting(DateTime(2026, 10, 27, 15), ''), 'Boa tarde! ✨');
    });
  });
}
