import 'dart:io';

import '../../core/auth/secure_storage_token_provider.dart';
import '../../core/auth/token_provider.dart';
import '../../core/location/geolocator_location_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_api_client.dart';
import '../../core/storage/local_database.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_worker.dart';
import '../../features/admin/data/admin_remote_data_source.dart';
import '../../features/admin/data/admin_repository_impl.dart';
import '../../features/admin/presentation/cubits/admin_audit_logs_cubit.dart';
import '../../features/admin/presentation/cubits/admin_dashboard_cubit.dart';
import '../../features/admin/presentation/cubits/admin_deliveries_cubit.dart';
import '../../features/admin/presentation/cubits/admin_drivers_cubit.dart';
import '../../features/admin/presentation/cubits/admin_financial_cubit.dart';
import '../../features/auth/data/auth_remote_data_source.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/presentation/auth_cubit.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/business/presentation/business_delivery_cubit.dart';
import '../../features/delivery/data/delivery_remote_data_source.dart';
import '../../features/delivery/data/delivery_repository_impl.dart';
import '../../features/delivery/domain/use_cases.dart';
import '../../features/delivery/presentation/delivery_detail_cubit.dart';
import '../../features/delivery/presentation/delivery_list_cubit.dart';
import '../../features/profile/presentation/profile_cubit.dart';
import '../../features/tracking/data/tracking_repository_impl.dart';
import '../../features/tracking/presentation/tracking_cubit.dart';

/// Dependências raiz do app (composition root) — fornecidas ao widget [App].
final class AppDependencies {
  AppDependencies({
    required this.localDatabase,
    required this.tokenStore,
    required this.apiClient,
    required this.authCubit,
    required this.deliveryListCubit,
    required this.deliveryDetailCubit,
    required this.createDeliveryCubit,
    required this.trackingCubit,
    required this.profileCubit,
    required this.adminDashboardCubit,
    required this.adminDriversCubit,
    required this.adminDeliveriesCubit,
    required this.adminFinancialCubit,
    required this.adminAuditLogsCubit,
    required this.syncService,
  });

  /// Banco local (Hive) — cache de entregas + fila de sync.
  final LocalDatabase localDatabase;

  /// Armazenamento seguro do token (flutter_secure_storage).
  final TokenStore tokenStore;

  /// Cliente HTTP centralizado (Dio).
  final ApiClient apiClient;

  final AuthCubit authCubit;
  final DeliveryListCubit deliveryListCubit;
  final DeliveryDetailCubit deliveryDetailCubit;
  final CreateDeliveryCubit createDeliveryCubit;
  final TrackingCubit trackingCubit;
  final ProfileCubit profileCubit;

  // Painel administrativo (`features/admin`).
  final AdminDashboardCubit adminDashboardCubit;
  final AdminDriversCubit adminDriversCubit;
  final AdminDeliveriesCubit adminDeliveriesCubit;
  final AdminFinancialCubit adminFinancialCubit;
  final AdminAuditLogsCubit adminAuditLogsCubit;

  /// Facade do motor de sincronização (fila offline → `/sync`).
  final SyncService syncService;
}

/// Composição dos serviços essenciais na inicialização do app.
///
/// Ordem (docs/flutter/docs/implementation-baseline.md): ambiente → API client
/// → auth/session → banco local → repositories → sync → features. Aceita
/// injeções para testes (diretório do banco, token store e API client fakes).
abstract final class AppBootstrap {
  static Future<AppDependencies> create({
    Directory? databaseDirectory,
    TokenStore? tokenStore,
    ApiClient? apiClient,
  }) async {
    // 1. Banco local (Hive) e armazenamento seguro do token.
    final database = await LocalDatabase.open(directory: databaseDirectory);
    final tokens = tokenStore ?? SecureStorageTokenProvider();

    // 2. Cliente HTTP centralizado (Bearer via TokenProvider compartilhado).
    //    O `onUnauthorized` reage a 401 em requisições autenticadas em plena
    //    sessão (token expirado/revogado): o app desloga e volta ao login.
    //    O holder resolve a referência circular auth → http → auth.
    final onSessionExpired = _CallbackHolder();
    final http = apiClient ??
        DioApiClient(
          tokenProvider: tokens,
          onUnauthorized: onSessionExpired.call,
        );

    // 3. Auth/sessão.
    final authCubit = AuthCubit(
      AuthRepositoryImpl(
        AuthRemoteDataSourceImpl(http),
        tokens,
      ),
    );
    onSessionExpired.callback = () {
      if (authCubit.state is AuthAuthenticated) {
        authCubit.logout();
      }
    };

    // 4. Sync engine (fila offline + worker).
    final deviceId = await database.deviceId();
    final syncService = SyncService(
      SyncWorker(http, database.syncQueue(), deviceId),
    );

    // 5. Entregas (remoto + cache local + fila de sync, offline-first).
    final deliveryRepository = DeliveryRepositoryImpl(
      DeliveryRemoteDataSourceImpl(http),
      database.deliveryCache(),
      database.syncQueue(),
      deviceId,
    );
    final deliveryListCubit = DeliveryListCubit(
      ListAvailableDeliveries(deliveryRepository),
      AcceptOffer(deliveryRepository),
    );
    final deliveryDetailCubit = DeliveryDetailCubit(
      getDelivery: GetDelivery(deliveryRepository),
      registerPickupArrival: RegisterPickupArrival(deliveryRepository),
      confirmPickup: ConfirmPickup(deliveryRepository),
      registerDestinationArrival:
          RegisterDestinationArrival(deliveryRepository),
      confirmDelivery: ConfirmDelivery(deliveryRepository),
      failDelivery: FailDelivery(deliveryRepository),
      startReturn: StartReturn(deliveryRepository),
      publishDelivery: PublishDelivery(deliveryRepository),
      cancelDelivery: CancelDelivery(deliveryRepository),
      confirmReturn: ConfirmReturn(deliveryRepository),
    );
    final createDeliveryCubit = CreateDeliveryCubit(
      CreateDelivery(deliveryRepository),
    );

    // 6. Rastreamento (GPS → SyncQueue, offline-first).
    final trackingCubit = TrackingCubit(
      TrackingRepositoryImpl(
        GeolocatorLocationService(),
        database.syncQueue(),
        deviceId,
      ),
    );

    // 7. Perfil (`/me`).
    final profileCubit = ProfileCubit(
      AuthRepositoryImpl(
        AuthRemoteDataSourceImpl(http),
        tokens,
      ),
    );

    // 8. Painel administrativo (API `/admin/*`).
    final adminRepository = AdminRepositoryImpl(
      AdminRemoteDataSourceImpl(http),
    );
    final adminDashboardCubit = AdminDashboardCubit(adminRepository);
    final adminDriversCubit = AdminDriversCubit(adminRepository);
    final adminDeliveriesCubit = AdminDeliveriesCubit(adminRepository);
    final adminFinancialCubit = AdminFinancialCubit(adminRepository);
    final adminAuditLogsCubit = AdminAuditLogsCubit(adminRepository);

    return AppDependencies(
      localDatabase: database,
      tokenStore: tokens,
      apiClient: http,
      authCubit: authCubit,
      deliveryListCubit: deliveryListCubit,
      deliveryDetailCubit: deliveryDetailCubit,
      createDeliveryCubit: createDeliveryCubit,
      trackingCubit: trackingCubit,
      profileCubit: profileCubit,
      adminDashboardCubit: adminDashboardCubit,
      adminDriversCubit: adminDriversCubit,
      adminDeliveriesCubit: adminDeliveriesCubit,
      adminFinancialCubit: adminFinancialCubit,
      adminAuditLogsCubit: adminAuditLogsCubit,
      syncService: syncService,
    );
  }
}

/// Holder de callback (resolve referências circulares na composition root).
final class _CallbackHolder {
  void Function() callback = _noop;

  void call() => callback();

  static void _noop() {}
}