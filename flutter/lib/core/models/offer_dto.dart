import 'json_utils.dart';

/// Oferta inicial do motoboy — espelha a tabela `delivery_offers` do backend.
///
/// O OpenAPI atual não define um schema `Offer` (apenas `CounterOffer`); este
/// DTO segue a model do backend. Status: `PENDING | ACCEPTED | REJECTED |
/// EXPIRED | CANCELLED` (Strings de transporte; as regras de negociação são
/// sempre validadas no servidor).
final class OfferDto {
  const OfferDto({
    required this.id,
    required this.deliveryId,
    required this.driverId,
    this.status,
    this.offeredAmount,
    this.availableUntil,
    this.sentAt,
    this.respondedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String deliveryId;
  final String driverId;

  /// Ex.: `PENDING` (default no backend), `ACCEPTED`, `REJECTED`, `EXPIRED`.
  final String? status;

  /// Valor da proposta em String (ex.: `"25.00"`) — nunca float autoritativo.
  final String? offeredAmount;

  final DateTime? availableUntil;
  final DateTime? sentAt;
  final DateTime? respondedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OfferDto.fromJson(Map<String, dynamic> json) {
    return OfferDto(
      id: json['id'] as String,
      deliveryId: json['delivery_id'] as String,
      driverId: json['driver_id'] as String,
      status: JsonUtils.stringOrNull(json['status']),
      offeredAmount: JsonUtils.stringOrNull(json['offered_amount']),
      availableUntil: JsonUtils.dateTime(json['available_until']),
      sentAt: JsonUtils.dateTime(json['sent_at']),
      respondedAt: JsonUtils.dateTime(json['responded_at']),
      createdAt: JsonUtils.dateTime(json['created_at']),
      updatedAt: JsonUtils.dateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'delivery_id': deliveryId,
        'driver_id': driverId,
        if (status != null) 'status': status,
        if (offeredAmount != null) 'offered_amount': offeredAmount,
        if (availableUntil != null)
          'available_until': availableUntil!.toUtc().toIso8601String(),
        if (sentAt != null) 'sent_at': sentAt!.toUtc().toIso8601String(),
        if (respondedAt != null)
          'responded_at': respondedAt!.toUtc().toIso8601String(),
        if (createdAt != null)
          'created_at': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null)
          'updated_at': updatedAt!.toUtc().toIso8601String(),
      };
}
