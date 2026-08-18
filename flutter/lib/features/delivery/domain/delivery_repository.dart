import 'delivery.dart';
import 'new_delivery.dart';
import 'proof_of_delivery.dart';

/// Resultado da listagem de entregas.
final class DeliveryListResult {
  const DeliveryListResult({required this.deliveries, required this.fromCache});

  final List<Delivery> deliveries;

  /// `true` quando veio do cache local (offline) em vez do servidor.
  final bool fromCache;
}

/// Resultado de detalhe de uma entrega.
final class DeliveryLoadResult {
  const DeliveryLoadResult({required this.delivery, required this.fromCache});

  final Delivery delivery;

  /// `true` quando veio do cache local (offline) em vez do servidor.
  final bool fromCache;
}

/// Resultado de uma ação (aceite/transição) sobre uma entrega.
final class DeliveryActionResult {
  const DeliveryActionResult({
    required this.delivery,
    required this.confirmedOnServer,
  });

  final Delivery delivery;

  /// `false` => persistido localmente e enfileirado na SyncQueue (pendente de
  /// confirmação do servidor). A UI deve diferenciar local de sincronizado.
  final bool confirmedOnServer;
}

/// Contrato da feature de entregas (use-case-facing).
abstract interface class DeliveryRepository {
  /// Lista entregas disponíveis (feed). Reutiliza o cache quando offline.
  Future<DeliveryListResult> listAvailable();

  /// Detalhe de uma entrega (remoto com fallback para o cache local).
  Future<DeliveryLoadResult> getById(String id);

  /// Aceita a oferta de um motoboy. Requer conectividade (MVP).
  Future<DeliveryActionResult> acceptOffer({
    required String deliveryId,
    required String offerId,
  });

  /// Registra chegada na coleta (`AT_PICKUP`). Offline-first.
  Future<DeliveryActionResult> registerPickupArrival(String deliveryId);

  /// Confirma a coleta (`PICKED_UP`). Offline-first.
  Future<DeliveryActionResult> confirmPickup(String deliveryId);

  /// Confirma a entrega (`DELIVERED`) com prova de entrega. Offline-first.
  Future<DeliveryActionResult> confirmDelivery({
    required String deliveryId,
    required ProofOfDelivery proof,
  });

  /// Cria uma entrega em `DRAFT` (comércio). Requer conectividade (MVP).
  Future<DeliveryActionResult> createDelivery({required NewDelivery delivery});

  /// Publica uma entrega (`DRAFT` → `OPEN`) e dispara o despacho no servidor.
  Future<DeliveryActionResult> publishDelivery(String deliveryId);

  /// Cancela uma entrega (comércio). Exige motivo.
  Future<DeliveryActionResult> cancelDelivery({
    required String deliveryId,
    required String reason,
    String? description,
  });

  /// Registra a chegada ao destino (`AT_DESTINATION`). Offline-first.
  Future<DeliveryActionResult> arriveDestination(String deliveryId);

  /// Registra falha na entrega (`DELIVERY_FAILED`) com motivo. Offline-first.
  Future<DeliveryActionResult> failDelivery({
    required String deliveryId,
    required String reason,
    String? description,
  });

  /// Inicia a devolução (`RETURN_IN_PROGRESS`). Offline-first.
  Future<DeliveryActionResult> startReturn(String deliveryId);

  /// Comércio confirma o recebimento da devolução (`RETURNED`).
  Future<DeliveryActionResult> confirmReturn(String deliveryId);
}
