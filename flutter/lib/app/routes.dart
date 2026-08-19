import 'package:flutter/material.dart';

import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/business/presentation/screens/business_dashboard_screen.dart';
import '../features/business/presentation/screens/business_delivery_detail_screen.dart';
import '../features/business/presentation/screens/create_delivery_screen.dart';
import '../features/delivery/presentation/screens/delivery_detail_screen.dart';
import '../features/driver/presentation/screens/driver_dashboard_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/tracking/presentation/screens/tracking_screen.dart';
import 'pages/delivery_dashboard_screen.dart';
import 'routes/app_routes.dart';

/// Tabela de rotas estáticas (telas sem parâmetro de caminho).
///
/// Rotas parametrizadas (`/deliveries/:id`, `/business/deliveries/:id`,
/// `/deliveries/:id/tracking`) são resolvidas em [appOnGenerateRoute]. A tela
/// inicial é o Splash, que restaura a sessão e redireciona para o dashboard do
/// papel correto (`business`, `driver` ou `admin`).
final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.splash: (_) => const SplashScreen(),
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.register: (_) => const RegisterScreen(),
  AppRoutes.dashboard: (_) => const DeliveryDashboardScreen(),
  AppRoutes.feed: (_) => const DeliveryDashboardScreen(),
  AppRoutes.businessDashboard: (_) => const BusinessDashboardScreen(),
  AppRoutes.driverDashboard: (_) => const DriverDashboardScreen(),
  AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
  AppRoutes.createDelivery: (_) => const CreateDeliveryScreen(),
  AppRoutes.profile: (_) => const ProfileScreen(),
};

/// Resolve as rotas nomeadas do app, incluindo as parametrizadas.
Route<dynamic>? appOnGenerateRoute(RouteSettings settings) {
  final name = settings.name;

  // `/deliveries/<id>/tracking` → rastreamento da entrega ativa.
  final trackingId = AppRoutes.trackingDeliveryIdFrom(name);
  if (trackingId != null) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => TrackingScreen(deliveryId: trackingId),
    );
  }

  // `/business/deliveries/<id>` → detalhe da entrega no contexto do comércio.
  final businessDeliveryId = AppRoutes.businessDeliveryIdFrom(name);
  if (businessDeliveryId != null) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) =>
          BusinessDeliveryDetailScreen(deliveryId: businessDeliveryId),
    );
  }

  // `/deliveries/<id>` → detalhe da entrega (motoboy/entrega ativa).
  final deliveryId = AppRoutes.deliveryIdFrom(name);
  if (deliveryId != null) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => DeliveryDetailScreen(deliveryId: deliveryId),
    );
  }

  final builder = appRoutes[name];
  if (builder == null) return null;
  return MaterialPageRoute<void>(settings: settings, builder: builder);
}