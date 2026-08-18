import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/features/business/presentation/business_delivery_cubit.dart';
import 'package:delivery_app/features/business/presentation/business_delivery_state.dart';
import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:delivery_app/features/delivery/domain/delivery_repository.dart';
import 'package:delivery_app/features/delivery/domain/new_delivery.dart';
import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:delivery_app/features/delivery/domain/use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

const _newDelivery = NewDelivery(
  origin: DeliveryAddress(
    address: 'Rua A, 1',
    latitude: -20.1,
    longitude: -40.1,
  ),
  destination: DeliveryAddress(
    address: 'Rua B, 2',
    latitude: -20.2,
    longitude: -40.2,
  ),
  recipient: Recipient(name: 'Ana', phone: '27999999999'),
  items: [
    DeliveryItem(
      name: 'Caixa',
      category: 'GENERAL',
      quantity: 1,
      approximateWeight: 5.0,
    ),
  ],
  pricingMode: DeliveryPricingMode.calculated,
);

class _FakeRepo implements DeliveryRepository {
  _FakeRepo({this.error});

  final ApiException? error;
  int createCalls = 0;

  @override
  Future<DeliveryActionResult> createDelivery({
    required NewDelivery delivery,
  }) async {
    createCalls++;
    if (error != null) throw error!;
    return DeliveryActionResult(
      delivery: Delivery(id: 'd-new', status: DeliveryStatus.draft),
      confirmedOnServer: true,
    );
  }

  @override
  Future<DeliveryListResult> listAvailable() => throw UnimplementedError();

  @override
  Future<DeliveryLoadResult> getById(String id) => throw UnimplementedError();

  @override
  Future<DeliveryActionResult> acceptOffer({
    required String deliveryId,
    required String offerId,
  }) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> registerPickupArrival(String deliveryId) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> confirmPickup(String deliveryId) =>
      throw UnimplementedError();

  @override
  Future<DeliveryActionResult> confirmDelivery({
    required String deliveryId,
    required ProofOfDelivery proof,
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
}

void main() {
  test('initial state is idle', () {
    final cubit = CreateDeliveryCubit(CreateDelivery(_FakeRepo()));
    expect(cubit.state, isA<CreateDeliveryIdle>());
    cubit.close();
  });

  test('submit success emits the created draft delivery', () async {
    final repo = _FakeRepo();
    final cubit = CreateDeliveryCubit(CreateDelivery(repo));
    addTearDown(cubit.close);

    await cubit.submit(_newDelivery);

    expect(repo.createCalls, 1);
    expect(cubit.state, isA<CreateDeliverySuccess>());
    final state = cubit.state as CreateDeliverySuccess;
    expect(state.delivery.status, DeliveryStatus.draft);
  });

  test('submit failure emits a safe error message', () async {
    final cubit = CreateDeliveryCubit(
      CreateDelivery(
        _FakeRepo(error: const ServerException('Erro interno.')),
      ),
    );
    addTearDown(cubit.close);

    await cubit.submit(_newDelivery);

    expect(cubit.state, isA<CreateDeliveryFailure>());
    expect((cubit.state as CreateDeliveryFailure).message, 'Erro interno.');
  });
}
