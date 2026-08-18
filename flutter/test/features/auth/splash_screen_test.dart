import 'package:delivery_app/app/routes/app_routes.dart';
import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/features/auth/domain/auth_repository.dart';
import 'package:delivery_app/features/auth/domain/auth_session.dart';
import 'package:delivery_app/features/auth/domain/auth_user.dart';
import 'package:delivery_app/features/auth/domain/register_params.dart';
import 'package:delivery_app/features/auth/presentation/auth_cubit.dart';
import 'package:delivery_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final _session = AuthSession(
  token: '1|token',
  user: const AuthUser(
    id: 'u1',
    name: 'João',
    email: 'joao@example.com',
    roles: ['driver'],
  ),
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.session, this.error});

  final AuthSession? session;
  final Object? error;

  @override
  Future<AuthSession?> restoreSession() async {
    if (error != null) throw error!;
    return session;
  }

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async =>
      session!;

  @override
  Future<AuthSession> register(RegisterParams params) async => session!;

  @override
  Future<AuthSession> refresh() async => session!;

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

class _LoginPlaceholder extends StatelessWidget {
  const _LoginPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Login')));
  }
}

class _FeedPlaceholder extends StatelessWidget {
  const _FeedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Feed')));
  }
}

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Dashboard')));
  }
}

Future<AuthCubit> _pumpSplash(
  WidgetTester tester,
  _FakeAuthRepository repository, {
  String authenticatedRoute = AppRoutes.feed,
}) async {
  final cubit = AuthCubit(repository);
  addTearDown(cubit.close);

  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) =>
              SplashScreen(authenticatedRoute: authenticatedRoute),
          AppRoutes.login: (_) => const _LoginPlaceholder(),
          AppRoutes.feed: (_) => const _FeedPlaceholder(),
          AppRoutes.dashboard: (_) => const _DashboardPlaceholder(),
        },
      ),
    ),
  );

  return cubit;
}

void main() {
  testWidgets('shows the splash on the first frame', (tester) async {
    await _pumpSplash(tester, _FakeAuthRepository());

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('redirects to login when there is no saved session',
      (tester) async {
    await _pumpSplash(tester, _FakeAuthRepository());

    await tester.pumpAndSettle();

    expect(find.byType(_LoginPlaceholder), findsOneWidget);
  });

  testWidgets('redirects to the authenticated route when the session is valid',
      (tester) async {
    await _pumpSplash(tester, _FakeAuthRepository(session: _session));

    await tester.pumpAndSettle();

    expect(find.byType(_FeedPlaceholder), findsOneWidget);
  });

  testWidgets('redirects to the custom route when authenticated',
      (tester) async {
    await _pumpSplash(
      tester,
      _FakeAuthRepository(session: _session),
      authenticatedRoute: AppRoutes.dashboard,
    );

    await tester.pumpAndSettle();

    expect(find.byType(_DashboardPlaceholder), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('redirects to login when restoring the session fails',
      (tester) async {
    await _pumpSplash(
      tester,
      _FakeAuthRepository(
        error: const UnauthorizedException('Token expirado.'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(_LoginPlaceholder), findsOneWidget);
  });
}