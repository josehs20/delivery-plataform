import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../features/auth/presentation/auth_cubit.dart';
import '../../../../features/delivery/domain/delivery.dart';
import '../../../../features/delivery/presentation/delivery_labels.dart';
import '../../../../features/delivery/presentation/delivery_list_cubit.dart';
import '../../../../features/delivery/presentation/delivery_list_state.dart';
import '../../../../features/delivery/presentation/widgets/delivery_card.dart';

/// Dashboard do comércio: lista as entregas do negócio (via `GET /deliveries`)
/// e dá acesso a criar, publicar e acompanhar.
class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DeliveryListCubit>().load();
    });
  }

  void _openCreate(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.createDelivery);
  }

  void _openDelivery(BuildContext context, Delivery delivery) {
    Navigator.of(context).pushNamed(
      AppRoutes.businessDeliveryDetailFor(delivery.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas entregas'),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova entrega'),
      ),
      body: BlocBuilder<DeliveryListCubit, DeliveryListState>(
        builder: (context, state) {
          return switch (state) {
            DeliveryListLoading() =>
              const Center(child: CircularProgressIndicator()),
            DeliveryListLocal(:final deliveries) => _DeliveryList(
                deliveries: deliveries,
                banner: const _Banner(
                  icon: Icons.cloud_off_outlined,
                  label: 'Modo offline — dados locais',
                ),
                onTap: (d) => _openDelivery(context, d),
              ),
            DeliveryListSyncing(:final deliveries) => _DeliveryList(
                deliveries: deliveries,
                syncing: true,
                onTap: (d) => _openDelivery(context, d),
              ),
            DeliveryListSynced(:final deliveries) => _DeliveryList(
                deliveries: deliveries,
                onTap: (d) => _openDelivery(context, d),
              ),
            DeliveryListFailure(:final message, :final deliveries?) =>
              _DeliveryList(
                deliveries: deliveries,
                banner: _Banner(icon: Icons.error_outline, label: message),
                onTap: (d) => _openDelivery(context, d),
              ),
            DeliveryListFailure(:final message) =>
              _ErrorState(message: message),
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
    this.onTap,
  });

  final List<Delivery> deliveries;
  final Widget? banner;
  final bool syncing;
  final void Function(Delivery)? onTap;

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
            ...deliveries.map(
              (delivery) => DeliveryCard(
                delivery: delivery,
                onTap: onTap == null ? null : () => onTap!(delivery),
                actions: Text(
                  'Status: ${deliveryStatusLabel(delivery.status)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.label});

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
          Text('Nenhuma entrega. Toque em "Nova entrega" para começar.'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

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
              onPressed: () => context.read<DeliveryListCubit>().load(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

