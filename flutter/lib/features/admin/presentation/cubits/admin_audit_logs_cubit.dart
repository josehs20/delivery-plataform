import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_exception.dart';
import '../../domain/admin_models.dart';
import '../../domain/admin_repository.dart';

/// Estados do módulo Logs de Auditoria.
sealed class AdminAuditLogsState {
  const AdminAuditLogsState();
}

final class AdminAuditLogsLoading extends AdminAuditLogsState {
  const AdminAuditLogsLoading();
}

final class AdminAuditLogsLoaded extends AdminAuditLogsState {
  const AdminAuditLogsLoaded({
    required this.logs,
    required this.pagination,
    required this.filters,
  });

  final List<AdminAuditLog> logs;
  final AdminPagination pagination;
  final AdminAuditLogFilters filters;
}

final class AdminAuditLogsFailure extends AdminAuditLogsState {
  const AdminAuditLogsFailure(this.message);

  final String message;
}

/// Orquestra a trilha de auditoria (`GET /admin/audit-logs`).
class AdminAuditLogsCubit extends Cubit<AdminAuditLogsState> {
  AdminAuditLogsCubit(this._repository) : super(const AdminAuditLogsLoading());

  final AdminRepository _repository;

  Future<void> load({
    AdminAuditLogFilters filters = const AdminAuditLogFilters(),
    int page = 1,
  }) async {
    emit(const AdminAuditLogsLoading());
    try {
      final result = await _repository.auditLogs(filters: filters, page: page);
      emit(AdminAuditLogsLoaded(
        logs: result.items,
        pagination: result.pagination,
        filters: filters,
      ));
    } on ApiException catch (error) {
      emit(AdminAuditLogsFailure(error.message));
    } catch (_) {
      emit(const AdminAuditLogsFailure('Não foi possível carregar a auditoria.'));
    }
  }
}
