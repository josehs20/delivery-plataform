import 'dart:io';

import 'package:delivery_app/app/bootstrap/app_bootstrap.dart';
import 'package:delivery_app/core/auth/token_provider.dart';
import 'package:delivery_app/core/network/api_client.dart';
import 'package:delivery_app/features/auth/presentation/auth_cubit.dart';
import 'package:delivery_app/features/auth/presentation/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;
}

class _FakeApiClient implements ApiClient {
  ApiResponse? meResponse;

  @override
  Future<ApiResponse> get(String path, {Map<String, String>? query}) async {
    if (path == '/me' && meResponse != null) return meResponse!;
    throw UnimplementedError('GET $path');
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    Map<String, String>? headers,
  }) =>
      throw UnimplementedError('POST $path');

  @override
  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError('PUT $path');

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError('PATCH $path');

  @override
  Future<ApiResponse> delete(String path, {Map<String, String>? query}) =>
      throw UnimplementedError('DELETE $path');
}

void main() {
  late Directory tempDir;
  late _FakeTokenStore tokenStore;
  late _FakeApiClient apiClient;
  late AppDependencies dependencies;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_bootstrap_test_');
    tokenStore = _FakeTokenStore();
    apiClient = _FakeApiClient();
    dependencies = await AppBootstrap.create(
      databaseDirectory: tempDir,
      tokenStore: tokenStore,
      apiClient: apiClient,
    );
  });

  tearDown(() async {
    await dependencies.localDatabase.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('injects the provided token store and api client', () {
    expect(dependencies.tokenStore, same(tokenStore));
    expect(dependencies.apiClient, same(apiClient));
  });

  test('wires the essential services and controllers', () {
    expect(dependencies.localDatabase, isNotNull);
    expect(dependencies.authCubit, isA<AuthCubit>());
    expect(dependencies.deliveryListCubit, isNotNull);
    expect(dependencies.deliveryDetailCubit, isNotNull);
    expect(dependencies.syncService, isNotNull);
  });

  test('auth cubit starts unauthenticated', () {
    expect(dependencies.authCubit.state, isA<AuthUnauthenticated>());
  });

  test('keeps the app unauthenticated when no token exists', () async {
    await dependencies.authCubit.restoreSession();

    expect(dependencies.authCubit.state, isA<AuthUnauthenticated>());
  });

  test('restores a session when a token is stored and /me responds', () async {
    await tokenStore.saveToken('1|token');
    apiClient.meResponse = ApiResponse(
      statusCode: 200,
      data: {
        'data': {
          'user': {'id': 'u1', 'name': 'João', 'roles': ['driver']},
        },
      },
    );

    await dependencies.authCubit.restoreSession();

    expect(dependencies.authCubit.state, isA<AuthAuthenticated>());
  });
}