import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/stats_provider.dart';
import '../../../data/models/stats_model.dart';
import '../../widgets/loading_overlay.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});
  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;

  static const _months = [
    '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];

  @override
  void initState() {
    super.initState();
    // Garante que os dados são sempre frescos ao entrar na aba
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsProvider.notifier).load(_month, _year);
    });
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) { _month = 12; _year--; } else { _month--; }
    });
    ref.read(statsProvider.notifier).load(_month, _year);
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) { _month = 1; _year++; } else { _month++; }
    });
    ref.read(statsProvider.notifier).load(_month, _year);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('GLAMOUR AGENDA',
              style: TextStyle(
                  fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
          const Text('Estatísticas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          // Botão de atualização manual
          IconButton(
            icon: state.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.rose, strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            onPressed: state.loading
                ? null
                : () => ref.read(statsProvider.notifier).load(_month, _year),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: state.loading,
        child: state.stats == null && !state.loading
            ? _AppError(
                message: state.error ?? 'Sem dados',
                onRetry: () =>
                    ref.read(statsProvider.notifier).load(_month, _year))
            : state.stats == null
                ? const SizedBox()
                : Column(
                    children: [
                      // ── Seletor de mês inline (não na AppBar) ──
                      Container(
                        color: AppColors.card,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left,
                                  color: AppColors.textMuted),
                              onPressed: _prevMonth,
                            ),
                            Text(
                              '${_months[_month]} $_year',
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right,
                                  color: AppColors.textMuted),
                              onPressed: _nextMonth,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.cardBorder),
                      Expanded(child: _Body(stats: state.stats!)),
                    ],
                  ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final MonthlyStats stats;
  const _Body({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RevenueCard(revenue: stats.revenue, summary: stats.summary),
        const SizedBox(height: 14),
        _SectionTitle('📊 Procedimentos do Mês'),
        _ProceduresList(procedures: stats.procedures),
        const SizedBox(height: 14),
        _SectionTitle('💳 Formas de Pagamento'),
        _PaymentPieChart(methods: stats.paymentMethods),
        const SizedBox(height: 14),
        _SectionTitle('📍 Por Localidade'),
        _LocationBars(locations: stats.locations),
        const SizedBox(height: 14),
        _SectionTitle('👑 Top Clientes'),
        _TopClients(clients: stats.topClients),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Receita ───────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  final Revenue revenue;
  final Summary summary;
  const _RevenueCard({required this.revenue, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.card,
          AppColors.cardBorder.withValues(alpha: 0.3)
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('RECEITA DO MÊS',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 10, letterSpacing: 2)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'R\$ ${revenue.total.toStringAsFixed(0)}',
            style: const TextStyle(
                color: AppColors.gold, fontSize: 32, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _RevItem(
              'R\$ ${revenue.received.toStringAsFixed(0)}', 'Recebido', AppColors.green),
          const SizedBox(width: 20),
          _RevItem(
              'R\$ ${revenue.pending.toStringAsFixed(0)}', 'Pendente', AppColors.rose),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value:           revenue.receivedPercentage / 100,
            backgroundColor: AppColors.cardBorder,
            valueColor:      const AlwaysStoppedAnimation(AppColors.green),
            minHeight:       6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${revenue.receivedPercentage}% recebido · ${summary.totalAppointments} atendimentos',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ]),
    );
  }
}

class _RevItem extends StatelessWidget {
  final String value, label;
  final Color  color;
  const _RevItem(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ]);
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.5)),
      );
}

// ── Procedimentos ─────────────────────────────────────────────────

class _ProceduresList extends StatelessWidget {
  final List<ProcedureStat> procedures;
  const _ProceduresList({required this.procedures});

  @override
  Widget build(BuildContext context) {
    if (procedures.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder)),
        child: const Center(
          child: Text('Nenhum procedimento no mês',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color:        AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.cardBorder)),
      child: Column(
        children: procedures.asMap().entries.map((e) {
          final p     = e.value;
          final color = AppColors.forProcedure(p.procedure);
          return Padding(
            padding: EdgeInsets.only(
                bottom: e.key < procedures.length - 1 ? 14 : 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text(p.procedure,
                      style: const TextStyle(
                          color: AppColors.text, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Text('${p.count} atend.',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value:           p.percentage / 100,
                  backgroundColor: AppColors.cardBorder,
                  valueColor:      AlwaysStoppedAnimation(color),
                  minHeight:       6,
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── Pagamentos ────────────────────────────────────────────────────

class _PaymentPieChart extends StatelessWidget {
  final List<PaymentMethodStat> methods;
  const _PaymentPieChart({required this.methods});

  static const _colors = [
    AppColors.green, AppColors.lavender, AppColors.gold, AppColors.rose
  ];

  @override
  Widget build(BuildContext context) {
    if (methods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder)),
        child: const Center(
          child: Text('Sem pagamentos registrados',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxWidth < 360 ? 160.0 : 180.0;
        return Container(
      height: chartHeight,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color:        AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.cardBorder)),
      child: Row(children: [
        Expanded(
          child: PieChart(PieChartData(
            sections: methods.asMap().entries.map((e) => PieChartSectionData(
              value:      e.value.percentage.toDouble(),
              color:      _colors[e.key % _colors.length],
              title:      '${e.value.percentage}%',
              titleStyle: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              radius: 55,
            )).toList(),
            sectionsSpace: 2,
          )),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: methods.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                width:  10,
                height: 10,
                decoration: BoxDecoration(
                    color:        _colors[e.key % _colors.length],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text('${e.value.method} ${e.value.percentage}%',
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          )).toList(),
          ),
        ),
      ]),
        );
      },
    );
  }
}

// ── Localidades ───────────────────────────────────────────────────

class _LocationBars extends StatelessWidget {
  final List<LocationStat> locations;
  const _LocationBars({required this.locations});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.rose, AppColors.lavender];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color:        AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.cardBorder)),
      child: Column(
        children: locations.asMap().entries.map((e) {
          final l = e.value;
          final c = colors[e.key % colors.length];
          return Padding(
            padding: EdgeInsets.only(
                bottom: e.key < locations.length - 1 ? 10 : 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('📍 ${l.location.replaceAll('Studio ', '')}',
                    style:
                        const TextStyle(color: AppColors.text, fontSize: 12)),
                Text('${l.percentage}%',
                    style: TextStyle(
                        color: c, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value:           l.percentage / 100,
                  backgroundColor: AppColors.cardBorder,
                  valueColor:      AlwaysStoppedAnimation(c),
                  minHeight:       6,
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── Top Clientes ──────────────────────────────────────────────────

class _TopClients extends StatelessWidget {
  final List<ClientStat> clients;
  const _TopClients({required this.clients});

  static const _medals = ['🥇', '🥈', '🥉'];
  static const _colors = [AppColors.gold, AppColors.lavender, AppColors.rose];

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder)),
        child: const Center(
          child: Text('Sem clientes no mês',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
          color:        AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: AppColors.cardBorder)),
      child: Column(
        children: clients.take(5).toList().asMap().entries.map((e) {
          final c     = e.value;
          final color = e.key < 3 ? _colors[e.key] : AppColors.textMuted;
          return ListTile(
            leading: Container(
              width:  34,
              height: 34,
              decoration: BoxDecoration(
                color:  color.withValues(alpha: 0.2),
                shape:  BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  e.key < 3 ? _medals[e.key] : '${e.key + 1}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            title: Text(c.clientName,
                style: const TextStyle(color: AppColors.text, fontSize: 13)),
            subtitle: Text('${c.count} atendimentos',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            trailing: Text('R\$ ${c.revenue.toStringAsFixed(0)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          );
        }).toList(),
      ),
    );
  }
}

// ── Estado de erro ────────────────────────────────────────────────

class _AppError extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _AppError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('😕', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          TextButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente',
                style: TextStyle(color: AppColors.rose)),
          ),
        ]),
      );
}