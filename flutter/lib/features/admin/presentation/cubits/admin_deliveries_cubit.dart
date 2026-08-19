import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/admin_models.dart';
import '../../domain/admin_repository.dart';

/// Estados do módulo Gestão de Entregas (torre de controle).
sealed class AdminDeliveriesState {
  const AdminDeliveriesState();
}

final class AdminDeliveriesLoading extends AdminDeliveriesState {
  const AdminDeliveriesLoading();
}

final class AdminDeliveriesLoaded extends AdminDeliveriesState {
  const AdminDeliveriesLoaded({
    required this.deliveries,
    required this.pagination,
    required this.filters,
    this.actionInProgress = false,
    this.message,
  });

  final List<AdminDelivery> deliveries;
  final AdminPagination pagination;
  final AdminDeliveryFilters filters;
  final bool actionInProgress;
  final String? message;

  AdminDeliveriesLoaded copyWith({
    List<AdminDelivery>? deliveries,
    AdminPagination? pagination,
    AdminDeliveryFilters? filters,
    bool? actionInProgress,
    String? message,
  }) {
    return AdminDeliveriesLoaded(
      deliveries: deliveries ?? this.deliveries,
      pagination: pagination ?? this.pagination,
      filters: filters ?? this.filters,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      message: message ?? this.message,
    );
  }
}

final class AdminDeliveriesFailure extends AdminDeliveriesState {
  const AdminDeliveriesFailure(this.message);

  final String message;
}

/// Orquestra a listagem filtrada de entregas e as ações administrativas
/// (atribuir motorista / cancelar entrega).
class AdminDeliveriesCubit extends Cubit<AdminDeliveriesState> {
  AdminDeliveriesCubit(this._repository) : super(const AdminDeliveriesLoading());

  final AdminRepository _repository;

  Future<void> load({
    AdminDeliveryFilters filters = const AdminDeliveryFilters(),
    int page = 1,
  }) async {
    emit(const AdminDeliveriesLoading());
    try {
      final result = await _repository.deliveries(filters: filters, page: page);
      emit(AdminDeliveriesLoaded(
        deliveries: result.items,
        pagination: result.pagination,
        filters: filters,
      ));
    } on ApiException catch (error) {
      emit(AdminDeliveriesFailure(error.message));
    } catch (_) {
      emit(const AdminDeliveriesFailure('Não foi possível carregar as entregas.'));
    }
  }

  Future<void> assign(String deliveryId, {required String driverId}) async {
    await _runAction(
      deliveryId,
      action: () => _repository.assignDelivery(deliveryId, driverId: driverId),
      successMessage: 'Entrega atribuída.',
    );
  }

  Future<void> cancel(
    String deliveryId, {
    required String reason,
    String? refundType,
  }) async {
    await _runAction(
      deliveryId,
      action: () => _repository.cancelDelivery(
        deliveryId,
        reason: reason,
        refundType: refundType,
      ),
      successMessage: 'Entrega cancelada.',
    );
  }

  Future<void> _runAction(
    String deliveryId, {
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    final current = switch (state) {
      AdminDeliveriesLoaded(
        :final deliveries,
        :final pagination,
        :final filters,
      ) =>
        (deliveries, pagination, filters),
      _ => null,
    };
    if (current == null) return;

    emit(AdminDeliveriesLoaded(
      deliveries: current.$1,
      pagination: current.$2,
      filters: current.$3,
      actionInProgress: true,
    ));

    try {
      await action();
      final refreshed =
          await _repository.deliveries(filters: current.$3, page: 1);
      emit(AdminDeliveriesLoaded(
        deliveries: refreshed.items,
        pagination: refreshed.pagination,
        filters: current.$3,
        message: successMessage,
      ));
    } on ApiException catch (error) {
      emit(_loadedWithMessage(current, error.message));
    } catch (_) {
      emit(_loadedWithMessage(current, 'Não foi possível concluir a ação.'));
    }
  }

  AdminDeliveriesLoaded _loadedWithMessage(
    (List<AdminDelivery>, AdminPagination, AdminDeliveryFilters) current,
    String message,
  ) {
    return AdminDeliveriesLoaded(
      deliveries: current.$1,
      pagination: current.$2,
      filters: current.$3,
      message: message,
    );
  }
}
