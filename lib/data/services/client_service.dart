import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/client_summary_model.dart';

class ClientService {
  final _api = ApiService();

  /// Lista clientes agregados (um resumo por cliente, não por agendamento).
  Future<List<ClientSummary>> getAll({String? search}) async {
    try {
      final r = await _api.dio.get(
        ApiEndpoints.clients,
        queryParameters: search != null && search.isNotEmpty ? {'search': search} : null,
      );
      return (r.data['data'] as List)
          .map((e) => ClientSummary.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }
}
