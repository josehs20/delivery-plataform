import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/location/location_point.dart';
import '../../../core/location/location_service.dart';
import '../domain/tracking_repository.dart';
import 'tracking_state.dart';

/// Orquestra o rastreamento da entrega ativa (motoboy).
///
/// - valida permissão/GPS antes de iniciar;
/// - assina o stream do repositório (que já enfileira cada amostra na
///   SyncQueue — offline-first) e reflete a posição mais recente na UI;
/// - `stop()` encerra a assinatura sem apagar os pontos já enfileirados.
class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit(this._repository) : super(const TrackingState.idle());

  final TrackingRepository _repository;

  StreamSubscription<LocationPoint>? _subscription;

  /// Inicia o rastreamento da entrega. Lida com permissão/GPS explicitamente.
  Future<void> start({required String deliveryId}) async {
    emit(state.copyWith(status: TrackingStatus.requestingPermission));

    final permission = await _repository.requestPermission();
    if (permission != LocationPermissionStatus.granted) {
      emit(state.copyWith(status: TrackingStatus.permissionDenied));
      return;
    }

    if (!await _repository.isGpsEnabled()) {
      emit(state.copyWith(status: TrackingStatus.gpsDisabled));
      return;
    }

    await _subscription?.cancel();
    _subscription = _repository
        .track(deliveryId: deliveryId)
        .listen(_onPoint, onError: (Object _) {
      if (isClosed) return;
      emit(state.copyWith(
        status: TrackingStatus.stopped,
        errorMessage: 'Falha ao capturar a localização.',
      ));
    });

    emit(state.copyWith(
      status: TrackingStatus.tracking,
      errorMessage: null,
    ));
  }

  /// Encerra o rastreamento (mantém os pontos já enfileirados).
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!isClosed) {
      emit(state.copyWith(status: TrackingStatus.stopped));
    }
  }

  void _onPoint(LocationPoint point) {
    if (isClosed) return;
    emit(state.copyWith(
      status: TrackingStatus.tracking,
      lastPoint: point,
      pointsRecorded: state.pointsRecorded + 1,
      errorMessage: null,
    ));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    await super.close();
  }
}
