import 'package:dio/dio.dart';

/// Constantes do contrato de idempotência (ADR-005).
final class Idempotency {
  const Idempotency._();

  /// Header lido pelo middleware `IdempotencyKeyMiddleware` do Laravel.
  ///
  /// Nota: o OpenAPI nomeia o parâmetro como `Idempotency-Key`, mas o
  /// middleware implementado lê `X-Idempotency-Key` (header também suporta o
  /// campo de corpo `idempotency_key`/`sync_token` como fallback).
  static const header = 'X-Idempotency-Key';

  /// Limites do contrato OpenAPI (min 8, max 255 caracteres).
  static const minLength = 8;
  static const maxLength = 255;
}

/// Anexa `X-Idempotency-Key` em requisições mutativas (POST/PUT/PATCH).
///
/// Uma chave explícita fornecida pelo chamador (ex.: para reutilizar a chave
/// num retry) é preservada; caso contrário, uma nova chave é gerada. GET e
/// DELETE são idempotentes por natureza e não recebem chave.
final class IdempotencyInterceptor extends Interceptor {
  IdempotencyInterceptor(this._keyGenerator);

  final String Function() _keyGenerator;

  static const _mutativeMethods = {'POST', 'PUT', 'PATCH'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final hasKey = options.headers.containsKey(Idempotency.header);

    if (_mutativeMethods.contains(method) && !hasKey) {
      options.headers[Idempotency.header] = _keyGenerator();
    }

    handler.next(options);
  }
}
