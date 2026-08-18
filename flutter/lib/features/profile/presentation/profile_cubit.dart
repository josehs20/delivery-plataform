import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/api_exception.dart';
import '../../auth/domain/auth_repository.dart';
import 'profile_state.dart';

/// Orquestra a tela de perfil (carregar `/me` e atualizar `PATCH /me`).
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileLoading());

  final AuthRepository _repository;

  Future<void> load() async {
    emit(const ProfileLoading());
    try {
      emit(ProfileLoaded(user: await _repository.me()));
    } on ApiException catch (error) {
      emit(ProfileFailure(error.message));
    } catch (_) {
      emit(const ProfileFailure('Não foi possível carregar o perfil.'));
    }
  }

  Future<void> save({
    String? name,
    String? email,
    String? phone,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    final current = switch (state) {
      ProfileLoaded(:final user) => user,
      ProfileSaved(:final user) => user,
      _ => null,
    };
    if (current == null) return;

    emit(ProfileSaving(user: current));
    try {
      final updated = await _repository.updateProfile(
        name: name,
        email: email,
        phone: phone,
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      emit(ProfileSaved(user: updated));
    } on ApiException catch (error) {
      emit(ProfileFailure(error.message));
    } catch (_) {
      emit(ProfileFailure('Não foi possível salvar o perfil.'));
    }
  }
}
