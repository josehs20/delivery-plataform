import '../../auth/domain/auth_user.dart';

/// Estados da tela de perfil.
sealed class ProfileState {
  const ProfileState();
}

/// Carregando dados via `/me`.
final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Dados carregados.
final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({required this.user});

  final AuthUser user;
}

/// Salvando alterações (`PATCH /me`).
final class ProfileSaving extends ProfileState {
  const ProfileSaving({required this.user});

  final AuthUser user;
}

/// Perfil salvo com sucesso.
final class ProfileSaved extends ProfileState {
  const ProfileSaved({required this.user});

  final AuthUser user;
}

/// Falha em carga/salvamento — mensagem segura.
final class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);

  final String message;
}
