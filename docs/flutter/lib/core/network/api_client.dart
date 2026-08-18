abstract interface class ApiClient {
  Future<ApiResponse> get(String path, {Map<String, String>? query});
  Future<ApiResponse> post(String path, {Map<String, dynamic>? body, String? idempotencyKey});
  Future<ApiResponse> put(String path, {Map<String, dynamic>? body});
}

final class ApiResponse {
  const ApiResponse({required this.statusCode, this.data});

  final int statusCode;
  final Object? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
