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
}