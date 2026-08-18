import 'dart:async';

import 'package:delivery_app/app/routes/app_routes.dart';
import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/features/auth/domain/auth_repository.dart';
import 'package:delivery_app/features/auth/domain/auth_session.dart';
import 'package:delivery_app/features/auth/domain/auth_user.dart';
import 'package:delivery_app/features/auth/domain/register_params.dart';
import 'package:delivery_app/features/auth/presentation/auth_cubit.dart';
import 'package:delivery_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final _session = AuthSession(
  token: '1|token',
  user: const AuthUser(
    id: 'u1',
    name: 'João',
    email: 'joao@example.com',
    roles: ['business'],
  ),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.session, this.error});

  final AuthSession? session;
  final Object? error;

  /// Quando definido, o login fica bloqueado até o completer completar
  /// (usado para testar o estado de loading).
  Completer<void>? gate;

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return session!;
  }

  @override
  Future<AuthSession> register(RegisterParams params) async => session!;

  @override
  Future<AuthSession> refresh() async => session!;

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthUser> me() async => session!.user;

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async =>
      session!.user;

  @override
  Future<void> logout() async {}
}

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Dashboard')));
  }
}

Future<AuthCubit> _pumpLoginScreen(
  WidgetTester tester,
  AuthRepository repository,
) async {
  final cubit = AuthCubit(repository);
  addTearDown(cubit.close);

  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          // Após autenticação o app navega para o dashboard do papel
          // (`business` no _session de teste).
          AppRoutes.businessDashboard: (_) => const _DashboardScreen(),
          AppRoutes.driverDashboard: (_) => const _DashboardScreen(),
        },
        initialRoute: AppRoutes.login,
      ),
    ),
  );

  return cubit;
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'joao@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await tester.tap(find.text('Entrar'));
}

void main() {
  testWidgets('renders identifier and password fields', (tester) async {
    await _pumpLoginScreen(tester, _FakeAuthRepository(session: _session));

    expect(find.text('Email ou telefone'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('empty submit shows validation errors', (tester) async {
    await _pumpLoginScreen(tester, _FakeAuthRepository(session: _session));

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe seu email ou telefone.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('invalid identifier is rejected', (tester) async {
    await _pumpLoginScreen(tester, _FakeAuthRepository(session: _session));

    await tester.enterText(find.byType(TextFormField).at(0), 'abc');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe um email ou telefone válido.'), findsOneWidget);
  });

  testWidgets('short password is rejected', (tester) async {
    await _pumpLoginScreen(tester, _FakeAuthRepository(session: _session));

    await tester.enterText(find.byType(TextFormField).at(0), 'joao@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(
      find.text('A senha deve ter no mínimo 8 caracteres.'),
      findsOneWidget,
    );
  });

  testWidgets('successful login navigates to the redirect route',
      (tester) async {
    await _pumpLoginScreen(tester, _FakeAuthRepository(session: _session));

    await _fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('authentication failure shows an error SnackBar', (tester) async {
    await _pumpLoginScreen(
      tester,
      _FakeAuthRepository(
        error: const UnauthorizedException('Credenciais inválidas.'),
      ),
    );

    await _fillAndSubmit(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Credenciais inválidas.'), findsOneWidget);
  });

  testWidgets('shows loading while authenticating', (tester) async {
    final repository = _FakeAuthRepository(session: _session)
      ..gate = Completer<void>();
    await _pumpLoginScreen(tester, repository);

    await _fillAndSubmit(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsNothing);

    repository.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
