import '../../../core/models/auth_response_dto.dart';
import '../../../core/models/json_utils.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/api_exception.dart';

/// Data source remoto de autenticação (contrato HTTP do Laravel).
abstract interface class AuthRemoteDataSource {
  /// `POST /auth/login` — email/telefone + senha.
  Future<AuthResponseDto> login({
    required String identifier,
    required String password,
  });

  /// `POST /auth/register` — payload conforme `RegisterRequest` do backend.
  Future<AuthResponseDto> register(Map<String, dynamic> payload);

  /// `POST /auth/refresh` — emite um novo token (Bearer atual no header).
  Future<AuthResponseDto> refresh();

  /// `POST /auth/logout` — revoga o token atual.
  Future<void> logout();

  /// `GET /me` — identidade do usuário autenticado.
  Future<UserDto> me();

  /// `PATCH /me` — atualiza perfil (nome/email/telefone/senha). Retorna o
  /// usuário atualizado (envelope `data.user`).
  Future<UserDto> updateProfile(Map<String, dynamic> payload);
}

final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthResponseDto> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {'identifier': identifier, 'password': password},
    );
    return _parseAuthResponse(response);
  }

  @override
  Future<AuthResponseDto> register(Map<String, dynamic> payload) async {
    final response = await _apiClient.post('/auth/register', body: payload);
    return _parseAuthResponse(response);
  }

  @override
  Future<AuthResponseDto> refresh() async {
    final response = await _apiClient.post('/auth/refresh', body: const {});
    return _parseAuthResponse(response);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post('/auth/logout', body: const {});
  }

  @override
  Future<UserDto> me() async {
    final response = await _apiClient.get('/me');
    final envelope = _asStringMap(response.data);
    // O contrato do backend usa o envelope `{"data": {"user": {...}}}`
    // (docs/docs/api/30-auth-api.md + OpenAPI). Sem esse unwrap, `user`
    // nunca seria encontrado e /me falharia com "Resposta inválida de /me.".
    final data = _asStringMap(envelope['data']);
    final rawUser = data['user'];
    if (rawUser is! Map) {
      throw const ServerException('Resposta inválida de /me.');
    }
    return UserDto.fromJson(JsonUtils.mapOrEmpty(rawUser));
  }

  @override
  Future<UserDto> updateProfile(Map<String, dynamic> payload) async {
    final response = await _apiClient.patch('/me', body: payload);
    final envelope = _asStringMap(response.data);
    final data = _asStringMap(envelope['data']);
    final rawUser = data['user'];
    if (rawUser is! Map) {
      throw const ServerException('Resposta inválida de /me.');
    }
    return UserDto.fromJson(JsonUtils.mapOrEmpty(rawUser));
  }

  static AuthResponseDto _parseAuthResponse(ApiResponse response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return AuthResponseDto.fromJson(data);
    if (data is Map) {
      return AuthResponseDto.fromJson(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    throw const ServerException('Resposta inválida do servidor.');
  }

  static Map<String, dynamic> _asStringMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
}
