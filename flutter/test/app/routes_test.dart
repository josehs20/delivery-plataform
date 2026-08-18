import 'package:delivery_app/app/pages/delivery_dashboard_screen.dart';
import 'package:delivery_app/app/routes.dart';
import 'package:delivery_app/app/routes/app_routes.dart';
import 'package:delivery_app/features/auth/presentation/screens/login_screen.dart';
import 'package:delivery_app/features/auth/presentation/screens/register_screen.dart';
import 'package:delivery_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:delivery_app/features/business/presentation/screens/business_dashboard_screen.dart';
import 'package:delivery_app/features/business/presentation/screens/business_delivery_detail_screen.dart';
import 'package:delivery_app/features/business/presentation/screens/create_delivery_screen.dart';
import 'package:delivery_app/features/delivery/presentation/screens/delivery_detail_screen.dart';
import 'package:delivery_app/features/driver/presentation/screens/driver_dashboard_screen.dart';
import 'package:delivery_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:delivery_app/features/tracking/presentation/screens/tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appRoutes registers all implemented screen routes', () {
    expect(appRoutes[AppRoutes.splash], isNotNull);
    expect(appRoutes[AppRoutes.login], isNotNull);
    expect(appRoutes[AppRoutes.register], isNotNull);
    expect(appRoutes[AppRoutes.dashboard], isNotNull);
    expect(appRoutes[AppRoutes.feed], isNotNull);
    expect(appRoutes[AppRoutes.businessDashboard], isNotNull);
    expect(appRoutes[AppRoutes.driverDashboard], isNotNull);
    expect(appRoutes[AppRoutes.createDelivery], isNotNull);
    expect(appRoutes[AppRoutes.profile], isNotNull);
  });

  test('appOnGenerateRoute resolves static routes to MaterialPageRoute', () {
    final route =
        appOnGenerateRoute(const RouteSettings(name: AppRoutes.login));

    expect(route, isA<MaterialPageRoute<void>>());
    expect(route!.settings.name, AppRoutes.login);
  });

  test('appOnGenerateRoute resolves the parametrized delivery detail route',
      () {
    final route = appOnGenerateRoute(
      RouteSettings(name: AppRoutes.deliveryDetailFor('d-42')),
    );

    expect(route, isA<MaterialPageRoute<void>>());
    expect(route!.settings.name, '/deliveries/d-42');
  });

  test('appOnGenerateRoute resolves business delivery and tracking routes', () {
    final business = appOnGenerateRoute(
      RouteSettings(name: AppRoutes.businessDeliveryDetailFor('d-1')),
    );
    final tracking = appOnGenerateRoute(
      RouteSettings(name: AppRoutes.trackingFor('d-1')),
    );

    expect(business, isA<MaterialPageRoute<void>>());
    expect(tracking, isA<MaterialPageRoute<void>>());
    expect(business!.settings.name, '/business/deliveries/d-1');
    expect(tracking!.settings.name, '/deliveries/d-1/tracking');
  });

  test('appOnGenerateRoute returns null for unknown or empty routes', () {
    expect(appOnGenerateRoute(const RouteSettings(name: '/unknown')), isNull);
    expect(appOnGenerateRoute(const RouteSettings(name: null)), isNull);
  });

  testWidgets('routes build the expected screen widgets', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));

    expect(appRoutes[AppRoutes.splash]!(context), isA<SplashScreen>());
    expect(appRoutes[AppRoutes.login]!(context), isA<LoginScreen>());
    expect(appRoutes[AppRoutes.dashboard]!(context),
        isA<DeliveryDashboardScreen>());
    expect(appRoutes[AppRoutes.feed]!(context), isA<DeliveryDashboardScreen>());

    final detailRoute = appOnGenerateRoute(
      RouteSettings(name: AppRoutes.deliveryDetailFor('d1')),
    )! as MaterialPageRoute<void>;
    expect(detailRoute.builder(context), isA<DeliveryDetailScreen>());
  });

  test('AppRoutes formats and parses delivery detail routes', () {
    expect(AppRoutes.deliveryDetailFor('d1'), '/deliveries/d1');
    expect(AppRoutes.deliveryIdFrom('/deliveries/d1'), 'd1');
    expect(AppRoutes.deliveryIdFrom('/deliveries/abc-123'), 'abc-123');
    expect(AppRoutes.deliveryIdFrom('/login'), isNull);
    expect(AppRoutes.deliveryIdFrom('/deliveries/'), isNull);
    expect(AppRoutes.deliveryIdFrom(AppRoutes.deliveryDetail), isNull);
    expect(AppRoutes.deliveryIdFrom(null), isNull);
  });

  testWidgets('routes build the expected screen widgets', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));

    expect(appRoutes[AppRoutes.splash]!(context), isA<SplashScreen>());
    expect(appRoutes[AppRoutes.login]!(context), isA<LoginScreen>());
    expect(appRoutes[AppRoutes.register]!(context), isA<RegisterScreen>());
    expect(appRoutes[AppRoutes.dashboard]!(context),
        isA<DeliveryDashboardScreen>());
    expect(appRoutes[AppRoutes.feed]!(context), isA<DeliveryDashboardScreen>());
    expect(appRoutes[AppRoutes.businessDashboard]!(context),
        isA<BusinessDashboardScreen>());
    expect(appRoutes[AppRoutes.driverDashboard]!(context),
        isA<DriverDashboardScreen>());
    expect(appRoutes[AppRoutes.createDelivery]!(context),
        isA<CreateDeliveryScreen>());
    expect(appRoutes[AppRoutes.profile]!(context), isA<ProfileScreen>());

    final detailRoute = appOnGenerateRoute(
      RouteSettings(name: AppRoutes.deliveryDetailFor('d1')),
    )! as MaterialPageRoute<void>;
    expect(detailRoute.builder(context), isA<DeliveryDetailScreen>());

    final businessRoute = appOnGenerateRoute(
      RouteSettings(name: AppRoutes.businessDeliveryDetailFor('d1')),
    )! as MaterialPageRoute<void>;
    expect(businessRoute.builder(context), isA<BusinessDeliveryDetailScreen>());

    final trackingRoute = appOnGenerateRoute(
      RouteSettings(name: AppRoutes.trackingFor('d1')),
    )! as MaterialPageRoute<void>;
    expect(trackingRoute.builder(context), isA<TrackingScreen>());
  });

  test('AppRoutes formats and parses delivery detail routes', () {
    expect(AppRoutes.deliveryDetailFor('d1'), '/deliveries/d1');
    expect(AppRoutes.deliveryIdFrom('/deliveries/d1'), 'd1');
    expect(AppRoutes.deliveryIdFrom('/deliveries/abc-123'), 'abc-123');
    expect(AppRoutes.deliveryIdFrom('/login'), isNull);
    expect(AppRoutes.deliveryIdFrom('/deliveries/'), isNull);
    expect(AppRoutes.deliveryIdFrom(AppRoutes.deliveryDetail), isNull);
    expect(AppRoutes.deliveryIdFrom(null), isNull);
  });

  test('AppRoutes parses business delivery and tracking ids', () {
    expect(
      AppRoutes.businessDeliveryIdFrom('/business/deliveries/d1'),
      'd1',
    );
    expect(AppRoutes.businessDeliveryIdFrom('/business/'), isNull);
    expect(AppRoutes.trackingDeliveryIdFrom('/deliveries/d1/tracking'), 'd1');
    expect(AppRoutes.trackingDeliveryIdFrom('/deliveries/d1'), isNull);
    expect(AppRoutes.trackingDeliveryIdFrom('/deliveries/'), isNull);
    expect(AppRoutes.trackingDeliveryIdFrom('/business/d1/tracking'), isNull);
  });

  test('dashboardForRole resolves the correct dashboard per role', () {
    expect(AppRoutes.dashboardForRole('business'), '/business');
    expect(AppRoutes.dashboardForRole('driver'), '/driver');
    expect(AppRoutes.dashboardForRole('admin'), AppRoutes.feed);
    expect(AppRoutes.dashboardForRole('unknown'), AppRoutes.feed);
  });
}