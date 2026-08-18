import 'json_utils.dart';
import 'offer_dto.dart';

/// Endereço geográfico com coordenadas — espelha `GeoAddressInput` do OpenAPI.
///
/// O backend armazena `origin_snapshot`/`destination_snapshot` com este shape.
final class DeliveryAddressDto {
  const DeliveryAddressDto({
    required this.address,
    this.latitude,
    this.longitude,
    this.reference,
  });

  final String address;
  final double? latitude;
  final double? longitude;
  final String? reference;

  factory DeliveryAddressDto.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressDto(
      address: JsonUtils.stringOrDefault(json['address']),
      latitude: JsonUtils.doubleOrNull(json['latitude']),
      longitude: JsonUtils.doubleOrNull(json['longitude']),
      reference: JsonUtils.stringOrNull(json['reference']),
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (reference != null) 'reference': reference,
      };
}

/// Destinatário — espelha `RecipientInput` do OpenAPI.
final class RecipientDto {
  const RecipientDto({
    required this.name,
    required this.phone,
    this.reference,
  });

  final String name;
  final String phone;
  final String? reference;

  factory RecipientDto.fromJson(Map<String, dynamic> json) {
    return RecipientDto(
      name: JsonUtils.stringOrDefault(json['name']),
      phone: JsonUtils.stringOrDefault(json['phone']),
      reference: JsonUtils.stringOrNull(json['reference']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (reference != null) 'reference': reference,
      };
}

/// Item de uma entrega — espelha `DeliveryItemInput`/tabela `delivery_items`.
final class DeliveryItemDto {
  const DeliveryItemDto({
    this.id,
    required this.name,
    this.description,
    this.category,
    this.quantity = 1,
    this.approximateWeight,
    this.dimensions,
    this.specialHandling,
    this.notes,
  });

  final String? id;
  final String name;
  final String? description;
  final String? category;
  final int quantity;
  final double? approximateWeight;
  final Map<String, dynamic>? dimensions;
  final String? specialHandling;
  final String? notes;

  factory DeliveryItemDto.fromJson(Map<String, dynamic> json) {
    return DeliveryItemDto(
      id: JsonUtils.stringOrNull(json['id']),
      name: JsonUtils.stringOrDefault(json['name']),
      description: JsonUtils.stringOrNull(json['description']),
      category: JsonUtils.stringOrNull(json['category']),
      quantity: JsonUtils.intOrNull(json['quantity']) ?? 1,
      approximateWeight: JsonUtils.doubleOrNull(json['approximate_weight']),
      dimensions: json['dimensions'] is Map
          ? JsonUtils.mapOrEmpty(json['dimensions'])
          : null,
      specialHandling: JsonUtils.stringOrNull(json['special_handling']),
      notes: JsonUtils.stringOrNull(json['notes']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        'quantity': quantity,
        if (approximateWeight != null)
          'approximate_weight': approximateWeight,
        if (dimensions != null) 'dimensions': dimensions,
        if (specialHandling != null) 'special_handling': specialHandling,
        if (notes != null) 'notes': notes,
      };
}

/// Entrega — espelha o schema `Delivery` do OpenAPI e a tabela `deliveries`.
///
/// Campos monetários permanecem como String + currency (BRL) — nunca float
/// autoritativo. O DTO apenas serializa/deserializa; não decide regras de
/// estado ou de máquina de estados.
final class DeliveryDto {
  const DeliveryDto({
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
    this.businessId,
    this.currentDriverId,
    this.publishedAt,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// Estado da entrega (ex.: `OPEN`, `PICKED_UP`, `DELIVERED`) — String de
  /// transporte; a autoridade do estado é sempre o servidor.
  final String status;

  /// `CALCULATED` | `MERCHANT_DEFINED`.
  final String? pricingMode;

  /// Código ISO-4217 (default `BRL` no contrato OpenAPI).
  final String currency;

  /// Valores monetários em String (ex.: `"25.00"`); nunca double.
  final String? suggestedAmount;
  final String? merchantOfferedAmount;
  final String? acceptedAmount;

  final DateTime? pickupDeadline;

  /// Ponto de coleta/destino. O backend envia `origin_snapshot`/
  /// `destination_snapshot`; o shape de request usa `origin`/`destination`
  /// (ambos são tolerados no parsing).
  final DeliveryAddressDto? origin;
  final DeliveryAddressDto? destination;

  final RecipientDto? recipient;
  final List<DeliveryItemDto> items;

  /// Ofertas vinculadas (relação `offers` do backend, quando presente).
  final List<OfferDto> offers;

  final String? businessId;
  final String? currentDriverId;

  final DateTime? publishedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;


  factory DeliveryDto.fromJson(Map<String, dynamic> json) {
    return DeliveryDto(
      id: json['id'] as String,
      status: json['status'] as String,
      pricingMode: JsonUtils.stringOrNull(json['pricing_mode']),
      currency: JsonUtils.stringOrDefault(json['currency'], fallback: 'BRL'),
      suggestedAmount: JsonUtils.stringOrNull(json['suggested_amount']),
      merchantOfferedAmount:
          JsonUtils.stringOrNull(json['merchant_offered_amount']),
      acceptedAmount: JsonUtils.stringOrNull(json['accepted_amount']),
      pickupDeadline: JsonUtils.dateTime(json['pickup_deadline']),
      origin: _addressFrom(json['origin']) ??
          _addressFrom(json['origin_snapshot']),
      destination: _addressFrom(json['destination']) ??
          _addressFrom(json['destination_snapshot']),
      recipient: _recipientFrom(json),
      items: _itemsFrom(json['items']),
      offers: _offersFrom(json['offers']),
      businessId: JsonUtils.stringOrNull(json['business_id']),
      currentDriverId: JsonUtils.stringOrNull(json['current_driver_id']),
      publishedAt: JsonUtils.dateTime(json['published_at']),
      acceptedAt: JsonUtils.dateTime(json['accepted_at']),
      pickedUpAt: JsonUtils.dateTime(json['picked_up_at']),
      deliveredAt: JsonUtils.dateTime(json['delivered_at']),
      cancelledAt: JsonUtils.dateTime(json['cancelled_at']),
      createdAt: JsonUtils.dateTime(json['created_at']),
      updatedAt: JsonUtils.dateTime(json['updated_at']),
    );
  }

  static DeliveryAddressDto? _addressFrom(Object? value) {
    return value is Map
        ? DeliveryAddressDto.fromJson(JsonUtils.mapOrEmpty(value))
        : null;
  }

  static RecipientDto? _recipientFrom(Map<String, dynamic> json) {
    final raw = json['recipient'];
    if (raw is Map) {
      return RecipientDto.fromJson(JsonUtils.mapOrEmpty(raw));
    }

    // Shape flat usado pelo backend nas respostas de entrega.
    final name = json['recipient_name'];
    final phone = json['recipient_phone'];
    if (name == null && phone == null) return null;

    return RecipientDto(
      name: JsonUtils.stringOrDefault(name),
      phone: JsonUtils.stringOrDefault(phone),
      reference: JsonUtils.stringOrNull(json['recipient_reference']),
    );
  }

  static List<DeliveryItemDto> _itemsFrom(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => DeliveryItemDto.fromJson(JsonUtils.mapOrEmpty(e)))
        .toList(growable: false);
  }

  static List<OfferDto> _offersFrom(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => OfferDto.fromJson(JsonUtils.mapOrEmpty(e)))
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        if (pricingMode != null) 'pricing_mode': pricingMode,
        'currency': currency,
        if (suggestedAmount != null) 'suggested_amount': suggestedAmount,
        if (merchantOfferedAmount != null)
          'merchant_offered_amount': merchantOfferedAmount,
        if (acceptedAmount != null) 'accepted_amount': acceptedAmount,
        if (pickupDeadline != null)
          'pickup_deadline': pickupDeadline!.toUtc().toIso8601String(),
        if (origin != null) 'origin': origin!.toJson(),
        if (destination != null) 'destination': destination!.toJson(),
        if (recipient != null) 'recipient': recipient!.toJson(),
        if (items.isNotEmpty)
          'items': items.map((e) => e.toJson()).toList(growable: false),
        if (offers.isNotEmpty)
          'offers': offers.map((e) => e.toJson()).toList(growable: false),
        if (businessId != null) 'business_id': businessId,
        if (currentDriverId != null) 'current_driver_id': currentDriverId,
        if (publishedAt != null)
          'published_at': publishedAt!.toUtc().toIso8601String(),
        if (acceptedAt != null)
          'accepted_at': acceptedAt!.toUtc().toIso8601String(),
        if (pickedUpAt != null)
          'picked_up_at': pickedUpAt!.toUtc().toIso8601String(),
        if (deliveredAt != null)
          'delivered_at': deliveredAt!.toUtc().toIso8601String(),
        if (cancelledAt != null)
          'cancelled_at': cancelledAt!.toUtc().toIso8601String(),
        if (createdAt != null)
          'created_at': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null)
          'updated_at': updatedAt!.toUtc().toIso8601String(),
      };

  /// Cria uma cópia alterando campos selecionados (imutável).
  ///
  /// Usado para refletir transições de estado locais enquanto offline (a
  /// autoridade final continua sendo o servidor).
  DeliveryDto copyWith({
    String? status,
    String? pricingMode,
    String? currency,
    String? suggestedAmount,
    String? merchantOfferedAmount,
    String? acceptedAmount,
    DateTime? pickupDeadline,
    DeliveryAddressDto? origin,
    DeliveryAddressDto? destination,
    RecipientDto? recipient,
    List<DeliveryItemDto>? items,
    List<OfferDto>? offers,
    String? businessId,
    String? currentDriverId,
    DateTime? publishedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryDto(
      id: id,
      status: status ?? this.status,
      pricingMode: pricingMode ?? this.pricingMode,
      currency: currency ?? this.currency,
      suggestedAmount: suggestedAmount ?? this.suggestedAmount,
      merchantOfferedAmount:
          merchantOfferedAmount ?? this.merchantOfferedAmount,
      acceptedAmount: acceptedAmount ?? this.acceptedAmount,
      pickupDeadline: pickupDeadline ?? this.pickupDeadline,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      recipient: recipient ?? this.recipient,
      items: items ?? this.items,
      offers: offers ?? this.offers,
      businessId: businessId ?? this.businessId,
      currentDriverId: currentDriverId ?? this.currentDriverId,
      publishedAt: publishedAt ?? this.publishedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

