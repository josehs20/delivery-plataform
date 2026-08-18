import '../../delivery/domain/delivery.dart';

/// Estados do fluxo de criação de entrega (comércio).
sealed class CreateDeliveryState {
  const CreateDeliveryState();
}

/// Formulário pronto para preenchimento.
final class CreateDeliveryIdle extends CreateDeliveryState {
  const CreateDeliveryIdle();
}

/// Enviando `POST /deliveries`.
final class CreateDeliverySubmitting extends CreateDeliveryState {
  const CreateDeliverySubmitting();
}

/// Entrega criada com sucesso (rascunho).
final class CreateDeliverySuccess extends CreateDeliveryState {
  const CreateDeliverySuccess({required this.delivery});

  final Delivery delivery;
}

/// Falha na criação — mensagem segura para apresentação.
final class CreateDeliveryFailure extends CreateDeliveryState {
  const CreateDeliveryFailure(this.message);

  final String message;
}
