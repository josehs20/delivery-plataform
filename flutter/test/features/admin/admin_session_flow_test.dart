// Fluxo de sessão do admin no app completo (App real + fakes de API/storage):
// restauração → tela administrativa (não o feed) → logout revoga token no
// backend e volta ao Login limpo. Também valida que o "Voltar" não joga o
// admin de volta ao Splash (anti loading infinito).

import 'dart:io';

import 'package:delivery_app/app/app.dart';
import 'package:delivery_app/app/bootstrap/app_bootstrap.dart';
import 'package:delivery_app/app/routes/app_routes.dart';
import 'package:delivery_app/core/auth/token_provider.dart';
import 'package:delivery_app/core/network/api_client.dart';
import 'package:delivery_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:delivery_app/features/auth/presentation/screens/login_screen.dart';
import 'package:delivery_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:delivery_app/features/delivery/presentation/screens/delivery_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenStore implements TokenStore {
  _FakeTokenStore(this._token);

  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;
}

class _FakeApiClient implements ApiClient {
  final List<String> calls = [];

  @override
  Future<ApiResponse> get(String path, {Map<String, String>? query}) async {
    calls.add('GET $path');
    if (path == '/me') {
      return ApiResponse(
        statusCode: 200,
        data: {
          'data': {
            'user': {
              'id': 'u-admin',
              'name': 'Admin',
              'email': 'admin@example.com',
              'phone': '+5531999990000',
              'roles': ['admin'],
            },
          },
        },
      );
    }
    throw UnimplementedError('GET $path');
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    Map<String, String>? headers,
  }) async {
    calls.add('POST $path');
    if (path == '/auth/logout') {
      return ApiResponse(
        statusCode: 200,
        data: {'data': {'message': 'Successfully logged out'}},
      );
    }
    throw UnimplementedError('POST $path');
  }

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
  late AppDependencies dependencies;
  late _FakeTokenStore tokenStore;
  late _FakeApiClient apiClient;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('admin_flow_test_');
    tokenStore = _FakeTokenStore('1|admin-token');
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

  testWidgets(
      'an admin session opens the dedicated admin screen (never the generic '
      'deliveries feed)', (tester) async {
    await tester.pumpWidget(App(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    expect(find.byType(DeliveryFeedScreen), findsNothing);
    expect(find.byType(SplashScreen), findsNothing);
    // Sem loading infinito: a restauração conclui e navega.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
      'admin logout calls POST /auth/logout, clears the local session and '
      'lands on the clean login screen', (tester) async {
    await tester.pumpWidget(App(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardScreen), findsOneWidget);

    await tester.ensureVisible(find.text('Sair da conta'));
    await tester.tap(find.text('Sair da conta'));
    await tester.pumpAndSettle();

    // Backend: POST /auth/logout consumido (sem 404) — registrado no cliente.
    expect(apiClient.calls, contains('POST /auth/logout'));
    // SecureStorage/Hive local limpos.
    expect(await tokenStore.readToken(), isNull);
    // Navegação: Login limpo.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(AdminDashboardScreen), findsNothing);
  });

  testWidgets(
      'navigating back to the root while authenticated returns to admin '
      '(no infinite loading)', (tester) async {
    await tester.pumpWidget(App(dependencies: dependencies));
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardScreen), findsOneWidget);

    // Simula o "Voltar"/navegação manual para a raiz `/` (Splash).
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(AppRoutes.splash);
    await tester.pumpAndSettle();

    // O Splash detecta a sessão ativa e redireciona de volta ao admin —
    // sem ficar preso no indicador de carregamento.
    expect(find.byType(AdminDashboardScreen), findsWidgets);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
