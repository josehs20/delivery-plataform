import 'dart:io';

import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/core/network/api_client.dart';
import 'package:delivery_app/core/sync/hive_sync_queue.dart';
import 'package:delivery_app/core/sync/sync_operation.dart';
import 'package:delivery_app/core/sync/sync_worker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this._handler);

  final Future<ApiResponse> Function() _handler;
  int calls = 0;
  Map<String, dynamic>? lastBody;
  String? lastPath;
  Map<String, String>? lastHeaders;

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    Map<String, String>? headers,
  }) {
    calls++;
    lastPath = path;
    lastBody = body;
    lastHeaders = headers;
    return _handler();
  }

  @override
  Future<ApiResponse> get(String path, {Map<String, String>? query}) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResponse> delete(String path, {Map<String, String>? query}) =>
      throw UnimplementedError();
}

void main() {
  late Directory tempDir;
  late HiveSyncQueue queue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_worker_test_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox<Map<dynamic, dynamic>>('sync_queue');
    queue = HiveSyncQueue(box);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> enqueue(String id) async {
    await queue.enqueue(
      SyncOperation(
        operationId: id,
        deviceId: 'device-1',
        entityType: 'DELIVERY',
        entityId: 'd1',
        operationType: 'CONFIRM_PICKUP',
        clientCreatedAt: DateTime.utc(2026, 8, 16, 12),
        payload: const {'delivery_id': 'd1'},
      ),
    );
  }

  SyncWorker buildWorker(_FakeApiClient client) {
    return SyncWorker(client, queue, 'device-1');
  }

  test('empty queue does not call the API', () async {
    final client = _FakeApiClient(() async => throw UnimplementedError());

    final result = await buildWorker(client).sync();

    expect(client.calls, 0);
    expect(result.isEmpty, isTrue);
    expect(result.hasFailures, isFalse);
  });

  test('sends the operations in the real Laravel /sync contract', () async {
    await enqueue('op-1');
    final client = _FakeApiClient(
      () async => const ApiResponse(statusCode: 200, data: {
        'data': {
          'results': [
            {'operation_id': 'op-1', 'status': 'PROCESSED'},
          ],
        },
      }),
    );

    await buildWorker(client).sync();

    expect(client.calls, 1);
    expect(client.lastPath, '/sync');
    expect(client.lastHeaders, {'X-Device-Id': 'device-1'});
    final operations = client.lastBody!['operations'] as List;
    expect(operations, hasLength(1));
    final op = operations.single as Map;
    expect(op['id'], 'op-1');
    expect(op['idempotency_key'], 'op-1');
    expect(op['entity'], 'delivery');
    expect(op['operation'], 'UPDATE');
    expect(op['created_at'], isNotEmpty);
    expect(op['payload'], {'delivery_id': 'd1'});
  });

  test('PROCESSED removes the operation from the queue', () async {
    await enqueue('op-1');
    final client = _FakeApiClient(
      () async => const ApiResponse(statusCode: 200, data: {
        'data': {
          'results': [
            {'operation_id': 'op-1', 'status': 'PROCESSED'},
          ],
        },
      }),
    );

    final result = await buildWorker(client).sync();

    expect(result.processed, 1);
    expect(result.hasFailures, isFalse);
    expect(await queue.count(), 0);
  });

  test('ALREADY_PROCESSED is treated as success (server deduplication)',
      () async {
    await enqueue('op-1');
    final client = _FakeApiClient(
      () async => const ApiResponse(statusCode: 200, data: {
        'data': {
          'results': [
            {'operation_id': 'op-1', 'status': 'ALREADY_PROCESSED'},
          ],
        },
      }),
    );

    final result = await buildWorker(client).sync();

    expect(result.alreadyProcessed, 1);
    expect(await queue.count(), 0);
  });

  test('treats each response status correctly in a mixed batch', () async {
    for (var i = 1; i <= 5; i++) {
      await enqueue('op-$i');
    }
    final client = _FakeApiClient(
      () async => const ApiResponse(statusCode: 200, data: {
        'data': {
          'results': [
            {'operation_id': 'op-1', 'status': 'PROCESSED'},
            {'operation_id': 'op-2', 'status': 'ALREADY_PROCESSED'},
            {'operation_id': 'op-3', 'status': 'CONFLICT'},
            {'operation_id': 'op-4', 'status': 'RETRY'},
            {'operation_id': 'op-5', 'status': 'FAILED'},
          ],
        },
      }),
    );

    final result = await buildWorker(client).sync();

    expect(result.processed, 1);
    expect(result.alreadyProcessed, 1);
    expect(result.conflicts, 1);
    expect(result.retried, 1);
    expect(result.failed, 1);
    expect(result.hasFailures, isTrue);

    expect(await queue.byId('op-1'), isNull);
    expect(await queue.byId('op-2'), isNull);
    expect(
      (await queue.byId('op-3'))!.status,
      SyncOperationStatus.conflict,
    );
    expect((await queue.byId('op-4'))!.status, SyncOperationStatus.retry);
    expect((await queue.byId('op-5'))!.status, SyncOperationStatus.failed);
  });

  test('operation without a result entry is retried (partial batch)', () async {
    await enqueue('op-1');
    await enqueue('op-2');
    final client = _FakeApiClient(
      () async => const ApiResponse(statusCode: 200, data: {
        'data': {
          'results': [
            {'operation_id': 'op-1', 'status': 'PROCESSED'},
          ],
        },
      }),
    );

    final result = await buildWorker(client).sync();

    expect(result.processed, 1);
    expect(result.retried, 1);
    expect((await queue.byId('op-2'))!.status, SyncOperationStatus.retry);
  });

  test('unknown status is treated as a safe retry', () async {
    await enqueue('op-1');
    final client = _FakeApiClient(
      () async => const ApiResponse(statusCode: 200, data: {
        'data': {
          'results': [
            {'operation_id': 'op-1', 'status': 'WEIRD'},
          ],
        },
      }),
    );

    final result = await buildWorker(client).sync();

    expect(result.retried, 1);
    expect((await queue.byId('op-1'))!.status, SyncOperationStatus.retry);
  });

  test('network failure marks all sent operations for retry', () async {
    await enqueue('op-1');
    await enqueue('op-2');
    final client = _FakeApiClient(
      () async => throw const NetworkException('Falha de conexão.'),
    );

    final result = await buildWorker(client).sync();

    expect(result.sent, 2);
    expect(result.retried, 2);
    expect(result.error, isA<NetworkException>());
    expect((await queue.byId('op-1'))!.status, SyncOperationStatus.retry);
    expect((await queue.byId('op-2'))!.status, SyncOperationStatus.retry);
  });

  test('server failure (5xx) marks all sent operations for retry', () async {
    await enqueue('op-1');
    final client = _FakeApiClient(
      () async => throw const ServerException('Erro interno.'),
    );

    final result = await buildWorker(client).sync();

    expect(result.retried, 1);
    expect(result.error, isA<ServerException>());
    expect((await queue.byId('op-1'))!.status, SyncOperationStatus.retry);
  });

  test('unauthorized failure does not consume attempts', () async {
    await enqueue('op-1');
    final client = _FakeApiClient(
      () async => throw const UnauthorizedException('Sessão expirada.'),
    );

    final result = await buildWorker(client).sync();

    expect(result.retried, 0);
    expect(result.error, isA<UnauthorizedException>());
    final stored = await queue.byId('op-1');
    expect(stored!.status, SyncOperationStatus.pending);
    expect(stored.attempts, 0);
  });
}

