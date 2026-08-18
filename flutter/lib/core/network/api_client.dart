/// Cliente HTTP centralizado — abstrai transporte e mapeamento de erros da
/// camada de dados.
///
/// Regras (docs/flutter/docs/05-api-client.md):
/// - um único cliente HTTP para todo o app;
/// - erros convertidos em exceções de domínio tipadas (nunca stack traces);
/// - requisições mutativas suportam chave de idempotência.
abstract interface class ApiClient {
  Future<ApiResponse> get(String path, {Map<String, String>? query});

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    Map<String, String>? headers,
  });

  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  });

  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  });

  Future<ApiResponse> delete(String path, {Map<String, String>? query});
}

/// Resposta HTTP normalizada (envelope de transporte).
final class ApiResponse {
  const ApiResponse({required this.statusCode, this.data});

  final int statusCode;

  /// Payload deserializado (Map/List/primitive), `null` quando vazio.
  final Object? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
