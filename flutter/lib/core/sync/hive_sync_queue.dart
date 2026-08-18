import 'package:hive/hive.dart';

import 'sync_operation.dart';
import 'sync_queue.dart';

/// Implementação da [SyncQueue] com Hive (box `sync_queue`).
///
/// Chave = `operationId`; gravação via `put` (atômica). Backoff exponencial
/// limitado (1m, 2m, 4m, ... cap 1h); após [maxAttempts], falha permanente.
final class HiveSyncQueue implements SyncQueue {
  HiveSyncQueue(this._box, {this.maxAttempts = 10});

  /// Número máximo de tentativas antes de marcar como falha permanente.
  final int maxAttempts;

  final Box<Map<dynamic, dynamic>> _box;

  static const _backoffBase = Duration(minutes: 1);
  static const _backoffCap = Duration(hours: 1);

  @override
  Future<void> enqueue(SyncOperation operation) async {
    // Idempotência local: a mesma operation_id nunca é duplicada.
    if (_box.containsKey(operation.operationId)) return;
    await _box.put(operation.operationId, operation.toJson());
  }

  @override
  Future<List<SyncOperation>> pending({int limit = 50}) async {
    final now = DateTime.now().toUtc();
    final due = <SyncOperation>[];

    for (final raw in _box.values) {
      final operation = SyncOperation.fromJson(_asStringMap(raw));
      final isDue = operation.status == SyncOperationStatus.pending ||
          (operation.status == SyncOperationStatus.retry &&
              (operation.nextRetryAt == null ||
                  !operation.nextRetryAt!.isAfter(now)));
      if (isDue) due.add(operation);
    }

    due.sort((a, b) => a.clientCreatedAt.compareTo(b.clientCreatedAt));
    return due.take(limit).toList(growable: false);
  }

  @override
  Future<SyncOperation?> byId(String operationId) async {
    final raw = _box.get(operationId);
    if (raw == null) return null;
    return SyncOperation.fromJson(_asStringMap(raw));
  }

  @override
  Future<int> count() async => _box.length;

  @override
  Future<void> markProcessed(String operationId) async {
    await _box.delete(operationId);
  }

  @override
  Future<void> markRetry(String operationId, {String? error}) async {
    final current = await byId(operationId);
    if (current == null) return;

    final attempts = current.attempts + 1;

    // Limite de tentativas: vira falha permanente (sem loop infinito).
    if (attempts >= maxAttempts) {
      await _box.put(
        operationId,
        current
            .copyWith(
              status: SyncOperationStatus.failed,
              attempts: attempts,
              nextRetryAt: null,
              error: error ?? current.error,
            )
            .toJson(),
      );
      return;
    }

    await _box.put(
      operationId,
      current
          .copyWith(
            status: SyncOperationStatus.retry,
            attempts: attempts,
            nextRetryAt: DateTime.now().toUtc().add(_backoffFor(attempts)),
            error: error ?? current.error,
          )
          .toJson(),
    );
  }

  @override
  Future<void> markConflict(String operationId, {String? reason}) async {
    final current = await byId(operationId);
    if (current == null) return;
    await _box.put(
      operationId,
      current
          .copyWith(
            status: SyncOperationStatus.conflict,
            nextRetryAt: null,
            error: reason ?? current.error,
          )
          .toJson(),
    );
  }

  @override
  Future<void> markFailed(String operationId, {String? error}) async {
    final current = await byId(operationId);
    if (current == null) return;
    await _box.put(
      operationId,
      current
          .copyWith(
            status: SyncOperationStatus.failed,
            nextRetryAt: null,
            error: error ?? current.error,
          )
          .toJson(),
    );
  }

  static Map<String, dynamic> _asStringMap(Map<dynamic, dynamic> raw) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  /// Backoff exponencial limitado: 1m, 2m, 4m, ... cap de 1h.
  static Duration _backoffFor(int attempt) {
    final exponent = attempt - 1;
    if (exponent >= 6) return _backoffCap;
    return Duration(seconds: _backoffBase.inSeconds * (1 << exponent));
  }
}
