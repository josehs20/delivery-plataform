import 'package:uuid/uuid.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/models/delivery_dto.dart';
import '../../../core/storage/delivery_cache_repository.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue.dart';
import '../domain/delivery.dart';
import '../domain/delivery_repository.dart';
import '../domain/new_delivery.dart';
import '../domain/proof_of_delivery.dart';
import 'delivery_mapper.dart';
import 'delivery_remote_data_source.dart';

/// Implementação do [DeliveryRepository]: orquestra remoto + cache local +
/// SyncQueue, com comportamento offline-first nas transições do motoboy.
final class DeliveryRepositoryImpl implements DeliveryRepository {
  DeliveryRepositoryImpl(
    this._remoteDataSource,
    this._cache,
    this._syncQueue,
    this._deviceId, {
    String Function()? operationIdGenerator,
  }) : _operationIdGenerator = operationIdGenerator ?? _uuidV4;

  static String _uuidV4() => const Uuid().v4();

  final DeliveryRemoteDataSource _remoteDataSource;
  final DeliveryCacheRepository _cache;
  final SyncQueue _syncQueue;
  final String _deviceId;
  final String Function() _operationIdGenerator;

  @override
  Future<DeliveryListResult> listAvailable() async {
    try {
      final deliveries = await _remoteDataSource.listDeliveries();
      await _cache.upsertAll(deliveries);
      return DeliveryListResult(
        deliveries:
            deliveries.map(DeliveryMapper.fromDto).toList(growable: false),
        fromCache: false,
      );
    } on NetworkException {
      final cached = await _cache.all();
      return DeliveryListResult(
        deliveries: cached.map(DeliveryMapper.fromDto).toList(growable: false),
        fromCache: true,
      );
    }
  }

  @override
  Future<DeliveryLoadResult> getById(String id) async {
    try {
      final dto = await _remoteDataSource.getDelivery(id);
      await _cache.upsert(dto);
      return DeliveryLoadResult(
        delivery: DeliveryMapper.fromDto(dto),
        fromCache: false,
      );
    } on NetworkException {
      final cached = await _cache.byId(id);
      if (cached == null) {
        throw const ServerException('Entrega não disponível offline.');
      }
      return DeliveryLoadResult(
        delivery: DeliveryMapper.fromDto(cached),
        fromCache: true,
      );
    }
  }

  @override
  Future<DeliveryActionResult> acceptOffer({
    required String deliveryId,
    required String offerId,
  }) async {
    // MVP: aceite exige conectividade (docs: nova oferta exige conectividade).
    final dto = await _remoteDataSource.acceptOffer(
      deliveryId: deliveryId,
      offerId: offerId,
      idempotencyKey: _operationIdGenerator(),
    );
    await _cache.upsert(dto);
    return DeliveryActionResult(
      delivery: DeliveryMapper.fromDto(dto),
      confirmedOnServer: true,
    );
  }

  @override
  Future<DeliveryActionResult> registerPickupArrival(String deliveryId) {
    return _transition(
      deliveryId: deliveryId,
      target: DeliveryStatus.atPickup,
      remoteCall: () => _remoteDataSource.arrivePickup(
        deliveryId: deliveryId,
        idempotencyKey: _operationIdGenerator(),
      ),
      operationType: 'ARRIVE_PICKUP',
      payload: {'delivery_id': deliveryId, 'action': 'arrive-pickup'},
    );
  }

  @override
  Future<DeliveryActionResult> confirmPickup(String deliveryId) {
    return _transition(
      deliveryId: deliveryId,
      target: DeliveryStatus.pickedUp,
      remoteCall: () => _remoteDataSource.pickup(
        deliveryId: deliveryId,
        idempotencyKey: _operationIdGenerator(),
      ),
      operationType: 'CONFIRM_PICKUP',
      payload: {'delivery_id': deliveryId, 'action': 'pickup'},
    );
  }

  @override
  Future<DeliveryActionResult> confirmDelivery({
    required String deliveryId,
    required ProofOfDelivery proof,
  }) {
    final proofPayload = proof.toPayload();
    return _transition(
      deliveryId: deliveryId,
      target: DeliveryStatus.delivered,
      remoteCall: () => _remoteDataSource.complete(
        deliveryId: deliveryId,
        proof: proofPayload,
        idempotencyKey: _operationIdGenerator(),
      ),
      operationType: 'COMPLETE',
      payload: {
        'delivery_id': deliveryId,
        'action': 'complete',
        'proof': proofPayload,
      },
    );
  }

  @override
  Future<DeliveryActionResult> createDelivery({
    required NewDelivery delivery,
  }) async {
    // MVP: nova solicitação exige conectividade (docs: comércio não cria
    // solicitação offline).
    final dto = await _remoteDataSource.createDelivery(delivery.toRequestPayload());
    await _cache.upsert(dto);
    return DeliveryActionResult(
      delivery: DeliveryMapper.fromDto(dto),
      confirmedOnServer: true,
    );
  }

  @override
  Future<DeliveryActionResult> publishDelivery(String deliveryId) async {
    final dto = await _remoteDataSource.publishDelivery(deliveryId);
    await _cache.upsert(dto);
    return DeliveryActionResult(
      delivery: DeliveryMapper.fromDto(dto),
      confirmedOnServer: true,
    );
  }

  @override
  Future<DeliveryActionResult> cancelDelivery({
    required String deliveryId,
    required String reason,
    String? description,
  }) async {
    final dto = await _remoteDataSource.cancelDelivery(
      deliveryId: deliveryId,
      reason: reason,
      description: description,
    );
    await _cache.upsert(dto);
    return DeliveryActionResult(
      delivery: DeliveryMapper.fromDto(dto),
      confirmedOnServer: true,
    );
  }

  @override
  Future<DeliveryActionResult> arriveDestination(String deliveryId) {
    return _transition(
      deliveryId: deliveryId,
      target: DeliveryStatus.atDestination,
      remoteCall: () => _remoteDataSource.arriveDestination(
        deliveryId: deliveryId,
        idempotencyKey: _operationIdGenerator(),
      ),
      operationType: 'ARRIVE_DESTINATION',
      payload: {'delivery_id': deliveryId, 'action': 'arrive-destination'},
    );
  }

  @override
  Future<DeliveryActionResult> failDelivery({
    required String deliveryId,
    required String reason,
    String? description,
  }) {
    return _transition(
      deliveryId: deliveryId,
      target: DeliveryStatus.deliveryFailed,
      remoteCall: () => _remoteDataSource.failDelivery(
        deliveryId: deliveryId,
        reason: reason,
        description: description,
        idempotencyKey: _operationIdGenerator(),
      ),
      operationType: 'FAIL',
      payload: {
        'delivery_id': deliveryId,
        'action': 'fail',
        'reason': reason,
        'description': ?description,
      },
    );
  }

  @override
  Future<DeliveryActionResult> startReturn(String deliveryId) {
    return _transition(
      deliveryId: deliveryId,
      target: DeliveryStatus.returnInProgress,
      remoteCall: () => _remoteDataSource.startReturn(
        deliveryId: deliveryId,
        idempotencyKey: _operationIdGenerator(),
      ),
      operationType: 'RETURN_START',
      payload: {'delivery_id': deliveryId, 'action': 'return-start'},
    );
  }

  @override
  Future<DeliveryActionResult> confirmReturn(String deliveryId) async {
    final dto = await _remoteDataSource.confirmReturn(deliveryId);
    await _cache.upsert(dto);
    return DeliveryActionResult(
      delivery: DeliveryMapper.fromDto(dto),
      confirmedOnServer: true,
    );
  }

  /// Transição de estado: tenta o servidor; se offline, persiste localmente
  /// e enfileira a operação na SyncQueue para sincronização posterior.
  Future<DeliveryActionResult> _transition({
    required String deliveryId,
    required DeliveryStatus target,
    required Future<DeliveryDto> Function() remoteCall,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final dto = await remoteCall();
      await _cache.upsert(dto);
      return DeliveryActionResult(
        delivery: DeliveryMapper.fromDto(dto),
        confirmedOnServer: true,
      );
    } on NetworkException {
      final updated = await _applyLocalTransition(deliveryId, target);
      await _enqueue(operationType, deliveryId, payload);
      return DeliveryActionResult(
        delivery: updated,
        confirmedOnServer: false,
      );
    }
  }

  Future<Delivery> _applyLocalTransition(
    String deliveryId,
    DeliveryStatus target,
  ) async {
    final cached = await _cache.byId(deliveryId);
    if (cached == null) {
      throw const ServerException('Entrega não disponível offline.');
    }
    final updated = cached.copyWith(status: target.wireValue);
    await _cache.upsert(updated);
    return DeliveryMapper.fromDto(updated);
  }

  Future<void> _enqueue(
    String operationType,
    String deliveryId,
    Map<String, dynamic> payload,
  ) async {
    await _syncQueue.enqueue(
      SyncOperation(
        operationId: _operationIdGenerator(),
        deviceId: _deviceId,
        entityType: 'DELIVERY',
        entityId: deliveryId,
        operationType: operationType,
        clientCreatedAt: DateTime.now().toUtc(),
        payload: payload,
      ),
    );
  }
}
