import 'dart:io';

import 'package:delivery_app/core/storage/local_database.dart';
import 'package:delivery_app/core/sync/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('local_db_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('deviceId is stable across restarts', () async {
    final db = await LocalDatabase.open(directory: tempDir);
    final first = await db.deviceId();
    await db.close();

    final reopened = await LocalDatabase.open(directory: tempDir);
    final second = await reopened.deviceId();
    await reopened.close();

    expect(second, first);
    expect(first, isNotEmpty);
  });

  test('provides delivery cache and sync queue repositories', () async {
    final db = await LocalDatabase.open(directory: tempDir);

    expect(db.deliveryCache(), isNotNull);
    expect(db.syncQueue(), isNotNull);
    expect(await db.deviceId(), isNotEmpty);

    await db.close();
  });

  test('sync queue enqueued via LocalDatabase is readable after reopen',
      () async {
    final db = await LocalDatabase.open(directory: tempDir);
    await db.syncQueue().enqueue(
          SyncOperation(
            operationId: 'op-1',
            deviceId: 'device-1',
            entityType: 'DELIVERY',
            entityId: 'd1',
            operationType: 'CONFIRM_PICKUP',
            clientCreatedAt: DateTime.utc(2026, 8, 16, 12),
            payload: const {'delivery_id': 'd1'},
          ),
        );
    await db.close();

    final reopened = await LocalDatabase.open(directory: tempDir);
    final pending = await reopened.syncQueue().pending();

    expect(pending, hasLength(1));
    expect(pending.single.operationId, 'op-1');
    await reopened.close();
  });
}
