import '../domain/delivery.dart';

/// Estados da tela de detalhe da entrega ativa.
///
/// Cobre: loading, local (persistido localmente, pendente de sync),
/// sincronizando, sincronizado e falha.
sealed class DeliveryDetailState {
  const DeliveryDetailState();
}

/// Carga do detalhe em andamento.
final class DeliveryDetailLoading extends DeliveryDetailState {
  const DeliveryDetailLoading();
}

/// Entrega lida do cache local / ação persistida localmente (offline).
final class DeliveryDetailLocal extends DeliveryDetailState {
  const DeliveryDetailLocal({required this.delivery});

  final Delivery delivery;
}

/// Operação em andamento com o servidor.
final class DeliveryDetailSyncing extends DeliveryDetailState {
  const DeliveryDetailSyncing({required this.delivery});

  final Delivery delivery;
}

/// Estado confirmado pelo servidor.
final class DeliveryDetailSynced extends DeliveryDetailState {
  const DeliveryDetailSynced({required this.delivery});

  final Delivery delivery;
}

/// Falha em carga/ação (mantém a entrega atual quando disponível).
final class DeliveryDetailFailure extends DeliveryDetailState {
  const DeliveryDetailFailure(this.message, {this.delivery});

  final String message;
  final Delivery? delivery;
}
