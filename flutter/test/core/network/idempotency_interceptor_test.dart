import 'package:delivery_app/core/network/idempotency_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingHandler extends RequestInterceptorHandler {
  final List<RequestOptions> captured = [];

  @override
  void next(RequestOptions requestOptions) {
    captured.add(requestOptions);
  }
}

void main() {
  late _RecordingHandler handler;

  setUp(() {
    handler = _RecordingHandler();
  });

  IdempotencyInterceptor build({String Function()? keyGenerator}) {
    return IdempotencyInterceptor(
      keyGenerator ?? () => 'generated-key-123',
    );
  }

  test('generates a key for POST requests without one', () {
    final interceptor = build();
    final options = RequestOptions(path: '/deliveries', method: 'POST');

    interceptor.onRequest(options, handler);

    expect(handler.captured.single.headers[Idempotency.header], 'generated-key-123');
  });

  test('generates a key for PUT and PATCH requests', () {
    for (final method in ['PUT', 'PATCH']) {
      final localHandler = _RecordingHandler();
      final interceptor = build();
      final options = RequestOptions(path: '/x', method: method);

      interceptor.onRequest(options, localHandler);

      expect(
        localHandler.captured.single.headers[Idempotency.header],
        'generated-key-123',
        reason: 'method $method deve receber chave de idempotência',
      );
    }
  });

  test('preserves a caller-provided key (retry reuses the same key)', () {
    final interceptor = build();
    final options = RequestOptions(
      path: '/deliveries/1/pickup',
      method: 'POST',
      headers: {Idempotency.header: 'my-key-123456'},
    );

    interceptor.onRequest(options, handler);

    expect(handler.captured.single.headers[Idempotency.header], 'my-key-123456');
  });

  test('does not add a key to GET requests', () {
    final interceptor = build();
    final options = RequestOptions(path: '/deliveries');

    interceptor.onRequest(options, handler);

    expect(
      handler.captured.single.headers.containsKey(Idempotency.header),
      isFalse,
    );
  });

  test('does not add a key to DELETE requests', () {
    final interceptor = build();
    final options = RequestOptions(path: '/deliveries/1', method: 'DELETE');

    interceptor.onRequest(options, handler);

    expect(
      handler.captured.single.headers.containsKey(Idempotency.header),
      isFalse,
    );
  });
}
