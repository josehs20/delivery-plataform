import 'dart:typed_data';

import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:delivery_app/features/delivery/domain/delivery_repository.dart';
import 'package:delivery_app/features/delivery/domain/new_delivery.dart';
import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:delivery_app/features/delivery/domain/use_cases.dart';
import 'package:delivery_app/features/delivery/presentation/delivery_detail_cubit.dart';
import 'package:delivery_app/features/delivery/presentation/delivery_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';

Delivery _delivery(DeliveryStatus status) => Delivery(
      id: 'd1',
      status: status,
      origin: const DeliveryAddress(address: 'Rua A, 1'),
      destination: const DeliveryAddress(address: 'Rua B, 2'),
      recipient: const Recipient(name: 'Ana', phone: '27999999999'),
      suggestedAmount: '25.00',
    );

class _FakeDetailRepository implements DeliveryRepository {
  _FakeDetailRepository({required this.delivery, this.confirmedOnServer = true});

  Delivery delivery;
  final bool confirmedOnServer;
  ApiException? getError;
  ApiException? actionError;

  int arrivalCalls = 0;
  int pickupCalls = 0;
  int completeCalls = 0;

  @override
  Future<DeliveryLoadResult> getById(String id) async {
    if (getError != null) throw getError!;
    return DeliveryLoadResult(delivery: delivery, fromCache: false);
  }

  @override
  Future<DeliveryListResult> listAvailable() => throw UnimplementedError();

  @override
  Future<DeliveryActionResult> acceptOffer({
    required String deliveryId,
    required String offerId,
  }) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> registerPickupArrival(String deliveryId) async {
    arrivalCalls++;
    if (actionError != null) throw actionError!;
    return _result(DeliveryStatus.atPickup);
  }

  @override
  Future<DeliveryActionResult> confirmPickup(String deliveryId) async {
    pickupCalls++;
    if (actionError != null) throw actionError!;
    return _result(DeliveryStatus.pickedUp);
  }

  @override
  Future<DeliveryActionResult> confirmDelivery({
    required String deliveryId,
    required ProofOfDelivery proof,
  }) async {
    completeCalls++;
    if (actionError != null) throw actionError!;
    return _result(DeliveryStatus.delivered);
  }

  @override
  Future<DeliveryActionResult> createDelivery({
    required NewDelivery delivery,
  }) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> publishDelivery(String deliveryId) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> cancelDelivery({
    required String deliveryId,
    required String reason,
    String? description,
  }) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> arriveDestination(String deliveryId) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> failDelivery({
    required String deliveryId,
    required String reason,
    String? description,
  }) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> startReturn(String deliveryId) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> confirmReturn(String deliveryId) =>
      throw UnimplementedError();

  DeliveryActionResult _result(DeliveryStatus status) => DeliveryActionResult(
        delivery: _delivery(status),
        confirmedOnServer: confirmedOnServer,
      );
}

DeliveryDetailCubit _cubitFor(_FakeDetailRepository repo) {
  return DeliveryDetailCubit(
    getDelivery: GetDelivery(repo),
    registerPickupArrival: RegisterPickupArrival(repo),
    confirmPickup: ConfirmPickup(repo),
    registerDestinationArrival: RegisterDestinationArrival(repo),
    confirmDelivery: ConfirmDelivery(repo),
    failDelivery: FailDelivery(repo),
    startReturn: StartReturn(repo),
    publishDelivery: PublishDelivery(repo),
    cancelDelivery: CancelDelivery(repo),
    confirmReturn: ConfirmReturn(repo),
  );
}

final _proof = ProofOfDelivery(
  type: ProofType.signature,
  signatureBytes: Uint8List.fromList([1, 2, 3]),
  capturedAt: DateTime.utc(2026, 8, 17),
);

void main() {
  group('DeliveryDetailCubit', () {
    test('initial state is Loading', () {
      final cubit = _cubitFor(
        _FakeDetailRepository(delivery: _delivery(DeliveryStatus.goingToPickup)),
      );

      expect(cubit.state, isA<DeliveryDetailLoading>());

      cubit.close();
    });

    test('load from server emits Synced', () async {
      final cubit = _cubitFor(
        _FakeDetailRepository(delivery: _delivery(DeliveryStatus.goingToPickup)),
      );

      await cubit.load('d1');

      final state = cubit.state as DeliveryDetailSynced;
      expect(state.delivery.id, 'd1');
      expect(state.delivery.status, DeliveryStatus.goingToPickup);

      cubit.close();
    });

    test('load failure emits Failure', () async {
      final repo = _FakeDetailRepository(
        delivery: _delivery(DeliveryStatus.goingToPickup),
      )..getError = const ServerException('Erro.');
      final cubit = _cubitFor(repo);

      await cubit.load('d1');

      expect(cubit.state, isA<DeliveryDetailFailure>());
      expect((cubit.state as DeliveryDetailFailure).message, 'Erro.');

      cubit.close();
    });

    test('registerPickupArrival success emits Synced with AT_PICKUP', () async {
      final repo = _FakeDetailRepository(
        delivery: _delivery(DeliveryStatus.goingToPickup),
      );
      final cubit = _cubitFor(repo);

      await cubit.load('d1');
      await cubit.registerPickupArrival();

      expect(repo.arrivalCalls, 1);
      final state = cubit.state as DeliveryDetailSynced;
      expect(state.delivery.status, DeliveryStatus.atPickup);

      cubit.close();
    });

    test('confirmPickup success emits Synced with PICKED_UP', () async {
      final repo = _FakeDetailRepository(
        delivery: _delivery(DeliveryStatus.atPickup),
      );
      final cubit = _cubitFor(repo);

      await cubit.load('d1');
      await cubit.confirmPickup();

      expect(repo.pickupCalls, 1);
      expect(
        (cubit.state as DeliveryDetailSynced).delivery.status,
        DeliveryStatus.pickedUp,
      );

      cubit.close();
    });

    test('confirmDelivery success emits Synced with DELIVERED', () async {
      final repo = _FakeDetailRepository(
        delivery: _delivery(DeliveryStatus.pickedUp),
      );
      final cubit = _cubitFor(repo);

      await cubit.load('d1');
      await cubit.confirmDelivery(_proof);

      expect(repo.completeCalls, 1);
      expect(
        (cubit.state as DeliveryDetailSynced).delivery.status,
        DeliveryStatus.delivered,
      );

      cubit.close();
    });

    test('offline action emits Local (pendente de sincronização)', () async {
      final repo = _FakeDetailRepository(
        delivery: _delivery(DeliveryStatus.atPickup),
        confirmedOnServer: false,
      );
      final cubit = _cubitFor(repo);

      await cubit.load('d1');
      await cubit.confirmPickup();

      expect(cubit.state, isA<DeliveryDetailLocal>());

      cubit.close();
    });

    test('action failure emits Failure preserving the delivery', () async {
      final repo = _FakeDetailRepository(
        delivery: _delivery(DeliveryStatus.atPickup),
      )..actionError = const ConflictException('Estado inválido.');
      final cubit = _cubitFor(repo);

      await cubit.load('d1');
      await cubit.confirmPickup();

      final state = cubit.state as DeliveryDetailFailure;
      expect(state.message, 'Estado inválido.');
      expect(state.delivery, isNotNull);

      cubit.close();
    });
  });
}

