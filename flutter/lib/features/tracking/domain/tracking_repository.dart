import '../../../core/location/location_point.dart';
import '../../../core/location/location_service.dart';

/// Contrato da feature de rastreamento (motoboy).
///
/// Conecta o [LocationService] (GPS, encapsulado) à fila de sincronização
/// offline (`entity_type=LOCATION`, contrato `POST /sync`), associando cada
/// amostra à entrega em andamento.
abstract interface class TrackingRepository {
  /// Solicita a permissão de localização ao usuário.
  Future<LocationPermissionStatus> requestPermission();

  /// Estado atual da permissão de localização.
  Future<LocationPermissionStatus> permissionStatus();

  /// `true` quando o GPS está habilitado.
  Future<bool> isGpsEnabled();

  /// Stream de pontos de localização associados à entrega, persistidos
  /// localmente na SyncQueue (offline-first) antes de qualquer confirmação.
  Stream<LocationPoint> track({
    required String deliveryId,
    int distanceFilterMeters = 10,
  });
}
