import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:uuid/uuid.dart';

import '../auth/secure_storage_token_provider.dart';
import '../auth/token_provider.dart';
import '../errors/api_exception.dart';
import 'api_client.dart';
import 'auth_interceptor.dart';
import 'error_mapper.dart';
import 'idempotency_interceptor.dart';

/// URL base definida via build (`--dart-define=API_BASE_URL=...`).
///
/// Vazia = não definida; a resolução cai no padrão por plataforma.
const String _apiBaseUrlFromEnv = String.fromEnvironment('API_BASE_URL');

/// URL base padrão da API (Laravel local).
///
/// Resolução por ambiente/dispositivo (sem segredos commitados):
/// 1. `--dart-define=API_BASE_URL=https://.../api/v1` — staging/produção e
///    device físico (usar o IP da máquina na rede local, ex.:
///    `http://192.168.0.10:8000/api/v1`);
/// 2. Android (emulador): `http://10.0.2.2:8000/api/v1` — `10.0.2.2` é o alias
///    do host no emulador Android (`localhost` lá aponta para o próprio
///    dispositivo, o que causa "Falha de conexão com o servidor");
/// 3. demais plataformas (desktop, iOS simulator): `http://localhost:8000/api/v1`.
String get defaultApiBaseUrl {
  if (_apiBaseUrlFromEnv.isNotEmpty) return _apiBaseUrlFromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api/v1';
  }
  return 'http://localhost:8000/api/v1';
}

/// Implementação concreta do [ApiClient] com o pacote `dio`.
///
/// - um único cliente HTTP centralizado (base URL, timeouts, headers);
/// - interceptor de autenticação (Bearer via [TokenProvider]);
/// - interceptor de idempotência (`X-Idempotency-Key` em POST/PUT/PATCH);
/// - erros convertidos em [ApiException] tipadas (sem stack traces).
final class DioApiClient implements ApiClient {
  DioApiClient({
    Dio? dio,
    String? baseUrl,
    TokenProvider? tokenProvider,
    String Function()? idempotencyKeyGenerator,
    void Function()? onUnauthorized,
  }) : _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: baseUrl ?? defaultApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        ..._dio.options.headers,
        Headers.acceptHeader: 'application/json',
        Headers.contentTypeHeader: 'application/json',
      },
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        tokenProvider ?? SecureStorageTokenProvider(),
        onUnauthorized: onUnauthorized,
      ),
      IdempotencyInterceptor(idempotencyKeyGenerator ?? _uuidV4),
    ]);
  }

  static String _uuidV4() => const Uuid().v4();

  final Dio _dio;

  @override
  Future<ApiResponse> get(String path, {Map<String, String>? query}) {
    return _request(() => _dio.get<Object?>(path, queryParameters: query));
  }

  @override
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    Map<String, String>? headers,
  }) {
    return _request(
      () => _dio.post<Object?>(
        path,
        data: body,
        options: _requestOptions(idempotencyKey, headers),
      ),
    );
  }

  @override
  Future<ApiResponse> put(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) {
    return _request(
      () => _dio.put<Object?>(
        path,
        data: body,
        options: _requestOptions(idempotencyKey, null),
      ),
    );
  }

  @override
  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) {
    return _request(
      () => _dio.patch<Object?>(
        path,
        data: body,
        options: _requestOptions(idempotencyKey, null),
      ),
    );
  }

  @override
  Future<ApiResponse> delete(String path, {Map<String, String>? query}) {
    return _request(() => _dio.delete<Object?>(path, queryParameters: query));
  }

  Future<ApiResponse> _request(Future<Response<Object?>> Function() send) async {
    try {
      final response = await send();
      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        data: response.data,
      );
    } on DioException catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  /// Aplica a chave de idempotência e headers customizados fornecidos.
  ///
  /// A chave é validada contra o contrato (`X-Idempotency-Key`, min 8, máx 255).
  Options? _requestOptions(String? idempotencyKey, Map<String, String>? headers) {
    final hasKey = idempotencyKey != null;
    final hasHeaders = headers != null && headers.isNotEmpty;
    if (!hasKey && !hasHeaders) return null;

    final merged = <String, dynamic>{...?headers};

    final key = idempotencyKey;
    if (key != null) {
      if (key.length < Idempotency.minLength ||
          key.length > Idempotency.maxLength) {
        throw ArgumentError.value(
          key,
          'idempotencyKey',
          'Deve ter entre ${Idempotency.minLength} e '
              '${Idempotency.maxLength} caracteres.',
        );
      }
      merged[Idempotency.header] = key;
    }

    return Options(headers: merged);
  }
}
