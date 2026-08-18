final class SyncOperation {
  const SyncOperation({
    required this.operationId,
    required this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.clientCreatedAt,
    required this.payload,
    this.clientSequence,
  });

  final String operationId;
  final String deviceId;
  final String entityType;
  final String entityId;
  final String operationType;
  final DateTime clientCreatedAt;
  final int? clientSequence;
  final Map<String, dynamic> payload;
}
