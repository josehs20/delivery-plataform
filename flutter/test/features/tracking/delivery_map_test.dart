import 'dart:typed_data';

import 'package:delivery_app/features/tracking/presentation/widgets/delivery_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// PNG 1x1 transparente — evita requisições de rede nos testes.
final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

class _NoOpTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPng);
}

Future<void> _pumpMap(WidgetTester tester, DeliveryMap map) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, height: 400, child: map),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const pickup = LatLng(-20.3155, -40.3128);
  const destination = LatLng(-20.4200, -40.5000);
  const driver = LatLng(-20.3500, -40.4000);

  testWidgets('renders pickup, destination and driver markers', (tester) async {
    await _pumpMap(
      tester,
      DeliveryMap(
        pickup: pickup,
        destination: destination,
        driver: driver,
        tileProvider: _NoOpTileProvider(),
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Coleta'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    expect(find.text('Entregador'), findsOneWidget);
  });

  testWidgets('hides the driver marker when no driver position is provided',
      (tester) async {
    await _pumpMap(
      tester,
      DeliveryMap(
        pickup: pickup,
        destination: destination,
        tileProvider: _NoOpTileProvider(),
      ),
    );

    expect(find.text('Coleta'), findsOneWidget);
    expect(find.text('Destino'), findsOneWidget);
    expect(find.text('Entregador'), findsNothing);
  });

  testWidgets('draws the route polyline between pickup and destination',
      (tester) async {
    await _pumpMap(
      tester,
      DeliveryMap(
        pickup: pickup,
        destination: destination,
        showRoute: true,
        tileProvider: _NoOpTileProvider(),
      ),
    );

    expect(find.byType(PolylineLayer), findsOneWidget);
  });

  testWidgets('omits the route polyline when showRoute is false',
      (tester) async {
    await _pumpMap(
      tester,
      DeliveryMap(
        pickup: pickup,
        destination: destination,
        showRoute: false,
        tileProvider: _NoOpTileProvider(),
      ),
    );

    expect(find.byType(PolylineLayer), findsNothing);
  });
}
