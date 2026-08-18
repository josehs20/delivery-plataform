import 'package:delivery_app/core/models/counter_offer_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CounterOfferDto', () {
    test('fromJson parses all fields', () {
      final counter = CounterOfferDto.fromJson(const {
        'id': 'c1',
        'delivery_id': 'd1',
        'driver_id': 'dr1',
        'amount': '32.50',
        'currency': 'BRL',
        'status': 'PENDING',
        'message': 'Consigo executar por esse valor.',
        'valid_until': '2026-08-16T21:00:00Z',
        'created_at': '2026-08-16T13:00:00Z',
      });

      expect(counter.id, 'c1');
      expect(counter.deliveryId, 'd1');
      expect(counter.driverId, 'dr1');
      expect(counter.amount, '32.50');
      expect(counter.currency, 'BRL');
      expect(counter.status, 'PENDING');
      expect(counter.message, 'Consigo executar por esse valor.');
      expect(counter.validUntil, DateTime.utc(2026, 8, 16, 21));
      expect(counter.respondedAt, isNull);
    });

    test('fromJson defaults currency to BRL when missing', () {
      final counter = CounterOfferDto.fromJson(const {
        'id': 'c2',
        'delivery_id': 'd1',
        'driver_id': 'dr1',
        'amount': '40.00',
      });

      expect(counter.currency, 'BRL');
      expect(counter.status, isNull);
      expect(counter.message, isNull);
    });

    test('toJson round-trips', () {
      final original = CounterOfferDto(
        id: 'c3',
        deliveryId: 'd1',
        driverId: 'dr1',
        amount: '45.00',
        currency: 'BRL',
        status: 'ACCEPTED',
        message: 'Valor aceito.',
      );

      final restored = CounterOfferDto.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.currency, original.currency);
      expect(restored.status, original.status);
      expect(restored.message, original.message);
    });
  });
}
