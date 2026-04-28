import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/availability_model.dart';
import '../../../providers/availability_provider.dart';
import '../../../providers/refresh_provider.dart';
import 'day_slots_widget.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime        _focusedDay    = DateTime.now();
  DateTime        _selectedDay   = DateTime.now();
  String?         _location;
  int             _lastRefresh   = -1;
  CalendarFormat  _calendarFormat = CalendarFormat.week; // ← semana por padrão

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Usa modo mês ou semana dependendo da altura disponível
      final height = WidgetsBinding
          .instance.platformDispatcher.views.first.physicalSize.height /
          WidgetsBinding
              .instance.platformDispatcher.views.first.devicePixelRatio;
      if (height >= 700 && mounted) {
        setState(() => _calendarFormat = CalendarFormat.month);
      }
      _loadMonth();
    });
  }

  void _loadMonth() {
    ref.read(availabilityProvider.notifier)
        .loadMonth(_focusedDay.month, _focusedDay.year, location: _location);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final refresh = ref.watch(refreshProvider);
    if (refresh != _lastRefresh) {
      _lastRefresh = refresh;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
    }

    final state  = ref.watch(availabilityProvider);
    final dayMap = <int, DayAvailability>{
      for (final d in state.monthDays) d.day: d
    };

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('GLAMOUR AGENDA',
              style: TextStyle(
                  fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
          const Text('Calendário',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          // ── Toggle semana / mês ────────────────
          IconButton(
            tooltip: _calendarFormat == CalendarFormat.month
                ? 'Vista semana'
                : 'Vista mês',
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.calendar_view_week_outlined
                  : Icons.calendar_month_outlined,
              color: AppColors.rose,
              size: 20,
            ),
            onPressed: () => setState(() {
              _calendarFormat = _calendarFormat == CalendarFormat.month
                  ? CalendarFormat.week
                  : CalendarFormat.month;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: AppColors.textMuted),
            onPressed: _loadMonth,
          ),
        ],
      ),
      body: Column(children: [

        // ── Filtro de local ──────────────────────
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              null,
              ...AppStrings.locations,
            ].map<Widget>((loc) {
              final sel = loc == _location;
              return Padding(
                padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                child: ChoiceChip(
                  label: Text(
                    loc ?? 'Todos',
                    style: TextStyle(
                        fontSize: 11,
                        color: sel ? AppColors.rose : AppColors.textMuted),
                  ),
                  selected:        sel,
                  onSelected:      (_) {
                    setState(() => _location = loc);
                    _loadMonth();
                  },
                  selectedColor:   AppColors.rose.withValues(alpha: 0.15),
                  backgroundColor: AppColors.card,
                  side: BorderSide(
                      color: sel
                          ? AppColors.rose.withValues(alpha: 0.5)
                          : AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  labelPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),

        // ── Calendário ───────────────────────────
        TableCalendar(
          locale:    'pt_BR',
          firstDay:  DateTime(2025),
          lastDay:   DateTime(2027),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Mês',
            CalendarFormat.week:  'Semana',
          },
          selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
          onFormatChanged: (format) => setState(() => _calendarFormat = format),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay  = focused;
            });
            ref.read(availabilityProvider.notifier).loadDaySlots(
              selected.day, selected.month, selected.year,
              location: _location,
            );
          },
          onPageChanged: (focused) {
            setState(() => _focusedDay = focused);
            ref.read(availabilityProvider.notifier)
                .loadMonth(focused.month, focused.year, location: _location);
          },
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (ctx, day, focused) {
              final info = dayMap[day.day];
              if (info == null) return null;
              return _DayCell(
                  day: day.day, status: info.status, selected: false);
            },
            selectedBuilder: (ctx, day, focused) {
              final info = dayMap[day.day];
              return _DayCell(
                  day: day.day,
                  status: info?.status ?? DayStatus.free,
                  selected: true);
            },
            todayBuilder: (ctx, day, focused) {
              final info = dayMap[day.day];
              return _DayCell(
                  day: day.day,
                  status: info?.status ?? DayStatus.free,
                  selected: false,
                  isToday: true);
            },
          ),
          // ── Tamanho compacto da grade ────────────
          rowHeight:    screenHeight < 700 ? 36 : 42,
          daysOfWeekHeight: 20,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered:       true,
            headerPadding: EdgeInsets.symmetric(
                vertical: screenHeight < 700 ? 4 : 8),
            titleTextStyle: const TextStyle(
                color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 14),
            leftChevronIcon:
                const Icon(Icons.chevron_left, color: AppColors.textMuted, size: 20),
            rightChevronIcon:
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            leftChevronPadding:  const EdgeInsets.all(4),
            rightChevronPadding: const EdgeInsets.all(4),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
            weekendStyle: TextStyle(color: AppColors.textDim,   fontSize: 11),
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle:   TextStyle(color: AppColors.textMuted),
            cellMargin:         EdgeInsets.all(2),
          ),
        ),

        // ── Legenda compacta ─────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend('Livre',    AppColors.green),
              const SizedBox(width: 12),
              _Legend('Parcial',  AppColors.gold),
              const SizedBox(width: 12),
              _Legend('Cheio',    AppColors.rose),
              const SizedBox(width: 12),
              _Legend('Descanso', AppColors.textDim),
            ],
          ),
        ),

        // ── Cabeçalho do dia selecionado ─────────
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(
              top:    BorderSide(color: AppColors.cardBorder),
              bottom: BorderSide(color: AppColors.cardBorder),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Data selecionada
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.rose, size: 13),
                const SizedBox(width: 6),
                Text(
                  _formatSelectedDay(_selectedDay),
                  style: const TextStyle(
                      color:      AppColors.text,
                      fontSize:   12,
                      fontWeight: FontWeight.w600),
                ),
              ]),
              // Contadores rápidos
              if (state.daySlots.isNotEmpty)
                Row(children: [
                  _SlotCounter(
                    count: state.daySlots.where((s) => !s.available).length,
                    label: 'agend.',
                    color: AppColors.rose,
                  ),
                  const SizedBox(width: 10),
                  _SlotCounter(
                    count: state.daySlots.where((s) => s.available).length,
                    label: 'livres',
                    color: AppColors.green,
                  ),
                ]),
            ],
          ),
        ),

        // ── Lista de slots ───────────────────────
        Expanded(
          child: DaySlotsWidget(
            date:    _selectedDay,
            slots:   state.daySlots,
            loading: state.loading,
          ),
        ),
      ]),
    );
  }

  String _formatSelectedDay(DateTime d) {
    const weekdays = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const months   = ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
                          'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return '${weekdays[d.weekday]}, ${d.day} ${months[d.month]} ${d.year}';
  }
}

// ── Contador de slots no cabeçalho ────────────────────────────────

class _SlotCounter extends StatelessWidget {
  final int    count;
  final String label;
  final Color  color;
  const _SlotCounter(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width:  18,
          height: 18,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Center(
            child: Text('$count',
                style: TextStyle(
                    color:      color,
                    fontSize:   9,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(color: color, fontSize: 10)),
      ]);
}

// ── Célula do dia ─────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final int       day;
  final DayStatus status;
  final bool      selected;
  final bool      isToday;

  const _DayCell({
    required this.day,
    required this.status,
    required this.selected,
    this.isToday = false,
  });

  Color get _color {
    switch (status) {
      case DayStatus.free:    return AppColors.green;
      case DayStatus.partial: return AppColors.gold;
      case DayStatus.full:    return AppColors.rose;
      case DayStatus.rest:    return AppColors.textDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? _color.withValues(alpha: 0.3)
        : isToday
            ? _color.withValues(alpha: 0.15)
            : Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? _color
              : isToday
                  ? _color.withValues(alpha: 0.6)
                  : Colors.transparent,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: selected || isToday
                ? _color
                : _color.withValues(alpha: 0.8),
            fontSize:   12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Legenda ───────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  final String label;
  final Color  color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width:  8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 9)),
      ]);
}