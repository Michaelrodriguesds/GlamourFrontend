import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';

/// Ação pendente na fila offline
class PendingAction {
  final String      id;        // UUID gerado localmente
  final String      type;      // 'create' | 'update' | 'delete'
  final String?     remoteId;  // ID do servidor (para update/delete)
  final Map<String, dynamic>? data; // Payload do agendamento
  final DateTime    createdAt;
  int               retries;

  PendingAction({
    required this.id,
    required this.type,
    this.remoteId,
    this.data,
    required this.createdAt,
    this.retries = 0,
  });

  Map<String, dynamic> toJson() => {
    'id':        id,
    'type':      type,
    'remoteId':  remoteId,
    'data':      data,
    'createdAt': createdAt.toIso8601String(),
    'retries':   retries,
  };

  factory PendingAction.fromJson(Map<String, dynamic> j) => PendingAction(
    id:        j['id'],
    type:      j['type'],
    remoteId:  j['remoteId'],
    data:      j['data'] != null ? Map<String, dynamic>.from(j['data']) : null,
    createdAt: DateTime.parse(j['createdAt']),
    retries:   j['retries'] ?? 0,
  );
}

/// Fila de operações offline.
///
/// Uso:
///   1. Quando sem internet, chame [enqueue] em vez do serviço HTTP.
///   2. Quando voltar online, chame [sync] passando o AppointmentService.
///   3. Ouça [pendingCount] para mostrar o badge "N pendentes".
class OfflineQueueService extends ChangeNotifier {
  static const _key = 'offline_queue_v1';

  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  SharedPreferences? _prefs;
  List<PendingAction> _queue = [];

  List<PendingAction> get queue   => List.unmodifiable(_queue);
  int                  get pendingCount => _queue.length;
  bool                 get hasPending  => _queue.isNotEmpty;

  // ── Inicialização ──────────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    final raw = _prefs?.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _queue = list.map((e) => PendingAction.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('OfflineQueue: erro ao carregar fila — $e');
    }
  }

  Future<void> _save() async {
    final raw = jsonEncode(_queue.map((e) => e.toJson()).toList());
    await _prefs?.setString(_key, raw);
    notifyListeners();
  }

  // ── Enfileirar ────────────────────────────────────────────────

  Future<String> enqueueCreate(Appointment apt) async {
    final tempId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    _queue.add(PendingAction(
      id:        tempId,
      type:      'create',
      data:      apt.toJson(),
      createdAt: DateTime.now(),
    ));
    await _save();
    debugPrint('OfflineQueue: create enfileirado ($tempId)');
    return tempId;
  }

  Future<void> enqueueUpdate(String remoteId, Appointment apt) async {
    // Remove update anterior para o mesmo ID (sem sentido manter histórico)
    _queue.removeWhere((a) => a.type == 'update' && a.remoteId == remoteId);
    _queue.add(PendingAction(
      id:        'offline_upd_${DateTime.now().millisecondsSinceEpoch}',
      type:      'update',
      remoteId:  remoteId,
      data:      apt.toJson(),
      createdAt: DateTime.now(),
    ));
    await _save();
    debugPrint('OfflineQueue: update enfileirado ($remoteId)');
  }

  Future<void> enqueueDelete(String remoteId) async {
    // Se havia create pendente para este ID, cancela tudo
    _queue.removeWhere((a) => a.id == remoteId);
    _queue.add(PendingAction(
      id:        'offline_del_${DateTime.now().millisecondsSinceEpoch}',
      type:      'delete',
      remoteId:  remoteId,
      createdAt: DateTime.now(),
    ));
    await _save();
    debugPrint('OfflineQueue: delete enfileirado ($remoteId)');
  }

  // ── Sincronização ─────────────────────────────────────────────
  //
  // Tenta enviar cada ação ao servidor.
  // Ações que falharem ficam na fila para a próxima tentativa.
  // Retorna quantas ações foram sincronizadas com sucesso.

  Future<int> sync({
    required Future<void> Function(Map<String, dynamic> data)          createFn,
    required Future<void> Function(String id, Map<String, dynamic> data) updateFn,
    required Future<void> Function(String id)                           deleteFn,
  }) async {
    if (_queue.isEmpty) return 0;

    debugPrint('OfflineQueue: sincronizando ${_queue.length} ações...');
    int synced = 0;
    final failed = <PendingAction>[];

    for (final action in List.from(_queue)) {
      try {
        switch (action.type) {
          case 'create':
            if (action.data != null) await createFn(action.data!);
            break;
          case 'update':
            if (action.remoteId != null && action.data != null) {
              await updateFn(action.remoteId!, action.data!);
            }
            break;
          case 'delete':
            if (action.remoteId != null) await deleteFn(action.remoteId!);
            break;
        }
        synced++;
        debugPrint('OfflineQueue: ✅ ${action.type} sincronizado (${action.id})');
      } catch (e) {
        action.retries++;
        debugPrint('OfflineQueue: ❌ ${action.type} falhou (tentativa ${action.retries}) — $e');
        // Após 5 tentativas fracassadas, descarta a ação
        if (action.retries < 5) {
          failed.add(action);
        } else {
          debugPrint('OfflineQueue: ⚠️ descartando após 5 tentativas (${action.id})');
        }
      }
    }

    _queue = failed;
    await _save();
    debugPrint('OfflineQueue: sincronização concluída — $synced ok, ${failed.length} restantes');
    return synced;
  }

  // ── Limpar ────────────────────────────────────────────────────

  Future<void> clear() async {
    _queue = [];
    await _save();
  }
}
