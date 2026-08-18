import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exception.dart';
import '../domain/delivery.dart';
import '../domain/delivery_repository.dart';
import '../domain/proof_of_delivery.dart';
import '../domain/use_cases.dart';
import 'delivery_detail_state.dart';

// Parâmetros nomeados são preferidos aqui por legibilidade (10 use cases); a
// atribuição manual aos campos privados é intencional.
// ignore_for_file: prefer_initializing_formals

/// Orquestra a tela de detalhe da entrega e suas ações de transição.
///
/// Concentra as ações do motoboy (chegadas, coleta, destino, prova, falha e
/// devolução) e as ações do comércio (publicar, cancelar e confirmar devolução)
/// para não duplicar o estado autoritativo da entrega em múltiplos controllers.
class DeliveryDetailCubit extends Cubit<DeliveryDetailState> {
  DeliveryDetailCubit({
    required GetDelivery getDelivery,
    required RegisterPickupArrival registerPickupArrival,
    required ConfirmPickup confirmPickup,
    required RegisterDestinationArrival registerDestinationArrival,
    required ConfirmDelivery confirmDelivery,
    required FailDelivery failDelivery,
    required StartReturn startReturn,
    required PublishDelivery publishDelivery,
    required CancelDelivery cancelDelivery,
    required ConfirmReturn confirmReturn,
  })  : _getDelivery = getDelivery,
        _registerPickupArrival = registerPickupArrival,
        _confirmPickup = confirmPickup,
        _registerDestinationArrival = registerDestinationArrival,
        _confirmDelivery = confirmDelivery,
        _failDelivery = failDelivery,
        _startReturn = startReturn,
        _publishDelivery = publishDelivery,
        _cancelDelivery = cancelDelivery,
        _confirmReturn = confirmReturn,
        super(const DeliveryDetailLoading());

  final GetDelivery _getDelivery;
  final RegisterPickupArrival _registerPickupArrival;
  final ConfirmPickup _confirmPickup;
  final RegisterDestinationArrival _registerDestinationArrival;
  final ConfirmDelivery _confirmDelivery;
  final FailDelivery _failDelivery;
  final StartReturn _startReturn;
  final PublishDelivery _publishDelivery;
  final CancelDelivery _cancelDelivery;
  final ConfirmReturn _confirmReturn;

  Delivery? get _current => switch (state) {
        DeliveryDetailLocal(:final delivery) => delivery,
        DeliveryDetailSyncing(:final delivery) => delivery,
        DeliveryDetailSynced(:final delivery) => delivery,
        DeliveryDetailFailure(:final delivery?) => delivery,
        _ => null,
      };

  /// Carrega o detalhe (remoto com fallback para cache offline).
  Future<void> load(String deliveryId) async {
    emit(const DeliveryDetailLoading());
    try {
      final result = await _getDelivery.call(deliveryId);
      if (result.fromCache) {
        emit(DeliveryDetailLocal(delivery: result.delivery));
      } else {
        emit(DeliveryDetailSynced(delivery: result.delivery));
      }
    } on ApiException catch (error) {
      emit(DeliveryDetailFailure(error.message, delivery: _current));
    } catch (_) {
      emit(const DeliveryDetailFailure(
        'Não foi possível carregar a entrega.',
      ));
    }
  }

  /// Registra a chegada na coleta (`AT_PICKUP`).
  Future<void> registerPickupArrival() async {
    await _runAction((delivery) => _registerPickupArrival.call(delivery.id));
  }

  /// Confirma a coleta (`PICKED_UP`).
  Future<void> confirmPickup() async {
    await _runAction((delivery) => _confirmPickup.call(delivery.id));
  }

  /// Registra a chegada ao destino (`AT_DESTINATION`).
  Future<void> registerDestinationArrival() async {
    await _runAction(
      (delivery) => _registerDestinationArrival.call(delivery.id),
    );
  }

  /// Confirma a entrega (`DELIVERED`) com a prova capturada.
  Future<void> confirmDelivery(ProofOfDelivery proof) async {
    final delivery = _current;
    if (delivery == null) return;
    emit(DeliveryDetailSyncing(delivery: delivery));
    try {
      _emitResult(
        await _confirmDelivery.call(deliveryId: delivery.id, proof: proof),
      );
    } on ApiException catch (error) {
      emit(DeliveryDetailFailure(error.message, delivery: delivery));
    }
  }

  /// Registra falha na entrega (`DELIVERY_FAILED`) com motivo.
  Future<void> failDelivery({
    required String reason,
    String? description,
  }) async {
    final delivery = _current;
    if (delivery == null) return;
    emit(DeliveryDetailSyncing(delivery: delivery));
    try {
      _emitResult(
        await _failDelivery.call(
          deliveryId: delivery.id,
          reason: reason,
          description: description,
        ),
      );
    } on ApiException catch (error) {
      emit(DeliveryDetailFailure(error.message, delivery: delivery));
    }
  }

  /// Inicia a devolução (`RETURN_IN_PROGRESS`).
  Future<void> startReturn() async {
    await _runAction((delivery) => _startReturn.call(delivery.id));
  }

  /// Publica a entrega (`DRAFT` → `OPEN` + despacho). Comércio.
  Future<void> publish() async {
    await _runAction((delivery) => _publishDelivery.call(delivery.id));
  }

  /// Cancela a entrega (comércio) com motivo.
  Future<void> cancel({required String reason, String? description}) async {
    final delivery = _current;
    if (delivery == null) return;
    emit(DeliveryDetailSyncing(delivery: delivery));
    try {
      _emitResult(
        await _cancelDelivery.call(
          deliveryId: delivery.id,
          reason: reason,
          description: description,
        ),
      );
    } on ApiException catch (error) {
      emit(DeliveryDetailFailure(error.message, delivery: delivery));
    }
  }

  /// Confirma o recebimento da devolução (`RETURNED`). Comércio.
  Future<void> confirmReturn() async {
    await _runAction((delivery) => _confirmReturn.call(delivery.id));
  }

  Future<void> _runAction(
    Future<DeliveryActionResult> Function(Delivery delivery) action,
  ) async {
    final delivery = _current;
    if (delivery == null) return;
    emit(DeliveryDetailSyncing(delivery: delivery));
    try {
      _emitResult(await action(delivery));
    } on ApiException catch (error) {
      emit(DeliveryDetailFailure(error.message, delivery: delivery));
    }
  }

  void _emitResult(DeliveryActionResult result) {
    if (result.confirmedOnServer) {
      emit(DeliveryDetailSynced(delivery: result.delivery));
    } else {
      // Persistido localmente + enfileirado: pendente de sincronização.
      emit(DeliveryDetailLocal(delivery: result.delivery));
    }
  }
}
