import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/core/network/api_client.dart';
import 'package:delivery_app/features/delivery/data/delivery_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake do [ApiClient] que devolve payloads no envelope do Laravel
/// (`{"data": {...}}`), como o backend real responde.
class _FakeApiClient implements ApiClient {
  _FakeApiClient(this._handler);

  final Object? Function(String path) _handler;

  @override
  Future<ApiResponse> get(String path, {Map<String, String>? query}) async =>
      ApiResponse(statusCode: 200, data: _handler(path));

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    Map<String, String>? headers,
  }) async =>
      ApiResponse(statusCode: 200, data: _handler(path));

  @override
  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async =>
      ApiResponse(statusCode: 200, data: _handler(path));

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async =>
      ApiResponse(statusCode: 200, data: _handler(path));

  @override
  Future<ApiResponse> delete(String path, {Map<String, String>? query}) async =>
      ApiResponse(statusCode: 200, data: _handler(path));
}

/// Shape mínimo de uma entrega como o backend serializa.
Map<String, dynamic> _deliveryJson(String id, String status) => {
      'id': id,
      'status': status,
      'currency': 'BRL',
      'suggested_amount': '25.00',
      'origin': {'address': 'Rua A, 1', 'latitude': -20.1, 'longitude': -40.1},
      'destination': {'address': 'Rua B, 2'},
      'recipient': {'name': 'Ana', 'phone': '27999999999'},
      'items': [
        {'name': 'Caixa', 'quantity': 1},
      ],
    };

void main() {
  group('DeliveryRemoteDataSourceImpl — envelope data (contrato Laravel)', () {
    test('listDeliveries() deserializa data.deliveries', () async {
      final remote = DeliveryRemoteDataSourceImpl(
        _FakeApiClient(
          (path) => <String, dynamic>{
            'data': <String, dynamic>{
              'deliveries': [_deliveryJson('d1', 'OPEN')],
              'pagination': <String, dynamic>{
                'total': 1,
                'per_page': 15,
                'current_page': 1,
                'last_page': 1,
              },
            },
          },
        ),
      );

      final deliveries = await remote.listDeliveries();

      expect(deliveries, hasLength(1));
      expect(deliveries.single.id, 'd1');
      expect(deliveries.single.status, 'OPEN');
      expect(deliveries.single.suggestedAmount, '25.00');
    });

    test('listDeliveries() sem o envelope data retorna lista vazia', () async {
      final remote = DeliveryRemoteDataSourceImpl(
        _FakeApiClient(
          (path) => <String, dynamic>{
            'deliveries': <Map<String, dynamic>>[],
          },
        ),
      );

      final deliveries = await remote.listDeliveries();

      expect(deliveries, isEmpty);
    });

    test('getDelivery() deserializa data.delivery', () async {
      final remote = DeliveryRemoteDataSourceImpl(
        _FakeApiClient(
          (path) => <String, dynamic>{
            'data': <String, dynamic>{
              'delivery': _deliveryJson('d1', 'ASSIGNED'),
            },
          },
        ),
      );

      final delivery = await remote.getDelivery('d1');

      expect(delivery.id, 'd1');
      expect(delivery.status, 'ASSIGNED');
    });

    test('arrivePickup() deserializa data.delivery retornado pela ação',
        () async {
      final remote = DeliveryRemoteDataSourceImpl(
        _FakeApiClient(
          (path) => <String, dynamic>{
            'data': <String, dynamic>{
              'delivery': _deliveryJson('d1', 'AT_PICKUP'),
            },
          },
        ),
      );

      final delivery = await remote.arrivePickup(
        deliveryId: 'd1',
        idempotencyKey: 'idem-12345678',
      );

      expect(delivery.status, 'AT_PICKUP');
    });

    test('sem data.delivery válido lança ServerException', () async {
      final remote = DeliveryRemoteDataSourceImpl(
        _FakeApiClient(
          (path) => <String, dynamic>{
            'data': <String, dynamic>{'message': 'ok'},
          },
        ),
      );

      await expectLater(
        remote.getDelivery('d1'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
