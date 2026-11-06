import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/marketing_model.dart';

/// Chamadas da aba "Clientes & Marketing".
class MarketingService {
  final _api = ApiService();

  Map<String, dynamic> _map(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  Future<RemindersData> getReminders() async {
    try {
      final r = await _api.dio.get(ApiEndpoints.marketingReminders);
      return RemindersData.fromJson(_map(r.data));
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  Future<MovementData> getMovement() async {
    try {
      final r = await _api.dio.get(ApiEndpoints.marketingMovement);
      return MovementData.fromJson(_map(r.data));
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  Future<SegmentsData> getSegments() async {
    try {
      final r = await _api.dio.get(ApiEndpoints.marketingSegments);
      return SegmentsData.fromJson(_map(r.data));
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Marca "Enviei". [type]: 'appointment', 'return' ou 'campaign'.
  Future<void> markSent({required String key, required String type, required String clientName}) async {
    try {
      await _api.dio.post(ApiEndpoints.marketingSent,
          data: {'key': key, 'type': type, 'clientName': clientName});
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Desfaz um "Enviei" tocado por engano.
  Future<void> unmarkSent(String key) async {
    try {
      await _api.dio.delete(ApiEndpoints.marketingSent, queryParameters: {'key': key});
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  Future<ClientPrefs> getPrefs(String clientName) async {
    try {
      final r = await _api.dio.get(ApiEndpoints.marketingPrefs(clientName));
      return ClientPrefs.fromJson(_map(r.data));
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  Future<ClientPrefs> updatePrefs(String clientName,
      {bool? remindAppointment, bool? remindReturn}) async {
    try {
      final r = await _api.dio.put(ApiEndpoints.marketingPrefs(clientName), data: {
        if (remindAppointment != null) 'remindAppointment': remindAppointment,
        if (remindReturn != null) 'remindReturn': remindReturn,
      });
      return ClientPrefs.fromJson(_map(r.data));
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }
}
