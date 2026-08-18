import 'delivery.dart';

/// Modo de precificação de uma nova entrega (`POST /deliveries`).
enum DeliveryPricingMode {
  calculated('CALCULATED'),
  manual('MANUAL');

  const DeliveryPricingMode(this.wireValue);

  /// Valor serializado esperado pelo backend (`pricing.mode`).
  final String wireValue;
}

/// Dados de criação de uma entrega — coletados pelo formulário do comércio e
/// convertidos no payload do `POST /deliveries` (contrato real do Laravel).
///
/// O preço final é sempre calculado/validado no servidor; `manualValue` é
/// apenas o valor sugerido pelo comércio quando o modo é `MANUAL`.
final class NewDelivery {
  const NewDelivery({
    required this.origin,
    required this.destination,
    required this.recipient,
    required this.items,
    required this.pricingMode,
    this.manualValue,
    this.pickupDeadline,
  });

  final DeliveryAddress origin;
  final DeliveryAddress destination;
  final Recipient recipient;
  final List<DeliveryItem> items;
  final DeliveryPricingMode pricingMode;

  /// Valor manual (String monetária) quando [pricingMode] == manual.
  final String? manualValue;

  /// Prazo de coleta (obrigatório no contrato `CreateDeliveryRequest`).
  final DateTime? pickupDeadline;

  /// Monta o corpo do `POST /api/v1/deliveries` conforme o
  /// `CreateDeliveryRequest` do Laravel.
  Map<String, dynamic> toRequestPayload() {
    return {
      'origin': {
        'address': origin.address,
        'latitude': origin.latitude,
        'longitude': origin.longitude,
        if (origin.reference != null) 'reference': origin.reference,
      },
      'destination': {
        'address': destination.address,
        'latitude': destination.latitude,
        'longitude': destination.longitude,
        if (destination.reference != null) 'reference': destination.reference,
      },
      'recipient': {
        'name': recipient.name,
        'phone': recipient.phone,
        if (recipient.reference != null) 'reference': recipient.reference,
      },
      'items': items
          .map(
            (item) => {
              'name': item.name,
              'category': item.category,
              'quantity': item.quantity,
              'approximate_weight': item.approximateWeight,
              if (item.notes != null) 'notes': item.notes,
            },
          )
          .toList(growable: false),
      'pricing': {
        'mode': pricingMode.wireValue,
        if (pricingMode == DeliveryPricingMode.manual &&
            manualValue != null)
          'manual_value': double.tryParse(manualValue!),
      },
      if (pickupDeadline != null)
        'pickup_deadline': pickupDeadline!.toUtc().toIso8601String(),
    };
  }
}
