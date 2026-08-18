import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/features/auth/domain/auth_repository.dart';
import 'package:delivery_app/features/auth/domain/auth_session.dart';
import 'package:delivery_app/features/auth/domain/auth_user.dart';
import 'package:delivery_app/features/auth/domain/register_params.dart';
import 'package:delivery_app/features/auth/presentation/auth_cubit.dart';
import 'package:delivery_app/features/auth/presentation/auth_state.dart';
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
  _FakeAuthRepository({this.loginError, this.restoredSession});

  final Object? loginError;
  final AuthSession? restoredSession;
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    return _session;
  }

  @override
  Future<AuthSession> register(RegisterParams params) async => _session;

  @override
  Future<AuthSession> refresh() async => _session;

  @override
  Future<AuthSession?> restoreSession() async => restoredSession;

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
  Future<void> logout() async {
    logoutCalls++;
  }
}

void main() {
  test('initial state is Unauthenticated', () {
    final cubit = AuthCubit(_FakeAuthRepository());

    expect(cubit.state, isA<AuthUnauthenticated>());

    cubit.close();
  });

  test('login emits Authenticating then Authenticated', () async {
    final cubit = AuthCubit(_FakeAuthRepository());
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<AuthAuthenticating>(),
        isA<AuthAuthenticated>(),
      ]),
    );

    await cubit.login(identifier: 'joao@example.com', password: 'password123');
    await expectation;

    expect((cubit.state as AuthAuthenticated).session.user.name, 'João');

    cubit.close();
  });

  test('login failure emits AuthError with a safe message', () async {
    final cubit = AuthCubit(
      _FakeAuthRepository(
        loginError: const UnauthorizedException('Credenciais inválidas.'),
      ),
    );
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<AuthAuthenticating>(),
        isA<AuthError>(),
      ]),
    );

    await cubit.login(identifier: 'x', password: 'y');
    await expectation;

    expect((cubit.state as AuthError).message, 'Credenciais inválidas.');

    cubit.close();
  });

  test('login unexpected failure emits a generic AuthError', () async {
    final cubit = AuthCubit(
      _FakeAuthRepository(loginError: StateError('boom')),
    );
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<AuthAuthenticating>(),
        isA<AuthError>(),
      ]),
    );

    await cubit.login(identifier: 'x', password: 'y');
    await expectation;

    expect((cubit.state as AuthError).message, contains('Não foi possível'));

    cubit.close();
  });

  test('restoreSession restores an authenticated session', () async {
    final cubit = AuthCubit(
      _FakeAuthRepository(restoredSession: _session),
    );
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<AuthAuthenticating>(),
        isA<AuthAuthenticated>(),
      ]),
    );

    await cubit.restoreSession();
    await expectation;

    expect(cubit.state, isA<AuthAuthenticated>());

    cubit.close();
  });

  test('restoreSession without a session returns to Unauthenticated', () async {
    final cubit = AuthCubit(_FakeAuthRepository());
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<AuthAuthenticating>(),
        isA<AuthUnauthenticated>(),
      ]),
    );

    await cubit.restoreSession();
    await expectation;

    expect(cubit.state, isA<AuthUnauthenticated>());

    cubit.close();
  });

  test('logout ends the session', () async {
    final repository = _FakeAuthRepository(restoredSession: _session);
    final cubit = AuthCubit(repository);
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<AuthAuthenticating>(),
        isA<AuthAuthenticated>(),
        isA<AuthUnauthenticated>(),
      ]),
    );

    await cubit.restoreSession();
    await cubit.logout();
    await expectation;

    expect(repository.logoutCalls, 1);
    expect(cubit.state, isA<AuthUnauthenticated>());

    cubit.close();
  });
}
