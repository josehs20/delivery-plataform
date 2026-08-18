import 'package:delivery_app/core/models/sync_operation_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncOperationDto', () {
    test('fromJson parses the OpenAPI contract shape', () {
      final op = SyncOperationDto.fromJson(const {
        'operation_id': 'op-1',
        'entity_type': 'DELIVERY',
        'entity_id': 'd1',
        'operation_type': 'CONFIRM_PICKUP',
        'client_created_at': '2026-08-16T12:10:00Z',
        'client_sequence': 42,
        'payload': {'delivery_id': 'd1'},
      });

      expect(op.operationId, 'op-1');
      expect(op.entityType, 'DELIVERY');
      expect(op.entityId, 'd1');
      expect(op.operationType, 'CONFIRM_PICKUP');
      expect(op.clientCreatedAt, DateTime.utc(2026, 8, 16, 12, 10));
      expect(op.clientSequence, 42);
      expect(op.payload, {'delivery_id': 'd1'});
    });

    test('toJson emits the real Laravel /sync wire format', () {
      final op = SyncOperationDto(
        operationId: 'op-1',
        entityType: 'DELIVERY',
        entityId: 'd1',
        operationType: 'CONFIRM_PICKUP',
        clientCreatedAt: DateTime.utc(2026, 8, 16, 12, 10),
        clientSequence: 42,
        payload: const {'delivery_id': 'd1'},
      );

      expect(op.toJson(), {
        'id': 'op-1',
        'idempotency_key': 'op-1',
        'entity': 'delivery',
        'operation': 'UPDATE',
        'priority': 42,
        'created_at': '2026-08-16T12:10:00.000Z',
        'payload': {'delivery_id': 'd1'},
      });
    });

    test('backendOperation maps transitions to UPDATE and CREATE/DELETE pass',
        () {
      expect(SyncOperationDto.backendOperation('ARRIVE_PICKUP'), 'UPDATE');
      expect(SyncOperationDto.backendOperation('CONFIRM_PICKUP'), 'UPDATE');
      expect(SyncOperationDto.backendOperation('COMPLETE'), 'UPDATE');
      expect(SyncOperationDto.backendOperation('STATE_TRANSITION'), 'UPDATE');
      expect(SyncOperationDto.backendOperation('CREATE'), 'CREATE');
      expect(SyncOperationDto.backendOperation('DELETE'), 'DELETE');
    });

    test('backendEntity maps to the lowercase Laravel entity names', () {
      expect(SyncOperationDto.backendEntity('DELIVERY'), 'delivery');
      expect(SyncOperationDto.backendEntity('LOCATION'), 'location');
      expect(SyncOperationDto.backendEntity('PROOF'), 'proof');
      expect(SyncOperationDto.backendEntity('EVENT'), 'event');
    });

    test('fromJson tolerates the real Laravel request shape', () {
      final op = SyncOperationDto.fromJson(const {
        'id': 'op-1',
        'idempotency_key': 'op-1',
        'entity': 'delivery',
        'operation': 'UPDATE',
        'priority': 5,
        'created_at': '2026-08-16T12:10:00Z',
        'payload': {'delivery_id': 'd1'},
      });

      expect(op.operationId, 'op-1');
      expect(op.entityType, 'delivery');
      expect(op.operationType, 'UPDATE');
      expect(op.clientSequence, 5);
      expect(op.clientCreatedAt, DateTime.utc(2026, 8, 16, 12, 10));
    });

    test('fromJson tolerates missing optional payload/sequence', () {
      final op = SyncOperationDto.fromJson(const {
        'operation_id': 'op-2',
        'entity_type': 'LOCATION',
        'entity_id': 'l1',
        'operation_type': 'CREATE',
        'client_created_at': '2026-08-16T12:10:00Z',
      });

      expect(op.clientSequence, isNull);
      expect(op.payload, isEmpty);
    });
  });

  group('SyncBatchRequestDto', () {
    test('toJson emits operations only (device_id goes in X-Device-Id)', () {
      final request = SyncBatchRequestDto(
        deviceId: 'device-abc',
        operations: [
          SyncOperationDto(
            operationId: 'op-1',
            entityType: 'DELIVERY',
            entityId: 'd1',
            operationType: 'CONFIRM_PICKUP',
            clientCreatedAt: DateTime.utc(2026, 8, 16, 12, 10),
          ),
        ],
      );

      expect(request.toJson().containsKey('device_id'), isFalse);
      expect(request.toJson()['operations'], hasLength(1));
      expect(
        (request.toJson()['operations'] as List).single,
        isA<Map<String, dynamic>>(),
      );
    });

    test('fromJson parses the request body', () {
      final request = SyncBatchRequestDto.fromJson(const {
        'device_id': 'device-abc',
        'operations': [
          {
            'operation_id': 'op-1',
            'entity_type': 'DELIVERY',
            'entity_id': 'd1',
            'operation_type': 'CONFIRM_PICKUP',
            'client_created_at': '2026-08-16T12:10:00Z',
          },
        ],
      });

      expect(request.deviceId, 'device-abc');
      expect(request.operations, hasLength(1));
      expect(request.operations.first.operationId, 'op-1');
    });
  });

  group('SyncBatchResultDto', () {
    test('fromJson parses the OpenAPI response item', () {
      final result = SyncBatchResultDto.fromJson(const {
        'operation_id': 'op-1',
        'status': 'PROCESSED',
        'server_entity_version': 11,
        'server_timestamp': '2026-08-16T12:11:02Z',
      });

      expect(result.operationId, 'op-1');
      expect(result.status, 'PROCESSED');
      expect(result.serverEntityVersion, 11);
      expect(result.serverTimestamp, DateTime.utc(2026, 8, 16, 12, 11, 2));
    });
  });

  group('SyncBatchResponseDto', () {
    test('parses the OpenAPI shape (data as list)', () {
      final response = SyncBatchResponseDto.fromJson(const {
        'data': [
          {'operation_id': 'op-1', 'status': 'PROCESSED'},
          {'operation_id': 'op-2', 'status': 'FAILED'},
        ],
      });

      expect(response.results, hasLength(2));
      expect(response.results.first.status, 'PROCESSED');
      expect(response.results.last.operationId, 'op-2');
    });

    test('parses the current backend shape (data.results)', () {
      final response = SyncBatchResponseDto.fromJson(const {
        'data': {
          'results': [
            {'operation_id': 'op-1', 'status': 'PROCESSED'},
          ],
        },
      });

      expect(response.results, hasLength(1));
      expect(response.results.single.operationId, 'op-1');
    });

    test('ignores unknown backend fields safely', () {
      final response = SyncBatchResponseDto.fromJson(const {
        'data': [
          {
            'operation_id': 'op-1',
            'status': 'FAILED',
            'error_code': 'ValidationException',
            'error_message': 'reason is required',
            'idempotency_key': 'key-123456',
          },
        ],
      });

      expect(response.results.single.status, 'FAILED');
      expect(response.results.single.serverEntityVersion, isNull);
    });
  });
}
