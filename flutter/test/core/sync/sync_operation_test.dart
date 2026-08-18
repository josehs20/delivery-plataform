import 'package:delivery_app/core/sync/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final operation = SyncOperation(
    operationId: 'op-1',
    deviceId: 'device-1',
    entityType: 'DELIVERY',
    entityId: 'd1',
    operationType: 'CONFIRM_PICKUP',
    clientCreatedAt: DateTime.utc(2026, 8, 16, 12, 10),
    clientSequence: 7,
    payload: const {'delivery_id': 'd1'},
  );

  group('SyncOperation', () {
    test('toJson/fromJson round-trips', () {
      final restored = SyncOperation.fromJson(operation.toJson());

      expect(restored.operationId, 'op-1');
      expect(restored.deviceId, 'device-1');
      expect(restored.entityType, 'DELIVERY');
      expect(restored.entityId, 'd1');
      expect(restored.operationType, 'CONFIRM_PICKUP');
      expect(restored.clientCreatedAt, DateTime.utc(2026, 8, 16, 12, 10));
      expect(restored.clientSequence, 7);
      expect(restored.payload, {'delivery_id': 'd1'});
      expect(restored.status, SyncOperationStatus.pending);
      expect(restored.attempts, 0);
      expect(restored.schemaVersion, SyncOperation.currentSchemaVersion);
    });

    test('fromJson tolerates missing optional fields', () {
      final restored = SyncOperation.fromJson({
        'operation_id': 'op-2',
        'device_id': 'device-1',
        'entity_type': 'LOCATION',
        'entity_id': 'l1',
        'operation_type': 'CREATE',
        'client_created_at': '2026-08-16T12:10:00Z',
      });

      expect(restored.clientSequence, isNull);
      expect(restored.payload, isEmpty);
      expect(restored.status, SyncOperationStatus.pending);
      expect(restored.nextRetryAt, isNull);
    });

    test('copyWith updates retry fields without mutating the original', () {
      final updated = operation.copyWith(
        status: SyncOperationStatus.retry,
        attempts: 1,
        nextRetryAt: DateTime.utc(2026, 8, 16, 13),
        error: 'timeout',
      );

      expect(updated.status, SyncOperationStatus.retry);
      expect(updated.attempts, 1);
      expect(updated.nextRetryAt, DateTime.utc(2026, 8, 16, 13));
      expect(updated.error, 'timeout');
      expect(updated.operationId, 'op-1');
      expect(operation.status, SyncOperationStatus.pending);
    });

    test('toDto maps to the HTTP wire contract (sem device_id)', () {
      final dto = operation.toDto();

      expect(dto.operationId, 'op-1');
      expect(dto.entityType, 'DELIVERY');
      expect(dto.entityId, 'd1');
      expect(dto.operationType, 'CONFIRM_PICKUP');
      expect(dto.clientCreatedAt, DateTime.utc(2026, 8, 16, 12, 10));
      expect(dto.clientSequence, 7);
      expect(dto.payload, {'delivery_id': 'd1'});
    });

    test('SyncOperationStatus.fromWire is tolerant', () {
      expect(
        SyncOperationStatus.fromWire('pending'),
        SyncOperationStatus.pending,
      );
      expect(SyncOperationStatus.fromWire('retry'), SyncOperationStatus.retry);
      expect(
        SyncOperationStatus.fromWire('conflict'),
        SyncOperationStatus.conflict,
      );
      expect(
        SyncOperationStatus.fromWire('bogus'),
        SyncOperationStatus.pending,
      );
      expect(SyncOperationStatus.fromWire(null), SyncOperationStatus.pending);
    });
  });
}
