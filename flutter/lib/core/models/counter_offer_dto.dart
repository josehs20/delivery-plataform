import 'json_utils.dart';

/// Contraproposta na negociação — espelha o schema `CounterOffer` do OpenAPI
/// e a tabela `counter_offers` do backend.
///
/// Status: `PENDING | ACCEPTED | REJECTED | EXPIRED | CANCELLED | SUPERSEDED`
/// (Strings de transporte; as regras de negociação são sempre validadas no
/// servidor).
final class CounterOfferDto {
  const CounterOfferDto({
    required this.id,
    required this.deliveryId,
    required this.driverId,
    required this.amount,
    this.currency = 'BRL',
    this.status,
    this.message,
    this.previousCounterOfferId,
    this.validUntil,
    this.respondedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String deliveryId;
  final String driverId;

  /// Valor da contraproposta em String (ex.: `"32.50"`) — nunca float.
  final String amount;

  /// Código ISO-4217 (default `BRL` no contrato OpenAPI).
  final String currency;

  /// Ex.: `PENDING`, `ACCEPTED`, `REJECTED`.
  final String? status;

  final String? message;
  final String? previousCounterOfferId;
  final DateTime? validUntil;
  final DateTime? respondedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CounterOfferDto.fromJson(Map<String, dynamic> json) {
    return CounterOfferDto(
      id: json['id'] as String,
      deliveryId: json['delivery_id'] as String,
      driverId: json['driver_id'] as String,
      amount: JsonUtils.stringOrDefault(json['amount']),
      currency: JsonUtils.stringOrDefault(json['currency'], fallback: 'BRL'),
      status: JsonUtils.stringOrNull(json['status']),
      message: JsonUtils.stringOrNull(json['message']),
      previousCounterOfferId:
          JsonUtils.stringOrNull(json['previous_counter_offer_id']),
      validUntil: JsonUtils.dateTime(json['valid_until']),
      respondedAt: JsonUtils.dateTime(json['responded_at']),
      createdAt: JsonUtils.dateTime(json['created_at']),
      updatedAt: JsonUtils.dateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'delivery_id': deliveryId,
        'driver_id': driverId,
        'amount': amount,
        'currency': currency,
        if (status != null) 'status': status,
        if (message != null) 'message': message,
        if (previousCounterOfferId != null)
          'previous_counter_offer_id': previousCounterOfferId,
        if (validUntil != null)
          'valid_until': validUntil!.toUtc().toIso8601String(),
        if (respondedAt != null)
          'responded_at': respondedAt!.toUtc().toIso8601String(),
        if (createdAt != null)
          'created_at': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null)
          'updated_at': updatedAt!.toUtc().toIso8601String(),
      };
}
