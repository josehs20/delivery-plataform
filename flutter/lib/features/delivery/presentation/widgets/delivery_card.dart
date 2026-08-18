import 'package:flutter/material.dart';

import '../../domain/delivery.dart';
import '../delivery_labels.dart';

/// Card reutilizável de entrega (listas de dashboard/feed).
///
/// Mostra valor (monetário formatado), status, origem/destino e uma área de
/// ações opcional (ex.: botão de aceite no feed, abrir detalhes).
class DeliveryCard extends StatelessWidget {
  const DeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
    this.actions,
  });

  final Delivery delivery;
  final VoidCallback? onTap;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                  Chip(label: Text(deliveryStatusLabel(delivery.status))),
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
              if (delivery.recipient != null) ...[
                const SizedBox(height: 4),
                _AddressLine(
                  icon: Icons.person_outline,
                  address: delivery.recipient!.name,
                ),
              ],
              if (actions != null) ...[
                const SizedBox(height: 12),
                actions!,
              ],
            ],
          ),
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
