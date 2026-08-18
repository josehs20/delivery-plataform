/// Papel de usuário aceito no cadastro (`POST /auth/register`).
enum AuthRole {
  business,
  driver;

  /// Valor serializado esperado pelo backend.
  String get wireValue => name;
}

/// Dados de cadastro — espelha o `RegisterRequest` do backend.
final class RegisterParams {
  const RegisterParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.role,
    this.businessName,
    this.businessCnpj,
    this.nationalDocument,
    this.vehicleType,
    this.vehiclePlate,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirmation;
  final AuthRole role;

  /// Campos específicos de negócio.
  final String? businessName;
  final String? businessCnpj;

  /// Campos específicos de motorista.
  final String? nationalDocument;
  final String? vehicleType;
  final String? vehiclePlate;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role.wireValue,
        if (businessName != null) 'business_name': businessName,
        if (businessCnpj != null) 'business_cnpj': businessCnpj,
        if (nationalDocument != null) 'national_document': nationalDocument,
        if (vehicleType != null) 'vehicle_type': vehicleType,
        if (vehiclePlate != null) 'vehicle_plate': vehiclePlate,
      };
}
