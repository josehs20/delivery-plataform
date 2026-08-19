import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/delivery/presentation/delivery_labels.dart';
import '../../domain/admin_models.dart';
import '../cubits/admin_financial_cubit.dart';

/// Módulo "Financeiro & Reembolsos" — pagamentos, reembolsos e repasses.
class AdminFinancialScreen extends StatefulWidget {
  const AdminFinancialScreen({super.key});

  @override
  State<AdminFinancialScreen> createState() => _AdminFinancialScreenState();
}

class _AdminFinancialScreenState extends State<AdminFinancialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminFinancialCubit>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminFinancialCubit, AdminFinancialState>(
      listenWhen: (previous, current) =>
          current is AdminFinancialLoaded && current.message != null,
      listener: (context, state) {
        final message = (state as AdminFinancialLoaded).message;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message ?? '')));
      },
      child: BlocBuilder<AdminFinancialCubit, AdminFinancialState>(
        builder: (context, state) {
          return switch (state) {
            AdminFinancialLoading() =>
              const Center(child: CircularProgressIndicator()),
            AdminFinancialFailure(:final message) => _ErrorRetry(
                message: message,
                onRetry: () => context.read<AdminFinancialCubit>().loadAll(),
              ),
            AdminFinancialLoaded(
              :final payments,
              :final refunds,
              :final payouts,
            ) =>
              _buildContent(context, payments, refunds, payouts),
          };
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AdminPayment> payments,
    List<AdminRefund> refunds,
    List<AdminPayout> payouts,
  ) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Expanded(
                  child: TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Pagamentos'),
                      Tab(text: 'Reembolsos'),
                      Tab(text: 'Repasses'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => _showRefundDialog(context, payments),
                  icon: const Icon(Icons.replay_outlined, size: 18),
                  label: const Text('Novo reembolso'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                _PaymentList(payments: payments),
                _RefundList(refunds: refunds),
                _PayoutList(payouts: payouts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefundDialog(
    BuildContext context,
    List<AdminPayment> payments,
  ) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String? paymentId = payments.isNotEmpty ? payments.first.id : null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Novo reembolso'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: paymentId,
                    decoration: const InputDecoration(
                      labelText: 'Pagamento',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final payment in payments)
                        DropdownMenuItem(
                          value: payment.id,
                          child: Text(
                            '${formatCurrency(payment.amount, payment.currency)}'
                            ' • ${payment.businessName ?? payment.id}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => paymentId = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Motivo',
                      border: OutlineInputBorder(),
                    ),
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
                    final amount = amountController.text.trim();
                    final reason = reasonController.text.trim();
                    if (paymentId == null || amount.isEmpty || reason.isEmpty) {
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    context
                        .read<AdminFinancialCubit>()
                        .createRefund(
                          paymentId: paymentId!,
                          amount: amount,
                          reason: reason,
                        );
                  },
                  child: const Text('Emitir'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({required this.payments});

  final List<AdminPayment> payments;

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) return const Center(child: Text('Nenhum pagamento.'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.payment_outlined),
          title: Text(payment.businessName ?? payment.id),
          subtitle: Text(
            '${payment.status}${payment.capturedAt != null ? ' • ${payment.capturedAt!.toLocal()}' : ''}',
          ),
          trailing: Text(
            formatCurrency(payment.amount, payment.currency),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        );
      },
    );
  }
}

class _RefundList extends StatelessWidget {
  const _RefundList({required this.refunds});

  final List<AdminRefund> refunds;

  @override
  Widget build(BuildContext context) {
    if (refunds.isEmpty) return const Center(child: Text('Nenhum reembolso.'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: refunds.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final refund = refunds[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.replay_outlined),
          title: Text(refund.reason ?? refund.id),
          subtitle: Text('${refund.status} • Pagamento ${refund.paymentId}'),
          trailing: Text(
            formatCurrency(refund.amount, 'BRL'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        );
      },
    );
  }
}

class _PayoutList extends StatelessWidget {
  const _PayoutList({required this.payouts});

  final List<AdminPayout> payouts;

  @override
  Widget build(BuildContext context) {
    if (payouts.isEmpty) return const Center(child: Text('Nenhum repasse.'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: payouts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final payout = payouts[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: Text(payout.driverName ?? payout.id),
          subtitle: Text(
            '${payout.status}${payout.paidAt != null ? ' • Pago em ${payout.paidAt!.toLocal()}' : ''}',
          ),
          trailing: Text(
            formatCurrency(payout.netAmount, 'BRL'),
            style: Theme.of(context).textTheme.titleSmall,
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
