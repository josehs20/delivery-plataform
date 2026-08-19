import '../../../core/models/json_utils.dart';
import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';
import 'admin_mappers.dart';
import 'admin_remote_data_source.dart';

/// Implementação do [AdminRepository] consumindo a API `/admin/*`.
final class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  Future<AdminMetrics> loadMetrics() async {
    return AdminMetrics.fromJson(await _remote.metrics());
  }

  @override
  Future<AdminPage<AdminDriverSummary>> pendingDrivers({
    int page = 1,
    int perPage = 15,
  }) async {
    return AdminMappers.pageOf(
      await _remote.pendingDrivers(page: page, perPage: perPage),
      'drivers',
      AdminDriverSummary.fromJson,
    );
  }

  @override
  Future<void> approveDriver(String driverId) async {
    await _remote.approveDriver(driverId);
  }

  @override
  Future<void> rejectDriver(String driverId, {required String reason}) async {
    await _remote.rejectDriver(driverId, reason: reason);
  }

  @override
  Future<void> suspendDriver(String driverId) async {
    await _remote.suspendDriver(driverId);
  }

  @override
  Future<AdminPage<AdminDelivery>> deliveries({
    AdminDeliveryFilters filters = const AdminDeliveryFilters(),
    int page = 1,
    int perPage = 15,
  }) async {
    final query = filters.toQuery()
      ..['page'] = '$page'
      ..['per_page'] = '$perPage';
    return AdminMappers.pageOf(
      await _remote.deliveries(query: query),
      'deliveries',
      AdminDelivery.fromJson,
    );
  }

  @override
  Future<void> assignDelivery(
    String deliveryId, {
    required String driverId,
  }) async {
    await _remote.assignDelivery(deliveryId, driverId: driverId);
  }

  @override
  Future<void> cancelDelivery(
    String deliveryId, {
    required String reason,
    String? refundType,
  }) async {
    await _remote.cancelDelivery(
      deliveryId,
      reason: reason,
      refundType: refundType,
    );
  }

  @override
  Future<AdminPage<AdminPayment>> payments({
    int page = 1,
    int perPage = 15,
  }) async {
    return AdminMappers.pageOf(
      await _remote.payments(query: {'page': '$page', 'per_page': '$perPage'}),
      'payments',
      AdminPayment.fromJson,
    );
  }

  @override
  Future<AdminPage<AdminRefund>> refunds({
    int page = 1,
    int perPage = 15,
  }) async {
    return AdminMappers.pageOf(
      await _remote.refunds(query: {'page': '$page', 'per_page': '$perPage'}),
      'refunds',
      AdminRefund.fromJson,
    );
  }

  @override
  Future<AdminRefund> createRefund({
    required String paymentId,
    required String amount,
    required String reason,
  }) async {
    final data = await _remote.createRefund(
      paymentId: paymentId,
      amount: amount,
      reason: reason,
    );
    final refund = JsonUtils.mapOrEmpty(data['refund']);
    return AdminRefund.fromJson(refund);
  }

  @override
  Future<AdminPage<AdminPayout>> payouts({
    int page = 1,
    int perPage = 15,
  }) async {
    return AdminMappers.pageOf(
      await _remote.payouts(query: {'page': '$page', 'per_page': '$perPage'}),
      'payouts',
      AdminPayout.fromJson,
    );
  }

  @override
  Future<AdminPage<AdminAuditLog>> auditLogs({
    AdminAuditLogFilters filters = const AdminAuditLogFilters(),
    int page = 1,
    int perPage = 15,
  }) async {
    final query = filters.toQuery()
      ..['page'] = '$page'
      ..['per_page'] = '$perPage';
    return AdminMappers.pageOf(
      await _remote.auditLogs(query: query),
      'audit_logs',
      AdminAuditLog.fromJson,
    );
  }
}
