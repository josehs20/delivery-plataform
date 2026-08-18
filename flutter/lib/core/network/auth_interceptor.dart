import 'package:dio/dio.dart';

import '../auth/token_provider.dart';

/// Anexa `Authorization: Bearer <token>` quando há token salvo.
///
/// - O token é lido via [TokenProvider] (default: flutter_secure_storage).
/// - Nunca loga o token.
/// - Se a requisição já possui um header `Authorization` (ex.: definido pelo
///   chamador após um refresh), o valor existente é preservado.
/// - Em uma resposta 401 de uma requisição autenticada, [onUnauthorized] é
///   invocado (sessão expirada/revogada) para o app poder deslogar o usuário.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._tokenProvider, {
    this.onUnauthorized,
  });

  final TokenProvider _tokenProvider;

  /// Chamado quando uma requisição que carregava `Authorization` recebe 401.
  final void Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('Authorization')) {
      final token = await _tokenProvider.readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final wasAuthenticated =
        err.requestOptions.headers.containsKey('Authorization');
    final isUnauthorized = err.response?.statusCode == 401;

    if (isUnauthorized && wasAuthenticated && onUnauthorized != null) {
      onUnauthorized!();
    }

    handler.next(err);
  }
}
