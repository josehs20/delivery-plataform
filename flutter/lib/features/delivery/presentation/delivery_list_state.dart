import '../domain/delivery.dart';

/// Estados do feed de entregas (lista).
///
/// Cobre: loading, local (offline/cache), sincronizando, sincronizado e falha
/// — a UI deve diferenciar "salvo localmente" de "confirmado pelo servidor".
sealed class DeliveryListState {
  const DeliveryListState();
}

/// Primeira carga em andamento.
final class DeliveryListLoading extends DeliveryListState {
  const DeliveryListLoading();
}

/// Dados lidos do cache local (offline).
final class DeliveryListLocal extends DeliveryListState {
  const DeliveryListLocal({required this.deliveries});

  final List<Delivery> deliveries;
}

/// Sincronizando com o servidor (mantém conteúdo atual na tela).
final class DeliveryListSyncing extends DeliveryListState {
  const DeliveryListSyncing({required this.deliveries});

  final List<Delivery> deliveries;
}

/// Sincronizado com o servidor.
final class DeliveryListSynced extends DeliveryListState {
  const DeliveryListSynced({required this.deliveries});

  final List<Delivery> deliveries;
}

/// Falha ao carregar/sincronizar (mantém conteúdo anterior quando existir).
final class DeliveryListFailure extends DeliveryListState {
  const DeliveryListFailure(this.message, {this.deliveries});

  final String message;
  final List<Delivery>? deliveries;
}
