import '../models/json_utils.dart';
import '../models/sync_operation_dto.dart';

/// Status durável de uma operação na fila local de sincronização.
enum SyncOperationStatus {
  /// Aguardando envio.
  pending,

  /// Falha transitória; aguarda [SyncOperation.nextRetryAt] (backoff).
  retry,

  /// Conflito detectado pelo servidor; exige resolução explícita na UI.
  conflict,

  /// Falha permanente (limite de tentativas ou rejeição do servidor).
  failed;

  /// Parse tolerante do valor persistido; desconhecido vira [pending].
  static SyncOperationStatus fromWire(String? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return SyncOperationStatus.pending;
  }
}

/// Operação durável da fila local (docs/flutter/docs/08-synchronization.md).
///
/// Cada item possui: operation_id, entidade, entidade_id, tipo de operação,
/// payload, criado_em, tentativas, próximo_retry, status, erro e versão de
/// schema. É o model local — separado do [SyncOperationDto] (contrato HTTP).
final class SyncOperation {
  const SyncOperation({
    required this.operationId,
    required this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.clientCreatedAt,
    this.clientSequence,
    this.payload = const {},
    this.status = SyncOperationStatus.pending,
    this.attempts = 0,
    this.nextRetryAt,
    this.error,
    this.schemaVersion = currentSchemaVersion,
  });

  /// Versão do schema da entrada persistida (migrations locais).
  static const currentSchemaVersion = 1;

  final String operationId;
  final String deviceId;
  final String entityType;
  final String entityId;
  final String operationType;
  final DateTime clientCreatedAt;
  final int? clientSequence;
  final Map<String, dynamic> payload;
  final SyncOperationStatus status;
  final int attempts;
  final DateTime? nextRetryAt;
  final String? error;
  final int schemaVersion;

  /// Marcador para diferenciar "parâmetro não informado" de "limpar para
  /// `null`" no [copyWith] (campos anuláveis).
  static const Object _notProvided = Object();

  SyncOperation copyWith({
    SyncOperationStatus? status,
    int? attempts,
    Object? nextRetryAt = _notProvided,
    Object? error = _notProvided,
  }) {
    return SyncOperation(
      operationId: operationId,
      deviceId: deviceId,
      entityType: entityType,
      entityId: entityId,
      operationType: operationType,
      clientCreatedAt: clientCreatedAt,
      clientSequence: clientSequence,
      payload: payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextRetryAt: identical(nextRetryAt, _notProvided)
          ? this.nextRetryAt
          : nextRetryAt as DateTime?,
      error: identical(error, _notProvided) ? this.error : error as String?,
      schemaVersion: schemaVersion,
    );
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      operationId: json['operation_id'] as String,
      deviceId: json['device_id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      operationType: json['operation_type'] as String,
      clientCreatedAt:
          DateTime.parse(json['client_created_at'] as String).toUtc(),
      clientSequence: JsonUtils.intOrNull(json['client_sequence']),
      payload: JsonUtils.mapOrEmpty(json['payload']),
      status: SyncOperationStatus.fromWire(JsonUtils.stringOrNull(json['status'])),
      attempts: JsonUtils.intOrNull(json['attempts']) ?? 0,
      nextRetryAt: JsonUtils.dateTime(json['next_retry_at']),
      error: JsonUtils.stringOrNull(json['error']),
      schemaVersion:
          JsonUtils.intOrNull(json['schema_version']) ?? currentSchemaVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'operation_id': operationId,
        'device_id': deviceId,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation_type': operationType,
        'client_created_at': clientCreatedAt.toUtc().toIso8601String(),
        if (clientSequence != null) 'client_sequence': clientSequence,
        'payload': payload,
        'status': status.name,
        'attempts': attempts,
        if (nextRetryAt != null)
          'next_retry_at': nextRetryAt!.toUtc().toIso8601String(),
        if (error != null) 'error': error,
        'schema_version': schemaVersion,
      };

  /// Converte para o DTO do contrato HTTP (`POST /api/v1/sync/batch`).
  SyncOperationDto toDto() => SyncOperationDto(
        operationId: operationId,
        entityType: entityType,
        entityId: entityId,
        operationType: operationType,
        clientCreatedAt: clientCreatedAt,
        clientSequence: clientSequence,
        payload: payload,
      );
}
