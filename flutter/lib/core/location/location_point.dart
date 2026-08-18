import 'package:uuid/uuid.dart';

/// Ponto de localização com timestamp (espelha `LocationPoint` do OpenAPI).
///
/// - `deliveryId` associa a amostra à entrega em andamento (contexto correto);
/// - `clientEventId` dá idempotência no envio ao servidor (`/sync/batch`).
final class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracy,
    this.speed,
    this.heading,
    this.deliveryId,
    this.clientEventId,
  });

  /// Cria uma amostra com `clientEventId` gerado (para tracking contínuo).
  factory LocationPoint.generate({
    required double latitude,
    required double longitude,
    required DateTime recordedAt,
    double? accuracy,
    double? speed,
    double? heading,
    String? deliveryId,
  }) {
    return LocationPoint(
      latitude: latitude,
      longitude: longitude,
      recordedAt: recordedAt,
      accuracy: accuracy,
      speed: speed,
      heading: heading,
      deliveryId: deliveryId,
      clientEventId: const Uuid().v4(),
    );
  }

  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;
  final String? deliveryId;
  final String? clientEventId;

  /// Amostra utilizável para operação: precisão dentro do limite e timestamp
  /// recente (regra: validar amostras antes de uso operacional).
  bool isValid({double maxAccuracyMeters = 150, Duration? maxAge}) {
    if (accuracy != null && accuracy! > maxAccuracyMeters) return false;
    if (maxAge != null) {
      final age = DateTime.now().toUtc().difference(recordedAt.toUtc());
      if (age > maxAge) return false;
    }
    return true;
  }

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String).toUtc(),
      deliveryId: json['delivery_id'] as String?,
      clientEventId: json['client_event_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        if (deliveryId != null) 'delivery_id': deliveryId,
        if (clientEventId != null) 'client_event_id': clientEventId,
      };
}
