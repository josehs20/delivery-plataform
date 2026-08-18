import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:delivery_app/features/delivery/domain/delivery_repository.dart';
import 'package:delivery_app/features/delivery/domain/new_delivery.dart';
import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:delivery_app/features/delivery/domain/use_cases.dart';
import 'package:delivery_app/features/delivery/presentation/delivery_list_cubit.dart';
import 'package:delivery_app/features/delivery/presentation/delivery_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

final _available = Delivery(
  id: 'd1',
  status: DeliveryStatus.open,
  origin: const DeliveryAddress(address: 'Rua A, 1'),
  destination: const DeliveryAddress(address: 'Rua B, 2'),
  recipient: const Recipient(name: 'Ana', phone: '27999999999'),
  suggestedAmount: '25.00',
  offers: const [
    Offer(
      id: 'o1',
      deliveryId: 'd1',
      driverId: 'dr1',
      status: 'PENDING',
      offeredAmount: '25.00',
    ),
  ],
);

class _FakeDeliveryRepository implements DeliveryRepository {
  _FakeDeliveryRepository({
    this.deliveries = const [],
    this.fromCache = false,
  });

  List<Delivery> deliveries;
  bool fromCache;
  ApiException? listError;
  ApiException? acceptError;
  int acceptCalls = 0;

  @override
  Future<DeliveryListResult> listAvailable() async {
    if (listError != null) throw listError!;
    return DeliveryListResult(
      deliveries: List.of(deliveries),
      fromCache: fromCache,
    );
  }

  @override
  Future<DeliveryActionResult> acceptOffer({
    required String deliveryId,
    required String offerId,
  }) async {
    acceptCalls++;
    if (acceptError != null) throw acceptError!;
    return DeliveryActionResult(
      delivery: _available,
      confirmedOnServer: true,
    );
  }

  @override
  Future<DeliveryLoadResult> getById(String id) => throw UnimplementedError();

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
}

void main() {
  group('DeliveryListCubit', () {
    test('initial state is Loading', () {
      final cubit = DeliveryListCubit(
        ListAvailableDeliveries(_FakeDeliveryRepository()),
        AcceptOffer(_FakeDeliveryRepository()),
      );

      expect(cubit.state, isA<DeliveryListLoading>());

      cubit.close();
    });

    test('load from server emits Synced', () async {
      final cubit = DeliveryListCubit(
        ListAvailableDeliveries(
          _FakeDeliveryRepository(deliveries: [_available]),
        ),
        AcceptOffer(_FakeDeliveryRepository()),
      );
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<DeliveryListLoading>(),
          isA<DeliveryListSynced>(),
        ]),
      );

      await cubit.load();
      await expectation;

      final state = cubit.state as DeliveryListSynced;
      expect(state.deliveries.single.id, 'd1');
      expect(state.deliveries.single.pendingOffer!.id, 'o1');

      cubit.close();
    });

    test('load from cache emits Local (offline)', () async {
      final cubit = DeliveryListCubit(
        ListAvailableDeliveries(
          _FakeDeliveryRepository(
            deliveries: [_available],
            fromCache: true,
          ),
        ),
        AcceptOffer(_FakeDeliveryRepository()),
      );

      await cubit.load();

      expect(cubit.state, isA<DeliveryListLocal>());
      expect((cubit.state as DeliveryListLocal).deliveries, hasLength(1));

      cubit.close();
    });

    test('load failure emits Failure with the message', () async {
      final repo = _FakeDeliveryRepository()
        ..listError = const ServerException('Erro interno.');
      final cubit = DeliveryListCubit(
        ListAvailableDeliveries(repo),
        AcceptOffer(_FakeDeliveryRepository()),
      );

      await cubit.load();

      expect(cubit.state, isA<DeliveryListFailure>());
      expect((cubit.state as DeliveryListFailure).message, 'Erro interno.');

      cubit.close();
    });

    test('refresh keeps content while syncing and updates on success',
        () async {
      final cubit = DeliveryListCubit(
        ListAvailableDeliveries(
          _FakeDeliveryRepository(deliveries: [_available]),
        ),
        AcceptOffer(_FakeDeliveryRepository()),
      );
      await cubit.load();

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<DeliveryListSyncing>(),
          isA<DeliveryListSynced>(),
        ]),
      );

      await cubit.refresh();
      await expectation;

      cubit.close();
    });

    test('refresh failure preserves the previous content', () async {
      final repo = _FakeDeliveryRepository(deliveries: [_available]);
      final cubit = DeliveryListCubit(
        ListAvailableDeliveries(repo),
        AcceptOffer(_FakeDeliveryRepository()),
      );
      await cubit.load();
      repo.listError = const NetworkException('offline');

      await cubit.refresh();

      final state = cubit.state as DeliveryListFailure;
      expect(state.deliveries, isNotNull);
      expect(state.deliveries!.single.id, 'd1');

      cubit.close();
    });

    test('accept calls the repository and reloads the feed', () async {
      final repo = _FakeDeliveryRepository(deliveries: [_available]);
      final cubit = DeliveryListCubit(
        ListAvailableDeliveries(repo),
        AcceptOffer(repo),
      );
      await cubit.load();

      await cubit.accept(_available);

      expect(repo.acceptCalls, 1);
      expect(cubit.state, isA<DeliveryListSynced>());

      cubit.close();
    });

    test('accept without a pending offer emits Failure', () async {
      final withoutOffer = Delivery(
        id: 'd2',
        status: DeliveryStatus.open,
        destination: const DeliveryAddress(address: 'Rua B'),
      );
      final repo = _FakeDeliveryRepository(deliveries: [withoutOffer]);
      final cubit = DeliveryListCubit(
        ListAvailableDeliveries(repo),
        AcceptOffer(repo),
      );
      await cubit.load();

      await cubit.accept(withoutOffer);

      expect(repo.acceptCalls, 0);
      expect(cubit.state, isA<DeliveryListFailure>());

      cubit.close();
    });

    test('accept failure emits Failure preserving content', () async {
      final repo = _FakeDeliveryRepository(deliveries: [_available])
        ..acceptError = const ConflictException('Entrega já atribuída.');
      final cubit = DeliveryListCubit(
        ListAvailableDeliveries(repo),
        AcceptOffer(repo),
      );
      await cubit.load();

      await cubit.accept(_available);

      final state = cubit.state as DeliveryListFailure;
      expect(state.message, 'Entrega já atribuída.');
      expect(state.deliveries, isNotNull);

      cubit.close();
    });
  });
}

