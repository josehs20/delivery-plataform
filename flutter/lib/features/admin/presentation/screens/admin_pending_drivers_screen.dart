import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/admin_models.dart';
import '../cubits/admin_drivers_cubit.dart';

/// Módulo "Aprovação de Motoboys" — fila de cadastros pendentes.
class AdminPendingDriversScreen extends StatefulWidget {
  const AdminPendingDriversScreen({super.key});

  @override
  State<AdminPendingDriversScreen> createState() =>
      _AdminPendingDriversScreenState();
}

class _AdminPendingDriversScreenState extends State<AdminPendingDriversScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminDriversCubit>().loadPending();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminDriversCubit, AdminDriversState>(
      listenWhen: (previous, current) =>
          current is AdminDriversLoaded && current.message != null,
      listener: (context, state) {
        final message = (state as AdminDriversLoaded).message;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message ?? '')));
      },
      child: BlocBuilder<AdminDriversCubit, AdminDriversState>(
        builder: (context, state) {
          return switch (state) {
            AdminDriversLoading() =>
              const Center(child: CircularProgressIndicator()),
            AdminDriversFailure(:final message) => _ErrorRetry(
                message: message,
                onRetry: () => context.read<AdminDriversCubit>().loadPending(),
              ),
            AdminDriversLoaded(:final drivers, :final actionInProgress) =>
              _buildList(context, drivers, actionInProgress),
          };
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<AdminDriverSummary> drivers,
    bool actionInProgress,
  ) {
    if (drivers.isEmpty) {
      return const Center(child: Text('Nenhum cadastro pendente.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: drivers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final driver = drivers[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(_initials(driver.name))),
            title: Text(driver.name ?? driver.id),
            subtitle: Text(
              [
                driver.email,
                driver.phone,
                if (driver.vehiclePlate != null)
                  '${driver.vehicleType ?? 'Veículo'}: ${driver.vehiclePlate}',
              ].whereType<String>().join(' • '),
            ),
            trailing: actionInProgress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: actionInProgress
                ? null
                : () => _showReviewModal(context, driver),
          ),
        );
      },
    );
  }

  /// Modal de revisão do cadastro: documentos + Aprovar / Rejeitar.
  Future<void> _showReviewModal(
    BuildContext context,
    AdminDriverSummary driver,
  ) {
    final cubit = context.read<AdminDriversCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Revisão de cadastro',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    driver.name ?? driver.id,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  Text(
                    [driver.email, driver.phone].whereType<String>().join(' • '),
                    style: Theme.of(sheetContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Documentos',
                    style: Theme.of(sheetContext).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...driver.documents.map(
                    (doc) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_documentIcon(doc.documentType)),
                      title: Text(doc.documentType),
                      subtitle: Text(
                        '${doc.verificationStatus ?? 'PENDENTE'}'
                        '${doc.objectKey != null ? ' • ${doc.objectKey}' : ''}',
                      ),
                      dense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _confirmReject(context, cubit, driver);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Rejeitar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            cubit.approve(driver.id);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Aprovar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '?').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  static IconData _documentIcon(String type) {
    return switch (type) {
      'CNH' || 'CRLV' => Icons.badge_outlined,
      'SELFIE' => Icons.face_outlined,
      _ => Icons.description_outlined,
    };
  }

  Future<void> _confirmReject(
    BuildContext context,
    AdminDriversCubit cubit,
    AdminDriverSummary driver,
  ) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rejeitar cadastro'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo da rejeição',
              border: OutlineInputBorder(),
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
              child: const Text('Rejeitar'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      await cubit.reject(driver.id, reason: reason);
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
