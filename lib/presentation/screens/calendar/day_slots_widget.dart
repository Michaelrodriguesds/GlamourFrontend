import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/availability_model.dart';

class DaySlotsWidget extends StatelessWidget {
  final DateTime        date;
  final List<TimeSlot>  slots;
  final bool            loading;
  final void Function(String appointmentId)? onTapAppointment;

  const DaySlotsWidget({
    super.key,
    required this.date,
    required this.slots,
    required this.loading,
    this.onTapAppointment,
  });

  @override
  Widget build(BuildContext context) {
    final freeCount   = slots.where((s) =>  s.available).length;
    final bookedCount = slots.where((s) => !s.available).length;

    return Column(children: [
      // ── Header ──────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📅 ${AppDateUtils.toFullDate(date)}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2),
            ),
            if (slots.isNotEmpty)
              Row(children: [
                if (bookedCount > 0) ...[
                  _PillBadge(
                      '$bookedCount ocupado${bookedCount != 1 ? 's' : ''}',
                      AppColors.rose),
                  const SizedBox(width: 6),
                ],
                _PillBadge(
                  freeCount > 0
                      ? '$freeCount livre${freeCount != 1 ? 's' : ''}'
                      : 'Lotado',
                  freeCount > 0 ? AppColors.green : AppColors.textDim,
                ),
              ]),
          ],
        ),
      ),

      // ── Lista de slots ───────────────────────────
      Expanded(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.rose, strokeWidth: 2))
            : slots.isEmpty
                ? _EmptyDay(date: date)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: slots.length,
                    itemBuilder: (_, i) => _SlotRow(
                      slot: slots[i],
                      onTap: slots[i].appointmentId != null
                          ? () => onTapAppointment
                              ?.call(slots[i].appointmentId!)
                          : null,
                    ),
                  ),
      ),
    ]);
  }
}

// ── Linha de slot ────────────────────────────────────────────────

class _SlotRow extends StatelessWidget {
  final TimeSlot      slot;
  final VoidCallback? onTap;
  const _SlotRow({required this.slot, this.onTap});

  // "Amanda Silva" → "Amanda S."
  String _formatName(String? name) {
    if (name == null || name.isEmpty) return '—';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0];
    return '${parts[0]} ${parts[1][0]}.';
  }

  @override
  Widget build(BuildContext context) {
    final isBooked = !slot.available;

    // Cor: não confirmado → gold | confirmado → cor do procedimento
    final Color accentColor = isBooked
        ? (slot.confirmed
            ? AppColors.forProcedure(slot.procedure ?? '')
            : AppColors.gold)
        : AppColors.green;

    final displayName = _formatName(slot.clientName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        // ⚠️ SEM borderRadius aqui — vai no ClipRRect abaixo
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: isBooked
                ? accentColor.withValues(alpha: 0.07)
                : AppColors.card,
            child: Row(children: [
              // ── Barra esquerda colorida (elemento separado) ──
              Container(
                width:  3,
                height: 48,
                color:  accentColor,
              ),

              // ── Conteúdo ─────────────────────────────────────
              Expanded(
                child: Container(
                  // Borda uniforme (mesma cor em todos os lados) — sem erro
                  decoration: BoxDecoration(
                    border: Border(
                      top:    BorderSide(color: AppColors.cardBorder),
                      right:  BorderSide(color: AppColors.cardBorder),
                      bottom: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    // Horário
                    SizedBox(
                      width: 44,
                      child: Text(
                        slot.time,
                        style: TextStyle(
                          color:      accentColor,
                          fontSize:   13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // Separador vertical
                    Container(
                      width: 1, height: 28,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 10),
                      color: accentColor.withValues(alpha: 0.25),
                    ),

                    // Info
                    Expanded(
                      child: isBooked
                          ? Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        color:      accentColor,
                                        fontSize:   12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Badge confirmado / aguardando
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: accentColor
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      slot.confirmed
                                          ? '✓ Conf.'
                                          : '⏳ Aguard.',
                                      style: TextStyle(
                                          color:      accentColor,
                                          fontSize:   8,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 2),
                                Text(
                                  '${AppStrings.procedureIcons[slot.procedure] ?? '✨'}'
                                  ' ${slot.procedure ?? ''}  ·  '
                                  '${slot.location?.replaceAll('Studio ', '') ?? ''}',
                                  style: const TextStyle(
                                      color:    AppColors.textMuted,
                                      fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : const Text(
                              'Livre',
                              style: TextStyle(
                                  color:    AppColors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                    ),

                    // Seta / ponto
                    if (isBooked)
                      Icon(Icons.chevron_right,
                          color: accentColor.withValues(alpha: 0.6),
                          size: 16)
                    else
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color:  AppColors.green.withValues(alpha: 0.4),
                          shape:  BoxShape.circle,
                        ),
                      ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Pill badge ────────────────────────────────────────────────────

class _PillBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _PillBadge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(label,
        style: TextStyle(
            color: color, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}

// ── Estado vazio ──────────────────────────────────────────────────

class _EmptyDay extends StatelessWidget {
  final DateTime date;
  const _EmptyDay({required this.date});
  @override
  Widget build(BuildContext context) {
    final isRest = AppDateUtils.isRestDay(date);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(isRest ? '😴' : '🌟',
            style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        Text(
          isRest ? 'Dia de descanso' : 'Dia completamente livre!',
          style: TextStyle(
            color:      isRest ? AppColors.textMuted : AppColors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}