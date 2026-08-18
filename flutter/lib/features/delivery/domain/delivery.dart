/// Máquina de estados de entrega (docs/LEARNED-CONTEXT.md, seção 8).
///
/// Os valores espelham os strings do backend (com underscores, ex.:
/// `AT_PICKUP`). A transição de estado é sempre validada no servidor — este
/// enum serve à apresentação/orquestração.
enum DeliveryStatus {
  draft('DRAFT'),
  open('OPEN'),
  negotiating('NEGOTIATING'),
  assigned('ASSIGNED'),
  driverAccepted('DRIVER_ACCEPTED'),
  goingToPickup('GOING_TO_PICKUP'),
  atPickup('AT_PICKUP'),
  pickedUp('PICKED_UP'),
  inTransit('IN_TRANSIT'),
  atDestination('AT_DESTINATION'),
  delivered('DELIVERED'),
  deliveryFailed('DELIVERY_FAILED'),
  returnRequired('RETURN_REQUIRED'),
  returnInProgress('RETURN_IN_PROGRESS'),
  returned('RETURNED'),
  cancelled('CANCELLED'),
  unknown('UNKNOWN');

  const DeliveryStatus(this.wireValue);

  /// Valor serializado (contrato OpenAPI/backend).
  final String wireValue;

  /// Parse tolerante do wire value; desconhecido vira [DeliveryStatus.unknown].
  static DeliveryStatus fromWire(String? value) {
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    return DeliveryStatus.unknown;
  }

  /// Estados em que a entrega ainda está ativa (para cache/filtro).
  static const active = {
    driverAccepted,
    goingToPickup,
    atPickup,
    pickedUp,
    inTransit,
    atDestination,
  };
}

/// Endereço geográfico do domínio.
final class DeliveryAddress {
  const DeliveryAddress({
    required this.address,
    this.latitude,
    this.longitude,
    this.reference,
  });

  final String address;
  final double? latitude;
  final double? longitude;
  final String? reference;
}

/// Destinatário da entrega.
final class Recipient {
  const Recipient({required this.name, required this.phone, this.reference});

  final String name;
  final String phone;
  final String? reference;
}

/// Item transportado.
final class DeliveryItem {
  const DeliveryItem({
    this.id,
    required this.name,
    this.description,
    this.category,
    this.quantity = 1,
    this.approximateWeight,
    this.notes,
  });

  final String? id;
  final String name;
  final String? description;
  final String? category;
  final int quantity;
  final double? approximateWeight;
  final String? notes;
}

/// Oferta (proposta do motoboy) vinculada a uma entrega.
final class Offer {
  const Offer({
    required this.id,
    required this.deliveryId,
    required this.driverId,
    this.status,
    this.offeredAmount,
  });

  final String id;
  final String deliveryId;
  final String driverId;

  /// `PENDING`, `ACCEPTED`, `REJECTED`, `EXPIRED`, `CANCELLED`.
  final String? status;
  final String? offeredAmount;

  bool get isPending => status == 'PENDING';
}

/// Entrega — entidade de domínio da feature (separada do DTO de transporte).
final class Delivery {
  const Delivery({
    required this.id,
    required this.status,
    this.pricingMode,
    this.currency = 'BRL',
    this.suggestedAmount,
    this.merchantOfferedAmount,
    this.acceptedAmount,
    this.pickupDeadline,
    this.origin,
    this.destination,
    this.recipient,
    this.items = const [],
    this.offers = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DeliveryStatus status;
  final String? pricingMode;
  final String currency;

  /// Valores monetários em String — nunca float autoritativo.
  final String? suggestedAmount;
  final String? merchantOfferedAmount;
  final String? acceptedAmount;

  final DateTime? pickupDeadline;
  final DeliveryAddress? origin;
  final DeliveryAddress? destination;
  final Recipient? recipient;
  final List<DeliveryItem> items;
  final List<Offer> offers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => DeliveryStatus.active.contains(status);

  /// Primeira oferta pendente (usada no fluxo de aceite), ou `null`.
  Offer? get pendingOffer {
    for (final offer in offers) {
      if (offer.isPending) return offer;
    }
    return null;
  }

  /// Valor monetário a exibir (aceito > ofertado pelo comércio > sugerido).
  String? get displayAmount =>
      acceptedAmount ?? merchantOfferedAmount ?? suggestedAmount;
}
