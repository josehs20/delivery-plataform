import 'package:intl/intl.dart';

import '../domain/delivery.dart';

/// Formata valores monetários para exibição.
///
/// Nunca para cálculo autoritativo — monetário é sempre String no domínio.
String formatCurrency(String? amount, String currencyCode) {
  final value = double.tryParse(amount ?? '');
  if (value == null) return '—';
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: currencyCode == 'BRL' ? 'R\$' : currencyCode,
  ).format(value);
}

/// Rótulo de apresentação do estado da entrega.
String deliveryStatusLabel(DeliveryStatus status) {
  return switch (status) {
    DeliveryStatus.draft => 'Rascunho',
    DeliveryStatus.open => 'Disponível',
    DeliveryStatus.negotiating => 'Negociando',
    DeliveryStatus.assigned => 'Atribuída',
    DeliveryStatus.driverAccepted => 'Aceita',
    DeliveryStatus.goingToPickup => 'A caminho da coleta',
    DeliveryStatus.atPickup => 'Na coleta',
    DeliveryStatus.pickedUp => 'Coletada',
    DeliveryStatus.inTransit => 'Em trânsito',
    DeliveryStatus.atDestination => 'No destino',
    DeliveryStatus.delivered => 'Entregue',
    DeliveryStatus.deliveryFailed => 'Falha na entrega',
    DeliveryStatus.returnRequired => 'Devolução necessária',
    DeliveryStatus.returnInProgress => 'Devolução em andamento',
    DeliveryStatus.returned => 'Devolvida',
    DeliveryStatus.cancelled => 'Cancelada',
    DeliveryStatus.unknown => 'Desconhecido',
  };
}
