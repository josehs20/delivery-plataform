import '../../../core/errors/api_exception.dart';
import '../../../core/models/delivery_dto.dart';
import '../../../core/models/json_utils.dart';
import '../../../core/network/api_client.dart';

/// Data source remoto de entregas (contrato HTTP do Laravel).
abstract interface class DeliveryRemoteDataSource {
  /// `GET /deliveries` — feed (lista com paginação).
  Future<List<DeliveryDto>> listDeliveries();

  /// `GET /deliveries/{id}` — detalhe.
  Future<DeliveryDto> getDelivery(String id);

  /// `POST /deliveries/{id}/accept` — aceite de oferta (`offer_id`).
  Future<DeliveryDto> acceptOffer({
    required String deliveryId,
    required String offerId,
    required String idempotencyKey,
  });

  /// `POST /deliveries/{id}/arrive-pickup` — `AT_PICKUP`.
  Future<DeliveryDto> arrivePickup({
    required String deliveryId,
    required String idempotencyKey,
  });

  /// `POST /deliveries/{id}/pickup` — `PICKED_UP`.
  Future<DeliveryDto> pickup({
    required String deliveryId,
    required String idempotencyKey,
  });

  /// `POST /deliveries/{id}/complete` — `DELIVERED` (com prova de entrega).
  Future<DeliveryDto> complete({
    required String deliveryId,
    required Map<String, dynamic> proof,
    required String idempotencyKey,
  });

  /// `POST /deliveries` — cria uma entrega em `DRAFT` (comércio).
  Future<DeliveryDto> createDelivery(Map<String, dynamic> payload);

  /// `POST /deliveries/{id}/publish` — `DRAFT` → `OPEN` + despacho.
  Future<DeliveryDto> publishDelivery(String deliveryId);

  /// `POST /deliveries/{id}/cancel` — cancela (comércio) com motivo.
  Future<DeliveryDto> cancelDelivery({
    required String deliveryId,
    required String reason,
    String? description,
  });

  /// `POST /deliveries/{id}/arrive-destination` — `AT_DESTINATION`.
  Future<DeliveryDto> arriveDestination({
    required String deliveryId,
    required String idempotencyKey,
  });

  /// `POST /deliveries/{id}/fail` — `DELIVERY_FAILED` com motivo.
  Future<DeliveryDto> failDelivery({
    required String deliveryId,
    required String reason,
    String? description,
    required String idempotencyKey,
  });

  /// `POST /deliveries/{id}/return/start` — `RETURN_IN_PROGRESS`.
  Future<DeliveryDto> startReturn({
    required String deliveryId,
    required String idempotencyKey,
  });

  /// `POST /deliveries/{id}/return/confirm` — comércio confirma `RETURNED`.
  Future<DeliveryDto> confirmReturn(String deliveryId);
}

final class DeliveryRemoteDataSourceImpl implements DeliveryRemoteDataSource {
  DeliveryRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<DeliveryDto>> listDeliveries() async {
    final response = await _apiClient.get('/deliveries');
    final envelope = _asStringMap(response.data);
    // O backend responde `{"data": {"deliveries": [...], "pagination": {...}}}`
    // (OpenAPI) — sem esse unwrap a lista sempre apareceria vazia.
    final data = _asStringMap(envelope['data']);
    final raw = data['deliveries'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DeliveryDto.fromJson(JsonUtils.mapOrEmpty(e)))
        .toList(growable: false);
  }

  @override
  Future<DeliveryDto> getDelivery(String id) async {
    final response = await _apiClient.get('/deliveries/$id');
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> acceptOffer({
    required String deliveryId,
    required String offerId,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/deliveries/$deliveryId/accept',
      body: {'offer_id': offerId, 'idempotency_key': idempotencyKey},
      idempotencyKey: idempotencyKey,
    );
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> arrivePickup({
    required String deliveryId,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/deliveries/$deliveryId/arrive-pickup',
      body: {'idempotency_key': idempotencyKey},
      idempotencyKey: idempotencyKey,
    );
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> pickup({
    required String deliveryId,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/deliveries/$deliveryId/pickup',
      body: {'idempotency_key': idempotencyKey},
      idempotencyKey: idempotencyKey,
    );
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> complete({
    required String deliveryId,
    required Map<String, dynamic> proof,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/deliveries/$deliveryId/complete',
      body: {'idempotency_key': idempotencyKey, 'proof': proof},
      idempotencyKey: idempotencyKey,
    );
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> createDelivery(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/deliveries', body: payload);
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> publishDelivery(String deliveryId) async {
    final response =
        await _apiClient.post('/deliveries/$deliveryId/publish', body: const {});
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> cancelDelivery({
    required String deliveryId,
    required String reason,
    String? description,
  }) async {
    final response = await _apiClient.post(
      '/deliveries/$deliveryId/cancel',
      body: {
        'reason': reason,
        'description': ?description,
      },
    );
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> arriveDestination({
    required String deliveryId,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/deliveries/$deliveryId/arrive-destination',
      body: {'idempotency_key': idempotencyKey},
      idempotencyKey: idempotencyKey,
    );
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> failDelivery({
    required String deliveryId,
    required String reason,
    String? description,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/deliveries/$deliveryId/fail',
      body: {
        'idempotency_key': idempotencyKey,
        'reason': reason,
        'description': ?description,
      },
      idempotencyKey: idempotencyKey,
    );
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> startReturn({
    required String deliveryId,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/deliveries/$deliveryId/return/start',
      body: {'idempotency_key': idempotencyKey},
      idempotencyKey: idempotencyKey,
    );
    return _singleDelivery(response.data);
  }

  @override
  Future<DeliveryDto> confirmReturn(String deliveryId) async {
    final response = await _apiClient.post(
      '/deliveries/$deliveryId/return/confirm',
      body: const {},
    );
    return _singleDelivery(response.data);
  }

  /// Extrai `data.delivery` da resposta de ações/detalhe.
  ///
  /// O backend responde `{"data": {"delivery": {...}}}` (OpenAPI); o unwrap
  /// do envelope acontece aqui para todos os endpoints de entrega individual.
  static DeliveryDto _singleDelivery(Object? data) {
    final envelope = _asStringMap(data);
    final map = _asStringMap(envelope['data']);
    final raw = map['delivery'];
    if (raw is! Map) {
      throw const ServerException('Resposta inválida do servidor.');
    }
    return DeliveryDto.fromJson(JsonUtils.mapOrEmpty(raw));
  }

  static Map<String, dynamic> _asStringMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}
