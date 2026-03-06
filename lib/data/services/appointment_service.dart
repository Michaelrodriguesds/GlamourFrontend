import 'package:dio/dio.dart';
import 'api_service.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final _api = ApiService();

  /// Lista agendamentos com filtros opcionais
  Future<List<Appointment>> getAll({
    String? date,
    int?    month,
    int?    year,
    String? location,
    String? procedure,
    bool?   paid,
    bool?   confirmed,
    String? client,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (date      != null) params['date']      = date;
      if (month     != null) params['month']     = month;
      if (year      != null) params['year']      = year;
      if (location  != null) params['location']  = location;
      if (procedure != null) params['procedure'] = procedure;
      if (paid      != null) params['paid']      = paid;
      if (confirmed != null) params['confirmed'] = confirmed;
      if (client    != null) params['client']    = client;

      final r = await _api.dio.get(
        ApiEndpoints.appointments,
        queryParameters: params,
      );
      return (r.data['data'] as List)
          .map((e) => Appointment.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Busca um agendamento pelo ID
  Future<Appointment> getById(String id) async {
    try {
      final r = await _api.dio.get(ApiEndpoints.appointmentById(id));
      return Appointment.fromJson(r.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Cria novo agendamento
  Future<Appointment> create(Appointment apt) async {
    try {
      final r = await _api.dio.post(
        ApiEndpoints.appointments,
        data: apt.toJson(),
      );
      return Appointment.fromJson(r.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Atualiza agendamento existente
  Future<Appointment> update(String id, Appointment apt) async {
    try {
      final r = await _api.dio.put(
        ApiEndpoints.appointmentById(id),
        data: apt.toJson(),
      );
      return Appointment.fromJson(r.data);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Remove agendamento
  Future<void> delete(String id) async {
    try {
      await _api.dio.delete(ApiEndpoints.appointmentById(id));
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Marca como pago
  Future<Appointment> markAsPaid(String id, {String? paymentMethod}) async {
    try {
      final r = await _api.dio.patch(
        ApiEndpoints.payAppointment(id),
        data: paymentMethod != null ? {'paymentMethod': paymentMethod} : {},
      );
      return Appointment.fromJson(r.data['data']);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }

  /// Confirma presença da cliente
  Future<Appointment> confirm(String id) async {
    try {
      final r = await _api.dio.patch(ApiEndpoints.confirmAppointment(id));
      return Appointment.fromJson(r.data['data']);
    } on DioException catch (e) {
      throw _api.handleError(e);
    }
  }
}