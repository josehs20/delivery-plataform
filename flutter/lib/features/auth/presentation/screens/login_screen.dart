import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes/app_routes.dart';
import '../auth_cubit.dart';
import '../auth_state.dart';

/// Tela de login — formulário com validação de UX, feedback de erro e
/// redirecionamento de rota por papel após autenticação.
///
/// Espera um [AuthCubit] no contexto (fornecido pelo bootstrap do app).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectRoute});

  /// Rota para onde navegar após autenticação. Quando `null`, o dashboard é
  /// resolvido pelo papel primário do usuário.
  final String? redirectRoute;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final _phonePattern = RegExp(r'^\+?[0-9]{10,15}$');

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    context.read<AuthCubit>().login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );
  }

  String? _validateIdentifier(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Informe seu email ou telefone.';
    if (!_emailPattern.hasMatch(v) && !_phonePattern.hasMatch(v)) {
      return 'Informe um email ou telefone válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Informe sua senha.';
    if (v.length < 8) return 'A senha deve ter no mínimo 8 caracteres.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocListener<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    Navigator.of(context).pushReplacementNamed(
                      widget.redirectRoute ??
                          AppRoutes.dashboardForRole(
                            state.session.user.primaryRole,
                          ),
                    );
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                  }
                },
                child: BlocBuilder<AuthCubit, AuthState>(
                  buildWhen: (previous, current) =>
                      current is AuthAuthenticating ||
                      previous is AuthAuthenticating,
                  builder: (context, state) {
                    final isLoading = state is AuthAuthenticating;
                    return _buildForm(context, isLoading: isLoading);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isLoading}) {
    final theme = Theme.of(context);

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Delivery Platform',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _identifierController,
              enabled: !isLoading,
              autofillHints: const [AutofillHints.username],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Email ou telefone',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: _validateIdentifier,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: !isLoading,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: isLoading
                      ? null
                      : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.of(context)
                      .pushNamed(AppRoutes.register),
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}

