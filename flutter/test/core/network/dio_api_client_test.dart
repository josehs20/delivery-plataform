import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:delivery_app/core/auth/token_provider.dart';
import 'package:delivery_app/core/errors/api_exception.dart';
import 'package:delivery_app/core/network/dio_api_client.dart';
import 'package:delivery_app/core/network/idempotency_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';

class _FakeTokenProvider implements TokenProvider {
  _FakeTokenProvider([this.token]);

  final String? token;

  @override
  Future<String?> readToken() async => token;
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.onFetch);

  final Future<ResponseBody> Function(RequestOptions options) onFetch;
  final List<RequestOptions> captured = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    captured.add(options);
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {Headers.contentTypeHeader: ['application/json']},
  );
}

void main() {
  late _FakeAdapter adapter;

  DioApiClient build({String Function()? keyGenerator}) {
    final dio = Dio();
    dio.httpClientAdapter = adapter;
    return DioApiClient(
      dio: dio,
      baseUrl: 'http://localhost:8000/api/v1',
      tokenProvider: _FakeTokenProvider('tok-123'),
      idempotencyKeyGenerator: keyGenerator ?? () => 'auto-key-123456',
    );
  }

  setUp(() {
    adapter = _FakeAdapter(
      (_) async => _json({'data': {'ok': true}}, 200),
    );
  });

  group('DioApiClient — success', () {
    test('get sends path/query and returns ApiResponse', () async {
      final client = build();

      final response = await client.get(
        '/deliveries',
        query: {'status': 'OPEN'},
      );

      final request = adapter.captured.single;
      expect(request.path, '/deliveries');
      expect(request.queryParameters, {'status': 'OPEN'});
      expect(request.headers['Authorization'], 'Bearer tok-123');
      expect(response.statusCode, 200);
      expect(response.isSuccess, isTrue);
      expect(response.data, {'data': {'ok': true}});
    });

    test('post serializes body and auto-generates idempotency key', () async {
      final client = build();

      await client.post('/deliveries', body: {'status': 'DRAFT'});

      final request = adapter.captured.single;
      expect(request.method, 'POST');
      expect(request.data, {'status': 'DRAFT'});
      expect(request.headers[Idempotency.header], 'auto-key-123456');
    });

    test('put preserves caller-provided idempotency key', () async {
      final client = build();

      await client.put(
        '/deliveries/1',
        body: {'recipient': {'name': 'Ana'}},
        idempotencyKey: 'custom-key-123456',
      );

      expect(
        adapter.captured.single.headers[Idempotency.header],
        'custom-key-123456',
      );
    });

    test('patch sends the request', () async {
      final client = build();

      final response = await client.patch('/me', body: {'name': 'João'});

      expect(adapter.captured.single.method, 'PATCH');
      expect(response.isSuccess, isTrue);
    });

    test('delete sends the request without idempotency key', () async {
      final client = build();

      await client.delete('/deliveries/1');

      final request = adapter.captured.single;
      expect(request.method, 'DELETE');
      expect(request.headers.containsKey(Idempotency.header), isFalse);
    });
  });

  group('DioApiClient — idempotency key validation', () {
    test('rejects a key shorter than 8 characters', () async {
      final client = build();

      await expectLater(
        client.post('/deliveries', idempotencyKey: 'short'),
        throwsArgumentError,
      );
    });

    test('rejects a key longer than 255 characters', () async {
      final client = build();
      final longKey = 'k' * 256;

      await expectLater(
        client.post('/deliveries', idempotencyKey: longKey),
        throwsArgumentError,
      );
    });
  });

  group('DioApiClient — error mapping', () {
    test('maps 422 to ValidationException with field errors', () async {
      adapter = _FakeAdapter(
        (_) async => _json({
          'message': 'Os dados fornecidos são inválidos.',
          'errors': {
            'origin': ['O campo origem é obrigatório.'],
          },
        }, 422),
      );
      final client = build();

      await expectLater(
        client.post('/deliveries'),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having(
                (e) => e.fieldErrors['origin'],
                'origin',
                contains('O campo origem é obrigatório.'),
              ),
        ),
      );
    });

    test('maps 409 to ConflictException with server code', () async {
      adapter = _FakeAdapter(
        (_) async => _json({
          'error': {
            'code': 'DELIVERY_ALREADY_ASSIGNED',
            'message': 'A entrega já foi atribuída a outro motoboy.',
          },
        }, 409),
      );
      final client = build();

      await expectLater(
        client.post('/deliveries/1/accept'),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.code,
            'code',
            'DELIVERY_ALREADY_ASSIGNED',
          ),
        ),
      );
    });

    test('maps 429 to RateLimitException', () async {
      adapter = _FakeAdapter((_) async => _json({'retry_after': 30}, 429));
      final client = build();

      await expectLater(
        client.post('/auth/login'),
        throwsA(
          isA<RateLimitException>().having(
            (e) => e.retryAfterSeconds,
            'retryAfterSeconds',
            30,
          ),
        ),
      );
    });

    test('maps connection failure to NetworkException', () async {
      adapter = _FakeAdapter(
        (_) async => throw const SocketException('Connection refused'),
      );
      final client = build();

      await expectLater(
        client.get('/deliveries'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('defaultApiBaseUrl — resolução por plataforma', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('sem dart-define, fora de Android → localhost', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(defaultApiBaseUrl, 'http://localhost:8000/api/v1');
    });

    test('sem dart-define, em Android (emulador) → 10.0.2.2', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(defaultApiBaseUrl, 'http://10.0.2.2:8000/api/v1');
    });

    test('sem dart-define, em iOS → localhost (simulador usa o host)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(defaultApiBaseUrl, 'http://localhost:8000/api/v1');
    });
  });
}

