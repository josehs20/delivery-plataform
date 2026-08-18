import 'json_utils.dart';

/// Operação da fila de sincronização — espelha o contrato implementado pelo
/// Laravel em `POST /api/v1/sync` (docs/docs/api/38-sync-api.md e
/// `laravel/app/Http/Requests/Api/V1/SyncOperationsRequest.php`).
///
/// Divergência conhecida: o OpenAPI (`/docs/openapi/openapi.yaml`) documenta
/// `POST /sync/batch` com `operation_id/entity_type/operation_type/
/// client_created_at`, porém o backend real serve `POST /sync` com
/// `id/idempotency_key/entity/operation/created_at` (e `X-Device-Id` no
/// header). O Laravel é a autoridade de aceite da sincronização, então o
/// cliente segue o contrato real e o mapeamento fica explícito aqui.
///
/// O model local durável em `core/sync` pode ter campos extras (ex.:
/// `device_id`, retry/status locais); este DTO é exclusivamente o contrato
/// HTTP.
final class SyncOperationDto {
  const SyncOperationDto({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.clientCreatedAt,
    this.clientSequence,
    this.payload = const {},
  });

  final String operationId;
  final String entityType;
  final String entityId;
  final String operationType;
  final DateTime clientCreatedAt;
  final int? clientSequence;
  final Map<String, dynamic> payload;

  factory SyncOperationDto.fromJson(Map<String, dynamic> json) {
    return SyncOperationDto(
      operationId: JsonUtils.stringOrDefault(
        json['operation_id'] ?? json['id'],
      ),
      entityType: JsonUtils.stringOrDefault(
        json['entity_type'] ?? json['entity'],
      ),
      entityId: JsonUtils.stringOrDefault(json['entity_id']),
      operationType: JsonUtils.stringOrDefault(
        json['operation_type'] ?? json['operation'],
      ),
      clientCreatedAt:
          JsonUtils.dateTime(json['client_created_at'] ?? json['created_at']) ??
              DateTime.now().toUtc(),
      clientSequence: JsonUtils.intOrNull(
        json['client_sequence'] ?? json['priority'],
      ),
      payload: JsonUtils.mapOrEmpty(json['payload']),
    );
  }

  /// Entidade no contrato real do Laravel (lowercase).
  static String backendEntity(String entityType) {
    return switch (entityType.toUpperCase()) {
      'DELIVERY' => 'delivery',
      'LOCATION' => 'location',
      'PROOF' => 'proof',
      'EVENT' => 'event',
      _ => entityType.toLowerCase(),
    };
  }

  /// Operação no contrato real do Laravel (`CREATE | UPDATE | DELETE`).
  ///
  /// Transições de entrega (`ARRIVE_PICKUP`, `CONFIRM_PICKUP`, `COMPLETE`,
  /// `STATE_TRANSITION`, ...) são enviadas como `UPDATE`; a semântica fica no
  /// `payload.action` (o resolver do backend valida a transição a partir dele).
  static String backendOperation(String operationType) {
    return switch (operationType.toUpperCase()) {
      'CREATE' => 'CREATE',
      'DELETE' => 'DELETE',
      _ => 'UPDATE',
    };
  }

  Map<String, dynamic> toJson() => {
        'id': operationId,
        // A chave de idempotência por operação é o próprio operation_id
        // (estável e reutilizado em retries — ADR-005).
        'idempotency_key': operationId,
        'entity': backendEntity(entityType),
        'operation': backendOperation(operationType),
        if (clientSequence != null) 'priority': clientSequence,
        'created_at': clientCreatedAt.toUtc().toIso8601String(),
        'payload': payload,
      };
}

/// Corpo de `POST /api/v1/sync` — espelha o `SyncOperationsRequest` do
/// Laravel. O `device_id` é enviado no header `X-Device-Id` pelo [SyncWorker].
final class SyncBatchRequestDto {
  const SyncBatchRequestDto({
    required this.deviceId,
    required this.operations,
  });

  final String deviceId;
  final List<SyncOperationDto> operations;

  factory SyncBatchRequestDto.fromJson(Map<String, dynamic> json) {
    return SyncBatchRequestDto(
      deviceId: JsonUtils.stringOrDefault(json['device_id']),
      operations: _operationsFrom(json['operations']),
    );
  }

  static List<SyncOperationDto> _operationsFrom(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => SyncOperationDto.fromJson(JsonUtils.mapOrEmpty(e)))
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
        'operations': operations.map((e) => e.toJson()).toList(growable: false),
      };
}

/// Item de `data.results` na resposta de `POST /api/v1/sync`.
///
/// Status do backend real: `PROCESSED | ALREADY_PROCESSED | FAILED`. O contrato
/// OpenAPI também prevê `CONFLICT | RETRY`; o parse tolera todos.
/// Campos extras (`idempotency_key`, `error_code`, `error_message`, `data`)
/// são ignorados com segurança.
final class SyncBatchResultDto {
  const SyncBatchResultDto({
    required this.operationId,
    required this.status,
    this.serverEntityVersion,
    this.serverTimestamp,
  });

  final String operationId;
  final String status;
  final int? serverEntityVersion;
  final DateTime? serverTimestamp;

  factory SyncBatchResultDto.fromJson(Map<String, dynamic> json) {
    return SyncBatchResultDto(
      operationId: JsonUtils.stringOrDefault(json['operation_id']),
      status: JsonUtils.stringOrDefault(json['status']),
      serverEntityVersion: JsonUtils.intOrNull(json['server_entity_version']),
      serverTimestamp: JsonUtils.dateTime(json['server_timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'operation_id': operationId,
        'status': status,
        if (serverEntityVersion != null)
          'server_entity_version': serverEntityVersion,
        if (serverTimestamp != null)
          'server_timestamp': serverTimestamp!.toUtc().toIso8601String(),
      };
}

/// Envelope da resposta de `POST /api/v1/sync`.
///
/// O backend real responde `data: {results: [SyncBatchResult, ...]}`; o parse
/// também tolera `data: [SyncBatchResult, ...]` (forma documentada no OpenAPI).
final class SyncBatchResponseDto {
  const SyncBatchResponseDto({required this.results});

  final List<SyncBatchResultDto> results;

  factory SyncBatchResponseDto.fromJson(Map<String, dynamic> json) {
    Object? raw = json['data'];
    if (raw is Map) {
      final map = JsonUtils.mapOrEmpty(raw);
      if (map.containsKey('results')) raw = map['results'];
    }

    final items = raw is List ? raw : const <Object?>[];

    return SyncBatchResponseDto(
      results: items
          .whereType<Map>()
          .map((e) => SyncBatchResultDto.fromJson(JsonUtils.mapOrEmpty(e)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          'results': results.map((e) => e.toJson()).toList(growable: false),
        },
      };
}
