import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/appointment_model.dart';
import '../../../data/services/appointment_service.dart';
import '../../../providers/appointments_provider.dart';

// ── Catálogo de procedimentos ─────────────────────────────────────
class _Proc {
  static const cilios             = 'Cílios';
  static const sobrancelhaHenna   = 'Sobrancelha com Henna';
  static const sobrancelhaLamina  = 'Sobrancelha sem Henna';
  static const spaLabios          = 'Spa dos Lábios';
  static const depilacao          = 'Depilação';
  static const designCompleto     = 'Designer Completo';

  // Todos os individuais (sem o "completo")
  static const all = [
    cilios,
    sobrancelhaHenna,
    sobrancelhaLamina,
    spaLabios,
    depilacao,
  ];

  static const icons = {
    cilios:            '👁️',
    sobrancelhaHenna:  '🌿',
    sobrancelhaLamina: '✏️',
    spaLabios:         '💋',
    depilacao:         '🪵',
    designCompleto:    '✨',
  };
}

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
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // ── Estado do formulário ─────────────────
  Set<String> _selectedProcs = {};   // procedimentos selecionados
  bool        _designCompleto = false;
  String      _location       = 'Studio Manilha';
  String      _payMethod      = '';
  DateTime    _date           = DateTime.now();
  String      _time           = '09:00';
  bool        _paid           = false;
  bool        _confirmed      = false;
  bool        _loading        = false;
  bool        _isEditing      = false;
  String?     _editId;

  static const _locations     = ['Studio Manilha', 'Studio Guaxindiba'];
  static const _payMethods    = ['A combinar', 'PIX', 'Cartão', 'Dinheiro'];

  @override
  void initState() {
    super.initState();
    if (widget.appointmentId != null) {
      _isEditing = true;
      _editId    = widget.appointmentId;
      _loadForEdit();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Lógica de seleção de procedimentos ───

  void _toggleProc(String proc) {
    setState(() {
      if (proc == _Proc.designCompleto) {
        // "Designer Completo" seleciona/deseleciona todos
        if (_designCompleto) {
          _designCompleto = false;
          _selectedProcs  = {};
        } else {
          _designCompleto = true;
          _selectedProcs  = Set.from(_Proc.all);
        }
      } else {
        _designCompleto = false;
        if (_selectedProcs.contains(proc)) {
          _selectedProcs = Set.from(_selectedProcs)..remove(proc);
        } else {
          _selectedProcs = Set.from(_selectedProcs)..add(proc);
        }
        // Se todos individuais estão marcados → ativa "completo"
        if (_selectedProcs.containsAll(_Proc.all)) {
          _designCompleto = true;
        }
      }
    });
  }

  List<String> get _proceduresList =>
      _designCompleto ? List.from(_Proc.all) : List.from(_selectedProcs);

  // ── Carrega para edição ──────────────────

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

        // Restaura procedimentos selecionados
        _selectedProcs  = Set.from(apt.procedures);
        _designCompleto = _selectedProcs.containsAll(_Proc.all);
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: AppColors.rose),
        );
      }
    }
  }

  // ── Submit ───────────────────────────────

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
          content: Text(_isEditing ? '✅ Agendamento atualizado!' : '✅ Agendamento criado!'),
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

  // ── Build ────────────────────────────────

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
                  // ── Nome da cliente ────────
                  _Label('👤 Nome da cliente'),
                  TextFormField(
                    controller:          _nameCtrl,
                    style:               const TextStyle(color: AppColors.text),
                    decoration:          const InputDecoration(hintText: 'Amanda Silva'),
                    validator:           Validators.clientName,
                    textCapitalization:  TextCapitalization.words,
                  ),
                  const SizedBox(height: 18),

                  // ── Procedimentos (multi-select) ────
                  _Label('✨ Procedimentos'),
                  _ProcedureSelector(
                    selected:        _selectedProcs,
                    designCompleto:  _designCompleto,
                    onToggle:        _toggleProc,
                  ),
                  if (_proceduresList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ProcedureSummary(procedures: _proceduresList),
                  ],
                  const SizedBox(height: 18),

                  // ── Data + Hora ────────────
                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('📅 Data'),
                            _DateField(
                                date: _date,
                                onChanged: (d) => setState(() => _date = d)),
                          ]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('⏰ Horário'),
                            _TimeField(
                                time: _time,
                                onChanged: (t) => setState(() => _time = t)),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 18),

                  // ── Local ──────────────────
                  _Label('📍 Local'),
                  _DropdownField<String>(
                    value:     _location,
                    items:     _locations,
                    display:   (v) => v,
                    onChanged: (v) => setState(() => _location = v!),
                  ),
                  const SizedBox(height: 18),

                  // ── Valor ──────────────────
                  _Label('💰 Valor (R\$)'),
                  TextFormField(
                    controller:   _priceCtrl,
                    style:        const TextStyle(color: AppColors.text),
                    keyboardType: TextInputType.number,
                    decoration:   const InputDecoration(
                        hintText: '150', prefixText: 'R\$ '),
                    validator: Validators.price,
                  ),
                  const SizedBox(height: 18),

                  // ── Forma de pagamento ─────
                  _Label('💳 Forma de pagamento'),
                  _DropdownField<String>(
                    value: _payMethod.isEmpty ? 'A combinar' : _payMethod,
                    items: _payMethods,
                    display: (v) => v,
                    onChanged: (v) =>
                        setState(() => _payMethod = v == 'A combinar' ? '' : v!),
                  ),
                  const SizedBox(height: 16),

                  // ── Toggles ────────────────
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

                  // ── Observações ────────────
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

                  // ── Botão submit ───────────
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width:  20,
                            child:  CircularProgressIndicator(
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

// ── Seletor de procedimentos ─────────────────────────────────────

class _ProcedureSelector extends StatelessWidget {
  final Set<String>           selected;
  final bool                  designCompleto;
  final ValueChanged<String>  onToggle;

  const _ProcedureSelector({
    required this.selected,
    required this.designCompleto,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Procedimentos individuais
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _Proc.all.map((proc) {
              final isSelected = selected.contains(proc);
              final icon       = _Proc.icons[proc] ?? '✨';
              return _ProcChip(
                label:      '$icon $proc',
                selected:   isSelected,
                color:      _chipColor(proc),
                onTap:      () => onToggle(proc),
              );
            }).toList(),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.cardBorder, height: 1),
          ),

          // Designer Completo
          _ProcChip(
            label:    '✨ Designer Completo',
            selected: designCompleto,
            color:    AppColors.gold,
            onTap:    () => onToggle(_Proc.designCompleto),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Color _chipColor(String proc) {
    switch (proc) {
      case _Proc.cilios:            return AppColors.lavender;
      case _Proc.sobrancelhaHenna:  return AppColors.green;
      case _Proc.sobrancelhaLamina: return AppColors.rose;
      case _Proc.spaLabios:         return const Color(0xFFFF9898);
      case _Proc.depilacao:         return const Color(0xFF98CFFF);
      default:                      return AppColors.gold;
    }
  }
}

class _ProcChip extends StatelessWidget {
  final String  label;
  final bool    selected;
  final Color   color;
  final VoidCallback onTap;
  final bool    fullWidth;

  const _ProcChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width:   fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:        selected
              ? color.withValues(alpha: 0.18)
              : AppColors.cardBorder.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: fullWidth
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle, color: color, size: 14),
              ),
            Text(
              label,
              style: TextStyle(
                color:      selected ? color : AppColors.textMuted,
                fontSize:   13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Resumo dos procedimentos selecionados
class _ProcedureSummary extends StatelessWidget {
  final List<String> procedures;
  const _ProcedureSummary({required this.procedures});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:        AppColors.rose.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.rose, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              procedures.join(' + '),
              style: const TextStyle(
                  color: AppColors.rose, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares do formulário ─────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color:         AppColors.textMuted,
                fontSize:      11,
                letterSpacing: 0.5)),
      );
}

class _DropdownField<T> extends StatelessWidget {
  final T                  value;
  final List<T>            items;
  final String Function(T) display;
  final ValueChanged<T?>   onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.display,
    required this.onChanged,
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
        items:     items.map((i) => DropdownMenuItem(value: i, child: Text(display(i)))).toList(),
        onChanged: onChanged,
      );
}

class _DateField extends StatelessWidget {
  final DateTime           date;
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

class _TimeField extends StatelessWidget {
  final String             time;
  final ValueChanged<String> onChanged;
  const _TimeField({required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final parts  = time.split(':');
          final picked = await showTimePicker(
            context:     context,
            initialTime: TimeOfDay(
                hour:   int.parse(parts[0]),
                minute: int.parse(parts[1])),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                      primary: AppColors.rose, surface: AppColors.card)),
              child: child!,
            ),
          );
          if (picked != null) {
            onChanged(
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color:        AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppColors.cardBorder),
          ),
          child: Row(children: [
            const Icon(Icons.access_time_outlined,
                color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(time,
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
  const _Toggle(
      {required this.label,
      required this.value,
      required this.color,
      required this.onChanged});

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
            Text(label,
                style: const TextStyle(color: AppColors.text, fontSize: 13)),
            Switch(
                value:          value,
                onChanged:      onChanged,
                activeThumbColor: color),
          ],
        ),
      );
}