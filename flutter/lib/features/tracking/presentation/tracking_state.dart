import '../../../core/location/location_point.dart';

/// Situação do rastreamento na tela do motoboy.
enum TrackingStatus {
  /// Rastreamento não iniciado.
  idle,

  /// Solicitando permissão de localização.
  requestingPermission,

  /// Permissão negada/restrita — orientar o usuário.
  permissionDenied,

  /// GPS desabilitado.
  gpsDisabled,

  /// Rastreando (stream de posições ativo).
  tracking,

  /// Rastreamento encerrado manualmente.
  stopped,
}

/// Estado reativo do rastreamento.
final class TrackingState {
  const TrackingState({
    required this.status,
    this.lastPoint,
    this.pointsRecorded = 0,
    this.errorMessage,
  });

  final TrackingStatus status;
  final LocationPoint? lastPoint;
  final int pointsRecorded;
  final String? errorMessage;

  bool get isTracking => status == TrackingStatus.tracking;

  const TrackingState.idle() : this(status: TrackingStatus.idle);

  TrackingState copyWith({
    TrackingStatus? status,
    LocationPoint? lastPoint,
    int? pointsRecorded,
    String? errorMessage,
  }) {
    return TrackingState(
      status: status ?? this.status,
      lastPoint: lastPoint ?? this.lastPoint,
      pointsRecorded: pointsRecorded ?? this.pointsRecorded,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
