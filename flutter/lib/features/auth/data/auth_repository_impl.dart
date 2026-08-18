import '../../../core/auth/token_provider.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/models/auth_response_dto.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/auth_user.dart';
import '../domain/register_params.dart';
import 'auth_remote_data_source.dart';
import 'user_mapper.dart';

/// Implementação do [AuthRepository] que orquestra o data source remoto e o
/// ciclo de vida do token no secure storage ([TokenStore]).
final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._tokenStore);

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStore _tokenStore;

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final auth = await _remoteDataSource.login(
      identifier: identifier,
      password: password,
    );
    return _persistSession(auth);
  }

  @override
  Future<AuthSession> register(RegisterParams params) async {
    final auth = await _remoteDataSource.register(params.toJson());
    return _persistSession(auth);
  }

  @override
  Future<AuthSession> refresh() async {
    final auth = await _remoteDataSource.refresh();
    final token = auth.token;
    if (token == null || token.isEmpty) {
      throw const ServerException('Resposta de refresh sem token.');
    }
    await _tokenStore.saveToken(token);

    // O refresh devolve apenas o token; o usuário é recarregado via /me.
    final me = await _remoteDataSource.me();
    return AuthSession(
      token: token,
      user: UserMapper.fromDto(me),
      tokenType: auth.tokenType,
      expiresIn: auth.expiresIn,
    );
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final me = await _remoteDataSource.me();
      return AuthSession(token: token, user: UserMapper.fromDto(me));
    } on UnauthorizedException {
      // Token inválido/expirado: limpa e trata como sessão inexistente.
      await _tokenStore.clearToken();
      return null;
    }
  }

  @override
  Future<AuthUser> me() async {
    final user = await _remoteDataSource.me();
    return UserMapper.fromDto(user);
  }

  @override
  Future<AuthUser> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    final payload = <String, dynamic>{
      'name': ?name,
      'email': ?email,
      'phone': ?phone,
      'current_password': ?currentPassword,
      'password': ?password,
      'password_confirmation': ?passwordConfirmation,
    };
    final user = await _remoteDataSource.updateProfile(payload);
    return UserMapper.fromDto(user);
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } on ApiException {
      // Mesmo sem resposta do servidor, a sessão local é encerrada.
    } finally {
      await _tokenStore.clearToken();
    }
  }

  Future<AuthSession> _persistSession(AuthResponseDto auth) async {
    final token = auth.token;
    if (token == null || token.isEmpty) {
      throw const ServerException('Resposta de autenticação sem token.');
    }
    await _tokenStore.saveToken(token);

    final user = auth.user;
    if (user == null) {
      throw const ServerException('Resposta de autenticação sem usuário.');
    }
    return AuthSession(
      token: token,
      user: UserMapper.fromDto(user),
      tokenType: auth.tokenType,
      expiresIn: auth.expiresIn,
    );
  }
}
