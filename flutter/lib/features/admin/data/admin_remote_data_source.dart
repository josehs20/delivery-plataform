import '../../../core/models/json_utils.dart';
import '../../../core/network/api_client.dart';

/// Data source remoto do painel administrativo (base `/api/v1/admin`).
///
/// Todos os métodos devolvem o conteúdo do envelope `data` (mapeado), já que a
/// conversão para models de domínio ocorre em mappers/repository.
abstract interface class AdminRemoteDataSource {
  Future<Map<String, dynamic>> metrics();

  Future<Map<String, dynamic>> pendingDrivers({int page = 1, int perPage = 15});

  Future<Map<String, dynamic>> approveDriver(String driverId);

  Future<Map<String, dynamic>> rejectDriver(String driverId, {required String reason});

  Future<Map<String, dynamic>> suspendDriver(String driverId);

  Future<Map<String, dynamic>> deliveries({Map<String, String>? query});

  Future<Map<String, dynamic>> assignDelivery(String deliveryId, {required String driverId});

  Future<Map<String, dynamic>> cancelDelivery(
    String deliveryId, {
    required String reason,
    String? refundType,
  });

  Future<Map<String, dynamic>> payments({Map<String, String>? query});

  Future<Map<String, dynamic>> refunds({Map<String, String>? query});

  Future<Map<String, dynamic>> createRefund({
    required String paymentId,
    required String amount,
    required String reason,
  });

  Future<Map<String, dynamic>> payouts({Map<String, String>? query});

  Future<Map<String, dynamic>> auditLogs({Map<String, String>? query});
}

final class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  AdminRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Map<String, dynamic>> metrics() async {
    final response = await _apiClient.get('/admin/metrics');
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> pendingDrivers({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await _apiClient.get(
      '/admin/drivers/pending',
      query: {'page': '$page', 'per_page': '$perPage'},
    );
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> approveDriver(String driverId) async {
    final response = await _apiClient.post('/admin/drivers/$driverId/approve');
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> rejectDriver(
    String driverId, {
    required String reason,
  }) async {
    final response = await _apiClient.post(
      '/admin/drivers/$driverId/reject',
      body: {'reason': reason},
    );
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> suspendDriver(String driverId) async {
    final response = await _apiClient.post('/admin/drivers/$driverId/suspend');
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> deliveries({Map<String, String>? query}) async {
    final response = await _apiClient.get('/admin/deliveries', query: query);
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> assignDelivery(
    String deliveryId, {
    required String driverId,
  }) async {
    final response = await _apiClient.post(
      '/admin/deliveries/$deliveryId/assign',
      body: {'driver_id': driverId},
    );
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> cancelDelivery(
    String deliveryId, {
    required String reason,
    String? refundType,
  }) async {
    final response = await _apiClient.post(
      '/admin/deliveries/$deliveryId/cancel',
      body: {
        'reason': reason,
        if (refundType != null && refundType.isNotEmpty)
          'refund_type': refundType,
      },
    );
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> payments({Map<String, String>? query}) async {
    final response = await _apiClient.get('/admin/payments', query: query);
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> refunds({Map<String, String>? query}) async {
    final response = await _apiClient.get('/admin/refunds', query: query);
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> createRefund({
    required String paymentId,
    required String amount,
    required String reason,
  }) async {
    final response = await _apiClient.post(
      '/admin/refunds',
      body: {'payment_id': paymentId, 'amount': amount, 'reason': reason},
    );
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> payouts({Map<String, String>? query}) async {
    final response = await _apiClient.get('/admin/payouts', query: query);
    return _dataMap(response);
  }

  @override
  Future<Map<String, dynamic>> auditLogs({Map<String, String>? query}) async {
    final response = await _apiClient.get('/admin/audit-logs', query: query);
    return _dataMap(response);
  }

  /// Extrai e normaliza o envelope `{"data": {...}}`.
  static Map<String, dynamic> _dataMap(ApiResponse response) {
    final envelope = JsonUtils.mapOrEmpty(response.data);
    return JsonUtils.mapOrEmpty(envelope['data']);
  }
}
