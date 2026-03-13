import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/general_note_model.dart';

class GeneralNoteService {
  final _api = ApiService();

  /// Busca todas as anotações
  Future<List<GeneralNote>> getAll({String? tag, String? search}) async {
    try {
      final params = <String, dynamic>{};
      if (tag    != null) params['tag']    = tag;
      if (search != null) params['search'] = search;

      final r = await _api.dio.get(
        ApiEndpoints.notes,
        queryParameters: params.isNotEmpty ? params : null,
      );
      final data = r.data['data'] ?? r.data;
      return (data as List).map((e) => GeneralNote.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Busca uma anotação pelo ID
  Future<GeneralNote> getById(String id) async {
    try {
      final r = await _api.dio.get(ApiEndpoints.noteById(id));
      return GeneralNote.fromJson(r.data['data'] ?? r.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Cria nova anotação
  Future<GeneralNote> create(GeneralNote note) async {
    try {
      final r = await _api.dio.post(
        ApiEndpoints.notes,
        data: note.toJson(),
      );
      return GeneralNote.fromJson(r.data['data'] ?? r.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Atualiza anotação existente
  Future<GeneralNote> update(String id, GeneralNote note) async {
    try {
      final r = await _api.dio.put(
        ApiEndpoints.noteById(id),
        data: note.toJson(),
      );
      return GeneralNote.fromJson(r.data['data'] ?? r.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Remove anotação
  Future<void> delete(String id) async {
    try {
      await _api.dio.delete(ApiEndpoints.noteById(id));
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Fixa / desafixa anotação
  Future<GeneralNote> togglePin(String id) async {
    try {
      final r = await _api.dio.patch(ApiEndpoints.pinNote(id));
      return GeneralNote.fromJson(r.data['data'] ?? r.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }
}
