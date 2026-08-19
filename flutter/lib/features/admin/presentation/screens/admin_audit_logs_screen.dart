import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/admin_models.dart';
import '../../domain/admin_repository.dart';
import '../cubits/admin_audit_logs_cubit.dart';

/// Módulo "Logs de Auditoria" — trilha de eventos do sistema.
class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final _actionController = TextEditingController();
  String? _entityType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminAuditLogsCubit>().load();
    });
  }

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  void _apply() {
    context.read<AdminAuditLogsCubit>().load(
          filters: AdminAuditLogFilters(
            action: _actionController.text.trim(),
            entityType: _entityType,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _actionController,
                  decoration: const InputDecoration(
                    hintText: 'Filtrar por ação (ex.: DRIVER_APPROVED)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String?>(
                value: _entityType,
                hint: const Text('Recurso'),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'driver', child: Text('driver')),
                  DropdownMenuItem(value: 'delivery', child: Text('delivery')),
                  DropdownMenuItem(value: 'refund', child: Text('refund')),
                ],
                onChanged: (value) {
                  setState(() => _entityType = value);
                  _apply();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: BlocBuilder<AdminAuditLogsCubit, AdminAuditLogsState>(
            builder: (context, state) {
              return switch (state) {
                AdminAuditLogsLoading() =>
                  const Center(child: CircularProgressIndicator()),
                AdminAuditLogsFailure(:final message) => _ErrorRetry(
                    message: message,
                    onRetry: () =>
                        context.read<AdminAuditLogsCubit>().load(),
                  ),
                AdminAuditLogsLoaded(:final logs) => _buildList(context, logs),
              };
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<AdminAuditLog> logs) {
    if (logs.isEmpty) return const Center(child: Text('Nenhum evento de auditoria.'));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final log = logs[index];
        final when = log.occurredAt?.toLocal().toIso8601String();
        return ListTile(
          dense: true,
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text('${log.action} • ${log.entityType}'),
          subtitle: Text(
            [
              if (log.entityId != null) 'id: ${log.entityId}',
              if (log.actorId != null) 'ator: ${log.actorId}',
              ?when,
            ].join(' • '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
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
