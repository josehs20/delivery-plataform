import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Área de desenho de assinatura com captura em PNG (bytes locais).
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    this.height = 180,
    this.backgroundColor = Colors.white,
  });

  final double height;
  final Color backgroundColor;

  @override
  SignaturePadState createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  Size _canvasSize = const Size(400, 180);

  bool get isEmpty => _strokes.isEmpty;

  void clear() {
    setState(() {
      _strokes.clear();
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _strokes.add([details.localPosition]));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _strokes.last.add(details.localPosition));
  }

  /// Captura a assinatura em bytes PNG; `null` quando vazia.
  Future<Uint8List?> toPngBytes({int pixelRatio = 2}) async {
    if (_strokes.isEmpty) return null;

    // Dentro de scrollables o LayoutBuilder pode reportar dimensões
    // infinitas; o tamanho real do quadro é usado como fallback.
    final width = (_canvasSize.width.isFinite ? _canvasSize.width : 400) *
        pixelRatio;
    final height = (_canvasSize.height.isFinite ? _canvasSize.height : 180) *
        pixelRatio;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(
      width / (_canvasSize.width.isFinite ? _canvasSize.width : 400),
      height / (_canvasSize.height.isFinite ? _canvasSize.height : 180),
    );
    canvas.drawRect(
      Offset.zero & _canvasSize,
      Paint()..color = widget.backgroundColor,
    );

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      for (var i = 0; i + 1 < stroke.length; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.round(), height.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : widget.height * 2,
          constraints.maxHeight.isFinite ? constraints.maxHeight : widget.height,
        );
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              child: CustomPaint(
                painter: _SignaturePainter(_strokes),
                child: isEmpty
                    ? const Center(child: Text('Desenhe sua assinatura aqui'))
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (var i = 0; i + 1 < stroke.length; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
