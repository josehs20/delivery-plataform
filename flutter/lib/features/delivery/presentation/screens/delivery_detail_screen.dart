import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes/app_routes.dart';
import '../../domain/delivery.dart';
import '../delivery_detail_cubit.dart';
import '../delivery_detail_state.dart';
import '../delivery_labels.dart';
import '../widgets/proof_of_delivery_modal.dart';

/// Detalhe da entrega ativa com as ações do motoboy
/// (chegada na coleta → coleta → entrega com prova).
class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
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
                onRetry: () =>
                    context.read<DeliveryDetailCubit>().load(widget.deliveryId),
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

  bool get _canRegisterArrival =>
      delivery.status == DeliveryStatus.assigned ||
      delivery.status == DeliveryStatus.driverAccepted ||
      delivery.status == DeliveryStatus.goingToPickup;

  bool get _canConfirmPickup => delivery.status == DeliveryStatus.atPickup;

  bool get _canArriveDestination =>
      delivery.status == DeliveryStatus.pickedUp ||
      delivery.status == DeliveryStatus.inTransit;

  bool get _canConfirmDelivery =>
      delivery.status == DeliveryStatus.inTransit ||
      delivery.status == DeliveryStatus.atDestination;

  bool get _canFail =>
      delivery.status == DeliveryStatus.pickedUp ||
      delivery.status == DeliveryStatus.inTransit ||
      delivery.status == DeliveryStatus.atDestination;

  bool get _canStartReturn =>
      delivery.status == DeliveryStatus.deliveryFailed ||
      delivery.status == DeliveryStatus.returnRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<DeliveryDetailCubit>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SyncBanner(
          local: local,
          syncing: syncing,
          errorMessage: errorMessage,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                formatCurrency(delivery.displayAmount, delivery.currency),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Chip(label: Text(deliveryStatusLabel(delivery.status))),
          ],
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'Endereços',
          children: [
            _InfoRow(
              icon: Icons.trip_origin,
              label: 'Coleta',
              value: delivery.origin?.address ?? '—',
            ),
            _InfoRow(
              icon: Icons.sports_motorsports,
              label: 'Destino',
              value: delivery.destination?.address ?? '—',
            ),
          ],
        ),
        if (delivery.recipient != null)
          _Section(
            title: 'Destinatário',
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Nome',
                value: delivery.recipient!.name,
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone',
                value: delivery.recipient!.phone,
              ),
            ],
          ),
        if (delivery.items.isNotEmpty)
          _Section(
            title: 'Itens',
            children: [
              for (final item in delivery.items)
                _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: item.name,
                  value: 'x${item.quantity}',
                ),
            ],
          ),
        const SizedBox(height: 24),
        if (DeliveryStatus.active.contains(delivery.status))
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.trackingFor(delivery.id),
            ),
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Rastrear entrega'),
          ),
        if (_canRegisterArrival)
          FilledButton.icon(
            onPressed: () => cubit.registerPickupArrival(),
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('Cheguei na coleta'),
          ),
        if (_canConfirmPickup)
          FilledButton.icon(
            onPressed: () => cubit.confirmPickup(),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Confirmar coleta'),
          ),
        if (_canArriveDestination)
          FilledButton.icon(
            onPressed: () => cubit.registerDestinationArrival(),
            icon: const Icon(Icons.location_city_outlined),
            label: const Text('Cheguei ao destino'),
          ),
        if (_canConfirmDelivery)
          FilledButton.icon(
            onPressed: () => _openProofModal(context),
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Confirmar entrega'),
          ),
        if (_canFail)
          OutlinedButton.icon(
            onPressed: () => _openFailModal(context),
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Registrar falha na entrega'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        if (_canStartReturn)
          OutlinedButton.icon(
            onPressed: () => _confirmStartReturn(context),
            icon: const Icon(Icons.assignment_return_outlined),
            label: const Text('Iniciar devolução'),
          ),
        if (delivery.status == DeliveryStatus.delivered ||
            delivery.status == DeliveryStatus.returned)
          const _DoneBanner(),
      ],
    );
  }

  Future<void> _openProofModal(BuildContext context) async {
    final proof = await showProofOfDeliveryModal(context);
    if (!context.mounted) return;
    if (proof != null) {
      context.read<DeliveryDetailCubit>().confirmDelivery(proof);
    }
  }

  Future<void> _openFailModal(BuildContext context) async {
    final result = await showDialog<({String reason, String? description})>(
      context: context,
      builder: (_) => const _FailDeliveryDialog(),
    );
    if (!context.mounted || result == null) return;
    context.read<DeliveryDetailCubit>().failDelivery(
          reason: result.reason,
          description: result.description,
        );
  }

  Future<void> _confirmStartReturn(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Iniciar devolução'),
        content: const Text(
          'Confirma que vai devolver a mercadoria ao comércio?',
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
    context.read<DeliveryDetailCubit>().startReturn();
  }
}

/// Diálogo de falha: exige motivo e aceita uma descrição opcional.
class _FailDeliveryDialog extends StatefulWidget {
  const _FailDeliveryDialog();

  @override
  State<_FailDeliveryDialog> createState() => _FailDeliveryDialogState();
}

class _FailDeliveryDialogState extends State<_FailDeliveryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      reason: _reasonController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Falha na entrega'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _reasonController,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motivo da falha',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Informe o motivo da falha.';
                if (v.length > 500) {
                  return 'O motivo não pode exceder 500 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detalhes (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Registrar falha'),
        ),
      ],
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({
    this.local = false,
    this.syncing = false,
    this.errorMessage,
  });

  final bool local;
  final bool syncing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget content;
    if (errorMessage != null) {
      content = _row(Icons.error_outline, errorMessage!, scheme.error);
    } else if (local) {
      content = _row(
        Icons.cloud_off_outlined,
        'Salvo localmente — aguardando sincronização',
        scheme.tertiary,
      );
    } else if (syncing) {
      content = const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Expanded(child: Text('Sincronizando...')),
        ],
      );
    } else {
      content = _row(Icons.cloud_done_outlined, 'Sincronizado', scheme.primary);
    }

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.all(12), child: content),
    );
  }

  Widget _row(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
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

class _DoneBanner extends StatelessWidget {
  const _DoneBanner();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Color(0xFFE6F4EA),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF1E8E3E)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Entrega concluída com sucesso.',
                style: TextStyle(color: Color(0xFF1E8E3E)),
              ),
            ),
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

