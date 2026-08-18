import 'package:delivery_app/core/models/offer_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfferDto', () {
    test('fromJson parses all fields', () {
      final offer = OfferDto.fromJson(const {
        'id': 'o1',
        'delivery_id': 'd1',
        'driver_id': 'dr1',
        'status': 'PENDING',
        'offered_amount': '25.00',
        'available_until': '2026-08-16T20:00:00Z',
        'sent_at': '2026-08-16T12:00:00Z',
        'responded_at': null,
        'created_at': '2026-08-16T12:00:00Z',
        'updated_at': '2026-08-16T12:00:00Z',
      });

      expect(offer.id, 'o1');
      expect(offer.deliveryId, 'd1');
      expect(offer.driverId, 'dr1');
      expect(offer.status, 'PENDING');
      expect(offer.offeredAmount, '25.00');
      expect(offer.availableUntil, DateTime.utc(2026, 8, 16, 20));
      expect(offer.sentAt, DateTime.utc(2026, 8, 16, 12));
      expect(offer.respondedAt, isNull);
    });

    test('fromJson tolerates missing optional fields', () {
      final offer = OfferDto.fromJson(const {
        'id': 'o2',
        'delivery_id': 'd1',
        'driver_id': 'dr1',
      });

      expect(offer.status, isNull);
      expect(offer.offeredAmount, isNull);
      expect(offer.availableUntil, isNull);
      expect(offer.createdAt, isNull);
    });

    test('toJson round-trips', () {
      final original = OfferDto(
        id: 'o3',
        deliveryId: 'd1',
        driverId: 'dr1',
        status: 'ACCEPTED',
        offeredAmount: '32.50',
      );

      final restored = OfferDto.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.deliveryId, original.deliveryId);
      expect(restored.driverId, original.driverId);
      expect(restored.status, original.status);
      expect(restored.offeredAmount, original.offeredAmount);
    });
  });
}
