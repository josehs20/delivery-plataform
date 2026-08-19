// Testes do repositório admin: parsing dos envelopes da API `/admin/*`
// e construção dos filtros de consulta.

import 'package:delivery_app/features/admin/data/admin_remote_data_source.dart';
import 'package:delivery_app/features/admin/data/admin_repository_impl.dart';
import 'package:delivery_app/features/admin/domain/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminRemote implements AdminRemoteDataSource {
  _FakeAdminRemote(this._handler);

  final Future<Map<String, dynamic>> Function(Map<String, dynamic> args) _handler;

  @override
  Future<Map<String, dynamic>> metrics() async =>
      _handler(const {'method': 'metrics'});

  @override
  Future<Map<String, dynamic>> pendingDrivers({
    int page = 1,
    int perPage = 15,
  }) async =>
      _handler({'method': 'pendingDrivers', 'page': page, 'perPage': perPage});

  @override
  Future<Map<String, dynamic>> approveDriver(String driverId) async =>
      _handler({'method': 'approve', 'driverId': driverId});

  @override
  Future<Map<String, dynamic>> rejectDriver(
    String driverId, {
    required String reason,
  }) async =>
      _handler({'method': 'reject', 'driverId': driverId, 'reason': reason});

  @override
  Future<Map<String, dynamic>> suspendDriver(String driverId) async =>
      _handler({'method': 'suspend', 'driverId': driverId});

  @override
  Future<Map<String, dynamic>> deliveries({Map<String, String>? query}) async =>
      _handler({'method': 'deliveries', 'query': query});

  @override
  Future<Map<String, dynamic>> assignDelivery(
    String deliveryId, {
    required String driverId,
  }) async =>
      _handler({'method': 'assign', 'deliveryId': deliveryId, 'driverId': driverId});

  @override
  Future<Map<String, dynamic>> cancelDelivery(
    String deliveryId, {
    required String reason,
    String? refundType,
  }) async =>
      _handler({
        'method': 'cancel',
        'deliveryId': deliveryId,
        'reason': reason,
        'refundType': refundType,
      });

  @override
  Future<Map<String, dynamic>> payments({Map<String, String>? query}) async =>
      _handler(const {'method': 'payments'});

  @override
  Future<Map<String, dynamic>> refunds({Map<String, String>? query}) async =>
      _handler(const {'method': 'refunds'});

  @override
  Future<Map<String, dynamic>> createRefund({
    required String paymentId,
    required String amount,
    required String reason,
  }) async =>
      _handler({
        'method': 'createRefund',
        'paymentId': paymentId,
        'amount': amount,
        'reason': reason,
      });

  @override
  Future<Map<String, dynamic>> payouts({Map<String, String>? query}) async =>
      _handler(const {'method': 'payouts'});

  @override
  Future<Map<String, dynamic>> auditLogs({Map<String, String>? query}) async =>
      _handler({'method': 'auditLogs', 'query': query});
}

Map<String, dynamic> _page(String key, List<Map<String, dynamic>> items) {
  return {
    key: items,
    'pagination': {
      'total': items.length,
      'per_page': 15,
      'current_page': 1,
      'last_page': 1,
    },
  };
}

void main() {
  test('loadMetrics parses the metrics envelope', () async {
    final repository = AdminRepositoryImpl(
      _FakeAdminRemote((args) async => {
            'deliveries_today': 3,
            'revenue': '45.00',
            'currency': 'BRL',
            'drivers_online': 2,
            'pending_drivers': 1,
          }),
    );

    final metrics = await repository.loadMetrics();

    expect(metrics.deliveriesToday, 3);
    expect(metrics.revenue, '45.00');
    expect(metrics.currency, 'BRL');
    expect(metrics.driversOnline, 2);
    expect(metrics.pendingDrivers, 1);
  });

  test('pendingDrivers parses drivers with documents and vehicle', () async {
    final repository = AdminRepositoryImpl(
      _FakeAdminRemote((args) async => _page('drivers', [
            {
              'id': 'd1',
              'approval_status': 'PENDING',
              'user': {'name': 'Maria', 'email': 'maria@example.com'},
              'vehicle': {'plate': 'ABC1D23', 'vehicle_type': 'MOTORCYCLE'},
              'documents': [
                {
                  'id': 'doc1',
                  'document_type': 'CNH',
                  'verification_status': 'PENDING',
                },
              ],
            },
          ])),
    );

    final page = await repository.pendingDrivers();

    expect(page.items, hasLength(1));
    expect(page.pagination.total, 1);
    final driver = page.items.first;
    expect(driver.name, 'Maria');
    expect(driver.isPending, isTrue);
    expect(driver.vehiclePlate, 'ABC1D23');
    expect(driver.documents.single.documentType, 'CNH');
  });

  test('deliveries parses nested business and driver and builds the query', () async {
    Map<String, String>? seenQuery;
    final repository = AdminRepositoryImpl(
      _FakeAdminRemote((args) async {
        seenQuery = args['query'] as Map<String, String>?;
        return _page('deliveries', [
          {
            'id': 'del1',
            'status': 'OPEN',
            'recipient_name': 'João',
            'suggested_amount': '25.00',
            'currency': 'BRL',
            'business': {'trade_name': 'Loja A'},
            'current_driver': {
              'user': {'name': 'Ana'},
            },
          },
        ]);
      }),
    );

    final page = await repository.deliveries(
      filters: const AdminDeliveryFilters(status: 'OPEN', search: 'João'),
    );

    expect(page.items.single.businessName, 'Loja A');
    expect(page.items.single.driverName, 'Ana');
    expect(page.items.single.status, 'OPEN');
    expect(seenQuery, containsPair('status', 'OPEN'));
    expect(seenQuery, containsPair('search', 'João'));
    expect(seenQuery, containsPair('page', '1'));
  });

  test('financial and audit endpoints parse their envelopes', () async {
    final repository = AdminRepositoryImpl(
      _FakeAdminRemote((args) async {
        return switch (args['method']) {
          'payments' => _page('payments', [
              {
                'id': 'p1',
                'amount': '25.00',
                'currency': 'BRL',
                'status': 'CAPTURED',
                'delivery': {
                  'business': {'legal_name': 'Loja A'},
                },
              },
            ]),
          'refunds' => _page('refunds', [
              {
                'id': 'r1',
                'payment_id': 'p1',
                'amount': '10.00',
                'status': 'PENDING',
              },
            ]),
          'createRefund' => {
              'refund': {
                'id': 'r2',
                'payment_id': 'p1',
                'amount': '5.00',
                'status': 'PENDING',
              },
            },
          'payouts' => _page('payouts', [
              {
                'id': 'pay1',
                'net_amount': '22.50',
                'status': 'PENDING',
                'driver': {
                  'user': {'name': 'Ana'},
                },
              },
            ]),
          'auditLogs' => _page('audit_logs', [
              {
                'id': 'a1',
                'action': 'DRIVER_APPROVED',
                'entity_type': 'driver',
                'metadata': {},
              },
            ]),
          _ => const {},
        };
      }),
    );

    final payments = await repository.payments();
    expect(payments.items.single.businessName, 'Loja A');

    final refunds = await repository.refunds();
    expect(refunds.items.single.amount, '10.00');

    final created = await repository.createRefund(
      paymentId: 'p1',
      amount: '5.00',
      reason: 'teste',
    );
    expect(created.id, 'r2');

    final payouts = await repository.payouts();
    expect(payouts.items.single.netAmount, '22.50');

    final logs = await repository.auditLogs(
      filters: const AdminAuditLogFilters(action: 'DRIVER_APPROVED'),
    );
    expect(logs.items.single.action, 'DRIVER_APPROVED');
  });
}

