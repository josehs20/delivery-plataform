import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../features/auth/presentation/auth_cubit.dart';
import '../../../../features/delivery/domain/delivery.dart';
import '../../../../features/delivery/presentation/delivery_list_cubit.dart';
import '../../../../features/delivery/presentation/delivery_list_state.dart';
import '../../../../features/delivery/presentation/widgets/delivery_card.dart';

/// Dashboard do motoboy: "Minhas entregas" (via `GET /deliveries` — o backend
/// retorna as entregas atribuídas ao motoboy) com abas Ativas/Histórico.
///
/// O fluxo de "ofertas disponíveis" (`GET /driver/offers`) e o status
/// online/offline (`POST /driver/availability`) não estão implementados no
/// backend (Stage 4) — portanto não são expostos como botões falsos.
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  var _showActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DeliveryListCubit>().load();
    });
  }

  void _openDelivery(BuildContext context, Delivery delivery) {
    Navigator.of(context).pushNamed(AppRoutes.deliveryDetailFor(delivery.id));
  }

  List<Delivery> _filter(List<Delivery> deliveries) {
    if (_showActive) {
      return deliveries
          .where((d) => DeliveryStatus.active.contains(d.status))
          .toList(growable: false);
    }
    return deliveries
        .where((d) => !DeliveryStatus.active.contains(d.status))
        .toList(growable: false);
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
      body: BlocBuilder<DeliveryListCubit, DeliveryListState>(
        builder: (context, state) {
          final deliveries = switch (state) {
            DeliveryListLocal(:final deliveries) => deliveries,
            DeliveryListSyncing(:final deliveries) => deliveries,
            DeliveryListSynced(:final deliveries) => deliveries,
            DeliveryListFailure(:final deliveries?) => deliveries,
            _ => const <Delivery>[],
          };

          return Column(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Ativas'),
                    icon: Icon(Icons.directions_bike),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Histórico'),
                    icon: Icon(Icons.history),
                  ),
                ],
                selected: {_showActive},
                onSelectionChanged: (selection) =>
                    setState(() => _showActive = selection.first),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: switch (state) {
                  DeliveryListLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  DeliveryListLocal() => _List(
                      deliveries: _filter(deliveries),
                      banner: const _Banner(
                        icon: Icons.cloud_off_outlined,
                        label: 'Modo offline — dados locais',
                      ),
                      onTap: (d) => _openDelivery(context, d),
                    ),
                  DeliveryListSyncing() => _List(
                      deliveries: _filter(deliveries),
                      syncing: true,
                      onTap: (d) => _openDelivery(context, d),
                    ),
                  DeliveryListSynced() => _List(
                      deliveries: _filter(deliveries),
                      onTap: (d) => _openDelivery(context, d),
                    ),
                  DeliveryListFailure(:final message, :final deliveries?) =>
                    _List(
                      deliveries: _filter(deliveries),
                      banner: _Banner(icon: Icons.error_outline, label: message),
                      onTap: (d) => _openDelivery(context, d),
                    ),
                  DeliveryListFailure(:final message) =>
                    _ErrorState(message: message),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
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
              ),
            ),
          const SizedBox(height: 24),
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
          Text('Nenhuma entrega aqui.'),
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

