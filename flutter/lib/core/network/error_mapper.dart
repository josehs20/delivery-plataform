import 'dart:async' show TimeoutException;

import 'package:dio/dio.dart';

import '../errors/api_exception.dart';

/// Converte [DioException] em [ApiException] tipada.
///
/// Regras (docs/docs/api/42-api-errors-idempotency-concurrency.md e
/// .cursor/rules/13-error-handling.mdc):
/// - nunca expor stack traces ou detalhes internos na mensagem;
/// - mensagem segura (do servidor quando disponível) para a UI;
/// - payload estruturado preservado em [ApiException.data] para o repository;
/// - falha de conectividade NÃO vira erro permanente quando a ação é
///   enfileirável ([NetworkException]).
final class ErrorMapper {
  const ErrorMapper._();

  static ApiException map(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkException(
          'Tempo de conexão esgotado. Verifique sua internet e tente novamente.',
          isTimeout: true,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          'Falha de conexão com o servidor. Verifique sua internet.',
        );
      case DioExceptionType.badCertificate:
        return NetworkException(
          'Falha na validação do certificado do servidor.',
        );
      case DioExceptionType.cancel:
        return NetworkException('Requisição cancelada.');
      case DioExceptionType.badResponse:
        final response = error.response;
        if (response == null) {
          return ServerException('Resposta inválida do servidor.');
        }
        return _fromStatusCode(response.statusCode ?? 0, response.data);
      case DioExceptionType.unknown:
        final response = error.response;
        if (response != null && response.statusCode != null) {
          return _fromStatusCode(response.statusCode!, response.data);
        }
        return NetworkException(
          'Falha de conexão com o servidor. Verifique sua internet.',
          isTimeout: error.error is TimeoutException,
        );
    }
  }

  static ApiException _fromStatusCode(int statusCode, Object? data) {
    switch (statusCode) {
      case 401:
        return UnauthorizedException(
          _serverMessage(data) ?? 'Sessão expirada. Entre novamente.',
          data: data,
        );
      case 403:
        return ForbiddenException(
          _serverMessage(data) ?? 'Você não tem permissão para esta ação.',
          data: data,
        );
      case 409:
        return ConflictException(
          _serverMessage(data) ?? 'Conflito no estado da operação.',
          code: _errorCode(data),
          data: data,
        );
      case 422:
        return ValidationException(
          _serverMessage(data) ?? 'Dados inválidos. Revise as informações.',
          fieldErrors: _fieldErrors(data),
          data: data,
        );
      case 429:
        return RateLimitException(
          _serverMessage(data) ??
              'Muitas tentativas. Aguarde e tente novamente.',
          retryAfterSeconds: _retryAfter(data),
          data: data,
        );
      default:
        return ServerException(
          _serverMessage(data) ?? 'Falha na requisição (HTTP $statusCode).',
          statusCode: statusCode,
          data: data,
        );
    }
  }

  /// Mensagem segura fornecida pelo servidor, quando disponível.
  static String? _serverMessage(Object? data) {
    if (data is! Map) return null;
    final error = data['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    final errors = data['errors'];
    if (errors is Map && errors['message'] is String) {
      return errors['message'] as String;
    }
    if (data['message'] is String) return data['message'] as String;
    return null;
  }

  /// Código de erro de domínio (ex.: `DELIVERY_ALREADY_ASSIGNED`).
  static String? _errorCode(Object? data) {
    if (data is! Map) return null;
    final error = data['error'];
    if (error is Map && error['code'] is String) return error['code'] as String;
    return null;
  }

  /// Erros por campo do Laravel: `{"errors": {"field": ["mensagem"]}}`.
  static Map<String, List<String>> _fieldErrors(Object? data) {
    if (data is! Map) return const {};
    final errors = data['errors'];
    if (errors is! Map) return const {};
    return errors.map((key, value) {
      final messages = value is List
          ? value
                .map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList(growable: false)
          : <String>[value?.toString() ?? ''];
      return MapEntry(key.toString(), messages);
    });
  }

  static int? _retryAfter(Object? data) {
    if (data is! Map) return null;
    final value = data['retry_after'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
