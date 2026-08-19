import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/admin_models.dart';
import '../../domain/admin_repository.dart';

/// Estados do módulo Aprovação de Motoboys.
sealed class AdminDriversState {
  const AdminDriversState();
}

final class AdminDriversLoading extends AdminDriversState {
  const AdminDriversLoading();
}

final class AdminDriversLoaded extends AdminDriversState {
  const AdminDriversLoaded({
    required this.drivers,
    required this.pagination,
    this.actionInProgress = false,
    this.message,
  });

  final List<AdminDriverSummary> drivers;
  final AdminPagination pagination;

  /// `true` enquanto uma ação (aprovar/rejeitar/suspender) está em andamento.
  final bool actionInProgress;

  /// Feedback de sucesso/erro da última ação (SnackBar).
  final String? message;

  AdminDriversLoaded copyWith({
    List<AdminDriverSummary>? drivers,
    AdminPagination? pagination,
    bool? actionInProgress,
    String? message,
  }) {
    return AdminDriversLoaded(
      drivers: drivers ?? this.drivers,
      pagination: pagination ?? this.pagination,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      message: message ?? this.message,
    );
  }
}

final class AdminDriversFailure extends AdminDriversState {
  const AdminDriversFailure(this.message);

  final String message;
}

/// Orquestra a fila de cadastros pendentes e as ações de aprovação.
class AdminDriversCubit extends Cubit<AdminDriversState> {
  AdminDriversCubit(this._repository) : super(const AdminDriversLoading());

  final AdminRepository _repository;

  Future<void> loadPending({int page = 1}) async {
    emit(const AdminDriversLoading());
    try {
      final result = await _repository.pendingDrivers(page: page);
      emit(AdminDriversLoaded(
        drivers: result.items,
        pagination: result.pagination,
      ));
    } on ApiException catch (error) {
      emit(AdminDriversFailure(error.message));
    } catch (_) {
      emit(const AdminDriversFailure('Não foi possível carregar os cadastros.'));
    }
  }

  Future<void> approve(String driverId) async {
    await _runAction(
      driverId,
      action: () => _repository.approveDriver(driverId),
      successMessage: 'Motorista aprovado.',
    );
  }

  Future<void> reject(String driverId, {required String reason}) async {
    await _runAction(
      driverId,
      action: () => _repository.rejectDriver(driverId, reason: reason),
      successMessage: 'Cadastro rejeitado.',
    );
  }

  Future<void> suspend(String driverId) async {
    await _runAction(
      driverId,
      action: () => _repository.suspendDriver(driverId),
      successMessage: 'Motorista suspenso.',
    );
  }

  Future<void> _runAction(
    String driverId, {
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final current = switch (state) {
      AdminDriversLoaded(:final drivers, :final pagination) =>
        (drivers, pagination),
      _ => null,
    };
    if (current == null) return;

    emit(AdminDriversLoaded(
      drivers: current.$1,
      pagination: current.$2,
      actionInProgress: true,
    ));

    try {
      await action();
      final refreshed = await _repository.pendingDrivers();
      emit(AdminDriversLoaded(
        drivers: refreshed.items,
        pagination: refreshed.pagination,
        message: successMessage,
      ));
    } on ApiException catch (error) {
      emit(AdminDriversLoaded(
        drivers: current.$1,
        pagination: current.$2,
        message: error.message,
      ));
    } catch (_) {
      emit(AdminDriversLoaded(
        drivers: current.$1,
        pagination: current.$2,
        message: 'Não foi possível concluir a ação.',
      ));
    }
  }
}
