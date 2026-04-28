import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/stats_model.dart';

class StatsService {
  final _api = ApiService();

  /// Estatísticas completas do mês
  Future<MonthlyStats> getMonthly(int month, int year) async {
    try {
      final r = await _api.dio.get(
        ApiEndpoints.monthlyStats,
        queryParameters: {'month': month, 'year': year},
      );
      return MonthlyStats.fromJson(r.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Tendência anual — todos os meses do ano até o mês atual
  /// Endpoint: GET /api/stats/trend?year=2025
  Future<YearTrend> getYearTrend(int year) async {
    try {
      final r = await _api.dio.get(
        ApiEndpoints.trendStats,
        queryParameters: {'year': year},
      );
      return YearTrend.fromJson(r.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }
}
