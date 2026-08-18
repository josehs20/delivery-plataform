// Smoke test do bootstrap: o App inicia no Splash e, sem sessão salva,
// redireciona para o Login (a primeira tela operacional do app).

import 'dart:io';

import 'package:delivery_app/app/app.dart';
import 'package:delivery_app/app/bootstrap/app_bootstrap.dart';
import 'package:delivery_app/app/routes/app_routes.dart';
import 'package:delivery_app/core/auth/token_provider.dart';
import 'package:delivery_app/core/network/api_client.dart';
import 'package:delivery_app/features/auth/presentation/screens/login_screen.dart';
import 'package:delivery_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
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
  @override
  Future<ApiResponse> get(String path, {Map<String, String>? query}) =>
      throw UnimplementedError('GET $path');

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
  late AppDependencies dependencies;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_smoke_test_');
    dependencies = await AppBootstrap.create(
      databaseDirectory: tempDir,
      tokenStore: _FakeTokenStore(),
      apiClient: _FakeApiClient(),
    );
  });

  tearDown(() async {
    await dependencies.localDatabase.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  testWidgets('boots on the splash and redirects to login without a session',
      (tester) async {
    await tester.pumpWidget(App(dependencies: dependencies));

    // Primeiro frame: Splash com o MaterialApp configurado.
    expect(find.byType(SplashScreen), findsOneWidget);
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'Delivery App');
    expect(materialApp.initialRoute, AppRoutes.splash);
    expect(materialApp.theme, isNotNull);

    // Sem token salvo, a restauração falha → Login (primeira tela operacional).
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
