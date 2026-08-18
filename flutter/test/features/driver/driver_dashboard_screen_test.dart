import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:delivery_app/features/delivery/domain/delivery_repository.dart';
import 'package:delivery_app/features/delivery/domain/new_delivery.dart';
import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:delivery_app/features/delivery/domain/use_cases.dart';
import 'package:delivery_app/features/delivery/presentation/delivery_list_cubit.dart';
import 'package:delivery_app/features/driver/presentation/screens/driver_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Delivery _delivery(String id, DeliveryStatus status) => Delivery(
      id: id,
      status: status,
      origin: const DeliveryAddress(address: 'Rua A, 1'),
      destination: const DeliveryAddress(address: 'Rua B, 2'),
      suggestedAmount: '25.00',
    );

class _FakeRepo implements DeliveryRepository {
  _FakeRepo(this.deliveries);

  List<Delivery> deliveries;

  @override
  Future<DeliveryListResult> listAvailable() async => DeliveryListResult(
        deliveries: List.of(deliveries),
        fromCache: false,
      );

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
  testWidgets('shows only active deliveries on the Ativas tab', (tester) async {
    final repo = _FakeRepo([
      _delivery('d1', DeliveryStatus.inTransit),
      _delivery('d2', DeliveryStatus.delivered),
    ]);
    final cubit = DeliveryListCubit(
      ListAvailableDeliveries(repo),
      AcceptOffer(repo),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: DriverDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Aba Ativas: apenas d1 (em trânsito).
    expect(find.text('Minhas entregas'), findsOneWidget);
    expect(find.text('Em trânsito'), findsOneWidget);
    expect(find.text('Entregue'), findsNothing);

    // Troca para Histórico: apenas d2 (entregue).
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    expect(find.text('Entregue'), findsOneWidget);
    expect(find.text('Em trânsito'), findsNothing);
  });
}
