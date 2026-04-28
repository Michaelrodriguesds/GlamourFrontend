import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/availability_model.dart';

class AvailabilityService {
  final _api = ApiService();

  /// Slots de horário de um dia específico
  Future<List<TimeSlot>> getDaySlots(String date, {String? location}) async {
    try {
      final params = <String, dynamic>{'date': date};
      if (location != null) params['location'] = location;

      final r = await _api.dio.get(
        ApiEndpoints.availability,
        queryParameters: params,
      );
      return (r.data['slots'] as List)
          .map((e) => TimeSlot.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Status de disponibilidade de cada dia do mês
  Future<List<DayAvailability>> getMonthStatus(
    int month,
    int year, {
    String? location,
  }) async {
    try {
      final params = <String, dynamic>{'month': month, 'year': year};
      if (location != null) params['location'] = location;

      final r = await _api.dio.get(
        ApiEndpoints.monthAvailability,
        queryParameters: params,
      );
      return (r.data['days'] as List)
          .map((e) => DayAvailability.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }
}