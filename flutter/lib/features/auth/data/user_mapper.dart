import '../../../core/models/auth_response_dto.dart';
import '../domain/auth_user.dart';

/// Converte o DTO de transporte [UserDto] no modelo de domínio [AuthUser].
///
/// A conversão DTO ↔ domínio fica restrita ao data layer.
final class UserMapper {
  const UserMapper._();

  static AuthUser fromDto(UserDto dto) {
    return AuthUser(
      id: dto.id,
      name: dto.name,
      email: dto.email,
      phone: dto.phone,
      roles: dto.roles,
      isBlocked: dto.isBlocked,
    );
  }
}
