import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/marketing_messages.dart';
import '../../../data/models/marketing_model.dart';
import '../../../data/services/marketing_service.dart';

// ── Aba "Clientes & Marketing" (dentro de Estatísticas) ─────────────
//
// Custo zero: o app NÃO envia mensagens. Ele mostra quem precisa de
// lembrete, monta o texto e copia; a dona cola no WhatsApp da cliente.
// Seções: Para enviar hoje · Movimento da semana · Suas clientes ·
// Campanha sugerida. Regras e prazos: backend src/config/marketing.js.

class MarketingTab extends StatefulWidget {
  const MarketingTab({super.key});

  @override
  State<MarketingTab> createState() => _MarketingTabState();
}

class _MarketingTabState extends State<MarketingTab> {
  final _service = MarketingService();

  RemindersData? _reminders;
  MovementData?  _movement;
  SegmentsData?  _segments;
  bool    _loading = true;
  String? _error;

  /// Chaves marcadas como "Enviei" (atualizadas na hora, sem recarregar).
  final Set<String> _sent = {};
  /// Chaves com envio/desfazer em andamento (evita toque duplo).
  final Set<String> _busy = {};

  String? _copiedText;
  String? _copiedName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        _service.getReminders(),
        _service.getMovement(),
        _service.getSegments(),
      ]);
      if (!mounted) return;
      final reminders = results[0] as RemindersData;
      setState(() {
        _reminders = reminders;
        _movement  = results[1] as MovementData;
        _segments  = results[2] as SegmentsData;
        _sent
          ..clear()
          ..addAll([...reminders.appointments, ...reminders.returns]
              .where((r) => r.sent)
              .map((r) => r.key));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _copy(String clientName, String text) async {
    // Mostra o texto na tela mesmo se a cópia falhar: dá para selecionar
    // e copiar à mão.
    setState(() {
      _copiedText = text;
      _copiedName = clientName;
    });
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      _snack('Mensagem para $clientName copiada — cole no WhatsApp dela.', AppColors.green);
    } catch (_) {
      if (!mounted) return;
      _snack('Não consegui copiar sozinho. Selecione o texto abaixo e copie.', AppColors.rose);
    }
  }

  Future<void> _toggleSent(ReminderItem item) async {
    if (_busy.contains(item.key)) return;
    final wasSent = _sent.contains(item.key);
    setState(() {
      _busy.add(item.key);
      if (wasSent) {
        _sent.remove(item.key);
      } else {
        _sent.add(item.key);
      }
    });
    try {
      if (wasSent) {
        await _service.unmarkSent(item.key);
      } else {
        await _service.markSent(key: item.key, type: item.type, clientName: item.clientName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (wasSent) {
            _sent.add(item.key);
          } else {
            _sent.remove(item.key);
          }
        });
        _snack('$e', AppColors.rose);
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.key));
    }
  }

  String _messageFor(ReminderItem item) => item.isAppointment
      ? appointmentReminderMessage(
          clientName: item.clientName,
          date:       item.date,
          time:       item.time,
          procedure:  item.procedure,
          location:   item.location,
        )
      : returnReminderMessage(
          clientName: item.clientName,
          procedure:  item.procedure,
          daysSince:  item.daysSince,
        );

  @override
  Widget build(BuildContext context) {
    if (_reminders == null || _movement == null || _segments == null) {
      if (_loading) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.rose, strokeWidth: 2.5),
        );
      }
      return _ErrorView(message: _error ?? 'Sem dados', onRetry: _load);
    }

    final reminders = _reminders!;
    final movement  = _movement!;
    final segments  = _segments!;
    final weakestName = movement.weakest != null
        ? weekdayNameFromIndex(movement.weakest!.weekday)
        : '';

    return LayoutBuilder(
      builder: (context, box) {
        // PC/notebook (com menu lateral sobra ~1000 px): colunas lado a lado.
        // Abaixo disso, tudo empilhado; botões empilhados só em tela estreita.
        final wide = box.maxWidth >= 900;
        final compact = !wide && box.maxWidth < 560;
        return RefreshIndicator(
          color: AppColors.rose,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Não foi possível atualizar: $_error',
                      style: TextStyle(color: AppColors.rose, fontSize: 12)),
                ),
              _buildReminders(reminders, wide, compact),
              const SizedBox(height: 16),
              _MovementSection(movement: movement),
              const SizedBox(height: 16),
              _buildSegments(segments, wide, weakestName),
              if (segments.inactive.isNotEmpty) ...[
                const SizedBox(height: 16),
                _CampaignCard(
                  clients: segments.inactive,
                  weakestName: weakestName,
                  onCopy: (c) => _copy(
                    c.clientName,
                    inactiveInviteMessage(clientName: c.clientName, weakestDayName: weakestName),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── 1. Para enviar hoje ────────────────────────────────────────────
  Widget _buildReminders(RemindersData data, bool wide, bool compact) {
    final all = [...data.appointments, ...data.returns];
    final sentCount = all.where((r) => _sent.contains(r.key)).length;

    Widget column(String title, Color color, List<ReminderItem> items, String empty) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(empty, style: TextStyle(color: AppColors.textMuted, fontSize: 12))
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ReminderTile(
                      item: item,
                      sent: _sent.contains(item.key),
                      busy: _busy.contains(item.key),
                      compact: compact,
                      onCopy: () => _copy(item.clientName, _messageFor(item)),
                      onToggleSent: () => _toggleSent(item),
                    ),
                  )),
          ],
        );

    final tomorrowLabel = friendlyDate(data.tomorrow);
    final left = column(
      tomorrowLabel.isEmpty ? 'AGENDADAS PARA AMANHÃ' : 'AGENDADAS PARA AMANHÃ · ${tomorrowLabel.toUpperCase()}',
      AppColors.gold,
      data.appointments,
      'Ninguém agendado para amanhã.',
    );
    final right = column(
      'HORA DE REFAZER · SEM HORÁRIO MARCADO',
      AppColors.lavender,
      data.returns,
      'Nenhuma cliente no prazo de retorno hoje.',
    );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text('Para enviar hoje',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Text('${all.length} lembrete${all.length == 1 ? '' : 's'} · $sentCount enviado${sentCount == 1 ? '' : 's'}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ])
          else ...[
            left,
            const SizedBox(height: 14),
            right,
          ],
          if (_copiedText != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.rose.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.rose.withValues(alpha: 0.5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MENSAGEM COPIADA — COLE NO WHATSAPP DE ${(_copiedName ?? '').toUpperCase()}',
                    style: TextStyle(color: AppColors.roseLight, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SelectableText(_copiedText!,
                    style: TextStyle(color: AppColors.text, fontSize: 13, height: 1.5)),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Cliente pediu para não receber? Abra a ficha dela em Clientes e desmarque os lembretes — ela some desta lista.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── 3. Suas clientes ───────────────────────────────────────────────
  Widget _buildSegments(SegmentsData s, bool wide, String weakestName) {
    final cards = [
      _SegmentCard(
        title: 'Fiéis',
        color: AppColors.gold,
        subtitle: 'Mais visitas nos últimos 6 meses',
        suggestion: 'Sugestão: agradecer com um mimo ou desconto de fidelidade.',
        clients: s.loyal,
        detail: (c) => '${c.visits} visita${c.visits == 1 ? '' : 's'}',
        onCopy: (c) => _copy(c.clientName, loyalThanksMessage(clientName: c.clientName)),
      ),
      _SegmentCard(
        title: 'Sumidas',
        color: AppColors.roseLight,
        subtitle: 'Não vêm há mais de 60 dias',
        suggestion: weakestName.isEmpty
            ? 'Sugestão: “sentimos sua falta” com convite para voltar.'
            : 'Sugestão: “sentimos sua falta” com convite para $weakestName.',
        clients: s.inactive,
        detail: (c) => 'há ${c.daysSince} dias',
        onCopy: (c) => _copy(
          c.clientName,
          inactiveInviteMessage(clientName: c.clientName, weakestDayName: weakestName),
        ),
      ),
      _SegmentCard(
        title: 'Novas',
        color: AppColors.green,
        subtitle: 'Primeira visita nos últimos 30 dias',
        suggestion: 'Sugestão: convidar a voltar para criar o hábito.',
        clients: s.newClients,
        detail: (c) => c.daysSince == 0 ? 'hoje' : 'há ${c.daysSince} dia${c.daysSince == 1 ? '' : 's'}',
        onCopy: (c) => _copy(c.clientName, newClientMessage(clientName: c.clientName)),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Suas clientes',
            style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
            ],
          )
        else
          ...cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)),
      ],
    );
  }
}

// ── Peças visuais ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  const _Card({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor ?? AppColors.cardBorder),
        ),
        child: child,
      );
}

class _ReminderTile extends StatelessWidget {
  final ReminderItem item;
  final bool sent;
  final bool busy;
  final bool compact;
  final VoidCallback onCopy;
  final VoidCallback onToggleSent;

  const _ReminderTile({
    required this.item,
    required this.sent,
    required this.busy,
    required this.compact,
    required this.onCopy,
    required this.onToggleSent,
  });

  String get _details {
    if (item.isAppointment) {
      final parts = [
        item.time,
        item.procedure,
        item.location.replaceAll('Studio ', ''),
      ].where((p) => p.isNotEmpty);
      return parts.join(' · ');
    }
    return '${item.procedure} · há ${item.daysSince} dias (prazo ${item.returnDays})';
  }

  @override
  Widget build(BuildContext context) {
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.clientName,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: sent ? TextDecoration.lineThrough : null,
          ),
        ),
        const SizedBox(height: 2),
        Text(_details, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );

    final copyBtn = FilledButton.icon(
      onPressed: onCopy,
      icon: const Icon(Icons.copy_rounded, size: 16),
      label: const Text('Copiar mensagem'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.rose,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );

    final sentBtn = OutlinedButton.icon(
      onPressed: busy ? null : onToggleSent,
      icon: Icon(sent ? Icons.undo_rounded : Icons.check_rounded, size: 16),
      label: Text(sent ? 'Desfazer' : 'Enviei'),
      style: OutlinedButton.styleFrom(
        foregroundColor: sent ? AppColors.textMuted : AppColors.green,
        side: BorderSide(color: AppColors.cardBorder),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );

    return Opacity(
      opacity: sent ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: compact
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                info,
                const SizedBox(height: 10),
                Row(children: [
                  if (!sent) ...[
                    Expanded(child: copyBtn),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: sentBtn),
                ]),
              ])
            : Row(children: [
                Expanded(child: info),
                if (!sent) ...[
                  copyBtn,
                  const SizedBox(width: 8),
                ],
                sentBtn,
              ]),
      ),
    );
  }
}

class _MovementSection extends StatelessWidget {
  final MovementData movement;
  const _MovementSection({required this.movement});

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1).replaceAll('.', ',');

  static String _capitalized(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    // Segunda a sábado; domingo só entra se teve atendimento.
    const order = [1, 2, 3, 4, 5, 6, 0];
    final byDay = {for (final w in movement.weekdays) w.weekday: w};
    final days = order
        .map((i) => byDay[i])
        .whereType<WeekdayStat>()
        .where((w) => w.weekday != 0 || w.count > 0)
        .toList();
    final maxAvg = days.fold<double>(0, (m, w) => w.average > m ? w.average : m);
    final weakest = movement.weakest;

    String? insight;
    if (weakest != null && movement.strongest != null && movement.differencePercent != null) {
      insight = '${_capitalized(weekdayNameFromIndex(weakest.weekday))} é o dia mais fraco: '
          '${movement.differencePercent}% menos atendimentos que '
          '${weekdayNameFromIndex(movement.strongest!.weekday)}.';
    }
    // Período com menos procura (final: pode ser usado dentro do map).
    final PeriodStat? lowestPeriod = movement.periods.isEmpty
        ? null
        : movement.periods.reduce((a, b) => b.percent < a.percent ? b : a);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text('Movimento da semana',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Text('Média por dia · últimos ${movement.days} dias',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          if (movement.total == 0)
            Text('Ainda não há atendimentos suficientes para mostrar o movimento.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12))
          else ...[
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((w) {
                  final isWeak = weakest != null && w.weekday == weakest.weekday;
                  final color = isWeak ? AppColors.gold : AppColors.lavender;
                  final h = maxAvg > 0 ? (w.average / maxAvg) * 130 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(_fmt(w.average),
                              style: TextStyle(
                                  color: isWeak ? AppColors.gold : AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: isWeak ? FontWeight.w700 : FontWeight.w400)),
                          const SizedBox(height: 4),
                          Container(
                            height: h < 2 ? 2.0 : h,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(w.label,
                              style: TextStyle(
                                  color: isWeak ? AppColors.gold : AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: isWeak ? FontWeight.w700 : FontWeight.w400)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            Text('POR PERÍODO',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...movement.periods.map((p) {
              final isLow = lowestPeriod != null && p.key == lowestPeriod.key;
              final color = isLow ? AppColors.gold : AppColors.lavender;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  SizedBox(
                    width: 92,
                    child: Text(p.label, style: TextStyle(color: AppColors.text, fontSize: 12)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: p.percent / 100,
                        minHeight: 8,
                        color: color,
                        backgroundColor: AppColors.cardBorder,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('${p.percent}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: isLow ? AppColors.gold : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: isLow ? FontWeight.w700 : FontWeight.w400)),
                  ),
                ]),
              );
            }),
            if (insight != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                ),
                child: Text(insight,
                    style: TextStyle(color: AppColors.text, fontSize: 13, height: 1.4)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SegmentCard extends StatefulWidget {
  final String title;
  final Color color;
  final String subtitle;
  final String suggestion;
  final List<SegmentClient> clients;
  final String Function(SegmentClient) detail;
  final void Function(SegmentClient) onCopy;

  const _SegmentCard({
    required this.title,
    required this.color,
    required this.subtitle,
    required this.suggestion,
    required this.clients,
    required this.detail,
    required this.onCopy,
  });

  @override
  State<_SegmentCard> createState() => _SegmentCardState();
}

class _SegmentCardState extends State<_SegmentCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final clients = widget.clients;
    final visible = _expanded ? clients : clients.take(3).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text(widget.title,
                  style: TextStyle(color: widget.color, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            Text('${clients.length}',
                style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w700)),
          ]),
          Text(widget.subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          if (clients.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Nenhuma cliente neste grupo ainda.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            )
          else
            ...visible.map((c) => _ClientCopyRow(
                  name: c.clientName,
                  detail: widget.detail(c),
                  onCopy: () => widget.onCopy(c),
                )),
          if (clients.length > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Mostrar menos' : 'Ver todas (${clients.length})',
                    style: TextStyle(color: AppColors.roseLight, fontSize: 12)),
              ),
            ),
          const SizedBox(height: 4),
          Text(widget.suggestion, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ClientCopyRow extends StatelessWidget {
  final String name;
  final String detail;
  final VoidCallback onCopy;
  const _ClientCopyRow({required this.name, required this.detail, required this.onCopy});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.text, fontSize: 13)),
        ),
        Text(detail, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        IconButton(
          tooltip: 'Copiar mensagem para $name',
          onPressed: onCopy,
          icon: Icon(Icons.copy_rounded, size: 18, color: AppColors.roseLight),
        ),
      ]);
}

class _CampaignCard extends StatefulWidget {
  final List<SegmentClient> clients;
  final String weakestName;
  final void Function(SegmentClient) onCopy;

  const _CampaignCard({required this.clients, required this.weakestName, required this.onCopy});

  @override
  State<_CampaignCard> createState() => _CampaignCardState();
}

class _CampaignCardState extends State<_CampaignCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.clients.length;
    final target = widget.weakestName.isEmpty
        ? 'nesta semana'
        : (widget.weakestName == 'sábado' || widget.weakestName == 'domingo'
            ? 'para o ${widget.weakestName}'
            : 'para a ${widget.weakestName}');
    final example = inactiveInviteMessage(
      clientName: widget.clients.first.clientName,
      weakestDayName: widget.weakestName,
    );

    return _Card(
      borderColor: AppColors.rose.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('CAMPANHA SUGERIDA',
              style: TextStyle(color: AppColors.roseLight, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text('Convide ${n == 1 ? 'a cliente sumida' : 'as $n clientes sumidas'} $target',
              style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('“$example”', style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 6),
          Text('Junta as duas pontas: recupera clientes e enche o dia mais vazio.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => setState(() => _open = !_open),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
              ),
              child: Text(_open ? 'Esconder clientes' : 'Ver as $n cliente${n == 1 ? '' : 's'} e copiar mensagens'),
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 8),
            ...widget.clients.map((c) => _ClientCopyRow(
                  name: c.clientName,
                  detail: 'há ${c.daysSince} dias',
                  onCopy: () => widget.onCopy(c),
                )),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar de novo')),
          ]),
        ),
      );
}
