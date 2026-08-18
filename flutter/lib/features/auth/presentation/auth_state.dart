import '../domain/auth_session.dart';

/// Estados do fluxo de autenticação.
sealed class AuthState {
  const AuthState();
}

/// Sem sessão válida (não autenticado).
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Autenticação em andamento (login/registro/restauração).
final class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

/// Sessão válida ativa.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.session});

  final AuthSession session;
}

/// Falha de autenticação — mensagem segura para apresentação.
final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}
