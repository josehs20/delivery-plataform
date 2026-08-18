import 'sync_operation.dart';

/// Fila durável de operações offline (docs/flutter/docs/08-synchronization.md).
///
/// Regras:
/// - a entrada é gravada localmente de forma atômica ANTES de a operação ser
///   confirmada como segura (offline-first);
/// - sobrevive a restart do app;
/// - mesmo `operationId` pode ser reenviado sem duplicar efeito no servidor
///   (idempotência local + idempotência do servidor);
/// - conflitos são explícitos na fila para resolução na UI.
abstract interface class SyncQueue {
  /// Grava a operação na fila. Idempotente por `operationId` (sem duplicar).
  Future<void> enqueue(SyncOperation operation);

  /// Operações prontas para envio (PENDING/RETRY com retry já vencido),
  /// ordenadas por `clientCreatedAt`, limitadas a [limit].
  Future<List<SyncOperation>> pending({int limit = 50});

  /// Busca uma operação por `operationId`, ou `null`.
  Future<SyncOperation?> byId(String operationId);

  /// Número total de operações na fila (todos os status).
  Future<int> count();

  /// Sucesso no servidor — remove a operação da fila.
  Future<void> markProcessed(String operationId);

  /// Falha transitória — incrementa tentativas e agenda próximo retry
  /// (backoff limitado; após o limite máximo vira falha permanente).
  Future<void> markRetry(String operationId, {String? error});

  /// Conflito — mantém na fila marcado como conflito para resolução.
  Future<void> markConflict(String operationId, {String? reason});

  /// Falha permanente — mantém o registro para auditoria/limpeza.
  Future<void> markFailed(String operationId, {String? error});
}
