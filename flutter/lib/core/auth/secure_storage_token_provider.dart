import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_provider.dart';

/// Implementação de [TokenStore] sobre o `flutter_secure_storage`.
///
/// Regra de segurança: tokens NUNCA são persistidos em plain text.
final class SecureStorageTokenProvider implements TokenStore {
  SecureStorageTokenProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Chave usada para persistir o token de acesso no secure storage.
  static const tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: tokenKey);

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: tokenKey, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: tokenKey);
}
