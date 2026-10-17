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
    return Column(children: [
      Expanded(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.rose, strokeWidth: 2))
            : slots.isEmpty
                ? _EmptyDay(date: date)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                    itemCount: slots.length,
                    itemBuilder: (_, i) => _SlotRow(
                      slot: slots[i],
                      onTapAppointment: onTapAppointment,
                    ),
                  ),
      ),
    ]);
  }
}

// ── Linha de slot ────────────────────────────────────────────────
// Agora suporta 1 ou 2 agendamentos no mesmo horário.
// Quando há 2, exibe ambos lado a lado (ou empilhados em telas pequenas).

class _SlotRow extends StatelessWidget {
  final TimeSlot slot;
  final void Function(String appointmentId)? onTapAppointment;

  const _SlotRow({required this.slot, this.onTapAppointment});

  @override
  Widget build(BuildContext context) {
    // Slot vazio
    if (!slot.isBooked) {
      return _buildEmptySlot();
    }

    // Slot com 1 agendamento
    if (!slot.isDouble) {
      return _buildSingleSlot(slot.appointments[0]);
    }

    // Slot com 2 ou mais agendamentos simultâneos (ex.: 2 em cada studio
    // quando o calendário mostra "Todos" os locais). TODOS são exibidos.
    return _buildMultiSlot(slot.appointments);
  }

  // ── Slot livre ──────────────────────────────────────────────────

  Widget _buildEmptySlot() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(children: [
          Container(width: 3, height: 48, color: AppColors.green),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(
                  top:    BorderSide(color: AppColors.cardBorder),
                  right:  BorderSide(color: AppColors.cardBorder),
                  bottom: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 38, maxWidth: 48),
                  child: Text(
                    slot.time,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 1, height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: AppColors.green.withValues(alpha: 0.25),
                ),
                const Text(
                  'Livre',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Slot com 1 agendamento ──────────────────────────────────────

  Widget _buildSingleSlot(AppointmentInfo apt) {
    final color = apt.confirmed
        ? AppColors.forProcedure(apt.procedure)
        : AppColors.gold;

    return GestureDetector(
      onTap: apt.id.isNotEmpty
          ? () => onTapAppointment?.call(apt.id)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(children: [
            Container(width: 3, height: 56, color: color),
            Expanded(
              child: Container(
                // `color` e `decoration` juntos no mesmo Container não são
                // permitidos pelo Flutter ("Cannot provide both a color and
                // a decoration") — a cor de fundo precisa ir DENTRO do
                // BoxDecoration, junto com a borda.
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  border: Border(
                    top:    BorderSide(color: AppColors.cardBorder),
                    right:  BorderSide(color: AppColors.cardBorder),
                    bottom: BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  // Horário
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 38, maxWidth: 48),
                    child: Text(
                      slot.time,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 1, height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: color.withValues(alpha: 0.25),
                  ),
                  // Info cliente
                  Expanded(
                    child: _AppointmentTile(apt: apt, color: color),
                  ),
                  Icon(Icons.chevron_right,
                      color: color.withValues(alpha: 0.6), size: 16),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Slot com 2 ou mais agendamentos simultâneos ─────────────────
  // Exibe o horário uma vez à esquerda e TODOS os clientes empilhados à
  // direita. Antes só os 2 primeiros eram desenhados: com o filtro "Todos"
  // (2 vagas por studio = até 4 no mesmo horário), o 3º e o 4º sumiam do
  // calendário.

  Widget _buildMultiSlot(List<AppointmentInfo> apts) {
    final colors = apts
        .map((a) => a.confirmed ? AppColors.forProcedure(a.procedure) : AppColors.gold)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Barra lateral com uma faixa de cor por agendamento
          SizedBox(
            width: 3,
            child: Column(children: [
              for (final c in colors) Expanded(child: Container(color: c)),
            ]),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top:    BorderSide(color: AppColors.cardBorder),
                  right:  BorderSide(color: AppColors.cardBorder),
                  bottom: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Coluna do horário + badge "N×"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: AppColors.rose.withValues(alpha: 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot.time,
                          style: const TextStyle(
                            color: AppColors.rose,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.rose.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${apts.length}×',
                            style: const TextStyle(
                              color: AppColors.rose,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(width: 1, color: AppColors.cardBorder),

                  // Todos os agendamentos empilhados
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < apts.length; i++) ...[
                          if (i > 0) Container(height: 1, color: AppColors.cardBorder),
                          GestureDetector(
                            onTap: apts[i].id.isNotEmpty
                                ? () => onTapAppointment?.call(apts[i].id)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              color: colors[i].withValues(alpha: 0.06),
                              child: _AppointmentTile(apt: apts[i], color: colors[i]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Tile de informações de um agendamento ────────────────────────

class _AppointmentTile extends StatelessWidget {
  final AppointmentInfo apt;
  final Color           color;
  const _AppointmentTile({required this.apt, required this.color});

  String _formatName(String name) {
    if (name.isEmpty) return '—';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts[0];
    return '${parts[0]} ${parts[1][0]}.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Expanded(
            child: Text(
              _formatName(apt.clientName),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              apt.confirmed ? '✓ Conf.' : '⏳ Aguard.',
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 2),
        Text(
          '${AppStrings.procedureIcons[apt.procedure] ?? '✨'}'
          ' ${apt.procedure}  ·  '
          '${apt.location?.replaceAll('Studio ', '') ?? ''}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
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
