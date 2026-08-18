final class DeliveryDto {
  const DeliveryDto({
    required this.id,
    required this.status,
    required this.currency,
    this.suggestedAmount,
    this.merchantOfferedAmount,
    this.acceptedAmount,
    this.pickupDeadline,
  });

  final String id;
  final String status;
  final String currency;
  final String? suggestedAmount;
  final String? merchantOfferedAmount;
  final String? acceptedAmount;
  final DateTime? pickupDeadline;

  factory DeliveryDto.fromJson(Map<String, dynamic> json) {
    return DeliveryDto(
      id: json['id'] as String,
      status: json['status'] as String,
      currency: json['currency'] as String? ?? 'BRL',
      suggestedAmount: json['suggested_amount'] as String?,
      merchantOfferedAmount: json['merchant_offered_amount'] as String?,
      acceptedAmount: json['accepted_amount'] as String?,
      pickupDeadline: json['pickup_deadline'] == null
          ? null
          : DateTime.parse(json['pickup_deadline'] as String).toUtc(),
    );
  }
}
