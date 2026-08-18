import 'package:delivery_app/features/business/presentation/screens/business_dashboard_screen.dart';
import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:delivery_app/features/delivery/domain/delivery_repository.dart';
import 'package:delivery_app/features/delivery/domain/new_delivery.dart';
import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:delivery_app/features/delivery/domain/use_cases.dart';
import 'package:delivery_app/features/delivery/presentation/delivery_list_cubit.dart';
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
  testWidgets('renders the business deliveries list and the create FAB',
      (tester) async {
    final repo = _FakeRepo([
      _delivery('d1', DeliveryStatus.open),
      _delivery('d2', DeliveryStatus.draft),
    ]);
    final cubit = DeliveryListCubit(
      ListAvailableDeliveries(repo),
      AcceptOffer(repo),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: BusinessDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Minhas entregas'), findsOneWidget);
    expect(find.text('Nova entrega'), findsOneWidget);
    expect(find.textContaining('Rua A, 1'), findsNWidgets(2));
  });
}
