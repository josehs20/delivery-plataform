import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/proof_of_delivery.dart';
import 'signature_pad.dart';

/// Abstração de captura de foto (isolada para fakes nos testes).
abstract interface class PhotoPicker {
  Future<String?> pickPhotoPath();
}

/// Implementação padrão usando o plugin `image_picker`.
final class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickPhotoPath() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    return file?.path;
  }
}

/// Abre o modal de prova de entrega e devolve a prova capturada
/// (ou `null` quando cancelado).
Future<ProofOfDelivery?> showProofOfDeliveryModal(
  BuildContext context, {
  PhotoPicker? photoPicker,
}) {
  return showModalBottomSheet<ProofOfDelivery>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ProofOfDeliveryModal(photoPicker: photoPicker),
  );
}

class _ProofOfDeliveryModal extends StatefulWidget {
  const _ProofOfDeliveryModal({this.photoPicker});

  final PhotoPicker? photoPicker;

  @override
  State<_ProofOfDeliveryModal> createState() => _ProofOfDeliveryModalState();
}

class _ProofOfDeliveryModalState extends State<_ProofOfDeliveryModal> {
  final _padKey = GlobalKey<SignaturePadState>();
  ProofType _type = ProofType.signature;
  String? _photoPath;
  bool _busy = false;
  final _notesController = TextEditingController();

  PhotoPicker get _photoPicker =>
      widget.photoPicker ?? ImagePickerPhotoPicker();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final proof = await _buildProof();
      if (proof == null) return; // validação falhou; mensagem já exibida

      if (!mounted) return;
      Navigator.of(context).pop(proof);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<ProofOfDelivery?> _buildProof() async {
    final capturedAt = DateTime.now().toUtc();
    if (_type == ProofType.signature) {
      final pad = _padKey.currentState;
      final bytes = pad == null ? null : await pad.toPngBytes();
      if (bytes == null || bytes.isEmpty) {
        _showMessage('Desenhe sua assinatura antes de confirmar.');
        return null;
      }
      return ProofOfDelivery(
        type: ProofType.signature,
        signatureBytes: bytes,
        capturedAt: capturedAt,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    }

    if (_photoPath == null || _photoPath!.isEmpty) {
      _showMessage('Selecione uma foto antes de confirmar.');
      return null;
    }
    return ProofOfDelivery(
      type: ProofType.photo,
      localPhotoPath: _photoPath,
      capturedAt: capturedAt,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  Future<void> _selectPhoto() async {
    setState(() => _busy = true);
    try {
      final path = await _photoPicker.pickPhotoPath();
      if (mounted && path != null) {
        setState(() => _photoPath = path);
      }
    } catch (_) {
      if (mounted) _showMessage('Não foi possível selecionar a foto.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Prova de entrega',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<ProofType>(
                segments: const [
                  ButtonSegment(
                    value: ProofType.signature,
                    label: Text('Assinatura'),
                    icon: Icon(Icons.draw_outlined),
                  ),
                  ButtonSegment(
                    value: ProofType.photo,
                    label: Text('Foto'),
                    icon: Icon(Icons.photo_camera_outlined),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _busy
                    ? null
                    : (selection) => setState(() => _type = selection.first),
              ),
              const SizedBox(height: 16),
              if (_type == ProofType.signature)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SignaturePad(key: _padKey),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _busy ? null : _padKey.currentState?.clear,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Limpar'),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _selectPhoto,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                        _photoPath == null
                            ? 'Selecionar foto'
                            : 'Foto selecionada',
                      ),
                    ),
                    if (_photoPath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _photoPath!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                enabled: !_busy,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _confirm,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Confirmar entrega'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

