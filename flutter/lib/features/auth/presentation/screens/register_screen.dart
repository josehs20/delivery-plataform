import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes/app_routes.dart';
import '../auth_cubit.dart';
import '../auth_state.dart';
import '../../domain/register_params.dart';

/// Tela de cadastro (comércio ou motoboy).
///
/// Campos específicos de cada papel seguem o `RegisterRequest` do Laravel
/// (`business_name`, `business_cnpj` / `national_document`, `vehicle_type`,
/// `vehicle_plate`). Ao concluir, inicia a sessão e navega para o dashboard do
/// papel.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  AuthRole _role = AuthRole.driver;
  final bool _obscurePassword = true;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  // Business.
  final _businessName = TextEditingController();
  final _businessCnpj = TextEditingController();

  // Driver.
  final _nationalDocument = TextEditingController();
  final _vehiclePlate = TextEditingController();
  String _vehicleType = 'motorcycle';

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    _businessName.dispose();
    _businessCnpj.dispose();
    _nationalDocument.dispose();
    _vehiclePlate.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    context.read<AuthCubit>().register(
          RegisterParams(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            passwordConfirmation: _passwordConfirmation.text,
            role: _role,
            businessName:
                _role == AuthRole.business ? _businessName.text.trim() : null,
            businessCnpj:
                _role == AuthRole.business ? _businessCnpj.text.trim() : null,
            nationalDocument: _role == AuthRole.driver
                ? _nationalDocument.text.trim()
                : null,
            vehicleType: _role == AuthRole.driver ? _vehicleType : null,
            vehiclePlate: _role == AuthRole.driver
                ? _vehiclePlate.text.trim()
                : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.dashboardForRole(state.session.user.primaryRole),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: BlocBuilder<AuthCubit, AuthState>(
            buildWhen: (previous, current) =>
                current is AuthAuthenticating ||
                previous is AuthAuthenticating,
            builder: (context, state) {
              final loading = state is AuthAuthenticating;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<AuthRole>(
                          segments: const [
                            ButtonSegment(
                              value: AuthRole.driver,
                              label: Text('Motoboy'),
                              icon: Icon(Icons.directions_bike),
                            ),
                            ButtonSegment(
                              value: AuthRole.business,
                              label: Text('Comércio'),
                              icon: Icon(Icons.storefront_outlined),
                            ),
                          ],
                          selected: {_role},
                          onSelectionChanged: (selection) =>
                              setState(() => _role = selection.first),
                        ),
                        const SizedBox(height: 24),
                        _field(_name, 'Nome completo',
                            validator: _required('Informe seu nome.')),
                        _field(_email, 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Informe seu email.';
                              if (!_emailPattern.hasMatch(v)) {
                                return 'Email inválido.';
                              }
                              return null;
                            }),
                        _field(_phone, 'Telefone',
                            keyboardType: TextInputType.phone,
                            validator: _required('Informe seu telefone.')),
                        _field(_password, 'Senha (mín. 8)',
                            obscure: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return 'Mínimo de 8 caracteres.';
                              }
                              return null;
                            }),
                        _field(
                          _passwordConfirmation,
                          'Confirmar senha',
                          obscure: _obscurePassword,
                          validator: (value) {
                            if (value != _password.text) {
                              return 'As senhas não coincidem.';
                            }
                            return null;
                          },
                        ),
                        if (_role == AuthRole.business) ...[
                          const SizedBox(height: 8),
                          _field(
                            _businessName,
                            'Nome da empresa',
                            validator: _required('Informe o nome da empresa.'),
                          ),
                          _field(
                            _businessCnpj,
                            'CNPJ',
                            validator: _required('Informe o CNPJ.'),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          _field(
                            _nationalDocument,
                            'Documento (CPF/CNH)',
                            validator: _required('Informe seu documento.'),
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: _vehicleType,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de veículo',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'motorcycle',
                                child: Text('Moto'),
                              ),
                              DropdownMenuItem(
                                value: 'car',
                                child: Text('Carro'),
                              ),
                              DropdownMenuItem(
                                value: 'van',
                                child: Text('Van'),
                              ),
                              DropdownMenuItem(
                                value: 'truck',
                                child: Text('Caminhão'),
                              ),
                            ],
                            onChanged: (value) => setState(
                                () => _vehicleType = value ?? 'motorcycle'),
                          ),
                          const SizedBox(height: 12),
                          _field(
                            _vehiclePlate,
                            'Placa do veículo',
                            validator: _required('Informe a placa.'),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Criar conta'),
                        ),
                        TextButton(
                          onPressed: loading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Já tenho conta — entrar'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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

  String? Function(String?)? _required(String message) =>
      (value) => (value?.trim() ?? '').isEmpty ? message : null;
}

