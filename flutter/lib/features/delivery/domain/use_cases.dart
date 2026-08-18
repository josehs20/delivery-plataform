import 'delivery_repository.dart';
import 'new_delivery.dart';
import 'proof_of_delivery.dart';

/// Use case: lista entregas disponíveis para o feed.
final class ListAvailableDeliveries {
  ListAvailableDeliveries(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryListResult> call() => _repository.listAvailable();
}

/// Use case: detalhe de uma entrega (remoto com fallback offline).
final class GetDelivery {
  GetDelivery(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryLoadResult> call(String deliveryId) =>
      _repository.getById(deliveryId);
}

/// Use case: aceita uma oferta (entrega passa para atribuída).
final class AcceptOffer {
  AcceptOffer(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call({
    required String deliveryId,
    required String offerId,
  }) {
    return _repository.acceptOffer(deliveryId: deliveryId, offerId: offerId);
  }
}

/// Use case: registra a chegada na coleta (`AT_PICKUP`).
final class RegisterPickupArrival {
  RegisterPickupArrival(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call(String deliveryId) =>
      _repository.registerPickupArrival(deliveryId);
}

/// Use case: confirma a coleta (`PICKED_UP`).
final class ConfirmPickup {
  ConfirmPickup(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call(String deliveryId) =>
      _repository.confirmPickup(deliveryId);
}

/// Use case: confirma a entrega (`DELIVERED`) exigindo prova de entrega.
final class ConfirmDelivery {
  ConfirmDelivery(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call({
    required String deliveryId,
    required ProofOfDelivery proof,
  }) {
    if (!proof.hasCapture) {
      throw ArgumentError('A prova de entrega precisa de assinatura ou foto.');
    }
    return _repository.confirmDelivery(deliveryId: deliveryId, proof: proof);
  }
}

/// Use case: cria uma entrega em `DRAFT` (comércio).
final class CreateDelivery {
  CreateDelivery(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call({required NewDelivery delivery}) =>
      _repository.createDelivery(delivery: delivery);
}

/// Use case: publica uma entrega (`DRAFT` → `OPEN` + despacho).
final class PublishDelivery {
  PublishDelivery(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call(String deliveryId) =>
      _repository.publishDelivery(deliveryId);
}

/// Use case: cancela uma entrega (comércio) com motivo.
final class CancelDelivery {
  CancelDelivery(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call({
    required String deliveryId,
    required String reason,
    String? description,
  }) {
    return _repository.cancelDelivery(
      deliveryId: deliveryId,
      reason: reason,
      description: description,
    );
  }
}

/// Use case: registra a chegada ao destino (`AT_DESTINATION`).
final class RegisterDestinationArrival {
  RegisterDestinationArrival(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call(String deliveryId) =>
      _repository.arriveDestination(deliveryId);
}

/// Use case: registra falha na entrega (`DELIVERY_FAILED`) com motivo.
final class FailDelivery {
  FailDelivery(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call({
    required String deliveryId,
    required String reason,
    String? description,
  }) {
    if (reason.trim().isEmpty) {
      throw ArgumentError('Informe o motivo da falha.');
    }
    return _repository.failDelivery(
      deliveryId: deliveryId,
      reason: reason.trim(),
      description: description,
    );
  }
}

/// Use case: inicia a devolução (`RETURN_IN_PROGRESS`).
final class StartReturn {
  StartReturn(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call(String deliveryId) =>
      _repository.startReturn(deliveryId);
}

/// Use case: comércio confirma o recebimento da devolução (`RETURNED`).
final class ConfirmReturn {
  ConfirmReturn(this._repository);

  final DeliveryRepository _repository;

  Future<DeliveryActionResult> call(String deliveryId) =>
      _repository.confirmReturn(deliveryId);
}
