import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/core/network/api_client.dart';
import 'package:delivery_app/features/auth/data/auth_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake do [ApiClient] que devolve payloads no envelope do Laravel
/// (`{"data": {...}}`), como o backend real responde.
class _FakeApiClient implements ApiClient {
  _FakeApiClient(this._handler);

  final Object? Function(String path) _handler;

  @override
  Future<ApiResponse> get(String path, {Map<String, String>? query}) async =>
      ApiResponse(statusCode: 200, data: _handler(path));

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    Map<String, String>? headers,
  }) async =>
      ApiResponse(statusCode: 200, data: _handler(path));

  @override
  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async =>
      ApiResponse(statusCode: 200, data: _handler(path));

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async =>
      ApiResponse(statusCode: 200, data: _handler(path));

  @override
  Future<ApiResponse> delete(String path, {Map<String, String>? query}) async =>
      ApiResponse(statusCode: 200, data: _handler(path));
}

void main() {
  group('AuthRemoteDataSourceImpl — envelope data (contrato Laravel)', () {
    test('me() deserializa o envelope {"data": {"user": {...}}}', () async {
      final remote = AuthRemoteDataSourceImpl(
        _FakeApiClient(
          (path) => <String, dynamic>{
            'data': <String, dynamic>{
              'user': <String, dynamic>{
                'id': 'u1',
                'name': 'João',
                'email': 'joao@example.com',
                'phone': '+5527999999999',
                'roles': ['business'],
                'is_blocked': false,
              },
              'permissions': <String>[],
              'context': <String, dynamic>{'business': <String, dynamic>{}},
            },
          },
        ),
      );

      final user = await remote.me();

      expect(user.id, 'u1');
      expect(user.name, 'João');
      expect(user.email, 'joao@example.com');
      expect(user.roles, ['business']);
      expect(user.isBlocked, isFalse);
    });

    test('me() lança ServerException quando falta data.user', () async {
      final remote = AuthRemoteDataSourceImpl(
        _FakeApiClient(
          (path) => <String, dynamic>{
            'data': <String, dynamic>{'permissions': <String>[]},
          },
        ),
      );

      await expectLater(remote.me(), throwsA(isA<ServerException>()));
    });

    test('login() deserializa data.token e data.user do envelope', () async {
      final remote = AuthRemoteDataSourceImpl(
        _FakeApiClient(
          (path) => <String, dynamic>{
            'data': <String, dynamic>{
              'user': <String, dynamic>{'id': 'u1', 'name': 'João'},
              'token': '1|token-value',
              'token_type': 'Bearer',
            },
          },
        ),
      );

      final auth = await remote.login(
        identifier: 'joao@example.com',
        password: 'password123',
      );

      expect(auth.token, '1|token-value');
      expect(auth.tokenType, 'Bearer');
      expect(auth.user!.id, 'u1');
    });
  });
}
