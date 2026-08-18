/// Fonte do token Bearer usado pelo interceptor de autenticação.
///
/// A implementação padrão lê do `flutter_secure_storage`
/// ([SecureStorageTokenProvider]); a interface permite fakes nos testes e
/// mantém o transporte HTTP desacoplado do plugin.
abstract interface class TokenProvider {
  /// Retorna o token de acesso atual, ou `null` quando não autenticado.
  Future<String?> readToken();
}

/// Ciclo de vida completo do token de acesso (sessão).
///
/// Usado pela feature de auth para salvar/limpar o token. Tokens NUNCA são
/// persistidos em plain text (secure storage).
abstract interface class TokenStore implements TokenProvider {
  Future<void> saveToken(String token);
  Future<void> clearToken();
}
