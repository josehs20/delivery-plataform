import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:delivery_app/features/delivery/domain/delivery_repository.dart';
import 'package:delivery_app/features/delivery/domain/new_delivery.dart';
import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:delivery_app/features/delivery/domain/use_cases.dart';
import 'package:delivery_app/features/delivery/presentation/delivery_list_cubit.dart';
import 'package:delivery_app/features/delivery/presentation/screens/delivery_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Delivery _available(String id) => Delivery(
      id: id,
      status: DeliveryStatus.open,
      origin: const DeliveryAddress(address: 'Rua A, 1'),
      destination: const DeliveryAddress(address: 'Rua B, 2'),
      suggestedAmount: '25.00',
      offers: [
        Offer(
          id: 'o-$id',
          deliveryId: id,
          driverId: 'dr1',
          status: 'PENDING',
          offeredAmount: '25.00',
        ),
      ],
    );

class _FakeRepo implements DeliveryRepository {
  _FakeRepo({this.deliveries = const [], this.fromCache = false});

  List<Delivery> deliveries;
  bool fromCache;
  ApiException? listError;

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
  }) async =>
      DeliveryActionResult(
        delivery: deliveries.first,
        confirmedOnServer: true,
      );

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

Future<DeliveryListCubit> _pumpFeed(WidgetTester tester, _FakeRepo repo) async {
  final cubit = DeliveryListCubit(
    ListAvailableDeliveries(repo),
    AcceptOffer(repo),
  );
  addTearDown(cubit.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: const MaterialApp(home: DeliveryFeedScreen()),
    ),
  );
  return cubit;
}

void main() {
  testWidgets('shows loading while the initial load runs', (tester) async {
    await _pumpFeed(tester, _FakeRepo(deliveries: [_available('d1')]));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders the synced feed with accept actions', (tester) async {
    final cubit = await _pumpFeed(tester, _FakeRepo(deliveries: [_available('d1')]));

    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.text('Entregas disponíveis'), findsOneWidget);
    expect(find.text('Rua B, 2'), findsOneWidget);
    expect(find.text('Aceitar oferta'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.textContaining('25,00'), findsOneWidget);
  });

  testWidgets('shows the offline banner when data comes from the cache',
      (tester) async {
    final cubit = await _pumpFeed(
      tester,
      _FakeRepo(deliveries: [_available('d1')], fromCache: true),
    );

    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.text('Modo offline — dados locais'), findsOneWidget);
    expect(find.text('Rua B, 2'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no deliveries',
      (tester) async {
    final cubit = await _pumpFeed(tester, _FakeRepo());

    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma entrega disponível'), findsOneWidget);
  });

  testWidgets('shows failure with retry when loading fails', (tester) async {
    final repo = _FakeRepo()..listError = const ServerException('Erro interno.');
    final cubit = await _pumpFeed(tester, repo);

    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.text('Erro interno.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
