import 'auth_user.dart';

/// Sessão autenticada (token + usuário) mantida pelo cubit.
final class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    this.tokenType = 'Bearer',
    this.expiresIn,
  });

  /// Token Sanctum (plain-text Bearer) — mantido apenas em secure storage.
  final String token;
  final AuthUser user;
  final String tokenType;
  final int? expiresIn;
}
