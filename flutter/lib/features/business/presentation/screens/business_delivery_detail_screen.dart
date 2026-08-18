import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/delivery/domain/delivery.dart';
import '../../../../features/delivery/presentation/delivery_detail_cubit.dart';
import '../../../../features/delivery/presentation/delivery_detail_state.dart';
import '../../../../features/delivery/presentation/delivery_labels.dart';

/// Detalhe de uma entrega no contexto do comércio.
///
/// Mostra as informações da entrega, as ofertas recebidas e as ações do
/// comércio: publicar (`DRAFT` → `OPEN`), cancelar (estados canceláveis) e
/// confirmar devolução (`RETURN_IN_PROGRESS` → `RETURNED`).
class BusinessDeliveryDetailScreen extends StatefulWidget {
  const BusinessDeliveryDetailScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  State<BusinessDeliveryDetailScreen> createState() =>
      _BusinessDeliveryDetailScreenState();
}

class _BusinessDeliveryDetailScreenState
    extends State<BusinessDeliveryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DeliveryDetailCubit>().load(widget.deliveryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da entrega')),
      body: BlocBuilder<DeliveryDetailCubit, DeliveryDetailState>(
        builder: (context, state) {
          return switch (state) {
            DeliveryDetailLoading() =>
              const Center(child: CircularProgressIndicator()),
            DeliveryDetailLocal(:final delivery) =>
              _DetailContent(delivery: delivery, local: true),
            DeliveryDetailSyncing(:final delivery) =>
              _DetailContent(delivery: delivery, syncing: true),
            DeliveryDetailSynced(:final delivery) =>
              _DetailContent(delivery: delivery),
            DeliveryDetailFailure(:final message, :final delivery?) =>
              _DetailContent(delivery: delivery, errorMessage: message),
            DeliveryDetailFailure(:final message) => _ErrorState(
                message: message,
                onRetry: () => context
                    .read<DeliveryDetailCubit>()
                    .load(widget.deliveryId),
              ),
          };
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.delivery,
    this.local = false,
    this.syncing = false,
    this.errorMessage,
  });

  final Delivery delivery;
  final bool local;
  final bool syncing;
  final String? errorMessage;

  bool get _canPublish => delivery.status == DeliveryStatus.draft;

  bool get _canCancel =>
      delivery.status == DeliveryStatus.draft ||
      delivery.status == DeliveryStatus.open ||
      delivery.status == DeliveryStatus.negotiating ||
      delivery.status == DeliveryStatus.assigned ||
      delivery.status == DeliveryStatus.driverAccepted;

  bool get _canConfirmReturn =>
      delivery.status == DeliveryStatus.returnInProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SyncBanner(local: local, syncing: syncing, errorMessage: errorMessage),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                formatCurrency(delivery.displayAmount, delivery.currency),
                style: theme.textTheme.titleLarge,
              ),
            ),
            Chip(label: Text(deliveryStatusLabel(delivery.status))),
          ],
        ),
        const SizedBox(height: 16),
        _InfoRow(
          icon: Icons.trip_origin,
          label: 'Origem',
          value: delivery.origin?.address ?? '—',
        ),
        _InfoRow(
          icon: Icons.sports_motorsports,
          label: 'Destino',
          value: delivery.destination?.address ?? '—',
        ),
        _InfoRow(
          icon: Icons.person_outline,
          label: 'Destinatário',
          value: delivery.recipient == null
              ? '—'
              : '${delivery.recipient!.name} · ${delivery.recipient!.phone}',
        ),
        if (delivery.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Itens (${delivery.items.length})',
            children: [
              for (final item in delivery.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${item.quantity}x ${item.name}'
                    '${item.category != null ? ' · ${item.category}' : ''}',
                  ),
                ),
            ],
          ),
        ],
        if (delivery.offers.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Ofertas recebidas (${delivery.offers.length})',
            children: [
              for (final offer in delivery.offers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${formatCurrency(offer.offeredAmount, delivery.currency)}'
                          ' · ${offer.status ?? 'desconhecido'}',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (_canPublish)
          FilledButton.icon(
            onPressed: () => _confirmPublish(context),
            icon: const Icon(Icons.publish),
            label: const Text('Publicar entrega'),
          ),
        if (_canConfirmReturn)
          FilledButton.icon(
            onPressed: () => _confirmReturn(context),
            icon: const Icon(Icons.assignment_return),
            label: const Text('Confirmar devolução'),
          ),
        if (_canCancel)
          OutlinedButton.icon(
            onPressed: () => _confirmCancel(context),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar entrega'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }

  Future<void> _confirmPublish(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publicar entrega'),
        content: const Text(
          'Ao publicar, a entrega ficará visível para motoboys e poderá '
          'receber ofertas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    context.read<DeliveryDetailCubit>().publish();
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final result = await showDialog<({String reason, String? description})>(
      context: context,
      builder: (_) => const _CancelDeliveryDialog(),
    );
    if (!context.mounted || result == null) return;
    context.read<DeliveryDetailCubit>().cancel(
          reason: result.reason,
          description: result.description,
        );
  }

  Future<void> _confirmReturn(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar devolução'),
        content: const Text(
          'Confirma o recebimento da mercadoria devolvida pelo motoboy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    context.read<DeliveryDetailCubit>().confirmReturn();
  }
}


/// Diálogo de cancelamento (comércio) — motivo obrigatório.
class _CancelDeliveryDialog extends StatefulWidget {
  const _CancelDeliveryDialog();

  @override
  State<_CancelDeliveryDialog> createState() => _CancelDeliveryDialogState();
}

class _CancelDeliveryDialogState extends State<_CancelDeliveryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _reason = 'NO_LONGER_NEEDED';

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      reason: _reason,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar entrega'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'NO_LONGER_NEEDED',
                  child: Text('Não preciso mais'),
                ),
                DropdownMenuItem(
                  value: 'WRONG_ADDRESS',
                  child: Text('Endereço incorreto'),
                ),
                DropdownMenuItem(
                  value: 'CUSTOMER_REQUEST',
                  child: Text('Solicitação do cliente'),
                ),
                DropdownMenuItem(
                  value: 'OPERATIONAL_ISSUE',
                  child: Text('Problema operacional'),
                ),
              ],
              onChanged: (value) => setState(() => _reason = value ?? _reason),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Cancelar entrega'),
        ),
      ],
    );
  }
}


class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({
    required this.local,
    required this.syncing,
    this.errorMessage,
  });

  final bool local;
  final bool syncing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label, color) = switch ((local, syncing, errorMessage)) {
      (true, _, _) => (
          Icons.cloud_off_outlined,
          'Salvo localmente — aguardando sincronização.',
          scheme.tertiary,
        ),
      (false, true, _) => (
          Icons.sync,
          'Sincronizando com o servidor...',
          scheme.primary,
        ),
      (false, false, String message) => (
          Icons.error_outline,
          message,
          scheme.error,
        ),
      _ => (Icons.cloud_done_outlined, 'Sincronizado', scheme.primary),
    };

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

