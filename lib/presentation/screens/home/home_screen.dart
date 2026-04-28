import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/services/appointment_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/refresh_provider.dart';
import '../../widgets/loading_overlay.dart';
import '../appointments/appointment_form_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Appointment> _today    = [];
  List<Appointment> _monthAll = [];
  bool _loading     = true;
  int  _lastRefresh = -1;

  @override
  void initState() { super.initState(); _load(); }

  bool _isPast(Appointment apt) {
    final now   = DateTime.now();
    final parts = apt.time.split(':');
    final h     = int.tryParse(parts[0]) ?? 0;
    final m     = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    // apt.date é UTC mas year/month/day já representam a data local escolhida
    // NÃO usar .toLocal() pois converte meia-noite UTC para dia anterior no BR
    return now.isAfter(DateTime(apt.date.year, apt.date.month, apt.date.day, h, m));
  }

  @override
  Widget build(BuildContext context) {
    final refresh = ref.watch(refreshProvider);
    if (refresh != _lastRefresh) {
      _lastRefresh = refresh;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    final now      = DateTime.now();
    final pending  = _monthAll.where((a) => !a.paid).toList();
    final unconf   = _monthAll.where((a) => !a.confirmed).toList();
    final received = _monthAll.where((a) => a.paid).fold<double>(0, (s, a) => s + a.price);
    final todayPending  = _today.where((a) => !_isPast(a)).toList();
    final todayFinished = _today.where((a) =>  _isPast(a)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('GLAMOUR AGENDA',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
          const Text('Início',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: AppColors.textMuted),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.textMuted),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: RefreshIndicator(
          color: AppColors.rose,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeroCard(today: now, count: todayPending.length),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.45,
                children: [
                  _SummaryCard(
                    icon: '📋', label: 'Agendados', color: AppColors.lavender,
                    count: _monthAll.length,
                    names: _monthAll.map((a) => a.clientName).toList(),
                    onTap: () => _showList(context, '📋 Todos agendados', _monthAll, AppColors.lavender),
                  ),
                  _SummaryCard(
                    icon: '⏳', label: 'Não confirmados', color: AppColors.gold,
                    count: unconf.length,
                    names: unconf.map((a) => a.clientName).toList(),
                    onTap: () => _showUnconfirmedList(context, unconf),
                  ),
                  _SummaryCard(
                    icon: '💰', label: 'Não pagos', color: AppColors.rose,
                    count: pending.length,
                    names: pending.map((a) => a.clientName).toList(),
                    onTap: () => _showList(context, '💰 Pendentes de pagamento', pending, AppColors.rose),
                  ),
                  _SummaryCard(
                    icon: '✅', label: 'Já recebido', color: AppColors.green,
                    count: null,
                    value: 'R\$ ${received.toStringAsFixed(0)}',
                    names: [],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('HOJE',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 2)),
                Text('${todayPending.length} pendente(s)',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
              ]),
              const SizedBox(height: 8),

              if (todayPending.isEmpty && todayFinished.isEmpty && !_loading)
                _EmptyToday()
              else ...[
                ...todayPending.map((apt) => _TodayCard(
                  apt: apt,
                  isPast: false,
                  onTap:     () => _openEdit(apt.id),
                  onPay:     !apt.paid      ? () => _pay(apt)        : null,
                  onConfirm: !apt.confirmed ? () => _confirm(apt.id) : null,
                  onDelete:  () => _deleteConfirm(apt.id),
                )),
                if (todayFinished.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('FINALIZADOS',
                        style: TextStyle(color: AppColors.textDim, fontSize: 11, letterSpacing: 2)),
                    Text('${todayFinished.length} concluído(s)',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                  ]),
                  const SizedBox(height: 8),
                  ...todayFinished.map((apt) => _TodayCard(
                    apt: apt,
                    isPast: true,
                    onTap:    () => _openEdit(apt.id),
                    onDelete: () => _deleteConfirm(apt.id),
                  )),
                ],
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final results = await Future.wait([
        AppointmentService().getAll(date: dateStr),
        AppointmentService().getAll(month: now.month, year: now.year),
      ]);
      if (!mounted) return;
      // A API já filtra por data — apenas ordena por horário
      // NÃO re-filtrar por toLocal() pois causa drift de timezone no BR
      setState(() {
        _today    = results[0]..sort((a, b) => a.time.compareTo(b.time));
        _monthAll = results[1];
        _loading  = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openEdit(String id) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AppointmentFormScreen(appointmentId: id)),
      ).then((_) => _load());

  Future<void> _pay(Appointment apt) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaySheet(),
    );
    if (method == null) return;
    try {
      await AppointmentService().markAsPaid(apt.id, paymentMethod: method);
      _load();
      if (mounted) _snack('✅ Pagamento registrado!', AppColors.green);
    } catch (e) {
      if (mounted) _snack('$e', AppColors.rose);
    }
  }

  Future<void> _confirm(String id) async {
    try {
      await AppointmentService().confirm(id);
      _load();
      if (mounted) _snack('✅ Confirmada!', AppColors.green);
    } catch (e) {
      if (mounted) _snack('$e', AppColors.rose);
    }
  }

  Future<void> _deleteConfirm(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir agendamento',
            style: TextStyle(color: AppColors.text, fontSize: 16)),
        content: const Text('Tem certeza? Esta ação não pode ser desfeita.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir',
                  style: TextStyle(color: AppColors.rose))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AppointmentService().delete(id);
      _load();
      if (mounted) _snack('🗑️ Agendamento excluído', AppColors.textMuted);
    } catch (e) {
      if (mounted) _snack('$e', AppColors.rose);
    }
  }

  void _showList(BuildContext ctx, String title, List<Appointment> apts, Color color) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textDim,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(children: [
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.4))),
                child: Text('${apts.length}',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
          ),
          const Divider(height: 12),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: apts.length,
              itemBuilder: (_, i) {
                final apt = apts[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text(apt.clientName.isNotEmpty ? apt.clientName[0].toUpperCase() : '?',
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(apt.clientName,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(
                            '${apt.procedure} · ${apt.time} · '
                            '${apt.date.day.toString().padLeft(2, '0')}/${apt.date.month.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ])),
                    Text('R\$ ${apt.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _showUnconfirmedList(BuildContext ctx, List<Appointment> apts) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textDim,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(children: [
              const Text('⏳ Aguardando confirmação',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4))),
                child: Text('${apts.length}',
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ]),
          ),
          const Divider(height: 12),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: apts.length,
              itemBuilder: (_, i) {
                final apt = apts[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            shape: BoxShape.circle),
                        child: Center(
                            child: Text(
                                apt.clientName.isNotEmpty
                                    ? apt.clientName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(apt.clientName,
                                style: const TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(
                              '${apt.procedure} · ${apt.time} · '
                              '${apt.date.day.toString().padLeft(2, '0')}/${apt.date.month.toString().padLeft(2, '0')}  ·  '
                              '${apt.location.replaceAll("Studio ", "")}',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11),
                            ),
                          ])),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (apt.paid ? AppColors.green : AppColors.rose)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(apt.paid ? '✓ Pago' : 'Pend.',
                            style: TextStyle(
                                color: apt.paid
                                    ? AppColors.green
                                    : AppColors.rose,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _ActionBtn('✓ Confirmar', AppColors.lavender, () async {
                        Navigator.pop(sheetCtx);
                        await _confirm(apt.id);
                      }),
                      const SizedBox(width: 8),
                      _ActionBtn('🗑️ Excluir', AppColors.rose, () async {
                        Navigator.pop(sheetCtx);
                        await _deleteConfirm(apt.id);
                      }),
                    ]),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
}

// ── Card de hoje ─────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final Appointment   apt;
  final bool          isPast;
  final VoidCallback  onTap;
  final VoidCallback? onPay;
  final VoidCallback? onConfirm;
  final VoidCallback  onDelete;

  const _TodayCard({
    required this.apt,
    required this.isPast,
    required this.onTap,
    required this.onDelete,
    this.onPay,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = isPast
        ? AppColors.textDim
        : AppColors.forProcedure(apt.procedure);

    return Opacity(
      opacity: isPast ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(children: [
                Container(width: 3, color: barColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome + valor
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                apt.clientName.isNotEmpty
                                    ? apt.clientName
                                    : '(sem nome)',
                                style: TextStyle(
                                  color: isPast
                                      ? AppColors.textMuted
                                      : AppColors.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              'R\$ ${apt.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Procedimento · horário · studio
                        Text(
                          '${apt.procedure}  ·  ${apt.time}  ·  '
                          '${apt.location.replaceAll("Studio ", "")}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 6),

                        // Badges
                        Wrap(spacing: 6, children: [
                          if (isPast)
                            _StatusBadge('✅ Finalizado', AppColors.textDim)
                          else ...[
                            _StatusBadge(
                              apt.confirmed
                                  ? '✓ Confirmada'
                                  : '⏳ Não confirmada',
                              apt.confirmed
                                  ? AppColors.lavender
                                  : AppColors.gold,
                            ),
                            _StatusBadge(
                              apt.paid ? '✓ Pago' : '💰 Pendente',
                              apt.paid ? AppColors.green : AppColors.rose,
                            ),
                          ],
                        ]),

                        // Ações (só pendentes)
                        if (!isPast && (onPay != null || onConfirm != null)) ...[
                          const SizedBox(height: 8),
                          const Divider(
                              height: 1, color: AppColors.cardBorder),
                          const SizedBox(height: 8),
                          Row(children: [
                            if (onPay != null)
                              _ActionBtn(
                                  '💰 Pagar', AppColors.green, onPay!),
                            if (onPay != null && onConfirm != null)
                              const SizedBox(width: 6),
                            if (onConfirm != null)
                              _ActionBtn('✓ Confirmar', AppColors.lavender,
                                  onConfirm!),
                            const Spacer(),
                            _ActionBtn('🗑️', AppColors.rose, onDelete),
                          ]),
                        ],

                        // Finalizado: excluir discreto
                        if (isPast) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _ActionBtn(
                                '🗑️', AppColors.textDim, onDelete),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badges e botões ──────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.45)),
    ),
    child: Text(label,
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}

class _ActionBtn extends StatelessWidget {
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    ),
  );
}

// ── Widgets de apoio ─────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final DateTime today;
  final int      count;
  const _HeroCard({required this.today, required this.count});
  @override
  Widget build(BuildContext context) {
    final h        = today.hour;
    final greeting = h < 12 ? 'Bom dia! 🌸' : h < 18 ? 'Boa tarde! ✨' : 'Boa noite! 🌙';
    final dateStr  = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(today);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.roseDark.withValues(alpha: 0.3),
          AppColors.lavender.withValues(alpha: 0.15),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(dateStr,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(greeting,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            children: [
              const TextSpan(text: 'Você tem '),
              TextSpan(
                  text: '$count atendimento${count != 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: AppColors.rose, fontWeight: FontWeight.w700)),
              TextSpan(text: ' pendente${count != 1 ? 's' : ''} hoje'),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String       icon, label;
  final Color        color;
  final int?         count;
  final String?      value;
  final List<String> names;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.count,
    required this.names,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value ?? '$count';
    final hasNames     = names.isNotEmpty && onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: hasNames
                  ? color.withValues(alpha: 0.4)
                  : AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              if (hasNames)
                Icon(Icons.chevron_right,
                    color: color.withValues(alpha: 0.6), size: 14),
            ]),
            Text(displayValue,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 20)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
            if (names.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                names.take(2).join(', ') +
                    (names.length > 2 ? ' +${names.length - 2}' : ''),
                style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🌟', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        const Text('Nenhum atendimento hoje!',
            style: TextStyle(
                color: AppColors.green, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _PaySheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Forma de pagamento',
          style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 16)),
      const SizedBox(height: 12),
      ...['PIX', 'Cartão', 'Dinheiro'].map((m) => ListTile(
            title: Text(m, style: const TextStyle(color: AppColors.text)),
            onTap: () => Navigator.pop(context, m),
          )),
    ]),
  );
}