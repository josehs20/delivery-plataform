import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/routes/app_routes.dart';
import '../auth_cubit.dart';
import '../auth_state.dart';

/// Tela inicial (bootstrap) — restaura a sessão a partir do token salvo e
/// direciona para o dashboard do papel correto (`business`, `driver` ou
/// `admin`) ou para o Login quando não há sessão.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.authenticatedRoute,
  });

  /// Rota para onde navegar quando a sessão for restaurada. Quando `null`,
  /// o dashboard é resolvido pelo papel primário do usuário.
  final String? authenticatedRoute;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Dispara a restauração após o primeiro frame (contexto/bloc prontos).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<AuthCubit>();
      final state = cubit.state;

      // Guarda contra "loading infinito": se a sessão já está ativa (ex.: o
      // usuário voltou para a raiz `/` pelo navegador/dispositivo), não chama
      // `GET /me` de novo nem exibe o spinner — apenas redireciona para o
      // dashboard correto da role (admin → /admin).
      if (state is AuthAuthenticated) {
        Navigator.of(context).pushReplacementNamed(
          widget.authenticatedRoute ??
              AppRoutes.dashboardForRole(state.session.user.primaryRole),
        );
        return;
      }

      cubit.restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed(
            widget.authenticatedRoute ??
                AppRoutes.dashboardForRole(state.session.user.primaryRole),
          );
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Delivery App', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}