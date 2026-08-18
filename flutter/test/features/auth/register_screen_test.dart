import 'package:delivery_app/app/routes/app_routes.dart';
import 'package:delivery_app/features/auth/domain/auth_repository.dart';
import 'package:delivery_app/features/auth/domain/auth_session.dart';
import 'package:delivery_app/features/auth/domain/auth_user.dart';
import 'package:delivery_app/features/auth/domain/register_params.dart';
import 'package:delivery_app/features/auth/presentation/auth_cubit.dart';
import 'package:delivery_app/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final _session = AuthSession(
  token: '1|token',
  user: const AuthUser(
    id: 'u1',
    name: 'Maria',
    email: 'maria@example.com',
    roles: ['business'],
  ),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository();

  RegisterParams? lastParams;

  @override
  Future<AuthSession> register(RegisterParams params) async {
    lastParams = params;
    return _session;
  }

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async =>
      _session;

  @override
  Future<AuthSession> refresh() async => _session;

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthUser> me() async => _session.user;

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async =>
      _session.user;

  @override
  Future<void> logout() async {}
}

class _BusinessDashboard extends StatelessWidget {
  const _BusinessDashboard();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Dashboard')));
}

void main() {
  testWidgets('toggles between driver and business fields', (tester) async {
    final repository = _FakeAuthRepository();
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    // Papel padrão: motoboy → campos de veículo visíveis.
    expect(find.text('Documento (CPF/CNH)'), findsOneWidget);
    expect(find.text('Nome da empresa'), findsNothing);

    // Alterna para comércio.
    await tester.tap(find.text('Comércio'));
    await tester.pumpAndSettle();

    expect(find.text('Nome da empresa'), findsOneWidget);
    expect(find.text('Documento (CPF/CNH)'), findsNothing);
  });

  testWidgets('submits business params and navigates to business dashboard',
      (tester) async {
    final repository = _FakeAuthRepository();
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          routes: {
            AppRoutes.register: (_) => const RegisterScreen(),
            AppRoutes.businessDashboard: (_) => const _BusinessDashboard(),
          },
          initialRoute: AppRoutes.register,
        ),
      ),
    );

    // Alterna para comércio.
    await tester.tap(find.text('Comércio'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome completo'), 'Loja X');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'loja@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone'), '27999999999');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha (mín. 8)'), 'password123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar senha'), 'password123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome da empresa'), 'Loja X Ltda');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'CNPJ'), '12.345.678/0001-90');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pumpAndSettle();

    expect(repository.lastParams, isNotNull);
    expect(repository.lastParams!.role, AuthRole.business);
    expect(repository.lastParams!.businessName, 'Loja X Ltda');
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
