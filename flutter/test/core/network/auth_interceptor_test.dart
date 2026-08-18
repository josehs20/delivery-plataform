import 'package:delivery_app/core/auth/token_provider.dart';
import 'package:delivery_app/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenProvider implements TokenProvider {
  _FakeTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> readToken() async => token;
}

class _RecordingHandler extends RequestInterceptorHandler {
  final List<RequestOptions> captured = [];

  @override
  void next(RequestOptions requestOptions) {
    captured.add(requestOptions);
  }
}

/// Handler de erro que não propaga o resultado (evita erro não tratado no
/// zone de teste quando `handler.next(err)` é chamado sem um request ativo).
class _SilentErrorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException err) {
    // no-op
  }
}

void main() {
  late _RecordingHandler handler;

  setUp(() {
    handler = _RecordingHandler();
  });

  test('attaches Bearer token when a token is saved', () async {
    final interceptor = AuthInterceptor(_FakeTokenProvider('tok-123'));
    final options = RequestOptions(path: '/deliveries');

    await interceptor.onRequest(options, handler);

    expect(handler.captured, hasLength(1));
    expect(handler.captured.single.headers['Authorization'], 'Bearer tok-123');
  });

  test('does not attach Authorization when there is no token', () async {
    final interceptor = AuthInterceptor(_FakeTokenProvider(null));
    final options = RequestOptions(path: '/deliveries');

    await interceptor.onRequest(options, handler);

    expect(handler.captured.single.headers.containsKey('Authorization'), isFalse);
  });

  test('preserves an existing Authorization header', () async {
    final interceptor = AuthInterceptor(_FakeTokenProvider('tok-123'));
    final options = RequestOptions(
      path: '/deliveries',
      headers: {'Authorization': 'Bearer existing-token'},
    );

    await interceptor.onRequest(options, handler);

    expect(
      handler.captured.single.headers['Authorization'],
      'Bearer existing-token',
    );
  });

  test('does not read the provider when the header is already present',
      () async {
    var readCalls = 0;
    final interceptor = AuthInterceptor(
      _TokenProviderSpy(onRead: () {
        readCalls++;
        return 'tok';
      }),
    );
    final options = RequestOptions(
      path: '/x',
      headers: {'Authorization': 'Bearer fixed'},
    );

    await interceptor.onRequest(options, handler);

    expect(readCalls, 0);
  });

  group('AuthInterceptor — onUnauthorized (sessão expirada)', () {
    test('invokes the callback on a 401 for an authenticated request',
        () async {
      var called = false;
      final interceptor = AuthInterceptor(
        _FakeTokenProvider('tok-123'),
        onUnauthorized: () => called = true,
      );
      final err = DioException(
        requestOptions: RequestOptions(
          path: '/deliveries',
          headers: {'Authorization': 'Bearer tok-123'},
        ),
        response: Response(
          requestOptions: RequestOptions(path: '/deliveries'),
          statusCode: 401,
        ),
      );

      interceptor.onError(err, _SilentErrorHandler());

      expect(called, isTrue);
    });

    test('does not invoke the callback on 401 during login (no auth header)',
        () async {
      var called = false;
      final interceptor = AuthInterceptor(
        _FakeTokenProvider(null),
        onUnauthorized: () => called = true,
      );
      final err = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
        ),
      );

      interceptor.onError(err, _SilentErrorHandler());

      expect(called, isFalse);
    });

    test('does not invoke the callback on non-401 errors', () async {
      var called = false;
      final interceptor = AuthInterceptor(
        _FakeTokenProvider('tok-123'),
        onUnauthorized: () => called = true,
      );
      final err = DioException(
        requestOptions: RequestOptions(
          path: '/deliveries',
          headers: {'Authorization': 'Bearer tok-123'},
        ),
        response: Response(
          requestOptions: RequestOptions(path: '/deliveries'),
          statusCode: 500,
        ),
      );

      interceptor.onError(err, _SilentErrorHandler());

      expect(called, isFalse);
    });
  });
}

class _TokenProviderSpy implements TokenProvider {
  _TokenProviderSpy({required this.onRead});

  final String Function() onRead;

  @override
  Future<String?> readToken() async => onRead();
}
