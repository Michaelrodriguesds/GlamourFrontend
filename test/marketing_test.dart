import 'package:agenda_flutter/core/utils/marketing_messages.dart';
import 'package:agenda_flutter/data/models/marketing_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('datas e dias da semana', () {
    test('friendlyDate', () {
      expect(friendlyDate('2026-10-31'), 'sábado, 31/10');
      expect(friendlyDate('2026-11-02'), 'segunda-feira, 02/11');
      expect(friendlyDate('data-ruim'), '');
    });

    test('weekdayNameFromIndex usa 0 = domingo', () {
      expect(weekdayNameFromIndex(0), 'domingo');
      expect(weekdayNameFromIndex(2), 'terça-feira');
      expect(weekdayNameFromIndex(6), 'sábado');
      expect(weekdayNameFromIndex(9), '');
    });
  });

  group('mensagens', () {
    test('lembrete do agendamento usa o primeiro nome e todos os dados', () {
      final m = appointmentReminderMessage(
        clientName: 'Juliana Souza',
        date: '2026-10-31',
        time: '09:00',
        procedure: 'Cílios Tufinho',
        location: 'Studio Manilha',
      );
      expect(m, startsWith('Oi, Juliana!'));
      expect(m, contains('amanhã (sábado, 31/10) às 09:00, no Studio Manilha: Cílios Tufinho.'));
      expect(m, contains('remarcar'));
    });

    test('lembrete do agendamento sem local nem horário não deixa buraco', () {
      final m = appointmentReminderMessage(
        clientName: 'Ana', date: '', time: '', procedure: 'Depilação', location: '');
      expect(m, 'Oi, Ana! Passando para lembrar do seu horário amanhã: Depilação. '
          'Se precisar remarcar, é só responder esta mensagem. Até amanhã! 💕');
    });

    test('retorno cita dias e procedimento e oferece sair da lista', () {
      final m = returnReminderMessage(clientName: 'ana paula', procedure: 'Depilação', daysSince: 30);
      expect(m, startsWith('Oi, Ana!'));
      expect(m, contains('30 dias do seu Depilação'));
      expect(m, contains('não quiser mais receber'));
    });

    test('convite da sumida concorda com o dia (nesta terça / neste sábado)', () {
      expect(inactiveInviteMessage(clientName: 'Bia', weakestDayName: 'terça-feira'),
          contains('Nesta terça-feira tenho horários livres'));
      expect(inactiveInviteMessage(clientName: 'Bia', weakestDayName: 'sábado'),
          contains('Neste sábado tenho horários livres'));
      expect(inactiveInviteMessage(clientName: 'Bia'), contains('Nesta semana'));
    });

    test('fiel e nova usam o primeiro nome', () {
      expect(loyalThanksMessage(clientName: 'FERNANDA lima'), startsWith('Oi, Fernanda!'));
      expect(newClientMessage(clientName: 'Débora'), startsWith('Oi, Débora!'));
    });
  });

  group('leitura dos dados do servidor', () {
    test('lembretes', () {
      final d = RemindersData.fromJson({
        'today': '2026-10-30',
        'tomorrow': '2026-10-31',
        'appointments': [
          {'key': 'appt|1', 'type': 'appointment', 'clientName': 'Juliana', 'time': '09:00',
           'procedure': 'Cílios Tufinho', 'location': 'Studio Manilha', 'date': '2026-10-31', 'sent': true},
        ],
        'returns': [
          {'key': 'return|Ana|Depilação|2026-09-30', 'type': 'return', 'clientName': 'Ana',
           'procedure': 'Depilação', 'daysSince': 30, 'returnDays': 30, 'lastDate': '2026-09-30', 'sent': false},
        ],
      });
      expect(d.appointments.single.isAppointment, isTrue);
      expect(d.appointments.single.sent, isTrue);
      expect(d.returns.single.daysSince, 30);
      expect(d.returns.single.isAppointment, isFalse);
    });

    test('movimento com e sem dados', () {
      final m = MovementData.fromJson({
        'days': 90,
        'total': 3,
        'weekdays': [
          {'weekday': 2, 'label': 'Ter', 'count': 1, 'average': 0.5},
        ],
        'weakest': {'weekday': 2, 'label': 'Ter', 'average': 0.5},
        'strongest': {'weekday': 5, 'label': 'Sex', 'average': 3},
        'differencePercent': 83,
        'periods': [
          {'key': 'morning', 'label': 'Manhã', 'count': 2, 'percent': 67},
        ],
      });
      expect(m.weakest!.weekday, 2);
      expect(m.strongest!.average, 3.0);
      expect(m.differencePercent, 83);

      final empty = MovementData.fromJson({'days': 90, 'total': 0, 'weekdays': [], 'weakest': null,
          'strongest': null, 'differencePercent': null, 'periods': []});
      expect(empty.weakest, isNull);
      expect(empty.differencePercent, isNull);
    });

    test('grupos e preferências (campos faltando não quebram)', () {
      final s = SegmentsData.fromJson({
        'loyal': [{'clientName': 'Fiel', 'visits': 3, 'revenue': 300}],
        'inactive': [{'clientName': 'Sumida', 'daysSince': 80}],
      });
      expect(s.loyal.single.visits, 3);
      expect(s.inactive.single.daysSince, 80);
      expect(s.newClients, isEmpty);

      final p = ClientPrefs.fromJson({'clientName': 'Maria', 'remindReturn': false});
      expect(p.remindAppointment, isTrue);
      expect(p.remindReturn, isFalse);
    });
  });
}
