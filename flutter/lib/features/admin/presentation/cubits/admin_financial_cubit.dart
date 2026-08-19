import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/admin_models.dart';
import '../../domain/admin_repository.dart';

/// Estados do módulo Financeiro & Reembolsos.
sealed class AdminFinancialState {
  const AdminFinancialState();
}

final class AdminFinancialLoading extends AdminFinancialState {
  const AdminFinancialLoading();
}

final class AdminFinancialLoaded extends AdminFinancialState {
  const AdminFinancialLoaded({
    required this.payments,
    required this.refunds,
    required this.payouts,
    this.paymentsPagination,
    this.refundsPagination,
    this.payoutsPagination,
    this.actionInProgress = false,
    this.message,
  });

  final List<AdminPayment> payments;
  final List<AdminRefund> refunds;
  final List<AdminPayout> payouts;
  final AdminPagination? paymentsPagination;
  final AdminPagination? refundsPagination;
  final AdminPagination? payoutsPagination;
  final bool actionInProgress;
  final String? message;

  AdminFinancialLoaded copyWith({
    List<AdminPayment>? payments,
    List<AdminRefund>? refunds,
    List<AdminPayout>? payouts,
    AdminPagination? paymentsPagination,
    AdminPagination? refundsPagination,
    AdminPagination? payoutsPagination,
    bool? actionInProgress,
    String? message,
  }) {
    return AdminFinancialLoaded(
      payments: payments ?? this.payments,
      refunds: refunds ?? this.refunds,
      payouts: payouts ?? this.payouts,
      paymentsPagination: paymentsPagination ?? this.paymentsPagination,
      refundsPagination: refundsPagination ?? this.refundsPagination,
      payoutsPagination: payoutsPagination ?? this.payoutsPagination,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      message: message ?? this.message,
    );
  }
}

final class AdminFinancialFailure extends AdminFinancialState {
  const AdminFinancialFailure(this.message);

  final String message;
}

/// Orquestra pagamentos, reembolsos e repasses do painel administrativo.
class AdminFinancialCubit extends Cubit<AdminFinancialState> {
  AdminFinancialCubit(this._repository) : super(const AdminFinancialLoading());

  final AdminRepository _repository;

  Future<void> loadAll() async {
    emit(const AdminFinancialLoading());
    try {
      final payments = await _repository.payments();
      final refunds = await _repository.refunds();
      final payouts = await _repository.payouts();
      emit(AdminFinancialLoaded(
        payments: payments.items,
        paymentsPagination: payments.pagination,
        refunds: refunds.items,
        refundsPagination: refunds.pagination,
        payouts: payouts.items,
        payoutsPagination: payouts.pagination,
      ));
    } on ApiException catch (error) {
      emit(AdminFinancialFailure(error.message));
    } catch (_) {
      emit(const AdminFinancialFailure('Não foi possível carregar os dados financeiros.'));
    }
  }

  Future<void> createRefund({
    required String paymentId,
    required String amount,
    required String reason,
  }) async {
    final current = switch (state) {
      AdminFinancialLoaded(:final payments) => payments,
      _ => null,
    };
    if (current == null) return;

    emit(state is AdminFinancialLoaded
        ? (state as AdminFinancialLoaded).copyWith(actionInProgress: true)
        : const AdminFinancialLoading());

    try {
      await _repository.createRefund(
        paymentId: paymentId,
        amount: amount,
        reason: reason,
      );
      final refunds = await _repository.refunds();
      emit((state as AdminFinancialLoaded).copyWith(
        refunds: refunds.items,
        refundsPagination: refunds.pagination,
        actionInProgress: false,
        message: 'Reembolso registrado.',
      ));
    } on ApiException catch (error) {
      emit((state as AdminFinancialLoaded).copyWith(
        actionInProgress: false,
        message: error.message,
      ));
    } catch (_) {
      emit((state as AdminFinancialLoaded).copyWith(
        actionInProgress: false,
        message: 'Não foi possível registrar o reembolso.',
      ));
    }
  }
}
