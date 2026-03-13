import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/general_note_service.dart';
import '../data/models/general_note_model.dart';

// ── Estado ───────────────────────────────────
class GeneralNoteState {
  final List<GeneralNote> notes;
  final bool              loading;
  final String?           error;
  final String?           tagFilter;
  final String            search;

  const GeneralNoteState({
    this.notes     = const [],
    this.loading   = false,
    this.error,
    this.tagFilter,
    this.search    = '',
  });

  GeneralNoteState copyWith({
    List<GeneralNote>? notes,
    bool?              loading,
    String?            error,
    String?            tagFilter,
    String?            search,
    bool               clearTag   = false,
    bool               clearError = false,
  }) =>
      GeneralNoteState(
        notes:     notes     ?? this.notes,
        loading:   loading   ?? this.loading,
        error:     clearError ? null : (error ?? this.error),
        tagFilter: clearTag  ? null : (tagFilter ?? this.tagFilter),
        search:    search    ?? this.search,
      );

  /// Pinnadas primeiro, depois por data de atualização
  List<GeneralNote> get sorted {
    final list = [...notes];
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }
}

// ── Notifier ─────────────────────────────────
class GeneralNoteNotifier extends StateNotifier<GeneralNoteState> {
  final GeneralNoteService _service;

  GeneralNoteNotifier(this._service) : super(const GeneralNoteState()) {
    load();
  }

  Future<void> load({String? tag, String? search}) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final list = await _service.getAll(
        tag:    tag    ?? state.tagFilter,
        search: search ?? (state.search.isNotEmpty ? state.search : null),
      );
      state = state.copyWith(notes: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setTagFilter(String? tag) {
    state = state.copyWith(tagFilter: tag, clearTag: tag == null);
    load(tag: tag);
  }

  void setSearch(String query) {
    state = state.copyWith(search: query);
    load(search: query.isNotEmpty ? query : null);
  }

  Future<void> create(GeneralNote note) async {
    try {
      final created = await _service.create(note);
      state = state.copyWith(notes: [created, ...state.notes]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> update(String id, GeneralNote note) async {
    try {
      final updated = await _service.update(id, note);
      state = state.copyWith(
        notes: state.notes.map((n) => n.id == id ? updated : n).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _service.delete(id);
      state = state.copyWith(
        notes: state.notes.where((n) => n.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> togglePin(String id) async {
    try {
      final updated = await _service.togglePin(id);
      state = state.copyWith(
        notes: state.notes.map((n) => n.id == id ? updated : n).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// ── Provider global ───────────────────────────
final generalNoteProvider =
    StateNotifierProvider<GeneralNoteNotifier, GeneralNoteState>((ref) {
  return GeneralNoteNotifier(GeneralNoteService());
});
