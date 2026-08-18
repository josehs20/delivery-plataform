import 'package:delivery_app/core/models/delivery_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeliveryDto', () {
    test('fromJson parses a full delivery with items and addresses', () {
      final delivery = DeliveryDto.fromJson(const {
        'id': 'd1',
        'status': 'OPEN',
        'pricing_mode': 'CALCULATED',
        'currency': 'BRL',
        'suggested_amount': '25.00',
        'merchant_offered_amount': '30.00',
        'accepted_amount': null,
        'pickup_deadline': '2026-08-16T18:00:00Z',
        'created_at': '2026-08-16T10:00:00Z',
        'updated_at': '2026-08-16T10:05:00Z',
        'origin_snapshot': {
          'address': 'Rua de origem, 100',
          'latitude': -20.3155,
          'longitude': -40.3128,
          'reference': 'Porta lateral',
        },
        'destination_snapshot': {
          'address': 'Estrada Rural X, s/n',
          'latitude': -20.42,
          'longitude': -40.5,
        },
        'recipient_name': 'João da Silva',
        'recipient_phone': '27999999999',
        'items': [
          {
            'id': 'i1',
            'name': 'Caixa de produtos',
            'category': 'GENERAL',
            'quantity': 2,
            'approximate_weight': 5.0,
            'notes': 'Manter em posição vertical',
          },
        ],
      });

      expect(delivery.id, 'd1');
      expect(delivery.status, 'OPEN');
      expect(delivery.pricingMode, 'CALCULATED');
      expect(delivery.currency, 'BRL');
      expect(delivery.suggestedAmount, '25.00');
      expect(delivery.merchantOfferedAmount, '30.00');
      expect(delivery.acceptedAmount, isNull);
      expect(delivery.pickupDeadline, DateTime.utc(2026, 8, 16, 18));
      expect(delivery.createdAt, DateTime.utc(2026, 8, 16, 10));
      expect(delivery.origin, isNotNull);
      expect(delivery.origin!.address, 'Rua de origem, 100');
      expect(delivery.origin!.latitude, -20.3155);
      expect(delivery.origin!.longitude, -40.3128);
      expect(delivery.origin!.reference, 'Porta lateral');
      expect(delivery.destination, isNotNull);
      expect(delivery.destination!.address, 'Estrada Rural X, s/n');
      expect(delivery.recipient, isNotNull);
      expect(delivery.recipient!.name, 'João da Silva');
      expect(delivery.recipient!.phone, '27999999999');
      expect(delivery.items, hasLength(1));
      expect(delivery.items.first.name, 'Caixa de produtos');
      expect(delivery.items.first.quantity, 2);
      expect(delivery.items.first.approximateWeight, 5.0);
    });

    test('fromJson defaults currency to BRL and tolerates missing optionals', () {
      final delivery = DeliveryDto.fromJson(const {
        'id': 'd2',
        'status': 'DRAFT',
      });

      expect(delivery.status, 'DRAFT');
      expect(delivery.currency, 'BRL');
      expect(delivery.pricingMode, isNull);
      expect(delivery.suggestedAmount, isNull);
      expect(delivery.origin, isNull);
      expect(delivery.destination, isNull);
      expect(delivery.recipient, isNull);
      expect(delivery.items, isEmpty);
    });

    test('parses recipient from the nested request shape', () {
      final delivery = DeliveryDto.fromJson(const {
        'id': 'd4',
        'status': 'DRAFT',
        'recipient': {'name': 'Ana', 'phone': '27988888888'},
      });

      expect(delivery.recipient, isNotNull);
      expect(delivery.recipient!.name, 'Ana');
      expect(delivery.recipient!.phone, '27988888888');
    });

    test('toJson round-trips', () {
      final original = DeliveryDto(
        id: 'd3',
        status: 'DELIVERED',
        pricingMode: 'MERCHANT_DEFINED',
        currency: 'BRL',
        suggestedAmount: '32.50',
        recipient: const RecipientDto(name: 'Ana', phone: '27988888888'),
        items: const [
          DeliveryItemDto(id: 'i1', name: 'Envelope', quantity: 1),
        ],
        createdAt: DateTime.utc(2026, 8, 16, 10),
      );

      final restored = DeliveryDto.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.status, original.status);
      expect(restored.pricingMode, original.pricingMode);
      expect(restored.currency, original.currency);
      expect(restored.suggestedAmount, original.suggestedAmount);
      expect(restored.recipient!.name, 'Ana');
      expect(restored.items, hasLength(1));
      expect(restored.items.first.name, 'Envelope');
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('DeliveryAddressDto', () {
    test('parses coordinates and reference tolerantly', () {
      final address = DeliveryAddressDto.fromJson(const {
        'address': 'Rua X, 1',
        'latitude': -20.1,
      });

      expect(address.address, 'Rua X, 1');
      expect(address.latitude, -20.1);
      expect(address.longitude, isNull);
      expect(address.reference, isNull);
    });
  });

  group('DeliveryItemDto', () {
    test('defaults quantity to 1 when absent', () {
      final item = DeliveryItemDto.fromJson(const {'name': 'Envelope'});

      expect(item.name, 'Envelope');
      expect(item.quantity, 1);
      expect(item.category, isNull);
    });
  });

  group('DeliveryDto offers', () {
    test('parses the offers relation when present', () {
      final delivery = DeliveryDto.fromJson(const {
        'id': 'd-offers',
        'status': 'OPEN',
        'offers': [
          {
            'id': 'o1',
            'delivery_id': 'd-offers',
            'driver_id': 'dr1',
            'status': 'PENDING',
            'offered_amount': '25.00',
          },
        ],
      });

      expect(delivery.offers, hasLength(1));
      expect(delivery.offers.first.id, 'o1');
      expect(delivery.offers.first.status, 'PENDING');
      expect(delivery.offers.first.offeredAmount, '25.00');
    });

    test('tolerates missing offers', () {
      final delivery =
          DeliveryDto.fromJson(const {'id': 'd2', 'status': 'DRAFT'});

      expect(delivery.offers, isEmpty);
    });
  });

  group('DeliveryDto.copyWith', () {
    test('updates the status without mutating the original', () {
      final original = DeliveryDto.fromJson(
        const {'id': 'd3', 'status': 'GOING_TO_PICKUP'},
      );

      final updated = original.copyWith(status: 'AT_PICKUP');

      expect(updated.status, 'AT_PICKUP');
      expect(updated.id, 'd3');
      expect(original.status, 'GOING_TO_PICKUP');
    });

    test('copyWith round-trips through toJson', () {
      final original = DeliveryDto(
        id: 'd4',
        status: 'OPEN',
        suggestedAmount: '25.00',
      );

      final updated = original.copyWith(status: 'DELIVERED');
      final restored = DeliveryDto.fromJson(updated.toJson());

      expect(restored.status, 'DELIVERED');
      expect(restored.suggestedAmount, '25.00');
    });
  });
}
