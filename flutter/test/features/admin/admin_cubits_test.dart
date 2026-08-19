// Testes dos Cubits do painel administrativo (estados e chamadas ao repositório).

import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/features/admin/domain/admin_models.dart';
import 'package:delivery_app/features/admin/domain/admin_repository.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_audit_logs_cubit.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_dashboard_cubit.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_deliveries_cubit.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_drivers_cubit.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_financial_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

const _metrics = AdminMetrics(
  deliveriesToday: 4,
  revenue: '90.00',
  currency: 'BRL',
  driversOnline: 3,
  pendingDrivers: 2,
);

const _driver = AdminDriverSummary(id: 'd1', name: 'Maria', approvalStatus: 'PENDING');

const _delivery = AdminDelivery(
  id: 'del1',
  status: 'OPEN',
  recipientName: 'João',
  businessName: 'Loja A',
);

const _payment = AdminPayment(
  id: 'p1',
  amount: '25.00',
  currency: 'BRL',
  status: 'CAPTURED',
);

const _pagination = AdminPagination(total: 1, perPage: 15, currentPage: 1, lastPage: 1);

const _emptyPage = AdminPage<AdminRefund>(
  items: [],
  pagination: AdminPagination(total: 0, perPage: 15, currentPage: 1, lastPage: 1),
);

const _log = AdminAuditLog(id: 'a1', action: 'DRIVER_APPROVED', entityType: 'driver');

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository({this.failWith});

  final Object? failWith;
  int approveCalls = 0;
  int rejectCalls = 0;
  int suspendCalls = 0;
  int assignCalls = 0;
  int cancelCalls = 0;
  int refundCalls = 0;

  void _maybeFail() {
    if (failWith != null) throw failWith!;
  }

  @override
  Future<AdminMetrics> loadMetrics() async {
    _maybeFail();
    return _metrics;
  }

  @override
  Future<AdminPage<AdminDriverSummary>> pendingDrivers({
    int page = 1,
    int perPage = 15,
  }) async {
    _maybeFail();
    return const AdminPage(items: [_driver], pagination: _pagination);
  }

  @override
  Future<void> approveDriver(String driverId) async {
    _maybeFail();
    approveCalls++;
  }

  @override
  Future<void> rejectDriver(String driverId, {required String reason}) async {
    _maybeFail();
    rejectCalls++;
  }

  @override
  Future<void> suspendDriver(String driverId) async {
    _maybeFail();
    suspendCalls++;
  }

  @override
  Future<AdminPage<AdminDelivery>> deliveries({
    AdminDeliveryFilters filters = const AdminDeliveryFilters(),
    int page = 1,
    int perPage = 15,
  }) async {
    _maybeFail();
    return const AdminPage(items: [_delivery], pagination: _pagination);
  }

  @override
  Future<void> assignDelivery(String deliveryId, {required String driverId}) async {
    _maybeFail();
    assignCalls++;
  }

  @override
  Future<void> cancelDelivery(
    String deliveryId, {
    required String reason,
    String? refundType,
  }) async {
    _maybeFail();
    cancelCalls++;
  }

  @override
  Future<AdminPage<AdminPayment>> payments({int page = 1, int perPage = 15}) async {
    _maybeFail();
    return const AdminPage(items: [_payment], pagination: _pagination);
  }

  @override
  Future<AdminPage<AdminRefund>> refunds({int page = 1, int perPage = 15}) async {
    _maybeFail();
    return _emptyPage;
  }

  @override
  Future<AdminRefund> createRefund({
    required String paymentId,
    required String amount,
    required String reason,
  }) async {
    _maybeFail();
    refundCalls++;
    return AdminRefund(id: 'r1', paymentId: paymentId, amount: amount, status: 'PENDING');
  }

  @override
  Future<AdminPage<AdminPayout>> payouts({int page = 1, int perPage = 15}) async {
    _maybeFail();
    return const AdminPage<AdminPayout>(items: [], pagination: AdminPagination(total: 0, perPage: 15, currentPage: 1, lastPage: 1));
  }

  @override
  Future<AdminPage<AdminAuditLog>> auditLogs({
    AdminAuditLogFilters filters = const AdminAuditLogFilters(),
    int page = 1,
    int perPage = 15,
  }) async {
    _maybeFail();
    return const AdminPage(items: [_log], pagination: _pagination);
  }
}

void main() {
  test('AdminDashboardCubit loads metrics and maps failures', () async {
    final ok = AdminDashboardCubit(_FakeAdminRepository());
    addTearDown(ok.close);
    await ok.load();
    expect(ok.state, isA<AdminDashboardLoaded>());
    expect((ok.state as AdminDashboardLoaded).metrics.pendingDrivers, 2);

    final failed = AdminDashboardCubit(
      _FakeAdminRepository(failWith: const ServerException('erro')),
    );
    addTearDown(failed.close);
    await failed.load();
    expect(failed.state, isA<AdminDashboardFailure>());
  });

  test('AdminDriversCubit loads the queue and approves a driver', () async {
    final repo = _FakeAdminRepository();
    final cubit = AdminDriversCubit(repo);
    addTearDown(cubit.close);

    await cubit.loadPending();
    expect(cubit.state, isA<AdminDriversLoaded>());
    expect((cubit.state as AdminDriversLoaded).drivers.single.id, 'd1');

    await cubit.approve('d1');
    expect(repo.approveCalls, 1);
    expect(cubit.state, isA<AdminDriversLoaded>());
    expect((cubit.state as AdminDriversLoaded).message, 'Motorista aprovado.');
  });

  test('AdminDriversCubit rejects with reason', () async {
    final repo = _FakeAdminRepository();
    final cubit = AdminDriversCubit(repo);
    addTearDown(cubit.close);

    await cubit.loadPending();
    await cubit.reject('d1', reason: 'Documento vencido.');

    expect(repo.rejectCalls, 1);
    expect((cubit.state as AdminDriversLoaded).message, 'Cadastro rejeitado.');
  });

  test('AdminDeliveriesCubit loads with filters and assigns', () async {
    final repo = _FakeAdminRepository();
    final cubit = AdminDeliveriesCubit(repo);
    addTearDown(cubit.close);

    await cubit.load(filters: const AdminDeliveryFilters(status: 'OPEN'));
    final state = cubit.state as AdminDeliveriesLoaded;
    expect(state.deliveries.single.status, 'OPEN');
    expect(state.filters.status, 'OPEN');

    await cubit.assign('del1', driverId: 'd9');
    expect(repo.assignCalls, 1);
  });

  test('AdminDeliveriesCubit cancels with reason and refund type', () async {
    final repo = _FakeAdminRepository();
    final cubit = AdminDeliveriesCubit(repo);
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.cancel('del1', reason: 'Fraude', refundType: 'FULL');

    expect(repo.cancelCalls, 1);
    expect((cubit.state as AdminDeliveriesLoaded).message, 'Entrega cancelada.');
  });

  test('AdminFinancialCubit loads all modules and creates refunds', () async {
    final repo = _FakeAdminRepository();
    final cubit = AdminFinancialCubit(repo);
    addTearDown(cubit.close);

    await cubit.loadAll();
    expect(cubit.state, isA<AdminFinancialLoaded>());
    expect((cubit.state as AdminFinancialLoaded).payments.single.id, 'p1');

    await cubit.createRefund(paymentId: 'p1', amount: '5.00', reason: 'teste');
    expect(repo.refundCalls, 1);
  });

  test('AdminAuditLogsCubit loads with filters', () async {
    final cubit = AdminAuditLogsCubit(_FakeAdminRepository());
    addTearDown(cubit.close);

    await cubit.load(filters: const AdminAuditLogFilters(action: 'DRIVER_APPROVED'));
    final state = cubit.state as AdminAuditLogsLoaded;
    expect(state.logs.single.action, 'DRIVER_APPROVED');
    expect(state.filters.action, 'DRIVER_APPROVED');
  });
}
