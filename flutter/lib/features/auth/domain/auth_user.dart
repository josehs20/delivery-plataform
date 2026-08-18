/// Usuário autenticado — modelo de domínio da feature de auth.
///
/// Derivado de `UserDto` (transporte) por um mapper no data layer. Papéis
/// vêm do servidor e nunca são confiados ao cliente como autorização.
final class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.roles = const [],
    this.isBlocked,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final List<String> roles;
  final bool? isBlocked;

  /// Conveniências de UI (branches de navegação); autorização é do servidor.
  bool get isBusiness => roles.contains('business');
  bool get isDriver => roles.contains('driver');

  /// Admin da plataforma (auditoria/operação) — ver docs/docs/api/41-admin-api.md.
  bool get isAdmin => roles.contains('admin');

  /// Papel primário usado na navegação: business > driver > admin.
  ///
  /// Um usuário normalmente possui um único papel; a ordem é apenas um critério
  /// determinístico para usuários com papéis compostos.
  String get primaryRole {
    if (isBusiness) return 'business';
    if (isDriver) return 'driver';
    return 'admin';
  }
}
