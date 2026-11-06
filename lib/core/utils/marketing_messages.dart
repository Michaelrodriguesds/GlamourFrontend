import 'greeting.dart';

/// Textos prontos da aba "Clientes & Marketing".
///
/// A dona toca em "Copiar mensagem" e cola no WhatsApp da cliente.
/// Lógica pura (sem Flutter), testada em test/marketing_messages_test.dart.
/// Para mudar um texto, altere aqui e publique o frontend.

const _weekdayNames = [
  'segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira',
  'sexta-feira', 'sábado', 'domingo',
];

/// Nome da semana a partir do índice do servidor (0 = domingo … 6 = sábado).
String weekdayNameFromIndex(int weekday) {
  if (weekday < 0 || weekday > 6) return '';
  // DateTime: 1 = segunda … 7 = domingo.
  final dartWeekday = weekday == 0 ? 7 : weekday;
  return _weekdayNames[dartWeekday - 1];
}

/// "2026-10-31" -> "sábado, 31/10". Texto vazio se a data for inválida.
String friendlyDate(String isoDate) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(isoDate);
  if (m == null) return '';
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final date = DateTime.utc(y, mo, d);
  return '${_weekdayNames[date.weekday - 1]}, ${m.group(3)}/${m.group(2)}';
}

/// Primeiro nome para a mensagem ("Ana Paula" -> "Ana").
String _first(String clientName) => friendlyName(clientName) ?? clientName.trim();

/// Lembrete da cliente agendada para amanhã.
String appointmentReminderMessage({
  required String clientName,
  required String date,
  required String time,
  required String procedure,
  required String location,
}) {
  final when = friendlyDate(date);
  final buffer = StringBuffer('Oi, ${_first(clientName)}! Passando para lembrar do seu horário amanhã');
  if (when.isNotEmpty) buffer.write(' ($when)');
  if (time.isNotEmpty) buffer.write(' às $time');
  if (location.isNotEmpty) buffer.write(', no $location');
  if (procedure.isNotEmpty) buffer.write(': $procedure');
  buffer.write('. Se precisar remarcar, é só responder esta mensagem. Até amanhã! 💕');
  return buffer.toString();
}

/// "Hora de refazer".
String returnReminderMessage({
  required String clientName,
  required String procedure,
  required int daysSince,
}) =>
    'Oi, ${_first(clientName)}! ✨ Já faz $daysSince dias do seu $procedure — '
    'está chegando a hora da manutenção. Quer que eu reserve um horário pra você? '
    'É só responder aqui. 💕\n\n(Se não quiser mais receber esses lembretes, é só avisar.)';

/// Agradecimento para cliente fiel.
String loyalThanksMessage({required String clientName}) =>
    'Oi, ${_first(clientName)}! 💕 Passando para agradecer pela confiança de sempre. '
    'Você é especial pra mim! Na sua próxima visita tem um mimo te esperando. ✨';

/// Resgate de cliente sumida, convidando para o dia mais fraco (se houver).
String inactiveInviteMessage({required String clientName, String weakestDayName = ''}) {
  final String day;
  if (weakestDayName.isEmpty) {
    day = 'Nesta semana';
  } else if (weakestDayName == 'sábado' || weakestDayName == 'domingo') {
    day = 'Neste $weakestDayName';
  } else {
    day = 'Nesta $weakestDayName';
  }
  return 'Oi, ${_first(clientName)}! 🌸 Sentimos sua falta por aqui. '
      '$day tenho horários livres — quer garantir o seu? É só responder esta mensagem. 💕';
}

/// Convite para cliente nova voltar.
String newClientMessage({required String clientName}) =>
    'Oi, ${_first(clientName)}! ✨ Foi um prazer te atender. '
    'Quando quiser agendar de novo, é só me chamar aqui que reservo um horário pra você. 💕';
