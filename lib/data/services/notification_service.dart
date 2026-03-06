import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';

/// Serviço de notificações — stub completo.
/// 
/// No web (Windows/Chrome): sempre no-op para evitar crash do DartWorker.
/// No iOS nativo: reativar flutter_local_notifications + timezone no pubspec
/// e descomentar a implementação real aqui.
class NotificationService {
  static Future<void> init() async {}
  static Future<void> requestPermission() async {}
  static Future<void> scheduleReminder(Appointment apt) async {}
  static Future<void> cancel(String aptId) async {
    debugPrint('NotificationService.cancel: $aptId (stub)');
  }
  static Future<void> cancelAll() async {}
}