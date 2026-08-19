import 'admin_models.dart';

/// Filtros da torre de controle de entregas (`GET /admin/deliveries`).
final class AdminDeliveryFilters {
  const AdminDeliveryFilters({
    this.status,
    this.dateFrom,
    this.dateTo,
    this.businessId,
    this.driverId,
    this.search,
  });

  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? businessId;
  final String? driverId;
  final String? search;

  bool get isEmpty =>
      status == null &&
      dateFrom == null &&
      dateTo == null &&
      businessId == null &&
      driverId == null &&
      (search == null || search!.isEmpty);

  Map<String, String> toQuery() {
    return {
      if (status != null && status!.isNotEmpty) 'status': status!,
      if (dateFrom != null)
        'date_from': dateFrom!.toUtc().toIso8601String().split('T').first,
      if (dateTo != null)
        'date_to': dateTo!.toUtc().toIso8601String().split('T').first,
      if (businessId != null && businessId!.isNotEmpty) 'business_id': businessId!,
      if (driverId != null && driverId!.isNotEmpty) 'driver_id': driverId!,
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
    };
  }
}

/// Filtros da trilha de auditoria (`GET /admin/audit-logs`).
final class AdminAuditLogFilters {
  const AdminAuditLogFilters({
    this.action,
    this.entityType,
    this.userId,
    this.dateFrom,
    this.dateTo,
  });

  final String? action;
  final String? entityType;
  final String? userId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get isEmpty =>
      action == null &&
      entityType == null &&
      userId == null &&
      dateFrom == null &&
      dateTo == null;

  Map<String, String> toQuery() {
    return {
      if (action != null && action!.isNotEmpty) 'action': action!,
      if (entityType != null && entityType!.isNotEmpty) 'entity_type': entityType!,
      if (userId != null && userId!.isNotEmpty) 'user_id': userId!,
      if (dateFrom != null)
        'date_from': dateFrom!.toUtc().toIso8601String().split('T').first,
      if (dateTo != null)
        'date_to': dateTo!.toUtc().toIso8601String().split('T').first,
    };
  }
}

/// Repositório do painel administrativo (docs/docs/api/41-admin-api.md).
abstract interface class AdminRepository {
  Future<AdminMetrics> loadMetrics();

  Future<AdminPage<AdminDriverSummary>> pendingDrivers({
    int page = 1,
    int perPage = 15,
  });

  Future<void> approveDriver(String driverId);

  Future<void> rejectDriver(String driverId, {required String reason});

  Future<void> suspendDriver(String driverId);

  Future<AdminPage<AdminDelivery>> deliveries({
    AdminDeliveryFilters filters = const AdminDeliveryFilters(),
    int page = 1,
    int perPage = 15,
  });

  Future<void> assignDelivery(String deliveryId, {required String driverId});

  Future<void> cancelDelivery(
    String deliveryId, {
    required String reason,
    String? refundType,
  });

  Future<AdminPage<AdminPayment>> payments({int page = 1, int perPage = 15});

  Future<AdminPage<AdminRefund>> refunds({int page = 1, int perPage = 15});

  Future<AdminRefund> createRefund({
    required String paymentId,
    required String amount,
    required String reason,
  });

  Future<AdminPage<AdminPayout>> payouts({int page = 1, int perPage = 15});

  Future<AdminPage<AdminAuditLog>> auditLogs({
    AdminAuditLogFilters filters = const AdminAuditLogFilters(),
    int page = 1,
    int perPage = 15,
  });
}
