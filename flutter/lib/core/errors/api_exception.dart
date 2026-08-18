/// Exceções tipadas de domínio para erros da API.
///
/// Produzidas pelo `ErrorMapper` a partir de códigos HTTP e falhas de
/// transporte. Nunca carregam stack traces nem dados sensíveis: apenas
/// mensagens seguras para apresentação e payloads estruturados opcionais
/// (para tratamento nos repositories, não exibição).
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.data});

  /// Mensagem segura para exibição ao usuário.
  final String message;

  /// Código HTTP original; `null` quando não houve resposta HTTP.
  final int? statusCode;

  /// Payload bruto da resposta (ex.: `{"errors": ...}`) para tratamento
  /// estruturado nos repositories.
  final Object? data;

  @override
  String toString() => '$runtimeType(status: $statusCode): $message';
}

/// 401 — credencial ausente, inválida ou expirada.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message,
      {super.statusCode = 401, super.data});
}

/// 403 — autenticado, porém sem permissão para a operação.
final class ForbiddenException extends ApiException {
  const ForbiddenException(super.message,
      {super.statusCode = 403, super.data});
}

/// 409 — conflito de estado (ex.: entrega já atribuída) ou conflito de
/// idempotência (mesma chave, payload diferente).
final class ConflictException extends ApiException {
  const ConflictException(super.message,
      {this.code, super.statusCode = 409, super.data});

  /// Código de erro de domínio do servidor (ex.: `DELIVERY_ALREADY_ASSIGNED`).
  final String? code;
}

/// 422 — erro de validação; [fieldErrors] mapeia campo → mensagens.
final class ValidationException extends ApiException {
  const ValidationException(
    super.message, {
    this.fieldErrors = const {},
    super.statusCode = 422,
    super.data,
  });

  final Map<String, List<String>> fieldErrors;
}

/// 429 — rate limit; [retryAfterSeconds] quando informado pelo servidor.
final class RateLimitException extends ApiException {
  const RateLimitException(
    super.message, {
    this.retryAfterSeconds,
    super.statusCode = 429,
    super.data,
  });

  final int? retryAfterSeconds;
}

/// 5xx — falha do servidor.
final class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode = 500, super.data});
}

/// Falha de conectividade ou timeout.
///
/// Regra (offline-first): falha de conectividade NÃO deve virar erro
/// permanente quando a ação é enfileirável.
final class NetworkException extends ApiException {
  const NetworkException(super.message, {this.isTimeout = false, super.data});

  /// `true` quando a causa foi timeout (conexão/envio/recebimento).
  final bool isTimeout;
}
