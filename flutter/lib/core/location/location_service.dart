import 'location_point.dart';

/// Status da permissão de localização.
enum LocationPermissionStatus {
  /// Permissão concedida (quando em uso ou sempre).
  granted,

  /// Permissão negada (pode ser solicitada novamente).
  denied,

  /// Negada permanentemente — o usuário precisa configurar nas ajustes.
  deniedForever,

  /// Restrita pela plataforma (ex.: parental controls).
  restricted,

  /// Indefinido pela plataforma.
  unknown;
}

/// Serviço de localização encapsulado atrás de interface (provider externo
/// isolado — regra de arquitetura).
///
/// Regras (docs/flutter/docs/09-location.md):
/// - solicitar permissões explicitamente e lidar com negado/restrito;
/// - distinguir GPS desabilitado de indisponibilidade de internet;
/// - registrar coordenadas com timestamp;
/// - rastrear somente quando permitido e necessário (bateria/dados).
abstract interface class LocationService {
  /// Solicita a permissão de localização ao usuário.
  Future<LocationPermissionStatus> requestPermission();

  /// Estado atual da permissão.
  Future<LocationPermissionStatus> permissionStatus();

  /// `true` quando o GPS (serviço de localização) está habilitado.
  Future<bool> isGpsEnabled();

  /// Posição atual (one-shot) com timestamp.
  ///
  /// Retorna `null` quando a permissão não foi concedida ou o GPS está
  /// desabilitado (falha silenciosa de permissão — a UI deve guiar o usuário).
  Future<LocationPoint?> currentPosition();

  /// Rastreamento contínuo associado a uma entrega ativa.
  ///
  /// Cada amostra carrega o `deliveryId` como contexto. O filtro de distância
  /// (em metros) evita amostragem excessiva e poupa bateria/dados.
  Stream<LocationPoint> track({
    String? deliveryId,
    int distanceFilterMeters = 5,
  });
}
