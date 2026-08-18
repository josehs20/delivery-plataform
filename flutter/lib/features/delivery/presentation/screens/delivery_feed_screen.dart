import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/delivery.dart';
import '../delivery_labels.dart';
import '../delivery_list_cubit.dart';
import '../delivery_list_state.dart';

/// Feed de entregas disponíveis para o motoboy.
///
/// Estados explícitos: loading, local (offline), sincronizando, sincronizado
/// e falha (com retry).
class DeliveryFeedScreen extends StatelessWidget {
  const DeliveryFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DeliveryListCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Entregas disponíveis')),
      body: BlocBuilder<DeliveryListCubit, DeliveryListState>(
        builder: (context, state) {
          return switch (state) {
            DeliveryListLoading() =>
              const Center(child: CircularProgressIndicator()),
            DeliveryListLocal(:final deliveries) => _DeliveryList(
                deliveries: deliveries,
                banner: const _SyncBanner(
                  icon: Icons.cloud_off_outlined,
                  label: 'Modo offline — dados locais',
                ),
              ),
            DeliveryListSyncing(:final deliveries) =>
              _DeliveryList(deliveries: deliveries, syncing: true),
            DeliveryListSynced(:final deliveries) =>
              _DeliveryList(deliveries: deliveries),
            DeliveryListFailure(:final message, :final deliveries?) =>
              _DeliveryList(
                deliveries: deliveries,
                banner: _SyncBanner(
                  icon: Icons.error_outline,
                  label: message,
                ),
              ),
            DeliveryListFailure(:final message) =>
              _ErrorState(message: message, onRetry: cubit.load),
          };
        },
      ),
    );
  }
}

class _DeliveryList extends StatelessWidget {
  const _DeliveryList({
    required this.deliveries,
    this.banner,
    this.syncing = false,
  });

  final List<Delivery> deliveries;
  final Widget? banner;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DeliveryListCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (syncing) const LinearProgressIndicator(),
          ?banner,
          if (deliveries.isEmpty)
            const _EmptyState()
          else
            ...deliveries.map((delivery) => _DeliveryCard(delivery: delivery)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAccept = delivery.pendingOffer != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    formatCurrency(delivery.displayAmount, delivery.currency),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(deliveryStatusLabel(delivery.status)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AddressLine(
              icon: Icons.trip_origin,
              address: delivery.origin?.address ?? '—',
            ),
            _AddressLine(
              icon: Icons.sports_motorsports,
              address: delivery.destination?.address ?? '—',
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: canAccept
                  ? () => context.read<DeliveryListCubit>().accept(delivery)
                  : null,
              child: Text(canAccept ? 'Aceitar oferta' : 'Sem oferta pendente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine({required this.icon, required this.address});

  final IconData icon;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(address)),
        ],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48),
          SizedBox(height: 12),
          Text('Nenhuma entrega disponível'),
        ],
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

