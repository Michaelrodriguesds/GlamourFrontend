import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/appointment_model.dart';
import 'status_badge.dart';

/// Card reutilizável exibindo um agendamento
class AppointmentCard extends StatelessWidget {
  final Appointment apt;
  final VoidCallback? onTap;
  final VoidCallback? onPay;
  final VoidCallback? onConfirm;

  const AppointmentCard({
    super.key,
    required this.apt,
    this.onTap,
    this.onPay,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final procColor = AppColors.forProcedure(apt.procedure);
    final procIcon  = AppStrings.procedureIcons[apt.procedure] ?? '✨';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:      const EdgeInsets.only(bottom: 10),
        decoration:  BoxDecoration(
          color:        AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:       Border(
            left: BorderSide(color: procColor, width: 3),
            top:  BorderSide(color: AppColors.cardBorder),
            right: BorderSide(color: AppColors.cardBorder),
            bottom: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Linha 1: Nome + Valor ──────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    apt.clientName,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'R\$ ${apt.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ── Linha 2: Procedimento + Hora ─
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$procIcon ${apt.procedure} · ${apt.time}',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  Text(
                    AppDateUtils.toDayMonth(apt.date),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Badges de status ───────────
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  StatusBadge.paid(apt.paid),
                  StatusBadge.confirmed(apt.confirmed),
                  StatusBadge.location(apt.location),
                  if (apt.paymentMethod.isNotEmpty)
                    StatusBadge.payMethod(apt.paymentMethod),
                ],
              ),

              // ── Observação ─────────────────
              if (apt.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '💬 ${apt.notes}',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // ── Ações rápidas ──────────────
              if (onPay != null || onConfirm != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!apt.paid && onPay != null)
                      _ActionButton(
                        label: '💰 Registrar pagamento',
                        color: AppColors.green,
                        onTap: onPay!,
                      ),
                    if (!apt.paid && onPay != null && !apt.confirmed && onConfirm != null)
                      const SizedBox(width: 6),
                    if (!apt.confirmed && onConfirm != null)
                      _ActionButton(
                        label: '✓ Confirmar',
                        color: AppColors.lavender,
                        onTap: onConfirm!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String   label;
  final Color    color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border:       Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}