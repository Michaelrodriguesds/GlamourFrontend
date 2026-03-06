import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/services/appointment_service.dart';
import '../../../providers/refresh_provider.dart';
import '../appointments/appointment_form_screen.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});
  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';
  List<Appointment> _all = [];
  bool   _loading   = true;
  String? _error;
  int    _lastRefresh = -1;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await AppointmentService().getAll();
      setState(() { _all = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final refresh = ref.watch(refreshProvider);
    if (refresh != _lastRefresh) {
      _lastRefresh = refresh;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    // Agrupa por nome de cliente
    final Map<String, List<Appointment>> map = {};
    for (final apt in _all) {
      map.putIfAbsent(apt.clientName, () => []).add(apt);
    }

    var clients = map.entries.toList();
    if (_query.isNotEmpty) {
      clients = clients
          .where((e) => e.key.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }
    // Ordena por mais atendimentos
    clients.sort((a, b) => b.value.length.compareTo(a.value.length));

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('GLAMOUR AGENDA',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
          Text('Clientes · ${clients.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: AppColors.textMuted),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: '🔍 Buscar cliente...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      })
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.rose, strokeWidth: 2.5))
              : _error != null
                  ? _ErrorState(error: _error!, onRetry: _load)
                  : clients.isEmpty
                      ? _EmptyState(hasQuery: _query.isNotEmpty)
                      : RefreshIndicator(
                          color: AppColors.rose,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: clients.length,
                            itemBuilder: (_, i) => _ClientCard(
                              name: clients[i].key,
                              apts: clients[i].value,
                              onTap: () => _openDetail(clients[i].key, clients[i].value),
                            ),
                          ),
                        ),
        ),
      ]),
    );
  }

  void _openDetail(String name, List<Appointment> apts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ClientDetailSheet(
        name: name,
        apts: apts,
        onPay: (id) async {
          Navigator.pop(context);
          final method = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: AppColors.card,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _PaySheet(),
          );
          if (method == null) return;
          try {
            await AppointmentService().markAsPaid(id, paymentMethod: method);
            _load();
            if (mounted) _snack('✅ Pagamento registrado!', AppColors.green);
          } catch (e) { if (mounted) _snack('$e', AppColors.rose); }
        },
        onConfirm: (id) async {
          Navigator.pop(context);
          try {
            await AppointmentService().confirm(id);
            _load();
            if (mounted) _snack('✅ Confirmada!', AppColors.green);
          } catch (e) { if (mounted) _snack('$e', AppColors.rose); }
        },
        onEdit: (id) {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => AppointmentFormScreen(appointmentId: id)))
              .then((_) => _load());
        },
        onDelete: (id) async {
          Navigator.pop(context);
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
          } catch (e) { if (mounted) _snack('$e', AppColors.rose); }
        },
      ),
    );
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
}

// ── Card do cliente na lista ─────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final String name;
  final List<Appointment> apts;
  final VoidCallback onTap;
  const _ClientCard({required this.name, required this.apts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total   = apts.fold<double>(0, (s, a) => s + a.price);
    final pending = apts.where((a) => !a.paid).length;
    final unconf  = apts.where((a) => !a.confirmed).length;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final sorted  = [...apts]..sort((a, b) => b.date.compareTo(a.date));
    final last    = sorted.first;
    final lastStr = '${last.date.day.toString().padLeft(2,'0')}/${last.date.month.toString().padLeft(2,'0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.rose.withValues(alpha: 0.3),
                AppColors.lavender.withValues(alpha: 0.3),
              ]),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.rose.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(initial,
                  style: const TextStyle(
                      color: AppColors.rose, fontWeight: FontWeight.w700, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                '${apts.length} atendimento${apts.length > 1 ? 's' : ''}  ·  último: $lastStr',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              if (pending > 0 || unconf > 0) ...[
                const SizedBox(height: 3),
                Wrap(spacing: 4, children: [
                  if (pending > 0) _MiniTag('$pending pend.', AppColors.rose),
                  if (unconf  > 0) _MiniTag('$unconf n.conf.', AppColors.gold),
                ]),
              ],
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('R\$ ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right, color: AppColors.textDim, size: 16),
          ]),
        ]),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color  color;
  const _MiniTag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}

// ── Bottom sheet de detalhe completo ────────────────────────────

class _ClientDetailSheet extends StatelessWidget {
  final String name;
  final List<Appointment> apts;
  final void Function(String) onPay;
  final void Function(String) onConfirm;
  final void Function(String) onEdit;
  final void Function(String) onDelete;

  const _ClientDetailSheet({
    required this.name,
    required this.apts,
    required this.onPay,
    required this.onConfirm,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sorted   = [...apts]..sort((a, b) => b.date.compareTo(a.date));
    final total    = apts.fold<double>(0, (s, a) => s + a.price);
    final received = apts.where((a) => a.paid).fold<double>(0, (s, a) => s + a.price);

    // Contagem por procedimento
    final Map<String, int> procCount = {};
    for (final a in apts) {
      procCount[a.procedure] = (procCount[a.procedure] ?? 0) + 1;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.97,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: AppColors.textDim, borderRadius: BorderRadius.circular(2)),
        ),

        // Cabeçalho: avatar + nome + totais
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.rose.withValues(alpha: 0.3),
                  AppColors.lavender.withValues(alpha: 0.3),
                ]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppColors.rose, fontWeight: FontWeight.w700, fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  '${apts.length} atendimento${apts.length != 1 ? 's' : ''}  ·  '
                  'Total: R\$ ${total.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                Text(
                  'Recebido: R\$ ${received.toStringAsFixed(0)}  ·  '
                  'Pendente: R\$ ${(total - received).toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ]),
            ),
          ]),
        ),

        // Chips de procedimentos realizados
        if (procCount.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Wrap(spacing: 6, runSpacing: 4, children: procCount.entries.map((e) {
              final color = AppColors.forProcedure(e.key);
              final icon  = AppStrings.procedureIcons[e.key] ?? '✨';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text('$icon ${e.key} × ${e.value}',
                    style: TextStyle(
                        color: color, fontSize: 10, fontWeight: FontWeight.w700)),
              );
            }).toList()),
          ),

        const Divider(height: 16),

        // Lista de atendimentos
        Expanded(
          child: ListView.builder(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: sorted.length,
            itemBuilder: (_, i) {
              final apt       = sorted[i];
              final procColor = AppColors.forProcedure(apt.procedure);
              final procIcon  = AppStrings.procedureIcons[apt.procedure] ?? '✨';
              final day  = apt.date.day.toString().padLeft(2, '0');
              final mon  = apt.date.month.toString().padLeft(2, '0');
              final year = apt.date.year;

              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Container(width: 3, color: procColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Procedimento + valor
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$procIcon ${apt.procedure}',
                                    style: TextStyle(
                                        color: procColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                Text('R\$ ${apt.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Data + hora + studio
                            Row(children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 11, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text('$day/$mon/$year  ·  ${apt.time}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 11)),
                              const SizedBox(width: 8),
                              const Icon(Icons.location_on_outlined,
                                  size: 11, color: AppColors.textMuted),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(apt.location,
                                    style: const TextStyle(
                                        color: AppColors.textMuted, fontSize: 11),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                            const SizedBox(height: 4),

                            // Forma de pagamento
                            if (apt.paymentMethod.isNotEmpty)
                              Row(children: [
                                const Icon(Icons.payment_outlined,
                                    size: 11, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(apt.paymentMethod,
                                    style: const TextStyle(
                                        color: AppColors.textMuted, fontSize: 11)),
                              ]),

                            const SizedBox(height: 6),

                            // Badges: pago + confirmado
                            Wrap(spacing: 6, runSpacing: 4, children: [
                              _Badge(
                                apt.paid ? '✓ Pago' : '💰 Pendente',
                                apt.paid ? AppColors.green : AppColors.rose,
                              ),
                              _Badge(
                                apt.confirmed ? '✓ Confirmada' : '⏳ Não confirmada',
                                apt.confirmed ? AppColors.lavender : AppColors.gold,
                              ),
                            ]),

                            // Observação
                            if (apt.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('📝 ${apt.notes}',
                                    style: const TextStyle(
                                        color: AppColors.textMuted, fontSize: 11)),
                              ),
                            ],

                            const SizedBox(height: 8),
                            const Divider(height: 1, color: AppColors.cardBorder),
                            const SizedBox(height: 8),

                            // Ações
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              if (!apt.paid)
                                _SheetAction('💰 Pagar', AppColors.green,
                                    () => onPay(apt.id)),
                              if (!apt.confirmed)
                                _SheetAction('✓ Confirmar', AppColors.lavender,
                                    () => onConfirm(apt.id)),
                              _SheetAction('✏️ Editar', AppColors.textMuted,
                                  () => onEdit(apt.id)),
                              _SheetAction('🗑️ Excluir', AppColors.rose,
                                  () => onDelete(apt.id)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _SheetAction extends StatelessWidget {
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  const _SheetAction(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('😕', style: TextStyle(fontSize: 36)),
      const SizedBox(height: 8),
      Text(error,
          style: const TextStyle(color: AppColors.textMuted),
          textAlign: TextAlign.center),
      TextButton(
          onPressed: onRetry,
          child: const Text('Tentar novamente',
              style: TextStyle(color: AppColors.rose))),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('👥', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 8),
      Text(
        hasQuery ? 'Nenhuma cliente encontrada' : 'Nenhum agendamento ainda',
        style: const TextStyle(color: AppColors.textMuted),
      ),
    ]),
  );
}

class _PaySheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Forma de pagamento',
          style: TextStyle(
              color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 12),
      ...['PIX', 'Cartão', 'Dinheiro'].map((m) => ListTile(
            title: Text(m, style: const TextStyle(color: AppColors.text)),
            onTap: () => Navigator.pop(context, m),
          )),
    ]),
  );
}