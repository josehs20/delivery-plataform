import 'package:uuid/uuid.dart';

import '../../../core/location/location_point.dart';
import '../../../core/location/location_service.dart';
import '../../../core/sync/sync_operation.dart';
import '../../../core/sync/sync_queue.dart';
import '../domain/tracking_repository.dart';

/// Implementação do [TrackingRepository].
///
/// - Encapsula o [LocationService] (GPS);
/// - enfileira cada amostra válida na [SyncQueue] como `entity_type=LOCATION`,
///   `operation=CREATE`, com `client_event_id` idempotente (o servidor
///   deduplica por `operation_id` + `client_id`);
/// - nunca confirma o envio: a persistência local é offline-first e o servidor
///   reconcilia.
final class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl(
    this._locationService,
    this._syncQueue,
    this._deviceId, {
    String Function()? eventIdGenerator,
  }) : _eventIdGenerator = eventIdGenerator ?? _uuidV4;

  static String _uuidV4() => const Uuid().v4();

  final LocationService _locationService;
  final SyncQueue _syncQueue;
  final String _deviceId;
  final String Function() _eventIdGenerator;

  @override
  Future<LocationPermissionStatus> requestPermission() =>
      _locationService.requestPermission();

  @override
  Future<LocationPermissionStatus> permissionStatus() =>
      _locationService.permissionStatus();

  @override
  Future<bool> isGpsEnabled() => _locationService.isGpsEnabled();

  @override
  Stream<LocationPoint> track({
    required String deliveryId,
    int distanceFilterMeters = 10,
  }) {
    return _locationService
        .track(deliveryId: deliveryId, distanceFilterMeters: distanceFilterMeters)
        .where((point) => point.isValid(maxAccuracyMeters: 150))
        .asyncMap((point) async {
      await _enqueueLocation(deliveryId, point);
      return point;
    });
  }

  Future<void> _enqueueLocation(String deliveryId, LocationPoint point) async {
    final clientEventId = point.clientEventId ?? _eventIdGenerator();
    final operationId = clientEventId;

    final payload = {
      'delivery_id': deliveryId,
      'latitude': point.latitude,
      'longitude': point.longitude,
      if (point.accuracy != null) 'accuracy': point.accuracy,
      if (point.speed != null) 'speed': point.speed,
      if (point.heading != null) 'heading': point.heading,
      'recorded_at': point.recordedAt.toUtc().toIso8601String(),
    };

    await _syncQueue.enqueue(
      SyncOperation(
        operationId: operationId,
        deviceId: _deviceId,
        entityType: 'LOCATION',
        entityId: deliveryId,
        operationType: 'CREATE',
        clientCreatedAt: DateTime.now().toUtc(),
        payload: payload,
      ),
    );
  }
}
