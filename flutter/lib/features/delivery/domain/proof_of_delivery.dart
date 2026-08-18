import 'dart:convert';
import 'dart:typed_data';

/// Tipo de evidência da prova de entrega (valores do backend).
enum ProofType {
  signature,
  photo;

  /// Valor serializado esperado pelo backend (`proof.type`).
  String get wireValue => name.toUpperCase();
}

/// Prova de entrega (PoD) — assinatura desenhada localmente ou foto.
///
/// A captura é local e offline-first: a evidência é persistida/enfileirada e
/// sincronizada depois (`SyncQueue` + `SyncWorker`). O upload de mídia pesada
/// é separado do evento (docs/flutter/docs/08-synchronization.md).
final class ProofOfDelivery {
  const ProofOfDelivery({
    required this.type,
    this.signatureBytes,
    this.localPhotoPath,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.notes,
  }) : assert(type != ProofType.signature || signatureBytes != null,
            'Assinatura exige bytes capturados');

  final ProofType type;

  /// Bytes PNG da assinatura desenhada (quando [type] == signature).
  final Uint8List? signatureBytes;

  /// Caminho local da foto (quando [type] == photo).
  final String? localPhotoPath;

  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final String? notes;

  bool get hasCapture =>
      (type == ProofType.signature && signatureBytes != null) ||
      (type == ProofType.photo && (localPhotoPath?.isNotEmpty ?? false));

  /// Payload do `proof` no contrato de `complete`/sync (type + data).
  Map<String, dynamic> toPayload() => {
        'type': type.wireValue,
        'data': signatureBytes != null
            ? 'data:image/png;base64,${base64Encode(signatureBytes!)}'
            : (localPhotoPath ?? ''),
        'captured_at': capturedAt.toUtc().toIso8601String(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes != null) 'notes': notes,
      };
}
