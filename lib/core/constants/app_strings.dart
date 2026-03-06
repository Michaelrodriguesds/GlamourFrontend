/// Textos e labels do app centralizados
class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────────
  static const String appName     = 'Glamour Agenda';
  static const String appSubtitle = 'Agenda Estética';

  // ── Procedimentos ──────────────────────────
  static const List<String> procedures = [
    'Cílios',
    'Sobrancelha',
    'Depilação',
    'Design Completo',
  ];

  // ── Ícones por procedimento ────────────────
  static const Map<String, String> procedureIcons = {
    'Cílios':           '👁️',
    'Sobrancelha':      '🌙',
    'Depilação':        '✨',
    'Design Completo':  '💎',
  };

   // ── Locais de atendimento ──────────────────
  static const List<String> locations = [
    'Studio Manilha',    
    'Studio Guaxindiba', 
  ];

  // ── Formas de pagamento ────────────────────
  static const List<String> paymentMethods = [
    'PIX',
    'Cartão',
    'Dinheiro',
    'A combinar',
  ];

  // ── Navegação ──────────────────────────────
  static const String navHome       = 'Início';
  static const String navCalendar   = 'Calendário';
  static const String navNew        = 'Novo';
  static const String navStats      = 'Stats';
  static const String navClients    = 'Clientes';

  // ── Formulário ─────────────────────────────
  static const String labelClientName   = 'Nome da cliente';
  static const String labelProcedure    = 'Procedimento';
  static const String labelDate         = 'Data';
  static const String labelTime         = 'Horário';
  static const String labelLocation     = 'Local';
  static const String labelPrice        = 'Valor (R\$)';
  static const String labelPayMethod    = 'Forma de pagamento';
  static const String labelPaid         = 'Pagamento realizado';
  static const String labelConfirmed    = 'Cliente confirmada';
  static const String labelNotes        = 'Observações';

  // ── Status ─────────────────────────────────
  static const String statusPaid        = '✓ Pago';
  static const String statusPending     = 'Pendente';
  static const String statusConfirmed   = '✓ Confirmada';
  static const String statusWaiting     = 'Aguardando';
  static const String statusFree        = 'Livre';
  static const String statusFull        = 'Lotado';
  static const String statusPartial     = 'Parcial';
  static const String statusRest        = 'Folga';
}