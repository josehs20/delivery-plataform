import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/register_params.dart';
import 'auth_state.dart';

/// Orquestra o fluxo de autenticação (Cubit — estado reativo do app).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthUnauthenticated());

  final AuthRepository _repository;

  /// Login com email/telefone + senha.
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    emit(const AuthAuthenticating());
    try {
      final session = await _repository.login(
        identifier: identifier,
        password: password,
      );
      emit(AuthAuthenticated(session: session));
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthError('Não foi possível entrar. Tente novamente.'));
    }
  }

  /// Cadastro (business/driver) — inicia a sessão ao concluir.
  Future<void> register(RegisterParams params) async {
    emit(const AuthAuthenticating());
    try {
      final session = await _repository.register(params);
      emit(AuthAuthenticated(session: session));
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthError('Não foi possível criar a conta. Tente novamente.'));
    }
  }

  /// Restaura a sessão a partir do token salvo (bootstrap do app).
  Future<void> restoreSession() async {
    emit(const AuthAuthenticating());
    try {
      final session = await _repository.restoreSession();
      if (session != null) {
        emit(AuthAuthenticated(session: session));
      } else {
        emit(const AuthUnauthenticated());
      }
    } on ApiException catch (error) {
      emit(AuthError(error.message));
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Encerra a sessão (revoga token e limpa o secure storage).
  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      emit(const AuthUnauthenticated());
    }
  }
}
