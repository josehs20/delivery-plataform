import 'dart:io';

import 'package:delivery_app/core/models/delivery_dto.dart';
import 'package:delivery_app/core/storage/delivery_cache_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<Map<dynamic, dynamic>> box;
  late HiveDeliveryCacheRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('delivery_cache_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<Map<dynamic, dynamic>>('deliveries_cache');
    repository = HiveDeliveryCacheRepository(box);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  DeliveryDto delivery(String id, {String status = 'OPEN'}) {
    return DeliveryDto(
      id: id,
      status: status,
      suggestedAmount: '25.00',
      currency: 'BRL',
    );
  }

  test('upsert and byId round-trips a delivery', () async {
    await repository.upsert(delivery('d1'));

    final stored = await repository.byId('d1');
    expect(stored, isNotNull);
    expect(stored!.id, 'd1');
    expect(stored.status, 'OPEN');
    expect(stored.suggestedAmount, '25.00');
    expect(stored.currency, 'BRL');
  });

  test('upsert overwrites an existing delivery', () async {
    await repository.upsert(delivery('d1', status: 'OPEN'));
    await repository.upsert(delivery('d1', status: 'PICKED_UP'));

    expect((await repository.byId('d1'))!.status, 'PICKED_UP');
    expect(await repository.all(), hasLength(1));
  });

  test('upsertAll persists all deliveries', () async {
    await repository.upsertAll([
      delivery('d1', status: 'OPEN'),
      delivery('d2', status: 'DELIVERED'),
    ]);

    expect(await repository.all(), hasLength(2));
  });

  test('byStatus filters deliveries', () async {
    await repository.upsertAll([
      delivery('d1', status: 'OPEN'),
      delivery('d2', status: 'PICKED_UP'),
      delivery('d3', status: 'DELIVERED'),
    ]);

    final active = await repository.byStatus({'OPEN', 'PICKED_UP'});

    expect(active.map((d) => d.id).toSet(), {'d1', 'd2'});
  });

  test('remove deletes a delivery', () async {
    await repository.upsert(delivery('d1'));

    await repository.remove('d1');

    expect(await repository.byId('d1'), isNull);
  });

  test('clear empties the cache', () async {
    await repository.upsertAll([delivery('d1'), delivery('d2')]);

    await repository.clear();

    expect(await repository.all(), isEmpty);
  });

  test('cache survives a restart (close and reopen)', () async {
    await repository.upsert(delivery('d1'));

    await box.close();
    box = await Hive.openBox<Map<dynamic, dynamic>>('deliveries_cache');
    final reopened = HiveDeliveryCacheRepository(box);

    final stored = await reopened.byId('d1');
    expect(stored, isNotNull);
    expect(stored!.status, 'OPEN');
  });
}
