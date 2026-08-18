import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/auth_cubit.dart';
import '../features/auth/presentation/auth_state.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import 'bootstrap/app_bootstrap.dart';
import 'routes/app_routes.dart';
import 'routes.dart' as app_router;
import 'theme/app_theme.dart';

/// Widget raiz do app: injeta os controllers (cubits) e configura o
/// [MaterialApp] com tema, título e gerenciamento de rotas.
class App extends StatefulWidget {
  const App({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: dependencies.authCubit),
        BlocProvider.value(value: dependencies.deliveryListCubit),
        BlocProvider.value(value: dependencies.deliveryDetailCubit),
        BlocProvider.value(value: dependencies.createDeliveryCubit),
        BlocProvider.value(value: dependencies.trackingCubit),
        BlocProvider.value(value: dependencies.profileCubit),
      ],
      child: MaterialApp(
        title: 'Delivery App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: _navigatorKey,
        initialRoute: AppRoutes.splash,
        routes: app_router.appRoutes,
        onGenerateRoute: app_router.appOnGenerateRoute,
        // Rota desconhecida: volta ao Splash (restauração segura).
        onUnknownRoute: _unknownRoute,
        // Guard de sessão: quando uma sessão autenticada é perdida (logout ou
        // 401 global em requisição autenticada), limpa o histórico e volta ao
        // Login. A navegação usa o navigatorKey (o listener fica acima do
        // Navigator via `builder`).
        builder: (context, child) {
          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (previous, current) =>
                previous is AuthAuthenticated &&
                current is AuthUnauthenticated,
            listener: (context, state) {
              _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                AppRoutes.login,
                (_) => false,
              );
            },
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

/// Rota desconhecida → Splash (restauração segura da sessão).
Route<void> _unknownRoute(RouteSettings settings) {
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => const SplashScreen(),
  );
}