import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/core/network/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _exception(
  DioExceptionType type, {
  Response<Object?>? response,
  Object? error,
}) {
  return DioException(
    requestOptions: RequestOptions(path: '/x'),
    type: type,
    response: response,
    error: error,
  );
}

Response<Object?> _errorResponse(int statusCode, Object? data) {
  return Response<Object?>(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  group('ErrorMapper — HTTP status codes', () {
    test('maps 401 to UnauthorizedException', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.badResponse,
        response: _errorResponse(401, {'message': 'Unauthenticated.'}),
      ));

      expect(result, isA<UnauthorizedException>());
      expect(result.statusCode, 401);
      expect(result.message, 'Unauthenticated.');
    });

    test('maps 403 to ForbiddenException', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.badResponse,
        response: _errorResponse(403, {'errors': {'message': 'Forbidden.'}}),
      ));

      expect(result, isA<ForbiddenException>());
      expect(result.statusCode, 403);
    });

    test('maps 409 to ConflictException with domain code', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.badResponse,
        response: _errorResponse(409, {
          'error': {
            'code': 'DELIVERY_ALREADY_ASSIGNED',
            'message': 'A entrega já foi atribuída a outro motoboy.',
            'request_id': 'req-1',
          },
        }),
      ));

      expect(result, isA<ConflictException>());
      expect((result as ConflictException).code, 'DELIVERY_ALREADY_ASSIGNED');
      expect(result.message, 'A entrega já foi atribuída a outro motoboy.');
    });

    test('maps 422 to ValidationException with field errors', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.badResponse,
        response: _errorResponse(422, {
          'message': 'Os dados fornecidos são inválidos.',
          'errors': {
            'origin': ['O campo origem é obrigatório.'],
            'items': ['Adicione ao menos um item.'],
          },
        }),
      ));

      expect(result, isA<ValidationException>());
      final validation = result as ValidationException;
      expect(validation.fieldErrors['origin'], [
        'O campo origem é obrigatório.',
      ]);
      expect(validation.fieldErrors['items'], ['Adicione ao menos um item.']);
    });

    test('maps 429 to RateLimitException with retry_after', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.badResponse,
        response: _errorResponse(429, {'retry_after': 60}),
      ));

      expect(result, isA<RateLimitException>());
      expect((result as RateLimitException).retryAfterSeconds, 60);
    });

    test('maps 500 to ServerException', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.badResponse,
        response: _errorResponse(500, {'message': 'Internal server error.'}),
      ));

      expect(result, isA<ServerException>());
      expect(result.statusCode, 500);
    });

    test('maps unhandled status codes to ServerException safely', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.badResponse,
        response: _errorResponse(404, {'message': 'Not found.'}),
      ));

      expect(result, isA<ServerException>());
      expect(result.statusCode, 404);
      expect(result.message, isNot(contains('StackTrace')));
    });

    test('uses safe fallback when the server sends no message', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.badResponse,
        response: _errorResponse(500, null),
      ));

      expect(result, isA<ServerException>());
      expect(result.message, isNotEmpty);
      expect(result.data, isNull);
    });
  });

  group('ErrorMapper — transport failures', () {
    test('maps timeouts to NetworkException with isTimeout=true', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final result = ErrorMapper.map(_exception(type));
        expect(result, isA<NetworkException>(),
            reason: 'type $type deve virar NetworkException');
        expect((result as NetworkException).isTimeout, isTrue);
      }
    });

    test('maps connectionError to NetworkException (not permanent)', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.connectionError,
      ));

      expect(result, isA<NetworkException>());
      expect((result as NetworkException).isTimeout, isFalse);
    });

    test('maps unknown error with SocketException-like cause to NetworkException',
        () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.unknown,
        error: Exception('Connection refused'),
      ));

      expect(result, isA<NetworkException>());
    });

    test('maps badResponse without response safely', () {
      final result = ErrorMapper.map(_exception(
        DioExceptionType.badResponse,
      ));

      expect(result, isA<ServerException>());
    });
  });
}
