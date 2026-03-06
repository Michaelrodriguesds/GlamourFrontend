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
  DateTime _focusedDay  = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String?  _location;
  int      _lastRefresh = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
  }

  void _loadMonth() {
    ref.read(availabilityProvider.notifier)
        .loadMonth(_focusedDay.month, _focusedDay.year, location: _location);
  }

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
          const Text('Calendário',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: AppColors.textMuted),
            onPressed: _loadMonth,
          ),
        ],
      ),
      body: Column(children: [
        // ── Filtro de local ─────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                null,
                ...AppStrings.locations,
              ].map<Widget>((loc) {
                final sel = loc == _location;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(loc ?? 'Todos',
                        style: TextStyle(
                            fontSize: 11,
                            color: sel ? AppColors.rose : AppColors.textMuted)),
                    selected: sel,
                    onSelected: (_) {
                      setState(() => _location = loc);
                      _loadMonth();
                    },
                    selectedColor: AppColors.rose.withValues(alpha: 0.15),
                    backgroundColor: AppColors.card,
                    side: BorderSide(
                        color: sel
                            ? AppColors.rose.withValues(alpha: 0.5)
                            : AppColors.cardBorder),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Calendário ──────────────────────────
        TableCalendar(
          locale: 'pt_BR',
          firstDay: DateTime(2025),
          lastDay:  DateTime(2027),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
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
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
                color: AppColors.text, fontWeight: FontWeight.w700),
            leftChevronIcon:
                Icon(Icons.chevron_left, color: AppColors.textMuted),
            rightChevronIcon:
                Icon(Icons.chevron_right, color: AppColors.textMuted),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle:
                TextStyle(color: AppColors.textMuted, fontSize: 12),
            weekendStyle:
                TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),

        // ── Legenda ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend('Livre',    AppColors.green),
              const SizedBox(width: 10),
              _Legend('Parcial',  AppColors.gold),
              const SizedBox(width: 10),
              _Legend('Cheio',    AppColors.rose),
              const SizedBox(width: 10),
              _Legend('Descanso', AppColors.textDim),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Slots do dia selecionado ─────────────
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
}

// ── Widgets ──────────────────────────────────

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
      margin: const EdgeInsets.all(3),
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
        child: Text('$day',
            style: TextStyle(
              color: selected
                  ? _color
                  : isToday
                      ? _color
                      : _color.withValues(alpha: 0.8),
              fontSize:   13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            )),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color  color;
  const _Legend(this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 9)),
  ]);
}