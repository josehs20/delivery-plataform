import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../delivery/domain/delivery.dart';
import '../../../delivery/presentation/delivery_detail_cubit.dart';
import '../../../delivery/presentation/delivery_detail_state.dart';
import '../tracking_cubit.dart';
import '../tracking_state.dart';
import '../widgets/delivery_map.dart';

/// Tela de rastreamento da entrega ativa (motoboy).
///
/// Mostra coleta/destino no mapa e a posição atual do entregador enquanto o
/// rastreamento estiver ativo. A captura é offline-first (enfileirada na
/// SyncQueue); a UI diferencia "rastreando" de "encerrado" explicitamente.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DeliveryDetailCubit>().load(widget.deliveryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rastreamento')),
      body: BlocBuilder<DeliveryDetailCubit, DeliveryDetailState>(
        builder: (context, detailState) {
          final delivery = switch (detailState) {
            DeliveryDetailLocal(:final delivery) => delivery,
            DeliveryDetailSyncing(:final delivery) => delivery,
            DeliveryDetailSynced(:final delivery) => delivery,
            DeliveryDetailFailure(:final delivery?) => delivery,
            _ => null,
          };

          if (delivery == null) {
            return detailState is DeliveryDetailFailure
                ? _ErrorState(
                    message: detailState.message,
                    onRetry: () =>
                        context.read<DeliveryDetailCubit>().load(
                              widget.deliveryId,
                            ),
                  )
                : const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<TrackingCubit, TrackingState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(child: _buildMap(context, delivery, state)),
                  _buildControls(context, widget.deliveryId, state),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    Delivery delivery,
    TrackingState state,
  ) {
    final origin = delivery.origin;
    final destination = delivery.destination;
    if (origin?.latitude == null ||
        origin?.longitude == null ||
        destination?.latitude == null ||
        destination?.longitude == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Sem coordenadas suficientes para exibir o mapa.'),
        ),
      );
    }

    return DeliveryMap(
      pickup: LatLng(origin!.latitude!, origin.longitude!),
      destination: LatLng(
        destination!.latitude!,
        destination.longitude!,
      ),
      driver: state.lastPoint == null
          ? null
          : LatLng(state.lastPoint!.latitude, state.lastPoint!.longitude),
    );
  }

  Widget _buildControls(
    BuildContext context,
    String deliveryId,
    TrackingState state,
  ) {
    final cubit = context.read<TrackingCubit>();
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusBanner(state: state),
            const SizedBox(height: 12),
            if (state.isTracking)
              FilledButton.icon(
                onPressed: cubit.stop,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Encerrar rastreamento'),
              )
            else
              FilledButton.icon(
                onPressed: () => cubit.start(deliveryId: deliveryId),
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Iniciar rastreamento'),
              ),
            const SizedBox(height: 8),
            Text(
              '${state.pointsRecorded} ponto(s) registrados localmente.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final TrackingState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, message) = switch (state.status) {
      TrackingStatus.idle => (
          Icons.gps_off,
          'Rastreamento pronto. Toque em iniciar quando sair para a coleta.',
        ),
      TrackingStatus.requestingPermission => (
          Icons.gps_fixed,
          'Solicitando permissão de localização...',
        ),
      TrackingStatus.permissionDenied => (
          Icons.location_off,
          'Permissão de localização negada. Ative nas configurações.',
        ),
      TrackingStatus.gpsDisabled => (
          Icons.location_off,
          'O GPS está desabilitado. Ative a localização do dispositivo.',
        ),
      TrackingStatus.tracking => (
          Icons.my_location,
          'Rastreando — posição enviada ao servidor quando houver conexão.',
        ),
      TrackingStatus.stopped => (
          Icons.gps_off,
          state.errorMessage ?? 'Rastreamento encerrado.',
        ),
    };

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
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

