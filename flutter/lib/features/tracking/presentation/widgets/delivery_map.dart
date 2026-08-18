import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mapa reutilizável da entrega: renderiza a coleta, o destino e (quando
/// disponível) a posição do entregador.
///
/// O provider de tiles é injetável (testes); por padrão usa OpenStreetMap.
class DeliveryMap extends StatelessWidget {
  const DeliveryMap({
    super.key,
    required this.pickup,
    required this.destination,
    this.driver,
    this.showRoute = true,
    this.tileProvider,
  });

  /// Coordenadas do ponto de coleta.
  final LatLng pickup;

  /// Coordenadas do destino.
  final LatLng destination;

  /// Posição atual do entregador (opcional).
  final LatLng? driver;

  /// Desenha a linha (rota estimada) entre coleta e destino.
  final bool showRoute;

  /// Provider de tiles do mapa (injetável; default OSM).
  final TileProvider? tileProvider;

  LatLngBounds get _bounds => LatLngBounds.fromPoints([
        pickup,
        destination,
        ?driver,
      ]);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: _bounds,
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
        initialZoom: 14,
        minZoom: 3,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.com.delivery_app',
          tileProvider: tileProvider,
        ),
        if (showRoute)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [pickup, destination],
                strokeWidth: 3,
                color: scheme.primary.withValues(alpha: 0.7),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: pickup,
              width: 96,
              height: 64,
              alignment: Alignment.topCenter,
              child: _MarkerPin(
                icon: Icons.trip_origin,
                color: Colors.green,
                label: 'Coleta',
              ),
            ),
            Marker(
              point: destination,
              width: 96,
              height: 64,
              alignment: Alignment.topCenter,
              child: _MarkerPin(
                icon: Icons.sports_motorsports,
                color: Colors.red,
                label: 'Destino',
              ),
            ),
            if (driver != null)
              Marker(
                point: driver!,
                width: 96,
                height: 64,
                alignment: Alignment.topCenter,
                child: _MarkerPin(
                  icon: Icons.navigation,
                  color: Colors.blue,
                  label: 'Entregador',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MarkerPin extends StatelessWidget {
  const _MarkerPin({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(blurRadius: 4, color: Colors.black26),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
