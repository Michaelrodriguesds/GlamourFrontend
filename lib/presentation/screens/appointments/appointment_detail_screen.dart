import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/services/appointment_service.dart';
import '../../../providers/appointments_provider.dart';
import '../../widgets/status_badge.dart';
import 'appointment_form_screen.dart';

/// Tela de detalhe de um agendamento específico
class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final String appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  Appointment? _apt;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final apt = await AppointmentService().getById(widget.appointmentId);
      setState(() {
        _apt = apt;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        _snack('Erro ao carregar: $e', AppColors.rose);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe'),
        actions: [
          if (_apt != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentFormScreen(
                      appointmentId: widget.appointmentId,
                    ),
                  ),
                );
                _load(); // Recarrega após edição
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.rose,
                strokeWidth: 2.5,
              ),
            )
          : _apt == null
              ? const Center(
                  child: Text(
                    'Agendamento não encontrado',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : _Body(
                  apt: _apt!,
                  onPay: _pay,
                  onConfirm: _confirm,
                  onDelete: _delete,
                ),
    );
  }

  Future<void> _pay() async {
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentSheet(),
    );
    if (method == null) return;
    try {
      await ref
          .read(appointmentsProvider.notifier)
          .markAsPaid(widget.appointmentId, paymentMethod: method);
      await _load();
      if (mounted) _snack('✅ Pagamento registrado!', AppColors.green);
    } catch (e) {
      if (mounted) _snack('$e', AppColors.rose);
    }
  }

  Future<void> _confirm() async {
    try {
      await ref
          .read(appointmentsProvider.notifier)
          .confirmAppointment(widget.appointmentId);
      await _load();
      if (mounted) _snack('✅ Cliente confirmada!', AppColors.green);
    } catch (e) {
      if (mounted) _snack('$e', AppColors.rose);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Remover agendamento',
          style: TextStyle(color: AppColors.text),
        ),
        content: const Text(
          'Tem certeza? Esta ação não pode ser desfeita.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remover',
              style: TextStyle(color: AppColors.rose),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(appointmentsProvider.notifier)
          .delete(widget.appointmentId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('$e', AppColors.rose);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }
}

// ── Corpo da tela ────────────────────────────

class _Body extends StatelessWidget {
  final Appointment apt;
  final VoidCallback onPay;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;

  const _Body({
    required this.apt,
    required this.onPay,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final procColor = AppColors.forProcedure(apt.procedure);
    final procIcon = AppStrings.procedureIcons[apt.procedure] ?? '✨';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Hero do agendamento ──────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: procColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: procColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$procIcon ${apt.procedure}',
                    style: TextStyle(
                      color: procColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'R\$ ${apt.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                apt.clientName,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${AppDateUtils.toFullDate(apt.date)} às ${apt.time}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '📍 ${apt.location}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Status ───────────────────────────
        _Section(
          title: 'STATUS',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge.paid(apt.paid),
              StatusBadge.confirmed(apt.confirmed),
              if (apt.paymentMethod.isNotEmpty)
                StatusBadge.payMethod(apt.paymentMethod),
              if (apt.paidAt != null)
                StatusBadge(
                  label: 'Pago em ${AppDateUtils.toFullDate(apt.paidAt!)}',
                  color: AppColors.green,
                ),
              if (apt.confirmedAt != null)
                StatusBadge(
                  label:
                      'Confirmada em ${AppDateUtils.toFullDate(apt.confirmedAt!)}',
                  color: AppColors.lavender,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Observações ──────────────────────
        if (apt.notes.isNotEmpty) ...[
          _Section(
            title: 'OBSERVAÇÕES',
            child: Text(
              apt.notes,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Ações ────────────────────────────
        _Section(
          title: 'AÇÕES',
          child: Column(
            children: [
              if (!apt.paid)
                _ActionTile(
                  icon: Icons.attach_money,
                  label: 'Registrar pagamento',
                  color: AppColors.green,
                  onTap: onPay,
                ),
              if (!apt.confirmed)
                _ActionTile(
                  icon: Icons.check_circle_outline,
                  label: 'Confirmar presença',
                  color: AppColors.lavender,
                  onTap: onConfirm,
                ),
              _ActionTile(
                icon: Icons.delete_outline,
                label: 'Remover agendamento',
                color: AppColors.rose,
                onTap: onDelete,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Widgets internos ─────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: TextStyle(color: color, fontSize: 13)),
      trailing: Icon(
        Icons.chevron_right,
        color: color.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }
}

class _PaymentSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Forma de pagamento',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...['PIX', 'Cartão', 'Dinheiro'].map(
            (m) => ListTile(
              title: Text(m, style: const TextStyle(color: AppColors.text)),
              onTap: () => Navigator.pop(context, m),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}