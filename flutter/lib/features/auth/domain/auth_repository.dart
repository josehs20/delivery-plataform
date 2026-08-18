import 'auth_session.dart';
import 'auth_user.dart';
import 'register_params.dart';

/// Contrato da feature de auth (voltado a use-cases).
///
/// Gerencia o ciclo de vida da sessão: autentica, registra, restaura a sessão
/// a partir do token salvo e encerra a sessão.
abstract interface class AuthRepository {
  /// Autentica com email/telefone + senha e persiste o token.
  Future<AuthSession> login({
    required String identifier,
    required String password,
  });

  /// Registra uma conta (business/driver) e inicia a sessão.
  Future<AuthSession> register(RegisterParams params);

  /// Renova o token mantendo a sessão (usuário recarregado via `/me`).
  Future<AuthSession> refresh();

  /// Restaura a sessão a partir do token salvo (bootstrap do app).
  ///
  /// Retorna `null` quando não há token ou o token não é mais válido.
  Future<AuthSession?> restoreSession();

  /// Recarrega o usuário autenticado via `/me` (ex.: tela de perfil).
  Future<AuthUser> me();

  /// Atualiza o perfil (`PATCH /me`). Campos não informados não são enviados.
  Future<AuthUser> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  });

  /// Encerra a sessão local e, quando possível, revoga o token no servidor.
  Future<void> logout();
}
