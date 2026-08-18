import 'dart:io';

import 'package:delivery_app/core/sync/hive_sync_queue.dart';
import 'package:delivery_app/core/sync/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<Map<dynamic, dynamic>> box;
  late HiveSyncQueue queue;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_queue_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<Map<dynamic, dynamic>>('sync_queue');
    queue = HiveSyncQueue(box);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  SyncOperation op({String id = 'op-1', DateTime? createdAt}) {
    return SyncOperation(
      operationId: id,
      deviceId: 'device-1',
      entityType: 'DELIVERY',
      entityId: 'd1',
      operationType: 'CONFIRM_PICKUP',
      clientCreatedAt: createdAt ?? DateTime.utc(2026, 8, 16, 12),
      payload: const {'delivery_id': 'd1'},
    );
  }

  test('enqueue persists the operation atomically', () async {
    await queue.enqueue(op());

    expect(await queue.count(), 1);
    final stored = await queue.byId('op-1');
    expect(stored, isNotNull);
    expect(stored!.entityType, 'DELIVERY');
    expect(stored.operationType, 'CONFIRM_PICKUP');
    expect(stored.payload, {'delivery_id': 'd1'});
    expect(stored.status, SyncOperationStatus.pending);
    expect(stored.attempts, 0);
  });

  test('enqueue is idempotent for the same operationId', () async {
    await queue.enqueue(op());
    await queue.enqueue(op());

    expect(await queue.count(), 1);
  });

  test('pending is sorted by clientCreatedAt and respects the limit', () async {
    await queue.enqueue(
      op(id: 'op-3', createdAt: DateTime.utc(2026, 8, 16, 14)),
    );
    await queue.enqueue(
      op(id: 'op-1', createdAt: DateTime.utc(2026, 8, 16, 12)),
    );
    await queue.enqueue(
      op(id: 'op-2', createdAt: DateTime.utc(2026, 8, 16, 13)),
    );

    final pending = await queue.pending(limit: 2);

    expect(pending.map((e) => e.operationId).toList(), ['op-1', 'op-2']);
  });

  test('markRetry increments attempts and schedules a backoff', () async {
    await queue.enqueue(op());

    await queue.markRetry('op-1', error: 'timeout');

    final stored = await queue.byId('op-1');
    expect(stored!.status, SyncOperationStatus.retry);
    expect(stored.attempts, 1);
    expect(stored.nextRetryAt, isNotNull);
    expect(stored.error, 'timeout');
  });

  test('retried operations are not pending until nextRetryAt is due', () async {
    await queue.enqueue(op());
    await queue.markRetry('op-1');

    expect(await queue.pending(), isEmpty);
  });

  test('markRetry beyond maxAttempts becomes a permanent failure', () async {
    final limited = HiveSyncQueue(box, maxAttempts: 3);
    await limited.enqueue(op());

    await limited.markRetry('op-1');
    await limited.markRetry('op-1');
    await limited.markRetry('op-1');

    final stored = await limited.byId('op-1');
    expect(stored!.status, SyncOperationStatus.failed);
    expect(stored.attempts, 3);
    expect(stored.nextRetryAt, isNull);
  });

  test('markConflict keeps the operation explicit and out of pending', () async {
    await queue.enqueue(op());

    await queue.markConflict('op-1', reason: 'CONFLICT');

    final stored = await queue.byId('op-1');
    expect(stored!.status, SyncOperationStatus.conflict);
    expect(stored.error, 'CONFLICT');
    expect(await queue.pending(), isEmpty);
  });

  test('markFailed keeps a permanent failure record', () async {
    await queue.enqueue(op());

    await queue.markFailed('op-1', error: 'permanent');

    final stored = await queue.byId('op-1');
    expect(stored!.status, SyncOperationStatus.failed);
    expect(await queue.pending(), isEmpty);
  });

  test('markProcessed removes the operation from the queue', () async {
    await queue.enqueue(op());

    await queue.markProcessed('op-1');

    expect(await queue.count(), 0);
    expect(await queue.byId('op-1'), isNull);
  });

  test('queue survives a restart (close and reopen)', () async {
    await queue.enqueue(op(id: 'op-keep'));

    await box.close();
    box = await Hive.openBox<Map<dynamic, dynamic>>('sync_queue');
    final reopened = HiveSyncQueue(box);

    expect(await reopened.count(), 1);
    final stored = await reopened.byId('op-keep');
    expect(stored, isNotNull);
    expect(stored!.payload, {'delivery_id': 'd1'});
    expect(stored.status, SyncOperationStatus.pending);
  });
}
