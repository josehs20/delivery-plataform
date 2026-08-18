import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/features/delivery/domain/delivery.dart';
import 'package:delivery_app/features/delivery/domain/delivery_repository.dart';
import 'package:delivery_app/features/delivery/domain/new_delivery.dart';
import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:delivery_app/features/delivery/domain/use_cases.dart';
import 'package:delivery_app/features/delivery/presentation/delivery_detail_cubit.dart';
import 'package:delivery_app/features/delivery/presentation/screens/delivery_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Delivery _delivery(DeliveryStatus status) => Delivery(
      id: 'd1',
      status: status,
      origin: const DeliveryAddress(address: 'Rua A, 1'),
      destination: const DeliveryAddress(address: 'Rua B, 2'),
      recipient: const Recipient(name: 'Ana', phone: '27999999999'),
      suggestedAmount: '25.00',
    );

class _FakeRepo implements DeliveryRepository {
  _FakeRepo(this.delivery);

  Delivery delivery;
  ApiException? getError;
  ApiException? actionError;
  int pickupCalls = 0;

  @override
  Future<DeliveryLoadResult> getById(String id) async {
    if (getError != null) throw getError!;
    return DeliveryLoadResult(delivery: delivery, fromCache: false);
  }

  @override
  Future<DeliveryActionResult> confirmPickup(String deliveryId) async {
    pickupCalls++;
    if (actionError != null) throw actionError!;
    delivery = _delivery(DeliveryStatus.pickedUp);
    return DeliveryActionResult(delivery: delivery, confirmedOnServer: true);
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
  Future<DeliveryActionResult> registerPickupArrival(String deliveryId) =>
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

Future<DeliveryDetailCubit> _pumpDetail(
  WidgetTester tester,
  _FakeRepo repo,
) async {
  final cubit = DeliveryDetailCubit(
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
  addTearDown(cubit.close);

  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: const MaterialApp(home: DeliveryDetailScreen(deliveryId: 'd1')),
    ),
  );
  // A tela dispara o load no primeiro frame (addPostFrameCallback).
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  testWidgets('shows pickup arrival action for driverAccepted', (tester) async {
    await _pumpDetail(
      tester,
      _FakeRepo(_delivery(DeliveryStatus.driverAccepted)),
    );

    expect(find.text('Cheguei na coleta'), findsOneWidget);
    expect(find.text('Sincronizado'), findsOneWidget);
    expect(find.textContaining('Rua B, 2', findRichText: true), findsOneWidget);
    expect(find.textContaining('Ana', findRichText: true), findsOneWidget);
  });

  testWidgets('shows pickup confirmation action at AT_PICKUP', (tester) async {
    await _pumpDetail(tester, _FakeRepo(_delivery(DeliveryStatus.atPickup)));

    expect(find.text('Confirmar coleta'), findsOneWidget);
  });

  testWidgets('shows destination arrival and fail actions after pickup',
      (tester) async {
    await _pumpDetail(tester, _FakeRepo(_delivery(DeliveryStatus.pickedUp)));

    expect(find.text('Cheguei ao destino'), findsOneWidget);
    expect(find.text('Registrar falha na entrega'), findsOneWidget);
    expect(find.text('Confirmar entrega'), findsNothing);
  });

  testWidgets('shows the complete action at AT_DESTINATION', (tester) async {
    await _pumpDetail(
      tester,
      _FakeRepo(_delivery(DeliveryStatus.atDestination)),
    );

    expect(find.text('Confirmar entrega'), findsOneWidget);
  });

  testWidgets('shows the done banner when delivered', (tester) async {
    await _pumpDetail(tester, _FakeRepo(_delivery(DeliveryStatus.delivered)));

    expect(find.text('Entrega concluída com sucesso.'), findsOneWidget);
  });

  testWidgets('confirm pickup updates the delivery state', (tester) async {
    final repo = _FakeRepo(_delivery(DeliveryStatus.atPickup));
    await _pumpDetail(tester, repo);

    await tester.tap(find.text('Confirmar coleta'));
    await tester.pumpAndSettle();

    expect(repo.pickupCalls, 1);
    expect(find.text('Coletada'), findsOneWidget);
    expect(find.text('Cheguei ao destino'), findsOneWidget);
  });

  testWidgets('shows return action after delivery failed', (tester) async {
    await _pumpDetail(
      tester,
      _FakeRepo(_delivery(DeliveryStatus.deliveryFailed)),
    );

    expect(find.text('Iniciar devolução'), findsOneWidget);
    expect(find.text('Cheguei na coleta'), findsNothing);
  });

  testWidgets('shows the done banner when returned', (tester) async {
    await _pumpDetail(tester, _FakeRepo(_delivery(DeliveryStatus.returned)));

    expect(find.text('Entrega concluída com sucesso.'), findsOneWidget);
  });

  testWidgets('shows the error state when the detail fails to load',
      (tester) async {
    final repo = _FakeRepo(_delivery(DeliveryStatus.pickedUp))
      ..getError = const ServerException('Erro.');
    await _pumpDetail(tester, repo);

    expect(find.text('Erro.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
