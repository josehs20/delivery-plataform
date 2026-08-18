import 'package:geolocator/geolocator.dart';

import 'location_point.dart';
import 'location_service.dart';

/// Implementação do [LocationService] com o plugin `geolocator`.
///
/// O SDK externo fica isolado atrás da interface; nada além desta classe
/// depende do plugin.
final class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService({
    this.accuracy = LocationAccuracy.high,
    this.positionTimeLimit,
  });

  final LocationAccuracy accuracy;
  final Duration? positionTimeLimit;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    return _mapPermission(await Geolocator.requestPermission());
  }

  @override
  Future<LocationPermissionStatus> permissionStatus() async {
    return _mapPermission(await Geolocator.checkPermission());
  }

  @override
  Future<bool> isGpsEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPoint?> currentPosition() async {
    if (await permissionStatus() != LocationPermissionStatus.granted) {
      return null;
    }
    if (!await isGpsEnabled()) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: _settings(),
    );
    return _toPoint(position);
  }

  @override
  Stream<LocationPoint> track({
    String? deliveryId,
    int distanceFilterMeters = 5,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((position) => _toPoint(position, deliveryId: deliveryId));
  }

  LocationSettings _settings() {
    return LocationSettings(
      accuracy: accuracy,
      timeLimit: positionTimeLimit,
    );
  }

  static LocationPoint _toPoint(Position position, {String? deliveryId}) {
    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      recordedAt: position.timestamp.toUtc(),
      deliveryId: deliveryId,
    );
  }

  static LocationPermissionStatus _mapPermission(
    LocationPermission permission,
  ) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationPermissionStatus.granted,
      LocationPermission.denied => LocationPermissionStatus.denied,
      LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      LocationPermission.unableToDetermine =>
        LocationPermissionStatus.unknown,
    };
  }
}
