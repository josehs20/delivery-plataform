import 'dart:typed_data';

import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/core/models/delivery_dto.dart';
import 'package:delivery_app/core/storage/delivery_cache_repository.dart';
import 'package:delivery_app/core/sync/sync_operation.dart';
import 'package:delivery_app/core/sync/sync_queue.dart';
import 'package:delivery_app/features/delivery/data/delivery_mapper.dart';
import 'package:delivery_app/features/delivery/data/delivery_remote_data_source.dart';
import 'package:delivery_app/features/delivery/data/delivery_repository_impl.dart';
import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:delivery_app/features/delivery/domain/new_delivery.dart';
import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:flutter_test/flutter_test.dart';

DeliveryDto _dto({String id = 'd1', String status = 'OPEN'}) {
  return DeliveryDto(
    id: id,
    status: status,
    currency: 'BRL',
    suggestedAmount: '25.00',
    origin: const DeliveryAddressDto(
      address: 'Rua A, 1',
      latitude: -20.1,
      longitude: -40.1,
    ),
    destination: const DeliveryAddressDto(
      address: 'Rua B, 2',
      latitude: -20.2,
      longitude: -40.2,
    ),
    recipient: const RecipientDto(name: 'Ana', phone: '27999999999'),
    items: const [DeliveryItemDto(name: 'Caixa', quantity: 1)],
  );
}

class _FakeRemote implements DeliveryRemoteDataSource {
  _FakeRemote({this.deliveries = const []});

  final List<DeliveryDto> deliveries;
  ApiException? listError;
  ApiException? getError;
  ApiException? actionError;

  int acceptCalls = 0;
  int arrivePickupCalls = 0;
  int pickupCalls = 0;
  int completeCalls = 0;

  @override
  Future<List<DeliveryDto>> listDeliveries() async {
    if (listError != null) throw listError!;
    return deliveries;
  }

  @override
  Future<DeliveryDto> getDelivery(String id) async {
    if (getError != null) throw getError!;
    return deliveries.firstWhere((d) => d.id == id);
  }

  @override
  Future<DeliveryDto> acceptOffer({
    required String deliveryId,
    required String offerId,
    required String idempotencyKey,
  }) async {
    acceptCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'ASSIGNED');
  }

  @override
  Future<DeliveryDto> arrivePickup({
    required String deliveryId,
    required String idempotencyKey,
  }) async {
    arrivePickupCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'AT_PICKUP');
  }

  @override
  Future<DeliveryDto> pickup({
    required String deliveryId,
    required String idempotencyKey,
  }) async {
    pickupCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'PICKED_UP');
  }

  @override
  Future<DeliveryDto> complete({
    required String deliveryId,
    required Map<String, dynamic> proof,
    required String idempotencyKey,
  }) async {
    completeCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'DELIVERED');
  }

  int createCalls = 0;
  int publishCalls = 0;
  int cancelCalls = 0;
  int arriveDestinationCalls = 0;
  int failCalls = 0;
  int startReturnCalls = 0;
  int confirmReturnCalls = 0;

  @override
  Future<DeliveryDto> createDelivery(Map<String, dynamic> payload) async {
    createCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: 'new-1', status: 'DRAFT');
  }

  @override
  Future<DeliveryDto> publishDelivery(String deliveryId) async {
    publishCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'OPEN');
  }

  @override
  Future<DeliveryDto> cancelDelivery({
    required String deliveryId,
    required String reason,
    String? description,
  }) async {
    cancelCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'CANCELLED');
  }

  @override
  Future<DeliveryDto> arriveDestination({
    required String deliveryId,
    required String idempotencyKey,
  }) async {
    arriveDestinationCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'AT_DESTINATION');
  }

  @override
  Future<DeliveryDto> failDelivery({
    required String deliveryId,
    required String reason,
    String? description,
    required String idempotencyKey,
  }) async {
    failCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'DELIVERY_FAILED');
  }

  @override
  Future<DeliveryDto> startReturn({
    required String deliveryId,
    required String idempotencyKey,
  }) async {
    startReturnCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'RETURN_IN_PROGRESS');
  }

  @override
  Future<DeliveryDto> confirmReturn(String deliveryId) async {
    confirmReturnCalls++;
    if (actionError != null) throw actionError!;
    return _dto(id: deliveryId, status: 'RETURNED');
  }
}

class _FakeCache implements DeliveryCacheRepository {
  final Map<String, DeliveryDto> _items = {};

  @override
  Future<void> upsert(DeliveryDto delivery) async =>
      _items[delivery.id] = delivery;

  @override
  Future<void> upsertAll(Iterable<DeliveryDto> deliveries) async {
    for (final delivery in deliveries) {
      _items[delivery.id] = delivery;
    }
  }

  @override
  Future<DeliveryDto?> byId(String id) async => _items[id];

  @override
  Future<List<DeliveryDto>> all() async => _items.values.toList();

  @override
  Future<List<DeliveryDto>> byStatus(Set<String> statuses) async =>
      _items.values.where((d) => statuses.contains(d.status)).toList();

  @override
  Future<void> remove(String id) async => _items.remove(id);

  @override
  Future<void> clear() async => _items.clear();
}

class _FakeSyncQueue implements SyncQueue {
  final List<SyncOperation> operations = [];

  @override
  Future<void> enqueue(SyncOperation operation) async =>
      operations.add(operation);

  @override
  Future<List<SyncOperation>> pending({int limit = 50}) async =>
      List.of(operations);

  @override
  Future<SyncOperation?> byId(String operationId) async {
    for (final operation in operations) {
      if (operation.operationId == operationId) return operation;
    }
    return null;
  }

  @override
  Future<int> count() async => operations.length;

  @override
  Future<void> markProcessed(String operationId) async {}

  @override
  Future<void> markRetry(String operationId, {String? error}) async {}

  @override
  Future<void> markConflict(String operationId, {String? reason}) async {}

  @override
  Future<void> markFailed(String operationId, {String? error}) async {}
}

DeliveryRepositoryImpl _repo({
  required _FakeRemote remote,
  required _FakeCache cache,
  required _FakeSyncQueue queue,
}) {
  return DeliveryRepositoryImpl(
    remote,
    cache,
    queue,
    'device-1',
    operationIdGenerator: () => 'op-key-0000000001',
  );
}

final _proof = ProofOfDelivery(
  type: ProofType.signature,
  signatureBytes: Uint8List.fromList([1, 2, 3]),
  capturedAt: DateTime.utc(2026, 8, 17),
);

void main() {
  group('DeliveryMapper', () {
    test('maps DTO to domain with status and pending offer', () {
      final dto = DeliveryDto.fromJson(const {
        'id': 'd1',
        'status': 'OPEN',
        'currency': 'BRL',
        'suggested_amount': '25.00',
        'offers': [
          {
            'id': 'o1',
            'delivery_id': 'd1',
            'driver_id': 'dr1',
            'status': 'PENDING',
            'offered_amount': '25.00',
          },
        ],
      });

      final delivery = DeliveryMapper.fromDto(dto);

      expect(delivery.status, DeliveryStatus.open);
      expect(delivery.pendingOffer, isNotNull);
      expect(delivery.pendingOffer!.id, 'o1');
      expect(delivery.displayAmount, '25.00');
    });
  });

  group('DeliveryRepositoryImpl — listagem e detalhe', () {
    test('listAvailable online returns server data and caches', () async {
      final remote = _FakeRemote(deliveries: [_dto()]);
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      final result =
          await _repo(remote: remote, cache: cache, queue: queue).listAvailable();

      expect(result.fromCache, isFalse);
      expect(result.deliveries.single.id, 'd1');
      expect(await cache.byId('d1'), isNotNull);
    });

    test('listAvailable offline falls back to the cache', () async {
      final remote = _FakeRemote()
        ..listError = const NetworkException('offline');
      final cache = _FakeCache();
      await cache.upsert(_dto(id: 'cached'));
      final queue = _FakeSyncQueue();

      final result =
          await _repo(remote: remote, cache: cache, queue: queue).listAvailable();

      expect(result.fromCache, isTrue);
      expect(result.deliveries.single.id, 'cached');
    });

    test('getById offline with cache returns fromCache=true', () async {
      final remote = _FakeRemote()
        ..getError = const NetworkException('offline');
      final cache = _FakeCache();
      await cache.upsert(_dto(id: 'd1', status: 'GOING_TO_PICKUP'));
      final queue = _FakeSyncQueue();

      final result =
          await _repo(remote: remote, cache: cache, queue: queue).getById('d1');

      expect(result.fromCache, isTrue);
      expect(result.delivery.status, DeliveryStatus.goingToPickup);
    });

    test('getById offline without cache throws ServerException', () async {
      final remote = _FakeRemote()
        ..getError = const NetworkException('offline');
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      await expectLater(
        _repo(remote: remote, cache: cache, queue: queue).getById('missing'),
        throwsA(isA<ServerException>()),
      );
    });
  });


  group('DeliveryRepositoryImpl — ações do motoboy', () {
    test('acceptOffer requires connectivity and confirms on the server',
        () async {
      final remote = _FakeRemote();
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .acceptOffer(deliveryId: 'd1', offerId: 'o1');

      expect(remote.acceptCalls, 1);
      expect(result.confirmedOnServer, isTrue);
      expect(result.delivery.status, DeliveryStatus.assigned);
      expect(queue.operations, isEmpty);
    });

    test('acceptOffer propagates remote failures (exige conectividade)',
        () async {
      final remote = _FakeRemote()
        ..actionError = const NetworkException('offline');
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      await expectLater(
        _repo(remote: remote, cache: cache, queue: queue)
            .acceptOffer(deliveryId: 'd1', offerId: 'o1'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('registerPickupArrival online confirms on the server', () async {
      final remote = _FakeRemote();
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .registerPickupArrival('d1');

      expect(remote.arrivePickupCalls, 1);
      expect(result.confirmedOnServer, isTrue);
      expect(result.delivery.status, DeliveryStatus.atPickup);
      expect(queue.operations, isEmpty);
    });

    test('registerPickupArrival offline enqueues and updates the cache',
        () async {
      final remote = _FakeRemote()
        ..actionError = const NetworkException('offline');
      final cache = _FakeCache();
      await cache.upsert(_dto(status: 'GOING_TO_PICKUP'));
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .registerPickupArrival('d1');

      expect(result.confirmedOnServer, isFalse);
      expect(result.delivery.status, DeliveryStatus.atPickup);
      expect((await cache.byId('d1'))!.status, 'AT_PICKUP');

      final operation = queue.operations.single;
      expect(operation.operationType, 'ARRIVE_PICKUP');
      expect(operation.entityType, 'DELIVERY');
      expect(operation.payload['action'], 'arrive-pickup');
      expect(operation.payload['delivery_id'], 'd1');
      expect(operation.deviceId, 'device-1');
    });

    test('confirmPickup offline enqueues CONFIRM_PICKUP', () async {
      final remote = _FakeRemote()
        ..actionError = const NetworkException('offline');
      final cache = _FakeCache();
      await cache.upsert(_dto(status: 'AT_PICKUP'));
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .confirmPickup('d1');

      expect(result.confirmedOnServer, isFalse);
      expect(result.delivery.status, DeliveryStatus.pickedUp);
      expect(queue.operations.single.operationType, 'CONFIRM_PICKUP');
      expect(queue.operations.single.payload['action'], 'pickup');
    });


    test('confirmDelivery offline enqueues COMPLETE with the proof', () async {
      final remote = _FakeRemote()
        ..actionError = const NetworkException('offline');
      final cache = _FakeCache();
      await cache.upsert(_dto(status: 'PICKED_UP'));
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .confirmDelivery(deliveryId: 'd1', proof: _proof);

      expect(result.confirmedOnServer, isFalse);
      expect(result.delivery.status, DeliveryStatus.delivered);
      expect((await cache.byId('d1'))!.status, 'DELIVERED');

      final operation = queue.operations.single;
      expect(operation.operationType, 'COMPLETE');
      expect(operation.payload['action'], 'complete');
      expect(operation.payload['proof'], isA<Map>());
      expect((operation.payload['proof'] as Map)['type'], 'SIGNATURE');
    });

    test('confirmDelivery online confirms on the server', () async {
      final remote = _FakeRemote();
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .confirmDelivery(deliveryId: 'd1', proof: _proof);

      expect(remote.completeCalls, 1);
      expect(result.confirmedOnServer, isTrue);
      expect(result.delivery.status, DeliveryStatus.delivered);
      expect(queue.operations, isEmpty);
    });
  });

  group('DeliveryRepositoryImpl — ações do comércio e novas transições', () {
    final newDelivery = NewDelivery(
      origin: const DeliveryAddress(
        address: 'Rua A, 1',
        latitude: -20.1,
        longitude: -40.1,
      ),
      destination: const DeliveryAddress(
        address: 'Rua B, 2',
        latitude: -20.2,
        longitude: -40.2,
      ),
      recipient: const Recipient(name: 'Ana', phone: '27999999999'),
      items: const [
        DeliveryItem(
          name: 'Caixa',
          category: 'GENERAL',
          quantity: 1,
          approximateWeight: 5.0,
        ),
      ],
      pricingMode: DeliveryPricingMode.calculated,
      pickupDeadline: DateTime.utc(2026, 8, 20, 12),
    );

    test('createDelivery posts the request payload and caches the draft',
        () async {
      final remote = _FakeRemote();
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .createDelivery(delivery: newDelivery);

      expect(remote.createCalls, 1);
      expect(result.confirmedOnServer, isTrue);
      expect(result.delivery.status, DeliveryStatus.draft);
      expect(await cache.byId('new-1'), isNotNull);
    });

    test('createDelivery builds the backend payload shape', () {
      final payload = newDelivery.toRequestPayload();
      expect(payload['origin']['latitude'], -20.1);
      expect(payload['destination']['address'], 'Rua B, 2');
      expect(payload['recipient']['name'], 'Ana');
      expect(payload['items'], hasLength(1));
      expect(payload['pricing']['mode'], 'CALCULATED');
      expect(payload['pickup_deadline'], isNotEmpty);
      expect(payload['items'].first['category'], 'GENERAL');
    });

    test('publishDelivery calls the backend and caches', () async {
      final remote = _FakeRemote();
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .publishDelivery('d1');

      expect(remote.publishCalls, 1);
      expect(result.delivery.status, DeliveryStatus.open);
    });

    test('cancelDelivery sends reason and returns cancelled', () async {
      final remote = _FakeRemote();
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .cancelDelivery(
        deliveryId: 'd1',
        reason: 'NO_LONGER_NEEDED',
        description: 'Teste',
      );

      expect(remote.cancelCalls, 1);
      expect(result.delivery.status, DeliveryStatus.cancelled);
    });

    test('arriveDestination offline enqueues ARRIVE_DESTINATION', () async {
      final remote = _FakeRemote()..actionError = const NetworkException('off');
      final cache = _FakeCache();
      await cache.upsert(_dto(status: 'PICKED_UP'));
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .arriveDestination('d1');

      expect(result.confirmedOnServer, isFalse);
      expect(result.delivery.status, DeliveryStatus.atDestination);
      final op = queue.operations.single;
      expect(op.operationType, 'ARRIVE_DESTINATION');
      expect(op.entityType, 'DELIVERY');
      expect(op.payload['action'], 'arrive-destination');
    });

    test('failDelivery offline enqueues FAIL with reason', () async {
      final remote = _FakeRemote()..actionError = const NetworkException('off');
      final cache = _FakeCache();
      await cache.upsert(_dto(status: 'IN_TRANSIT'));
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .failDelivery(deliveryId: 'd1', reason: 'Cliente ausente');

      expect(result.confirmedOnServer, isFalse);
      expect(result.delivery.status, DeliveryStatus.deliveryFailed);
      final op = queue.operations.single;
      expect(op.operationType, 'FAIL');
      expect(op.payload['reason'], 'Cliente ausente');
      expect(op.payload['action'], 'fail');
    });

    test('startReturn offline enqueues RETURN_START', () async {
      final remote = _FakeRemote()..actionError = const NetworkException('off');
      final cache = _FakeCache();
      await cache.upsert(_dto(status: 'DELIVERY_FAILED'));
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .startReturn('d1');

      expect(result.confirmedOnServer, isFalse);
      expect(result.delivery.status, DeliveryStatus.returnInProgress);
      final op = queue.operations.single;
      expect(op.operationType, 'RETURN_START');
      expect(op.payload['action'], 'return-start');
    });

    test('confirmReturn calls the backend and returns returned', () async {
      final remote = _FakeRemote();
      final cache = _FakeCache();
      final queue = _FakeSyncQueue();

      final result = await _repo(remote: remote, cache: cache, queue: queue)
          .confirmReturn('d1');

      expect(remote.confirmReturnCalls, 1);
      expect(result.confirmedOnServer, isTrue);
      expect(result.delivery.status, DeliveryStatus.returned);
    });
  });
}


