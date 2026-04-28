import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/models/availability_model.dart';
import '../../../data/services/appointment_service.dart';
import '../../../data/services/availability_service.dart';
import '../../../providers/appointments_provider.dart';

// ── Catálogo de procedimentos ─────────────────────────────────────
class _Proc {
  static const ciliosTufinho      = 'Cílios Tufinho';
  static const sobrancelhaHenna   = 'Sobrancelha com Henna';
  static const sobrancelhaLamina  = 'Sobrancelha sem Henna';
  static const spaLabios          = 'Spa dos Lábios';
  static const depilacao          = 'Depilação';
  static const limpezaPele        = 'Limpeza de Pele';

  static const all = [
    ciliosTufinho,
    sobrancelhaHenna,
    sobrancelhaLamina,
    spaLabios,
    depilacao,
    limpezaPele,
  ];

  static const icons = {
    ciliosTufinho:     '✨',
    sobrancelhaHenna:  '🌿',
    sobrancelhaLamina: '✏️',
    spaLabios:         '💋',
    depilacao:         '🪵',
    limpezaPele:       '🧴',
  };

  static Color colorOf(String proc) {
    switch (proc) {
      case _Proc.ciliosTufinho:     return AppColors.ciliosTufinho;
      case _Proc.sobrancelhaHenna:  return AppColors.green;
      case _Proc.sobrancelhaLamina: return AppColors.rose;
      case _Proc.spaLabios:         return const Color(0xFFFF9898);
      case _Proc.depilacao:         return const Color(0xFF98CFFF);
      case _Proc.limpezaPele:       return AppColors.gold;
      default:                      return AppColors.lavender;
    }
  }
}

// ── Slots de horário (07–21h) ─────────────────────────────────────
const _timeSlots = [
  '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
  '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00',
];

// ─────────────────────────────────────────────────────────────────

class AppointmentFormScreen extends ConsumerStatefulWidget {
  final String? appointmentId;
  const AppointmentFormScreen({super.key, this.appointmentId});

  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState
    extends ConsumerState<AppointmentFormScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Set<String> _selectedProcs = {};
  String      _location       = 'Studio Manilha';
  String      _payMethod      = '';
  DateTime    _date           = DateTime.now();
  String      _time           = '09:00';
  bool        _paid           = false;
  bool        _confirmed      = false;
  bool        _loading        = false;
  bool        _isEditing      = false;
  String?     _editId;

  // ── Disponibilidade do dia selecionado ──────────────────────────
  Map<String, TimeSlot> _slotMap  = {};
  bool                  _loadingSlots = false;

  static const _locations  = ['Studio Manilha', 'Studio Guaxindiba'];
  static const _payMethods = ['A combinar', 'PIX', 'Cartão', 'Dinheiro'];

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null) {
      _isEditing = true;
      _editId    = widget.appointmentId;
      _loadForEdit();
    } else {
      _loadSlots(); // carrega disponibilidade do dia atual
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Carregar disponibilidade real do dia ─────────────────────────

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    try {
      final dateStr =
          '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
      final slots = await AvailabilityService().getDaySlots(
        dateStr,
        location: _location,
      );
      if (mounted) {
        setState(() {
          _slotMap      = {for (final s in slots) s.time: s};
          _loadingSlots = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _slotMap = {}; _loadingSlots = false; });
    }
  }

  void _toggleProc(String proc) {
    setState(() {
      if (_selectedProcs.contains(proc)) {
        _selectedProcs = Set.from(_selectedProcs)..remove(proc);
      } else {
        _selectedProcs = Set.from(_selectedProcs)..add(proc);
      }
    });
  }

  List<String> get _proceduresList => List.from(_selectedProcs);
  bool get _isCombo => _selectedProcs.length > 1;

  Future<void> _loadForEdit() async {
    setState(() => _loading = true);
    try {
      final apt = await AppointmentService().getById(_editId!);
      setState(() {
        _nameCtrl.text  = apt.clientName;
        _priceCtrl.text = apt.price.toStringAsFixed(0);
        _notesCtrl.text = apt.notes;
        _location       = apt.location;
        _payMethod      = apt.paymentMethod;
        _date           = apt.date;
        _time           = apt.time;
        _paid           = apt.paid;
        _confirmed      = apt.confirmed;
        _loading        = false;
        _selectedProcs  = Set.from(
          apt.procedures.where((p) => _Proc.all.contains(p)),
        );
      });
      _loadSlots();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao carregar: $e'),
              backgroundColor: AppColors.rose),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_proceduresList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos um procedimento'),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    // Avisa se o slot está lotado (mas não bloqueia — backend decide)
    final slot = _slotMap[_time];
    if (slot != null && !slot.available && !_isEditing) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Horário lotado',
              style: TextStyle(color: AppColors.rose)),
          content: Text(
            'O horário $_time já tem ${slot.occupancy} de ${slot.maxCapacity} vagas preenchidas.\n\nDeseja tentar assim mesmo?',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Escolher outro')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tentar assim mesmo',
                  style: TextStyle(color: AppColors.rose)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _loading = true);
    try {
      final apt = Appointment(
        id:            _editId ?? '',
        clientName:    _nameCtrl.text.trim(),
        procedures:    _proceduresList,
        date:          _date,
        time:          _time,
        location:      _location,
        price:         double.parse(_priceCtrl.text.replaceAll(',', '.')),
        paymentMethod: _payMethod.isEmpty ? 'A combinar' : _payMethod,
        paid:          _paid,
        confirmed:     _confirmed,
        notes:         _notesCtrl.text.trim(),
        createdAt:     DateTime.now(),
      );

      if (_isEditing) {
        await ref.read(appointmentsProvider.notifier).update(_editId!, apt);
      } else {
        await ref.read(appointmentsProvider.notifier).create(apt);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing
              ? '✅ Agendamento atualizado!'
              : '✅ Agendamento criado!'),
          backgroundColor: AppColors.green,
        ));
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.rose),
        );
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Remover agendamento',
            style: TextStyle(color: AppColors.text)),
        content: const Text('Tem certeza?',
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover',
                style: TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(appointmentsProvider.notifier).delete(_editId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Agendamento' : 'Novo Agendamento'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.rose),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.rose))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Nome ──────────────────────────
                  _Label('👤 Nome da cliente'),
                  TextFormField(
                    controller:         _nameCtrl,
                    style:              const TextStyle(color: AppColors.text),
                    decoration:         const InputDecoration(hintText: 'Amanda Silva'),
                    validator:          Validators.clientName,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 18),

                  // ── Procedimentos ──────────────────
                  _Label('✨ Procedimentos'),
                  _ProcedureSelector(
                    selected: _selectedProcs,
                    onToggle: _toggleProc,
                  ),
                  if (_proceduresList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ProcedureSummary(
                        procedures: _proceduresList, isCombo: _isCombo),
                  ],
                  const SizedBox(height: 18),

                  // ── Data + Hora ────────────────────
                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('📅 Data'),
                            _DateField(
                                date: _date,
                                onChanged: (d) {
                                  setState(() => _date = d);
                                  _loadSlots(); // recarrega disponibilidade
                                }),
                          ]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('⏰ Horário'),
                            _TimeWheelField(
                              time:         _time,
                              slotMap:      _slotMap,
                              loadingSlots: _loadingSlots,
                              editingId:    _editId,
                              onChanged:    (t) => setState(() => _time = t),
                            ),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // ── Local ──────────────────────────
                  _Label('📍 Local'),
                  _DropdownField<String>(
                    value:     _location,
                    items:     _locations,
                    display:   (v) => v,
                    onChanged: (v) {
                      setState(() => _location = v!);
                      _loadSlots(); // recarrega para o novo local
                    },
                  ),
                  const SizedBox(height: 18),

                  // ── Valor ──────────────────────────
                  _Label(_isCombo
                      ? '💰 Valor Total do Combo (R\$)'
                      : '💰 Valor (R\$)'),
                  TextFormField(
                    controller:   _priceCtrl,
                    style:        const TextStyle(color: AppColors.text),
                    keyboardType: TextInputType.number,
                    decoration:   const InputDecoration(
                        hintText: '150', prefixText: 'R\$ '),
                    validator: Validators.price,
                  ),
                  const SizedBox(height: 18),

                  // ── Pagamento ──────────────────────
                  _Label('💳 Forma de pagamento'),
                  _DropdownField<String>(
                    value: _payMethod.isEmpty ? 'A combinar' : _payMethod,
                    items: _payMethods,
                    display: (v) => v,
                    onChanged: (v) =>
                        setState(() => _payMethod = v == 'A combinar' ? '' : v!),
                  ),
                  const SizedBox(height: 16),

                  // ── Toggles ────────────────────────
                  _Toggle(
                    label:     '✅ Pagamento realizado',
                    value:     _paid,
                    color:     AppColors.green,
                    onChanged: (v) => setState(() => _paid = v),
                  ),
                  const SizedBox(height: 8),
                  _Toggle(
                    label:     '✓ Cliente confirmada',
                    value:     _confirmed,
                    color:     AppColors.lavender,
                    onChanged: (v) => setState(() => _confirmed = v),
                  ),
                  const SizedBox(height: 18),

                  // ── Observações ────────────────────
                  _Label('💬 Observações'),
                  TextFormField(
                    controller: _notesCtrl,
                    style:      const TextStyle(color: AppColors.text),
                    maxLines:   3,
                    decoration: const InputDecoration(
                        hintText: 'Ex: pagar na próxima visita...'),
                    validator: Validators.notes,
                  ),
                  const SizedBox(height: 28),

                  // ── Botão submit ───────────────────
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(_isEditing
                            ? 'SALVAR ALTERAÇÕES 🌸'
                            : 'CONFIRMAR AGENDAMENTO 🌸'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ── Time Picker com disponibilidade real ─────────────────────────
//
// Cada chip mostra:
//   • Verde  → livre (0 agendamentos)
//   • Âmbar  → 1 de 2 vagas ocupada
//   • Rosa   → lotado (2 de 2)
//   • Cinza  → carregando

class _TimeWheelField extends StatelessWidget {
  final String               time;
  final Map<String, TimeSlot> slotMap;
  final bool                 loadingSlots;
  final String?              editingId;
  final ValueChanged<String> onChanged;

  const _TimeWheelField({
    required this.time,
    required this.slotMap,
    required this.loadingSlots,
    required this.onChanged,
    this.editingId,
  });

  Color _chipColor(String t) {
    if (loadingSlots || slotMap.isEmpty) return AppColors.textDim;
    final slot = slotMap[t];
    if (slot == null) return AppColors.green;
    if (!slot.available) return AppColors.rose;
    if (slot.occupancy > 0) return AppColors.gold;
    return AppColors.green;
  }

  String _chipLabel(String t) {
    final slot = slotMap[t];
    if (slot == null || slotMap.isEmpty) return t;
    if (!slot.available) return '$t\n✗ lotado';
    if (slot.occupancy > 0) return '$t\n${slot.occupancy}/${slot.maxCapacity}';
    return '$t\nlivre';
  }

  Future<void> _open(BuildContext context) async {
    await showModalBottomSheet(
      context:            context,
      backgroundColor:    AppColors.card,
      isScrollControlled: true,
      useSafeArea:        true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _TimePickerSheet(
        selected:     time,
        slotMap:      slotMap,
        loading:      loadingSlots,
        editingId:    editingId,
        onSelected:   onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slot  = slotMap[time];
    final color = _chipColor(time);

    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color:        AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColors.cardBorder),
        ),
        child: Row(children: [
          Icon(Icons.schedule_outlined, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                      color:      color,
                      fontSize:   16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1),
                ),
                if (slot != null && !loadingSlots)
                  Text(
                    !slot.available
                        ? 'Lotado (${slot.occupancy}/${slot.maxCapacity})'
                        : slot.occupancy > 0
                            ? '${slot.occupancy}/${slot.maxCapacity} vagas usadas'
                            : 'Livre',
                    style: TextStyle(color: color, fontSize: 9),
                  ),
              ],
            ),
          ),
          const Icon(Icons.expand_more, color: AppColors.textMuted, size: 18),
        ]),
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  final String               selected;
  final Map<String, TimeSlot> slotMap;
  final bool                 loading;
  final String?              editingId;
  final ValueChanged<String> onSelected;

  const _TimePickerSheet({
    required this.selected,
    required this.slotMap,
    required this.loading,
    required this.onSelected,
    this.editingId,
  });

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late String _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.selected;
  }

  void _confirm() {
    widget.onSelected(_sel);
    Navigator.pop(context);
  }

  Color _slotColor(String t) {
    final slot = widget.slotMap[t];
    if (slot == null || widget.slotMap.isEmpty) return AppColors.green;
    if (!slot.available) return AppColors.rose;
    if (slot.occupancy > 0) return AppColors.gold;
    return AppColors.green;
  }

  String _slotSub(String t) {
    final slot = widget.slotMap[t];
    if (slot == null || widget.slotMap.isEmpty) return 'livre';
    if (!slot.available) return 'lotado';
    if (slot.occupancy > 0) return '${slot.occupancy}/${slot.maxCapacity}';
    return 'livre';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Handle
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: AppColors.textDim,
              borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Row(children: [
          const Icon(Icons.schedule_outlined, color: AppColors.rose, size: 18),
          const SizedBox(width: 8),
          const Text('Selecionar Horário',
              style: TextStyle(color: AppColors.text, fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:        AppColors.rose.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
            ),
            child: Text(_sel,
                style: const TextStyle(color: AppColors.rose, fontSize: 15,
                    fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ]),

        const SizedBox(height: 10),

        // Legenda
        if (!widget.loading && widget.slotMap.isNotEmpty)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _Dot(AppColors.green,  'Livre'),
            const SizedBox(width: 12),
            _Dot(AppColors.gold,   '1 vaga restante'),
            const SizedBox(width: 12),
            _Dot(AppColors.rose,   'Lotado'),
          ]),
        const SizedBox(height: 14),

        // Grid de horários
        widget.loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                    color: AppColors.rose, strokeWidth: 2))
            : Wrap(
                spacing:    8,
                runSpacing: 8,
                children: _timeSlots.map((t) {
                  final isSel  = t == _sel;
                  final color  = _slotColor(t);
                  final sub    = _slotSub(t);
                  final isFullyBooked = widget.slotMap[t]?.available == false;

                  return GestureDetector(
                    onTap: () => setState(() => _sel = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width:   80,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? color : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? color : color.withValues(alpha: 0.4),
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t,
                            style: TextStyle(
                              color: isSel ? Colors.white : color,
                              fontSize:   13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            style: TextStyle(
                              color: isSel
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : color.withValues(alpha: 0.8),
                              fontSize: 9,
                              fontWeight: isFullyBooked
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Confirmar  $_sel',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color  color;
  final String label;
  const _Dot(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: color, fontSize: 9)),
  ]);
}

// ── Seletor de procedimentos ─────────────────────────────────────

class _ProcedureSelector extends StatelessWidget {
  final Set<String>          selected;
  final ValueChanged<String> onToggle;

  const _ProcedureSelector(
      {required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.cardBorder),
      ),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _Proc.all.map((proc) {
          final isSelected = selected.contains(proc);
          final icon       = _Proc.icons[proc] ?? '✨';
          final color      = _Proc.colorOf(proc);
          return _ProcChip(
            label:    '$icon $proc',
            selected: isSelected,
            color:    color,
            onTap:    () => onToggle(proc),
          );
        }).toList(),
      ),
    );
  }
}

class _ProcChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _ProcChip({
    required this.label, required this.selected,
    required this.color,  required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : AppColors.cardBorder.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (selected)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(Icons.check_circle, color: color, size: 13),
            ),
          Text(label,
              style: TextStyle(
                color:      selected ? color : AppColors.textMuted,
                fontSize:   12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              )),
        ]),
      ),
    );
  }
}

class _ProcedureSummary extends StatelessWidget {
  final List<String> procedures;
  final bool         isCombo;
  const _ProcedureSummary({required this.procedures, required this.isCombo});

  @override
  Widget build(BuildContext context) {
    final color = isCombo ? AppColors.gold : AppColors.rose;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(isCombo ? Icons.auto_awesome : Icons.check_circle_outline,
            color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (isCombo)
              Text('COMBO',
                  style: TextStyle(color: color, fontSize: 9,
                      fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            Text(procedures.join(' + '),
                style: TextStyle(color: color, fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(color: AppColors.textMuted,
                fontSize: 11, letterSpacing: 0.5)),
      );
}

class _DropdownField<T> extends StatelessWidget {
  final T                  value;
  final List<T>            items;
  final String Function(T) display;
  final ValueChanged<T?>   onChanged;

  const _DropdownField({
    required this.value, required this.items,
    required this.display, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        initialValue: value,
        dropdownColor: AppColors.card,
        style: const TextStyle(color: AppColors.text, fontSize: 14),
        decoration: InputDecoration(
          filled:    true,
          fillColor: AppColors.card,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:   const BorderSide(color: AppColors.cardBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:   const BorderSide(color: AppColors.rose, width: 1.5)),
        ),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(display(i))))
            .toList(),
        onChanged: onChanged,
      );
}

class _DateField extends StatelessWidget {
  final DateTime               date;
  final ValueChanged<DateTime> onChanged;
  const _DateField({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context:     context,
            initialDate: date,
            firstDate:   DateTime(2025),
            lastDate:    DateTime(2027),
            builder:     (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                      primary: AppColors.rose, surface: AppColors.card)),
              child: child!,
            ),
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color:        AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppColors.cardBorder),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(AppDateUtils.toFullDate(date),
                style: const TextStyle(color: AppColors.text, fontSize: 13)),
          ]),
        ),
      );
}

class _Toggle extends StatelessWidget {
  final String             label;
  final bool               value;
  final Color              color;
  final ValueChanged<bool> onChanged;
  const _Toggle({
    required this.label, required this.value,
    required this.color,  required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.text, fontSize: 13)),
            Switch(
                value:            value,
                onChanged:        onChanged,
                activeThumbColor: color),
          ],
        ),
      );
}
