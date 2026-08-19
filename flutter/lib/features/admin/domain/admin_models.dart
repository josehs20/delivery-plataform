import '../../../core/models/json_utils.dart';

/// Paginação das listagens administrativas (envelope `pagination`).
final class AdminPagination {
  const AdminPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  factory AdminPagination.fromJson(Map<String, dynamic> json) {
    return AdminPagination(
      total: JsonUtils.intOrNull(json['total']) ?? 0,
      perPage: JsonUtils.intOrNull(json['per_page']) ?? 15,
      currentPage: JsonUtils.intOrNull(json['current_page']) ?? 1,
      lastPage: JsonUtils.intOrNull(json['last_page']) ?? 1,
    );
  }
}

/// Página genérica de uma listagem administrativa.
final class AdminPage<T> {
  const AdminPage({required this.items, required this.pagination});

  final List<T> items;
  final AdminPagination pagination;
}

/// Métricas globais do painel (calculadas no servidor — nunca na UI).
final class AdminMetrics {
  const AdminMetrics({
    required this.deliveriesToday,
    required this.revenue,
    required this.currency,
    required this.driversOnline,
    required this.pendingDrivers,
  });

  final int deliveriesToday;

  /// Valor monetário autoritativo (String + currency, nunca double).
  final String revenue;
  final String currency;
  final int driversOnline;
  final int pendingDrivers;

  factory AdminMetrics.fromJson(Map<String, dynamic> json) {
    return AdminMetrics(
      deliveriesToday: JsonUtils.intOrNull(json['deliveries_today']) ?? 0,
      revenue: JsonUtils.stringOrDefault(json['revenue'], fallback: '0.00'),
      currency: JsonUtils.stringOrDefault(json['currency'], fallback: 'BRL'),
      driversOnline: JsonUtils.intOrNull(json['drivers_online']) ?? 0,
      pendingDrivers: JsonUtils.intOrNull(json['pending_drivers']) ?? 0,
    );
  }
}

/// Documento de um motorista (CNH, CRLV, selfie...) — espelha `driver_documents`.
final class AdminDriverDocument {
  const AdminDriverDocument({
    required this.id,
    required this.documentType,
    this.objectKey,
    this.verificationStatus,
    this.expiresAt,
  });

  final String id;
  final String documentType;
  final String? objectKey;
  final String? verificationStatus;
  final DateTime? expiresAt;

  factory AdminDriverDocument.fromJson(Map<String, dynamic> json) {
    return AdminDriverDocument(
      id: JsonUtils.stringOrDefault(json['id']),
      documentType: JsonUtils.stringOrDefault(json['document_type']),
      objectKey: JsonUtils.stringOrNull(json['object_key']),
      verificationStatus: JsonUtils.stringOrNull(json['verification_status']),
      expiresAt: JsonUtils.dateTime(json['expires_at']),
    );
  }
}

/// Resumo de um motorista na fila de aprovação cadastral.
final class AdminDriverSummary {
  const AdminDriverSummary({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.nationalDocument,
    this.approvalStatus,
    this.operationalStatus,
    this.vehiclePlate,
    this.vehicleType,
    this.documents = const [],
  });

  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? nationalDocument;
  final String? approvalStatus;
  final String? operationalStatus;
  final String? vehiclePlate;
  final String? vehicleType;
  final List<AdminDriverDocument> documents;

  bool get isPending => approvalStatus == 'PENDING';

  factory AdminDriverSummary.fromJson(Map<String, dynamic> json) {
    final user = JsonUtils.mapOrEmpty(json['user']);
    final vehicle = JsonUtils.mapOrEmpty(json['vehicle']);
    final rawDocuments = json['documents'];
    final documents = rawDocuments is List
        ? rawDocuments
            .whereType<Map>()
            .map((e) => AdminDriverDocument.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v)),
                ))
            .toList(growable: false)
        : const <AdminDriverDocument>[];

    return AdminDriverSummary(
      id: JsonUtils.stringOrDefault(json['id']),
      name: JsonUtils.stringOrNull(user['name']),
      email: JsonUtils.stringOrNull(user['email']),
      phone: JsonUtils.stringOrNull(user['phone']),
      nationalDocument: JsonUtils.stringOrNull(json['national_document']),
      approvalStatus: JsonUtils.stringOrNull(json['approval_status']),
      operationalStatus: JsonUtils.stringOrNull(json['operational_status']),
      vehiclePlate: JsonUtils.stringOrNull(vehicle['plate']),
      vehicleType: JsonUtils.stringOrNull(vehicle['vehicle_type']),
      documents: documents,
    );
  }
}

/// Entrega na torre de controle administrativa.
final class AdminDelivery {
  const AdminDelivery({
    required this.id,
    required this.status,
    this.recipientName,
    this.recipientPhone,
    this.suggestedAmount,
    this.currency,
    this.businessName,
    this.driverName,
    this.createdAt,
    this.deliveredAt,
  });

  final String id;
  final String status;
  final String? recipientName;
  final String? recipientPhone;
  final String? suggestedAmount;
  final String? currency;
  final String? businessName;
  final String? driverName;
  final DateTime? createdAt;
  final DateTime? deliveredAt;

  factory AdminDelivery.fromJson(Map<String, dynamic> json) {
    final business = JsonUtils.mapOrEmpty(json['business']);
    final currentDriver = JsonUtils.mapOrEmpty(json['current_driver']);
    final driverUser = JsonUtils.mapOrEmpty(currentDriver['user']);

    return AdminDelivery(
      id: JsonUtils.stringOrDefault(json['id']),
      status: JsonUtils.stringOrDefault(json['status']),
      recipientName: JsonUtils.stringOrNull(json['recipient_name']),
      recipientPhone: JsonUtils.stringOrNull(json['recipient_phone']),
      suggestedAmount: JsonUtils.stringOrNull(json['suggested_amount']),
      currency: JsonUtils.stringOrNull(json['currency']),
      businessName: JsonUtils.stringOrNull(business['trade_name']) ??
          JsonUtils.stringOrNull(business['legal_name']),
      driverName: JsonUtils.stringOrNull(driverUser['name']),
      createdAt: JsonUtils.dateTime(json['created_at']),
      deliveredAt: JsonUtils.dateTime(json['delivered_at']),
    );
  }
}

/// Pagamento de comércio no extrato global.
final class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    this.provider,
    this.deliveryId,
    this.businessName,
    this.capturedAt,
  });

  final String id;

  /// Monetário autoritativo (String + currency).
  final String amount;
  final String currency;
  final String status;
  final String? provider;
  final String? deliveryId;
  final String? businessName;
  final DateTime? capturedAt;

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    final delivery = JsonUtils.mapOrEmpty(json['delivery']);
    final business = JsonUtils.mapOrEmpty(delivery['business']);

    return AdminPayment(
      id: JsonUtils.stringOrDefault(json['id']),
      amount: JsonUtils.stringOrDefault(json['amount'], fallback: '0.00'),
      currency: JsonUtils.stringOrDefault(json['currency'], fallback: 'BRL'),
      status: JsonUtils.stringOrDefault(json['status']),
      provider: JsonUtils.stringOrNull(json['provider']),
      deliveryId: JsonUtils.stringOrNull(json['delivery_id']),
      businessName: JsonUtils.stringOrNull(business['trade_name']) ??
          JsonUtils.stringOrNull(business['legal_name']),
      capturedAt: JsonUtils.dateTime(json['captured_at']),
    );
  }
}

/// Reembolso emitido pelo admin.
final class AdminRefund {
  const AdminRefund({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.status,
    this.reason,
    this.requestedAt,
  });

  final String id;
  final String paymentId;

  /// Monetário autoritativo (String + currency).
  final String amount;
  final String status;
  final String? reason;
  final DateTime? requestedAt;

  factory AdminRefund.fromJson(Map<String, dynamic> json) {
    return AdminRefund(
      id: JsonUtils.stringOrDefault(json['id']),
      paymentId: JsonUtils.stringOrDefault(json['payment_id']),
      amount: JsonUtils.stringOrDefault(json['amount'], fallback: '0.00'),
      status: JsonUtils.stringOrDefault(json['status']),
      reason: JsonUtils.stringOrNull(json['reason']),
      requestedAt: JsonUtils.dateTime(json['requested_at']),
    );
  }
}

/// Repasse (payout) para um motoboy.
final class AdminPayout {
  const AdminPayout({
    required this.id,
    required this.netAmount,
    required this.status,
    this.driverName,
    this.deliveryId,
    this.paidAt,
  });

  final String id;

  /// Monetário autoritativo (String + currency).
  final String netAmount;
  final String status;
  final String? driverName;
  final String? deliveryId;
  final DateTime? paidAt;

  factory AdminPayout.fromJson(Map<String, dynamic> json) {
    final driver = JsonUtils.mapOrEmpty(json['driver']);
    final driverUser = JsonUtils.mapOrEmpty(driver['user']);

    return AdminPayout(
      id: JsonUtils.stringOrDefault(json['id']),
      netAmount: JsonUtils.stringOrDefault(json['net_amount'], fallback: '0.00'),
      status: JsonUtils.stringOrDefault(json['status']),
      driverName: JsonUtils.stringOrNull(driverUser['name']),
      deliveryId: JsonUtils.stringOrNull(json['delivery_id']),
      paidAt: JsonUtils.dateTime(json['paid_at']),
    );
  }
}

/// Entrada da trilha de auditoria.
final class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    this.actorType,
    this.actorId,
    this.occurredAt,
    this.metadata = const {},
  });

  final String id;
  final String action;
  final String entityType;
  final String? entityId;
  final String? actorType;
  final String? actorId;
  final DateTime? occurredAt;
  final Map<String, dynamic> metadata;

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: JsonUtils.stringOrDefault(json['id']),
      action: JsonUtils.stringOrDefault(json['action']),
      entityType: JsonUtils.stringOrDefault(json['entity_type']),
      entityId: JsonUtils.stringOrNull(json['entity_id']),
      actorType: JsonUtils.stringOrNull(json['actor_type']),
      actorId: JsonUtils.stringOrNull(json['actor_id']),
      occurredAt: JsonUtils.dateTime(json['occurred_at']),
      metadata: JsonUtils.mapOrEmpty(json['metadata']),
    );
  }
}


