import 'package:delivery_app/features/delivery/domain/proof_of_delivery.dart';
import 'package:delivery_app/features/delivery/presentation/widgets/proof_of_delivery_modal.dart';
import 'package:delivery_app/features/delivery/presentation/widgets/signature_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePhotoPicker implements PhotoPicker {
  @override
  Future<String?> pickPhotoPath() async => '/tmp/photo.jpg';
}

ProofOfDelivery? _result;

Future<void> _openModal(
  WidgetTester tester, {
  PhotoPicker? photoPicker,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                _result =
                    await showProofOfDeliveryModal(context, photoPicker: photoPicker);
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Confirmar entrega'));
  await tester.tap(find.text('Confirmar entrega'));
  // O PNG da assinatura é codificado fora do zone de fake-async.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _result = null;
  });

  testWidgets('opens with signature and photo options', (tester) async {
    await _openModal(tester);

    expect(find.text('Prova de entrega'), findsOneWidget);
    expect(find.text('Assinatura'), findsOneWidget);
    expect(find.text('Foto'), findsOneWidget);
    expect(find.byType(SignaturePad), findsOneWidget);
    expect(find.text('Confirmar entrega'), findsOneWidget);
  });

  testWidgets('confirm without signature shows a validation message',
      (tester) async {
    await _openModal(tester);

    await _confirm(tester);

    expect(find.text('Desenhe sua assinatura antes de confirmar.'),
        findsOneWidget);
    expect(_result, isNull);
  });

  testWidgets('drawing a signature and confirming returns a proof',
      (tester) async {
    await _openModal(tester);

    final pad = find.byType(SignaturePad);
    expect(find.text('Desenhe sua assinatura aqui'), findsOneWidget);

    await tester.drag(pad, const Offset(60, 20));
    await tester.pump();
    expect(find.text('Desenhe sua assinatura aqui'), findsNothing);

    await _confirm(tester);

    expect(_result, isNotNull);
    expect(_result!.type, ProofType.signature);
    expect(_result!.hasCapture, isTrue);
  });

  testWidgets('photo flow with a fake picker returns a photo proof',
      (tester) async {
    await _openModal(tester, photoPicker: _FakePhotoPicker());
    await tester.tap(find.text('Foto'));
    await tester.pumpAndSettle();
    expect(find.text('Selecionar foto'), findsOneWidget);

    await tester.tap(find.text('Selecionar foto'));
    await tester.pumpAndSettle();
    expect(find.text('Foto selecionada'), findsOneWidget);

    await _confirm(tester);

    expect(_result, isNotNull);
    expect(_result!.type, ProofType.photo);
    expect(_result!.localPhotoPath, '/tmp/photo.jpg');
  });
}
