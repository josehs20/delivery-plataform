/// Rotas nomeadas do app (registradas no bootstrap de navegação).
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const feed = '/deliveries/feed';
  static const deliveryDetail = '/deliveries/:id';

  /// Dashboard do comércio (`features/business`).
  static const businessDashboard = '/business';

  /// Dashboard do motoboy (`features/driver`).
  static const driverDashboard = '/driver';

  /// Tela dedicada ao papel `admin` (`features/admin`).
  static const adminDashboard = '/admin';

  /// Criação de nova entrega (comércio).
  static const createDelivery = '/business/deliveries/new';

  /// Detalhe de entrega no contexto do comércio.
  static const businessDeliveryDetail = '/business/deliveries/:id';

  /// Perfil do usuário autenticado.
  static const profile = '/profile';

  /// Rastreamento de uma entrega ativa (motoboy).
  static const tracking = '/deliveries/:id/tracking';

  /// Rota nomeada para o detalhe de uma entrega (ex.: `/deliveries/d1`).
  static String deliveryDetailFor(String deliveryId) =>
      '/deliveries/$deliveryId';

  /// Rota nomeada para o detalhe de uma entrega no contexto do comércio.
  static String businessDeliveryDetailFor(String deliveryId) =>
      '/business/deliveries/$deliveryId';

  /// Rota nomeada para o rastreamento de uma entrega.
  static String trackingFor(String deliveryId) =>
      '/deliveries/$deliveryId/tracking';

  /// Extrai o `deliveryId` de uma rota de detalhe (`/deliveries/<id>`),
  /// ou `null` quando a rota não corresponde ao padrão.
  static String? deliveryIdFrom(String? routeName) {
    if (routeName == null) return null;
    const prefix = '/deliveries/';
    if (!routeName.startsWith(prefix)) return null;
    final id = routeName.substring(prefix.length);
    if (id.isEmpty || id == ':id') return null;
    return id;
  }

  /// Extrai o `deliveryId` de uma rota de detalhe do comércio
  /// (`/business/deliveries/<id>`), ou `null`.
  static String? businessDeliveryIdFrom(String? routeName) {
    if (routeName == null) return null;
    const prefix = '/business/deliveries/';
    if (!routeName.startsWith(prefix)) return null;
    final id = routeName.substring(prefix.length);
    if (id.isEmpty || id == ':id') return null;
    return id;
  }

  /// Extrai o `deliveryId` de uma rota de rastreamento
  /// (`/deliveries/<id>/tracking`), ou `null`.
  static String? trackingDeliveryIdFrom(String? routeName) {
    if (routeName == null) return null;
    const prefix = '/deliveries/';
    const suffix = '/tracking';
    if (!routeName.startsWith(prefix) || !routeName.endsWith(suffix)) {
      return null;
    }
    final id = routeName.substring(
      prefix.length,
      routeName.length - suffix.length,
    );
    if (id.isEmpty || id == ':id') return null;
    return id;
  }

  /// Dashboard correto para o papel primário do usuário autenticado.
  ///
  /// O Laravel é a autoridade dos papéis; esta rota apenas direciona a UI:
  /// - business → `/business`;
  /// - driver → `/driver`;
  /// - admin → `/admin` (tela dedicada de administração — o app móvel não tem
  ///   feed operacional para essa role; a gestão completa é no painel web).
  static String dashboardForRole(String role) {
    return switch (role) {
      'business' => businessDashboard,
      'driver' => driverDashboard,
      'admin' => adminDashboard,
      // Papel não reconhecido: mantém o comportamento genérico anterior.
      _ => feed,
    };
  }
}
