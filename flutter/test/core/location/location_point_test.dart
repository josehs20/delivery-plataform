import 'package:delivery_app/core/location/location_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationPoint', () {
    test('fromJson/toJson round-trips with context fields', () {
      final point = LocationPoint.fromJson(const {
        'latitude': -20.3155,
        'longitude': -40.3128,
        'accuracy': 12.0,
        'speed': 5.0,
        'heading': 90.0,
        'recorded_at': '2026-08-17T12:00:00Z',
        'delivery_id': 'd1',
        'client_event_id': 'evt-1',
      });

      expect(point.latitude, -20.3155);
      expect(point.longitude, -40.3128);
      expect(point.accuracy, 12.0);
      expect(point.recordedAt, DateTime.utc(2026, 8, 17, 12));
      expect(point.deliveryId, 'd1');
      expect(point.clientEventId, 'evt-1');

      final json = point.toJson();
      expect(json['latitude'], -20.3155);
      expect(json['recorded_at'], '2026-08-17T12:00:00.000Z');
      expect(json['delivery_id'], 'd1');
    });

    test('generate assigns a clientEventId for idempotency', () {
      final point = LocationPoint.generate(
        latitude: -20.1,
        longitude: -40.1,
        recordedAt: DateTime.utc(2026, 8, 17),
        deliveryId: 'd1',
      );

      expect(point.clientEventId, isNotNull);
      expect(point.clientEventId, isNotEmpty);
      expect(point.deliveryId, 'd1');
    });

    test('isValid rejects poor accuracy', () {
      final good = LocationPoint.generate(
        latitude: 0,
        longitude: 0,
        recordedAt: DateTime.now().toUtc(),
        accuracy: 20,
      );
      final bad = LocationPoint.generate(
        latitude: 0,
        longitude: 0,
        recordedAt: DateTime.now().toUtc(),
        accuracy: 500,
      );

      expect(good.isValid(), isTrue);
      expect(bad.isValid(), isFalse);
      expect(bad.isValid(maxAccuracyMeters: 600), isTrue);
    });

    test('isValid rejects stale timestamps', () {
      final stale = LocationPoint.generate(
        latitude: 0,
        longitude: 0,
        recordedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 30)),
      );

      expect(stale.isValid(maxAge: const Duration(minutes: 5)), isFalse);
      expect(stale.isValid(maxAge: const Duration(hours: 1)), isTrue);
    });

    test('toJson omits null optional fields', () {
      final point = LocationPoint(
        latitude: 1,
        longitude: 2,
        recordedAt: DateTime.utc(2026, 8, 17),
      );

      final json = point.toJson();

      expect(json.containsKey('accuracy'), isFalse);
      expect(json.containsKey('delivery_id'), isFalse);
      expect(json.containsKey('client_event_id'), isFalse);
    });
  });
}
