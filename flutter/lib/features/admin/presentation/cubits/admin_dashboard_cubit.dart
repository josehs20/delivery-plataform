import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/admin_models.dart';
import '../../domain/admin_repository.dart';

/// Estados do módulo Visão Geral (métricas globais do painel).
sealed class AdminDashboardState {
  const AdminDashboardState();
}

final class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

final class AdminDashboardLoaded extends AdminDashboardState {
  const AdminDashboardLoaded({required this.metrics});

  final AdminMetrics metrics;
}

final class AdminDashboardFailure extends AdminDashboardState {
  const AdminDashboardFailure(this.message);

  final String message;
}

/// Orquestra os cards de métricas globais (`GET /admin/metrics`).
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._repository)
      : super(const AdminDashboardLoading());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(const AdminDashboardLoading());
    try {
      emit(AdminDashboardLoaded(metrics: await _repository.loadMetrics()));
    } on ApiException catch (error) {
      emit(AdminDashboardFailure(error.message));
    } catch (_) {
      emit(const AdminDashboardFailure('Não foi possível carregar as métricas.'));
    }
  }
}
