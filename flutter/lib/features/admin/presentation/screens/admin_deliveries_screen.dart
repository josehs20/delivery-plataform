import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/delivery/domain/delivery.dart';
import '../../../../features/delivery/presentation/delivery_labels.dart';
import '../../domain/admin_models.dart';
import '../../domain/admin_repository.dart';
import '../cubits/admin_deliveries_cubit.dart';

/// Módulo "Gestão de Entregas" — torre de controle com busca, filtros e ações
/// administrativas (atribuir motorista / cancelar).
class AdminDeliveriesScreen extends StatefulWidget {
  const AdminDeliveriesScreen({super.key});

  @override
  State<AdminDeliveriesScreen> createState() => _AdminDeliveriesScreenState();
}

class _AdminDeliveriesScreenState extends State<AdminDeliveriesScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminDeliveriesCubit>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<AdminDeliveriesCubit>().load(
      filters: AdminDeliveryFilters(
        status: _statusFilter,
        search: _searchController.text.trim(),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _statusFilter = null);
    context.read<AdminDeliveriesCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminDeliveriesCubit, AdminDeliveriesState>(
      listenWhen: (previous, current) =>
          current is AdminDeliveriesLoaded && current.message != null,
      listener: (context, state) {
        final message = (state as AdminDeliveriesLoaded).message;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message ?? '')));
      },
      child: Column(
        children: [
          _buildFilterBar(context),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<AdminDeliveriesCubit, AdminDeliveriesState>(
              builder: (context, state) {
                return switch (state) {
                  AdminDeliveriesLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  AdminDeliveriesFailure(:final message) => _ErrorRetry(
                      message: message,
                      onRetry: () =>
                          context.read<AdminDeliveriesCubit>().load(),
                    ),
                  AdminDeliveriesLoaded(
                    :final deliveries,
                    :final actionInProgress,
                  ) =>
                    _buildList(context, deliveries, actionInProgress),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por destinatário ou telefone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String?>(
            value: _statusFilter,
            hint: const Text('Status'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              for (final status in DeliveryStatus.values)
                if (status != DeliveryStatus.unknown)
                  DropdownMenuItem<String?>(
                    value: status.wireValue,
                    child: Text(deliveryStatusLabel(status)),
                  ),
            ],
            onChanged: (value) {
              setState(() => _statusFilter = value);
              _applyFilters();
            },
          ),
          IconButton(
            tooltip: 'Limpar filtros',
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<AdminDelivery> deliveries,
    bool actionInProgress,
  ) {
    if (deliveries.isEmpty) {
      return const Center(child: Text('Nenhuma entrega encontrada.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: deliveries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.local_shipping_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              delivery.recipientName ?? delivery.id,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                delivery.businessName,
                delivery.driverName != null ? 'Motoboy: ${delivery.driverName}' : null,
                if (delivery.suggestedAmount != null)
                  formatCurrency(delivery.suggestedAmount, delivery.currency ?? 'BRL'),
              ].whereType<String>().join(' • '),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(
                    deliveryStatusLabel(DeliveryStatus.fromWire(delivery.status)),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Ações administrativas',
                  icon: actionInProgress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.more_vert),
                  onPressed: actionInProgress
                      ? null
                      : () => _showActionsModal(context, delivery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Modal de ações administrativas: atribuir motorista ou cancelar entrega.
  Future<void> _showActionsModal(
    BuildContext context,
    AdminDelivery delivery,
  ) {
    final cubit = context.read<AdminDeliveriesCubit>();

    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ações administrativas',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  delivery.recipientName ?? delivery.id,
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _showAssignDialog(context, cubit, delivery);
                  },
                  icon: const Icon(Icons.person_add_alt_outlined),
                  label: const Text('Atribuir motorista'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _showCancelDialog(context, cubit, delivery);
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar entrega'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAssignDialog(
    BuildContext context,
    AdminDeliveriesCubit cubit,
    AdminDelivery delivery,
  ) async {
    final controller = TextEditingController();
    final driverId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Atribuir motorista'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'ID do motorista (ULID)',
              border: OutlineInputBorder(),
              helperText: 'Somente motoristas aprovados podem ser atribuídos.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Atribuir'),
            ),
          ],
        );
      },
    );

    if (driverId != null && driverId.isNotEmpty) {
      await cubit.assign(delivery.id, driverId: driverId);
    }
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    AdminDeliveriesCubit cubit,
    AdminDelivery delivery,
  ) async {
    final reasonController = TextEditingController();
    String? refundType = 'NONE';

    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Cancelar entrega'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Motivo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: refundType,
                    decoration: const InputDecoration(
                      labelText: 'Reembolso',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NONE', child: Text('Nenhum')),
                      DropdownMenuItem(value: 'FULL', child: Text('Total')),
                      DropdownMenuItem(value: 'PARTIAL', child: Text('Parcial')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => refundType = value ?? 'NONE'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) return;
                    Navigator.of(dialogContext).pop((reason, refundType!));
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await cubit.cancel(delivery.id, reason: result.$1, refundType: result.$2);
    }
  }
}

/// Estado de erro com botão "Tentar novamente".
class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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

