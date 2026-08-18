import 'package:delivery_app/app/pages/delivery_dashboard_screen.dart';
import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:delivery_app/features/delivery/domain/delivery_repository.dart';
import 'package:delivery_app/features/delivery/domain/new_delivery.dart';
import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:delivery_app/features/delivery/domain/use_cases.dart';
import 'package:delivery_app/features/delivery/presentation/delivery_list_cubit.dart';
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
  int listCalls = 0;
  List<Delivery> deliveries = [_available('d1')];

  @override
  Future<DeliveryListResult> listAvailable() async {
    listCalls++;
    return DeliveryListResult(
      deliveries: List.of(deliveries),
      fromCache: false,
    );
  }

  @override
  Future<DeliveryActionResult> acceptOffer({
    required String deliveryId,
    required String offerId,
  }) =>
      throw UnimplementedError();

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
  testWidgets('triggers the feed load on mount and renders the deliveries',
      (tester) async {
    final repo = _FakeRepo();
    final cubit = DeliveryListCubit(
      ListAvailableDeliveries(repo),
      AcceptOffer(repo),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: DeliveryDashboardScreen()),
      ),
    );

    // Antes do post-frame, o feed ainda está em loading.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(repo.listCalls, 1);
    expect(find.text('Entregas disponíveis'), findsOneWidget);
    expect(find.text('Aceitar oferta'), findsOneWidget);
  });

  testWidgets('is only a thin wrapper around the delivery feed screen',
      (tester) async {
    final repo = _FakeRepo()..deliveries = [];
    final cubit = DeliveryListCubit(
      ListAvailableDeliveries(repo),
      AcceptOffer(repo),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: DeliveryDashboardScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(repo.listCalls, 1);
    expect(find.text('Nenhuma entrega disponível'), findsOneWidget);
  });
}