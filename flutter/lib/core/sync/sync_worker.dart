import '../errors/api_exception.dart';
import '../models/sync_operation_dto.dart';
import '../network/api_client.dart';
import 'sync_queue.dart';

/// Resumo de um ciclo de sincronização.
final class SyncResult {
  const SyncResult({
    required this.sent,
    required this.processed,
    required this.alreadyProcessed,
    required this.conflicts,
    required this.retried,
    required this.failed,
    this.error,
  });

  /// Operações enviadas no batch.
  final int sent;

  /// Confirmadas pelo servidor (`PROCESSED`).
  final int processed;

  /// Já processadas em tentativa anterior (`ALREADY_PROCESSED`).
  final int alreadyProcessed;

  /// Conflitos detectados (`CONFLICT`).
  final int conflicts;

  /// Falhas transitórias agendadas para retry (`RETRY` / falha de rede).
  final int retried;

  /// Falhas permanentes (`FAILED`).
  final int failed;

  /// Erro no nível do batch (rede/auth/servidor), quando ocorreu.
  final ApiException? error;

  bool get isEmpty => sent == 0;
  bool get hasFailures => conflicts > 0 || failed > 0 || error != null;
}

/// Processa a fila local enviando `POST /api/v1/sync`
/// (docs/docs/api/38-sync-api.md + contrato real do Laravel).
///
/// Contrato real do backend (autoridade de aceite):
/// - corpo: `{operations: [{id, idempotency_key, entity, operation, payload,
///   created_at}]}`;
/// - `device_id` no header `X-Device-Id`;
/// - resposta: `data.results: [{operation_id, status, ...}]`.
///
/// Tratamento das respostas:
/// - `PROCESSED` / `ALREADY_PROCESSED` → remove da fila (idempotência);
/// - `CONFLICT` → marca conflito (explícito na UI);
/// - `RETRY` / status desconhecido / operação sem resultado → retry com backoff;
/// - `FAILED` → falha permanente;
/// - falha transitória no batch (rede/5xx/429) → retry de todas as enviadas;
/// - 401/403 → não consome tentativas; erro exposto no [SyncResult].
final class SyncWorker {
  SyncWorker(
    this._apiClient,
    this._queue,
    this._deviceId, {
    this.batchSize = 50,
  });

  final ApiClient _apiClient;
  final SyncQueue _queue;
  final String _deviceId;
  final int batchSize;

  Future<SyncResult> sync() async {
    final operations = await _queue.pending(limit: batchSize);
    if (operations.isEmpty) {
      return const SyncResult(
        sent: 0,
        processed: 0,
        alreadyProcessed: 0,
        conflicts: 0,
        retried: 0,
        failed: 0,
      );
    }

    final request = SyncBatchRequestDto(
      deviceId: _deviceId,
      operations: operations.map((op) => op.toDto()).toList(growable: false),
    );

    final ApiResponse response;
    try {
      // O `device_id` vai no header `X-Device-Id` (contrato real do Laravel);
      // sem chave de idempotência explícita no batch: o interceptor gera uma
      // UUID por batch e a idempotência por operação fica no `operation_id`
      // (o servidor deduplica por `id` + `client_id`).
      response = await _apiClient.post(
        '/sync',
        body: request.toJson(),
        headers: {'X-Device-Id': _deviceId},
      );
    } on ApiException catch (error) {
      if (_isTransient(error)) {
        for (final op in operations) {
          await _queue.markRetry(op.operationId, error: error.message);
        }
        return SyncResult(
          sent: operations.length,
          processed: 0,
          alreadyProcessed: 0,
          conflicts: 0,
          retried: operations.length,
          failed: 0,
          error: error,
        );
      }
      // 401/403/422/409: não queima tentativas; expõe o erro para o caller.
      return SyncResult(
        sent: operations.length,
        processed: 0,
        alreadyProcessed: 0,
        conflicts: 0,
        retried: 0,
        failed: 0,
        error: error,
      );
    }

    final batch = _parseResponse(response);

    var processed = 0;
    var alreadyProcessed = 0;
    var conflicts = 0;
    var retried = 0;
    var failed = 0;
    final answered = <String>{};

    for (final result in batch.results) {
      answered.add(result.operationId);
      switch (result.status) {
        case 'PROCESSED':
          await _queue.markProcessed(result.operationId);
          processed++;
          break;
        case 'ALREADY_PROCESSED':
          await _queue.markProcessed(result.operationId);
          alreadyProcessed++;
          break;
        case 'CONFLICT':
          await _queue.markConflict(result.operationId, reason: result.status);
          conflicts++;
          break;
        case 'RETRY':
          await _queue.markRetry(result.operationId, error: 'Servidor pediu retry.');
          retried++;
          break;
        case 'FAILED':
          await _queue.markFailed(result.operationId, error: 'Falha permanente.');
          failed++;
          break;
        default:
          await _queue.markRetry(
            result.operationId,
            error: 'Status desconhecido: ${result.status}',
          );
          retried++;
          break;
      }
    }

    // Operações sem resultado individual (tolerância a sucesso parcial):
    // tratadas como retry seguro.
    for (final op in operations.where((op) => !answered.contains(op.operationId))) {
      await _queue.markRetry(op.operationId, error: 'Sem resultado no batch.');
      retried++;
    }

    return SyncResult(
      sent: operations.length,
      processed: processed,
      alreadyProcessed: alreadyProcessed,
      conflicts: conflicts,
      retried: retried,
      failed: failed,
    );
  }

  static bool _isTransient(ApiException error) =>
      error is NetworkException ||
      error is ServerException ||
      error is RateLimitException;

  static SyncBatchResponseDto _parseResponse(ApiResponse response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SyncBatchResponseDto.fromJson(data);
    }
    if (data is Map) {
      return SyncBatchResponseDto.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return const SyncBatchResponseDto(results: []);
  }
}
