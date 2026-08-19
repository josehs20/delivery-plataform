import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/delivery/presentation/delivery_labels.dart';
import '../../domain/admin_models.dart';
import '../cubits/admin_dashboard_cubit.dart';

/// Módulo "Visão Geral" — cards com as métricas globais do painel.
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminDashboardCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        return switch (state) {
          AdminDashboardLoading() =>
            const Center(child: CircularProgressIndicator()),
          AdminDashboardFailure(:final message) => _ErrorRetry(
              message: message,
              onRetry: () => context.read<AdminDashboardCubit>().load(),
            ),
          AdminDashboardLoaded(:final metrics) => _buildMetrics(context, metrics),
        };
      },
    );
  }

  Widget _buildMetrics(BuildContext context, AdminMetrics metrics) {
    final cards = <(IconData, String, String)>[
      (
        Icons.local_shipping_outlined,
        'Entregas hoje',
        '${metrics.deliveriesToday}',
      ),
      (
        Icons.account_balance_wallet_outlined,
        'Faturamento (hoje)',
        formatCurrency(metrics.revenue, metrics.currency),
      ),
      (
        Icons.two_wheeler_outlined,
        'Motoboys online',
        '${metrics.driversOnline}',
      ),
      (
        Icons.how_to_reg_outlined,
        'Cadastros pendentes',
        '${metrics.pendingDrivers}',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final (icon, label, value) in cards)
            SizedBox(
              width: 260,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(label, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
            FilledButton.tonal(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}
