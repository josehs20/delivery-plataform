import 'json_utils.dart';

/// Identidade do usuário autenticado — espelha o schema `User` do OpenAPI.
///
/// Retornado em `POST /auth/login`, `POST /auth/register` e `GET /me`.
/// Papéis/status são apenas Strings de transporte; a autorização é sempre
/// validada no servidor (fronteira cliente/servidor).
final class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.status,
    this.roles = const [],
    this.isBlocked,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;

  /// Ex.: `ACTIVE`, `BLOCKED` (espelha o OpenAPI; valor não validado aqui).
  final String? status;

  final List<String> roles;
  final bool? isBlocked;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: JsonUtils.stringOrDefault(json['name']),
      email: JsonUtils.stringOrNull(json['email']),
      phone: JsonUtils.stringOrNull(json['phone']),
      status: JsonUtils.stringOrNull(json['status']),
      roles: JsonUtils.stringList(json['roles']),
      isBlocked: JsonUtils.boolOrNull(json['is_blocked']),
      emailVerifiedAt: JsonUtils.dateTime(json['email_verified_at']),
      phoneVerifiedAt: JsonUtils.dateTime(json['phone_verified_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (status != null) 'status': status,
        'roles': roles,
        if (isBlocked != null) 'is_blocked': isBlocked,
        if (emailVerifiedAt != null)
          'email_verified_at': emailVerifiedAt!.toUtc().toIso8601String(),
        if (phoneVerifiedAt != null)
          'phone_verified_at': phoneVerifiedAt!.toUtc().toIso8601String(),
      };
}

/// Envelope `data` do contrato de autenticação — espelha o schema
/// `AuthResponse` do OpenAPI.
///
/// Usado em `POST /auth/login`, `POST /auth/register` (com `user` + `token`)
/// e `POST /auth/refresh` (apenas `token`). O `token` é o token Sanctum
/// (Bearer) que deve ser armazenado apenas em secure storage.
final class AuthResponseDto {
  const AuthResponseDto({
    this.user,
    this.token,
    this.tokenType = 'Bearer',
    this.expiresIn,
    this.message,
  });

  final UserDto? user;
  final String? token;
  final String tokenType;
  final int? expiresIn;
  final String? message;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final data = JsonUtils.mapOrEmpty(json['data']);
    final rawUser = data['user'];

    return AuthResponseDto(
      user: rawUser is Map
          ? UserDto.fromJson(JsonUtils.mapOrEmpty(rawUser))
          : null,
      token: JsonUtils.stringOrNull(data['token']),
      tokenType:
          JsonUtils.stringOrDefault(data['token_type'], fallback: 'Bearer'),
      expiresIn: JsonUtils.intOrNull(data['expires_in']),
      message: JsonUtils.stringOrNull(data['message']),
    );
  }

  Map<String, dynamic> toJson() => {
        'data': {
          if (user != null) 'user': user!.toJson(),
          if (token != null) 'token': token,
          'token_type': tokenType,
          if (expiresIn != null) 'expires_in': expiresIn,
          if (message != null) 'message': message,
        },
      };
}
