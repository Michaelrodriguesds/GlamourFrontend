import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/general_note_model.dart';
import '../../../providers/general_note_provider.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(generalNoteProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generalNoteProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('GLAMOUR AGENDA',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
          Text('Notas · ${state.notes.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: AppColors.textMuted),
            onPressed: () => ref.read(generalNoteProvider.notifier).load(),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.rose),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: Column(children: [
        // ── Busca ───────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: '🔍 Buscar anotação...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                        ref.read(generalNoteProvider.notifier).setSearch('');
                      })
                  : null,
            ),
            onChanged: (v) {
              setState(() => _query = v);
              ref.read(generalNoteProvider.notifier).setSearch(v);
            },
          ),
        ),

        // ── Filtro por tag ───────────────────────
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              null,
              ...AppStrings.noteTags.keys,
            ].map<Widget>((tag) {
              final sel = tag == state.tagFilter;
              final label = tag == null ? '📋 Todas' : AppStrings.noteTags[tag]!;
              return Padding(
                padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
                child: ChoiceChip(
                  label: Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: sel ? AppColors.rose : AppColors.textMuted)),
                  selected: sel,
                  onSelected: (_) => ref
                      .read(generalNoteProvider.notifier)
                      .setTagFilter(tag),
                  selectedColor: AppColors.rose.withValues(alpha: 0.15),
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

        // ── Lista de notas ───────────────────────
        Expanded(
          child: state.loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.rose, strokeWidth: 2.5))
              : state.notes.isEmpty
                  ? _EmptyState(hasFilter: _query.isNotEmpty || state.tagFilter != null)
                  : RefreshIndicator(
                      color: AppColors.rose,
                      onRefresh: () => ref.read(generalNoteProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                        itemCount: state.sorted.length,
                        itemBuilder: (_, i) => _NoteCard(
                          note: state.sorted[i],
                          onTap:    () => _openForm(context, note: state.sorted[i]),
                          onPin:    () => ref.read(generalNoteProvider.notifier).togglePin(state.sorted[i].id),
                          onDelete: () => _confirmDelete(state.sorted[i]),
                        ),
                      ),
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.rose,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openForm(BuildContext context, {GeneralNote? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _NoteForm(
        note: note,
        onSave: (title, content, tag, color) async {
          final n = GeneralNote(
            id:        note?.id ?? '',
            title:     title,
            content:   content,
            tag:       tag,
            color:     color,
            pinned:    note?.pinned ?? false,
            createdAt: note?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );
          if (note == null) {
            await ref.read(generalNoteProvider.notifier).create(n);
          } else {
            await ref.read(generalNoteProvider.notifier).update(note.id, n);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(GeneralNote note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Excluir anotação',
            style: TextStyle(color: AppColors.text, fontSize: 16)),
        content: Text('"${note.title}"',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir',
                  style: TextStyle(color: AppColors.rose))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(generalNoteProvider.notifier).delete(note.id);
    }
  }
}

// ── Card de anotação ─────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final GeneralNote  note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  Color get _accent {
    try {
      final hex = note.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.lavender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagLabel = AppStrings.noteTags[note.tag] ?? '📝 Geral';
    final updatedStr = _formatDate(note.updatedAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        // ── Borda uniforme (mesma cor em todos os lados) + borderRadius ──
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Barra colorida esquerda (elemento separado) ──
              Container(width: 4, color: _accent),
              // ── Conteúdo ─────────────────────────────────────
              Expanded(
                child: Container(
                  color: AppColors.card,
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Título + ações
            Row(children: [
              if (note.pinned)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.push_pin, color: AppColors.rose, size: 14),
                ),
              Expanded(
                child: Text(note.title,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
              // Pin button
              GestureDetector(
                onTap: onPin,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: note.pinned ? AppColors.rose : AppColors.textDim,
                    size: 16,
                  ),
                ),
              ),
              // Delete button
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline,
                      color: AppColors.textDim, size: 16),
                ),
              ),
            ]),
            const SizedBox(height: 6),

            // Conteúdo (preview)
            if (note.content.isNotEmpty)
              Text(
                note.content,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),

            // Tag + data
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withValues(alpha: 0.4)),
                ),
                child: Text(tagLabel,
                    style: TextStyle(
                        color: _accent, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(updatedStr,
                  style: const TextStyle(
                      color: AppColors.textDim, fontSize: 9)),
            ]),
          ]),  // Column
                ), // Container (conteúdo)
              ), // Expanded
            ],   // Row children
          ),     // Row
          ),     // IntrinsicHeight
        ),       // ClipRRect
      ),         // Container (borda)
    );           // GestureDetector
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Hoje ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    }
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}

// ── Formulário de anotação ────────────────────────────────────────

class _NoteForm extends StatefulWidget {
  final GeneralNote? note;
  final Future<void> Function(String title, String content, String tag, String color) onSave;

  const _NoteForm({this.note, required this.onSave});

  @override
  State<_NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<_NoteForm> {
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _tag        = 'geral';
  String _color      = '#B47FD4';
  bool   _saving     = false;

  static const _colors = [
    '#B47FD4', // Lavanda
    '#E8527A', // Rose
    '#4ECBA0', // Green
    '#F0C060', // Gold
    '#98CFFF', // Blue
    '#FF9898', // Salmon
    '#8A7A9A', // Muted
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleCtrl.text   = widget.note!.title;
      _contentCtrl.text = widget.note!.content;
      _tag   = widget.note!.tag;
      _color = widget.note!.color;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título é obrigatório'),
            backgroundColor: AppColors.rose));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _titleCtrl.text.trim(),
        _contentCtrl.text.trim(),
        _tag,
        _color,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.rose));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: AppColors.textDim, borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Row(children: [
          Text(widget.note == null ? '📝 Nova Anotação' : '✏️ Editar Anotação',
              style: const TextStyle(
                  color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (_saving)
            const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: AppColors.rose, strokeWidth: 2))
          else
            TextButton(
              onPressed: _save,
              child: const Text('Salvar',
                  style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 14),

        // Título
        TextField(
          controller: _titleCtrl,
          style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Título da anotação',
            hintStyle: const TextStyle(color: AppColors.textDim),
            filled: true, fillColor: AppColors.background,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.rose, width: 1.5)),
          ),
        ),
        const SizedBox(height: 12),

        // Conteúdo
        TextField(
          controller: _contentCtrl,
          style: const TextStyle(color: AppColors.text, fontSize: 13),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Escreva sua anotação...',
            hintStyle: const TextStyle(color: AppColors.textDim),
            filled: true, fillColor: AppColors.background,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.rose, width: 1.5)),
          ),
        ),
        const SizedBox(height: 14),

        // Tags
        Row(children: [
          const Text('Tag:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppStrings.noteTags.entries.map((e) {
                  final sel = e.key == _tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _tag = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.rose.withValues(alpha: 0.2) : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? AppColors.rose : AppColors.cardBorder),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                                color: sel ? AppColors.rose : AppColors.textMuted,
                                fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Cor
        Row(children: [
          const Text('Cor:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(width: 10),
          ..._colors.map((hex) {
            Color c;
            try { c = Color(int.parse('FF${hex.replaceFirst('#','')}', radix: 16)); }
            catch (_) { c = AppColors.lavender; }
            final sel = hex == _color;
            return GestureDetector(
              onTap: () => setState(() => _color = hex),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                width: sel ? 28 : 24,
                height: sel ? 28 : 24,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: sel ? Border.all(color: Colors.white, width: 2.5) : null,
                  boxShadow: sel ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)] : null,
                ),
              ),
            );
          }),
        ]),
        const SizedBox(height: 8),
      ]),
      ), // SingleChildScrollView
    );
  }
}

// ── Estado vazio ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('📝', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 8),
      Text(
        hasFilter ? 'Nenhuma anotação encontrada' : 'Nenhuma anotação ainda\nToque em + para criar',
        style: const TextStyle(color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
    ]),
  );
}