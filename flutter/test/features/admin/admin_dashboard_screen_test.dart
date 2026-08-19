// Smoke test do Painel Administrativo: shell responsivo (drawer em telas
// estreitas), módulo Visão Geral e navegação entre módulos.

import 'package:delivery_app/features/admin/domain/admin_models.dart';
import 'package:delivery_app/features/admin/domain/admin_repository.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_audit_logs_cubit.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_dashboard_cubit.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_deliveries_cubit.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_drivers_cubit.dart';
import 'package:delivery_app/features/admin/presentation/cubits/admin_financial_cubit.dart';
import 'package:delivery_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _pagination = AdminPagination(total: 1, perPage: 15, currentPage: 1, lastPage: 1);

const _empty = AdminPagination(total: 0, perPage: 15, currentPage: 1, lastPage: 1);

class _FakeAdminRepository implements AdminRepository {
  @override
  Future<AdminMetrics> loadMetrics() async => const AdminMetrics(
        deliveriesToday: 7,
        revenue: '150.00',
        currency: 'BRL',
        driversOnline: 5,
        pendingDrivers: 3,
      );

  @override
  Future<AdminPage<AdminDriverSummary>> pendingDrivers({
    int page = 1,
    int perPage = 15,
  }) async =>
      const AdminPage(
        items: [AdminDriverSummary(id: 'd1', name: 'Maria', approvalStatus: 'PENDING')],
        pagination: _pagination,
      );

  @override
  Future<AdminPage<AdminDelivery>> deliveries({
    AdminDeliveryFilters filters = const AdminDeliveryFilters(),
    int page = 1,
    int perPage = 15,
  }) async =>
      const AdminPage(
        items: [AdminDelivery(id: 'del1', status: 'OPEN', recipientName: 'João')],
        pagination: _pagination,
      );

  @override
  Future<AdminPage<AdminPayment>> payments({int page = 1, int perPage = 15}) async =>
      const AdminPage(items: [AdminPayment(id: 'p1', amount: '25.00', currency: 'BRL', status: 'CAPTURED')], pagination: _pagination);

  @override
  Future<AdminPage<AdminRefund>> refunds({int page = 1, int perPage = 15}) async =>
      const AdminPage<AdminRefund>(items: [], pagination: _empty);

  @override
  Future<AdminPage<AdminPayout>> payouts({int page = 1, int perPage = 15}) async =>
      const AdminPage<AdminPayout>(items: [], pagination: _empty);

  @override
  Future<AdminPage<AdminAuditLog>> auditLogs({
    AdminAuditLogFilters filters = const AdminAuditLogFilters(),
    int page = 1,
    int perPage = 15,
  }) async =>
      const AdminPage(
        items: [AdminAuditLog(id: 'a1', action: 'DRIVER_APPROVED', entityType: 'driver')],
        pagination: _pagination,
      );

  @override
  Future<void> approveDriver(String driverId) async {}

  @override
  Future<void> rejectDriver(String driverId, {required String reason}) async {}

  @override
  Future<void> suspendDriver(String driverId) async {}

  @override
  Future<void> assignDelivery(String deliveryId, {required String driverId}) async {}

  @override
  Future<void> cancelDelivery(String deliveryId, {required String reason, String? refundType}) async {}

  @override
  Future<AdminRefund> createRefund({required String paymentId, required String amount, required String reason}) async =>
      AdminRefund(id: 'r1', paymentId: paymentId, amount: amount, status: 'PENDING');
}

Widget _buildApp(AdminRepository repository) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AdminDashboardCubit(repository)),
      BlocProvider.value(value: AdminDriversCubit(repository)),
      BlocProvider.value(value: AdminDeliveriesCubit(repository)),
      BlocProvider.value(value: AdminFinancialCubit(repository)),
      BlocProvider.value(value: AdminAuditLogsCubit(repository)),
    ],
    child: const MaterialApp(home: AdminDashboardScreen()),
  );
}

void main() {
  testWidgets('renders the overview module with metric cards and logout', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeAdminRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Visão Geral'), findsWidgets);
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(find.text('Entregas hoje'), findsOneWidget);
    expect(find.text('Faturamento (hoje)'), findsOneWidget);
    expect(find.text('Cadastros pendentes'), findsOneWidget);
  });

  testWidgets('navigates between modules via the drawer', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeAdminRepository()));
    await tester.pumpAndSettle();

    // Tela estreita → hambúrguer abre o Drawer.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gestão de Entregas'));
    await tester.pumpAndSettle();

    // Módulo de entregas ativo: título + filtro de busca + item carregado.
    expect(find.text('João'), findsOneWidget);
    expect(find.text('Buscar por destinatário ou telefone'), findsOneWidget);
  });
}
