import 'sync_operation.dart';

abstract interface class SyncQueue {
  Future<void> enqueue(SyncOperation operation);
  Future<List<SyncOperation>> pending({int limit = 50});
  Future<void> markProcessed(String operationId);
  Future<void> markRetry(String operationId, {String? error});
  Future<void> markConflict(String operationId, {String? reason});
}
