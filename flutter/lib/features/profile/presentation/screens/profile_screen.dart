import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/auth_user.dart';
import '../profile_cubit.dart';
import '../profile_state.dart';

/// Tela de perfil: exibe identidade/papéis e permite editar nome, email,
/// telefone e senha (`GET /me` + `PATCH /me`).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileCubit>().load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _currentPassword.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  void _fill(AuthUser user) {
    _name.text = user.name;
    _email.text = user.email ?? '';
    _phone.text = user.phone ?? '';
  }

  void _save(ProfileCubit cubit) {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final wantsPasswordChange = _password.text.isNotEmpty;
    cubit.save(
      name: _name.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      currentPassword: wantsPasswordChange ? _currentPassword.text : null,
      password: wantsPasswordChange ? _password.text : null,
      passwordConfirmation:
          wantsPasswordChange ? _passwordConfirmation.text : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSaved) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Perfil atualizado com sucesso.')),
              );
            _fill(state.user);
          } else if (state is ProfileFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            return switch (state) {
              ProfileLoading() =>
                const Center(child: CircularProgressIndicator()),
              ProfileFailure(:final message) => _ErrorState(
                  message: message,
                  onRetry: () => context.read<ProfileCubit>().load(),
                ),
              ProfileLoaded(:final user) => _form(user, false),
              ProfileSaving(:final user) => _form(user, true),
              ProfileSaved(:final user) => _form(user, false),
            };
          },
        ),
      ),
    );
  }

  Widget _form(AuthUser user, bool saving) {
    _fill(user);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                user.name.isEmpty
                    ? '?'
                    : user.name.characters.first.toUpperCase(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Papéis: ${user.roles.isEmpty ? '—' : user.roles.join(', ')}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _field(_name, 'Nome',
                validator: (value) =>
                    (value?.trim() ?? '').isEmpty ? 'Informe seu nome.' : null),
            _field(_email, 'Email', keyboardType: TextInputType.emailAddress),
            _field(_phone, 'Telefone', keyboardType: TextInputType.phone),
            const Divider(height: 32),
            Text('Alterar senha', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _field(_currentPassword, 'Senha atual', obscure: true),
            _field(
              _password,
              'Nova senha (mín. 8)',
              obscure: true,
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                if (value.length < 8) return 'Mínimo de 8 caracteres.';
                return null;
              },
            ),
            _field(
              _passwordConfirmation,
              'Confirmar nova senha',
              obscure: true,
              validator: (value) {
                if (value != _password.text) {
                  return 'As senhas não coincidem.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saving
                  ? null
                  : () => _save(context.read<ProfileCubit>()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Salvar alterações'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

