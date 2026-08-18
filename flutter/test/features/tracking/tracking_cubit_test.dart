import 'dart:async';

import 'package:delivery_app/core/location/location_point.dart';
import 'package:delivery_app/core/location/location_service.dart';
import 'package:delivery_app/features/tracking/domain/tracking_repository.dart';
import 'package:delivery_app/features/tracking/presentation/tracking_cubit.dart';
import 'package:delivery_app/features/tracking/presentation/tracking_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTrackingRepository implements TrackingRepository {
  _FakeTrackingRepository({
    this.permission = LocationPermissionStatus.granted,
    this.gpsEnabled = true,
    this.points = const [],
  });

  final LocationPermissionStatus permission;
  final bool gpsEnabled;
  final List<LocationPoint> points;

  final _controller = StreamController<LocationPoint>.broadcast();
  int trackCalls = 0;

  @override
  Future<LocationPermissionStatus> requestPermission() async => permission;

  @override
  Future<LocationPermissionStatus> permissionStatus() async => permission;

  @override
  Future<bool> isGpsEnabled() async => gpsEnabled;

  @override
  Stream<LocationPoint> track({
    required String deliveryId,
    int distanceFilterMeters = 10,
  }) {
    trackCalls++;
    return _controller.stream;
  }

  void emit(LocationPoint point) => _controller.add(point);

  Future<void> close() => _controller.close();
}

LocationPoint _point(double latitude) => LocationPoint(
      latitude: latitude,
      longitude: -40.0,
      recordedAt: DateTime.utc(2026, 8, 17, 12),
      accuracy: 10,
    );

void main() {
  test('initial state is idle', () {
    final cubit = TrackingCubit(
      _FakeTrackingRepository(),
    );
    expect(cubit.state.status, TrackingStatus.idle);
    cubit.close();
  });

  test('start emits tracking and counts points', () async {
    final repo = _FakeTrackingRepository(points: const []);
    final cubit = TrackingCubit(repo);
    addTearDown(cubit.close);

    final future = cubit.start(deliveryId: 'd1');
    // Aguarda o início (permissão/GPS) sem pontos ainda.
    await Future<void>.delayed(Duration.zero);
    await future;

    expect(cubit.state.status, TrackingStatus.tracking);

    repo.emit(_point(-20.1));
    await Future<void>.delayed(Duration.zero);
    repo.emit(_point(-20.2));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.pointsRecorded, 2);
    expect(cubit.state.lastPoint!.latitude, -20.2);
    expect(repo.trackCalls, 1);
  });

  test('start with denied permission emits permissionDenied', () async {
    final cubit = TrackingCubit(
      _FakeTrackingRepository(permission: LocationPermissionStatus.denied),
    );
    addTearDown(cubit.close);

    await cubit.start(deliveryId: 'd1');

    expect(cubit.state.status, TrackingStatus.permissionDenied);
  });

  test('start with gps disabled emits gpsDisabled', () async {
    final cubit = TrackingCubit(
      _FakeTrackingRepository(gpsEnabled: false),
    );
    addTearDown(cubit.close);

    await cubit.start(deliveryId: 'd1');

    expect(cubit.state.status, TrackingStatus.gpsDisabled);
  });

  test('stop emits stopped and does not reset recorded points', () async {
    final repo = _FakeTrackingRepository();
    final cubit = TrackingCubit(repo);
    addTearDown(cubit.close);

    await cubit.start(deliveryId: 'd1');
    repo.emit(_point(-20.1));
    await Future<void>.delayed(Duration.zero);

    await cubit.stop();

    expect(cubit.state.status, TrackingStatus.stopped);
    expect(cubit.state.pointsRecorded, 1);
  });
}
