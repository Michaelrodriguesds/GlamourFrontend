import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Badge reutilizável de status (pago, confirmado, local, etc.)
class StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 10,
  });

  // ── Factories semânticos ──────────────────
  factory StatusBadge.paid(bool paid) => StatusBadge(
    label: paid ? '✓ Pago' : 'Pendente',
    color: paid ? AppColors.green : AppColors.rose,
  );

  factory StatusBadge.confirmed(bool confirmed) => StatusBadge(
    label: confirmed ? '✓ Confirmada' : 'Aguardando',
    color: confirmed ? AppColors.green : AppColors.gold,
  );

  factory StatusBadge.location(String location) => StatusBadge(
    label: '📍 ${location.replaceAll('Studio ', '')}',
    color: AppColors.lavender,
  );

  factory StatusBadge.payMethod(String method) => StatusBadge(
    label: method,
    color: AppColors.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:       color,
          fontSize:    fontSize,
          fontWeight:  FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}