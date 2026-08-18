import 'package:delivery_app/core/auth/token_provider.dart';
import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/core/models/auth_response_dto.dart';
import 'package:delivery_app/features/auth/data/auth_remote_data_source.dart';
import 'package:delivery_app/features/auth/data/auth_repository_impl.dart';
import 'package:delivery_app/features/auth/domain/register_params.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> clearToken() async => token = null;
}

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({
    this.loginResult,
    this.meResult,
    this.loginError,
    this.meError,
  });

  final AuthResponseDto? loginResult;
  final UserDto? meResult;
  final ApiException? loginError;
  final ApiException? meError;

  int loginCalls = 0;
  int meCalls = 0;
  int profileUpdateCalls = 0;
  bool logoutCalled = false;

  @override
  Future<AuthResponseDto> login({
    required String identifier,
    required String password,
  }) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<AuthResponseDto> register(Map<String, dynamic> payload) async {
    return loginResult!;
  }

  @override
  Future<AuthResponseDto> refresh() async => loginResult!;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<UserDto> me() async {
    meCalls++;
    if (meError != null) throw meError!;
    return meResult!;
  }

  @override
  Future<UserDto> updateProfile(Map<String, dynamic> payload) async {
    profileUpdateCalls++;
    return meResult ?? const UserDto(id: 'u1', name: 'Atualizado');
  }
}

final _authResponse = AuthResponseDto(
  user: const UserDto(
    id: 'u1',
    name: 'João',
    email: 'joao@example.com',
    roles: ['business'],
  ),
  token: '1|token-value',
  tokenType: 'Bearer',
  expiresIn: 1440,
);

final _me = UserDto(
  id: 'u1',
  name: 'João',
  email: 'joao@example.com',
  roles: const ['business'],
);

const _registerParams = RegisterParams(
  name: 'Loja X',
  email: 'loja@example.com',
  phone: '27999999999',
  password: 'password123',
  passwordConfirmation: 'password123',
  role: AuthRole.business,
  businessName: 'Loja X',
  businessCnpj: '12.345.678/0001-90',
);

void main() {
  group('AuthRepositoryImpl', () {
    test('login saves the token and builds a session', () async {
      final tokenStore = _FakeTokenStore();
      final remote = _FakeAuthRemoteDataSource(loginResult: _authResponse);
      final repository = AuthRepositoryImpl(remote,
        tokenStore,
      );

      final session = await repository.login(
        identifier: 'joao@example.com',
        password: 'password123',
      );

      expect(tokenStore.token, '1|token-value');
      expect(session.token, '1|token-value');
      expect(session.user.id, 'u1');
      expect(session.user.isBusiness, isTrue);
      expect(remote.loginCalls, 1);
    });

    test('login failure does not persist a token', () async {
      final tokenStore = _FakeTokenStore();
      final remote = _FakeAuthRemoteDataSource(
        loginError: const UnauthorizedException('Credenciais inválidas.'),
      );
      final repository = AuthRepositoryImpl(remote,
        tokenStore,
      );

      await expectLater(
        repository.login(identifier: 'x', password: 'y'),
        throwsA(isA<UnauthorizedException>()),
      );

      expect(tokenStore.token, isNull);
    });

    test('register persists the token and returns a session', () async {
      final tokenStore = _FakeTokenStore();
      final remote = _FakeAuthRemoteDataSource(loginResult: _authResponse);
      final repository = AuthRepositoryImpl(remote,
        tokenStore,
      );

      final session = await repository.register(_registerParams);

      expect(tokenStore.token, '1|token-value');
      expect(session.user.name, 'João');
    });

    test('restoreSession returns null when there is no token', () async {
      final repository = AuthRepositoryImpl(_FakeAuthRemoteDataSource(),
        _FakeTokenStore(),
      );

      final session = await repository.restoreSession();

      expect(session, isNull);
    });

    test('restoreSession loads the user via /me when a token exists', () async {
      final tokenStore = _FakeTokenStore()..token = '1|saved-token';
      final remote = _FakeAuthRemoteDataSource(meResult: _me);
      final repository = AuthRepositoryImpl(remote,
        tokenStore,
      );

      final session = await repository.restoreSession();

      expect(session, isNotNull);
      expect(session!.token, '1|saved-token');
      expect(session.user.email, 'joao@example.com');
      expect(remote.meCalls, 1);
    });

    test('restoreSession clears the token when /me returns 401', () async {
      final tokenStore = _FakeTokenStore()..token = '1|expired';
      final remote = _FakeAuthRemoteDataSource(
        meError: const UnauthorizedException('Sessão expirada.'),
      );
      final repository = AuthRepositoryImpl(remote,
        tokenStore,
      );

      final session = await repository.restoreSession();

      expect(session, isNull);
      expect(tokenStore.token, isNull);
    });

    test('logout revokes on the server and clears the local token', () async {
      final tokenStore = _FakeTokenStore()..token = '1|token';
      final remote = _FakeAuthRemoteDataSource();
      final repository = AuthRepositoryImpl(remote,
        tokenStore,
      );

      await repository.logout();

      expect(remote.logoutCalled, isTrue);
      expect(tokenStore.token, isNull);
    });

    test('me() returns the mapped user', () async {
      final remote = _FakeAuthRemoteDataSource(meResult: _me);
      final repository = AuthRepositoryImpl(remote,
        _FakeTokenStore(),
      );

      final user = await repository.me();

      expect(user.id, 'u1');
      expect(user.isBusiness, isTrue);
    });

    test('updateProfile forwards the payload and maps the user', () async {
      final remote = _FakeAuthRemoteDataSource(meResult: _me);
      final repository = AuthRepositoryImpl(remote,
        _FakeTokenStore(),
      );

      final updated = await repository.updateProfile(
        name: 'Novo Nome',
        email: 'novo@example.com',
      );

      expect(remote.profileUpdateCalls, 1);
      expect(updated.id, 'u1');
      expect(updated.email, 'joao@example.com');
    });
  });
}

