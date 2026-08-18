import 'package:delivery_app/core/models/auth_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserDto', () {
    test('fromJson parses all fields and tolerates missing optionals', () {
      final user = UserDto.fromJson(const {
        'id': '0b4e3d2f-0001-4000-8000-000000000001',
        'name': 'João da Silva',
        'email': 'joao@example.com',
        'phone': '27999999999',
        'status': 'ACTIVE',
        'roles': ['business', 'driver'],
        'is_blocked': false,
        'email_verified_at': '2026-08-16T12:00:00Z',
      });

      expect(user.id, '0b4e3d2f-0001-4000-8000-000000000001');
      expect(user.name, 'João da Silva');
      expect(user.email, 'joao@example.com');
      expect(user.phone, '27999999999');
      expect(user.status, 'ACTIVE');
      expect(user.roles, ['business', 'driver']);
      expect(user.isBlocked, isFalse);
      expect(user.emailVerifiedAt, DateTime.utc(2026, 8, 16, 12));
      expect(user.phoneVerifiedAt, isNull);
    });

    test('fromJson ignores unknown fields and empty optionals', () {
      final user = UserDto.fromJson(const {
        'id': 'abc',
        'name': 'Maria',
        'unknown_field': 'ignored',
      });

      expect(user.id, 'abc');
      expect(user.name, 'Maria');
      expect(user.email, isNull);
      expect(user.roles, isEmpty);
      expect(user.isBlocked, isNull);
    });

    test('toJson round-trips through fromJson', () {
      final original = UserDto(
        id: 'abc',
        name: 'Maria',
        email: 'maria@example.com',
        status: 'ACTIVE',
        roles: const ['driver'],
      );

      final restored = UserDto.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.email, original.email);
      expect(restored.status, original.status);
      expect(restored.roles, original.roles);
    });
  });

  group('AuthResponseDto', () {
    test('fromJson parses login response (user + token)', () {
      final auth = AuthResponseDto.fromJson(const {
        'data': {
          'user': {
            'id': 'abc',
            'name': 'João',
            'roles': ['business'],
          },
          'token': '1|sanctum-token-value',
          'token_type': 'Bearer',
          'expires_in': 1440,
        },
      });

      expect(auth.user, isNotNull);
      expect(auth.user!.id, 'abc');
      expect(auth.token, '1|sanctum-token-value');
      expect(auth.tokenType, 'Bearer');
      expect(auth.expiresIn, 1440);
    });

    test('fromJson supports refresh response (token only)', () {
      final auth = AuthResponseDto.fromJson(const {
        'data': {'token': '2|new-token', 'token_type': 'Bearer'},
      });

      expect(auth.user, isNull);
      expect(auth.token, '2|new-token');
    });

    test('fromJson tolerates a missing envelope', () {
      final auth = AuthResponseDto.fromJson(const {});

      expect(auth.user, isNull);
      expect(auth.token, isNull);
      expect(auth.tokenType, 'Bearer');
    });

    test('toJson round-trips', () {
      const original = AuthResponseDto(
        token: '1|token',
        tokenType: 'Bearer',
        expiresIn: 1440,
      );

      final restored = AuthResponseDto.fromJson(original.toJson());

      expect(restored.token, original.token);
      expect(restored.tokenType, original.tokenType);
      expect(restored.expiresIn, original.expiresIn);
      expect(restored.user, isNull);
    });
  });
}
