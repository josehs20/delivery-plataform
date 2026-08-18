# Delivery Platform — Contexto Consolidado do Projeto

> **Arquivo de contexto para os próximos prompts.** Consolida:
> `docs/ARCHITECTURE-CONTEXT.md` (arquitetura Laravel/DDD), `docs/LEARNED-CONTEXT.md`
> (contexto Flutter) e **tudo o que já foi implementado** no monorepo até
> **2026-08-17** (Prompts 1–8 do Flutter).
>
> **Status**: Active Reference · **Leia antes de qualquer implementação.**

---

## 1. Identidade do projeto

Plataforma de entregas regionais (comércio ↔ motoboy) com app Flutter + backend Laravel.

| Camada | Stack |
|---|---|
| Backend | Laravel 11/12, PHP 8.2+ (strict types), MySQL, DDD + 4 camadas, PSR-12 |
| Frontend | Flutter 3.47 / Dart 3.13, Clean Architecture orientada a features |
| Estado Flutter | BLoC/Cubit (estratégia única — não misturar com Riverpod etc.) |
| Banco local Flutter | Hive (offline-first) |
| HTTP Flutter | Dio (cliente centralizado) |
| Mapa/GPS Flutter | flutter_map (OSM) + geolocator |

### Estrutura do monorepo

```text
delivery-platform/
├── docs/          # Fonte de verdade de produto/negócio
│   ├── docs/      # domínio, data-model, api, business-rules, decisions, openapi
│   ├── flutter/   # specs técnicas do Flutter (docs/) + regras .cursor/rules/
│   └── laravel/   # specs técnicas do Laravel (docs/) + regras .cursor/rules/
├── laravel/       # Backend implementado (Stage 4)
└── flutter/       # App Flutter (prompts trabalham aqui)
```

---

## 2. Fontes de verdade (ordem de autoridade)

1. **`/docs/**`** — produto/negócio canônico (domínio, regras, API, decisões).
2. **`/flutter/docs/**`** — spec técnica do Flutter (14 docs + contracts + openapi).
3. **`/laravel/docs/**`** — spec técnica do backend.
4. **`.cursor/rules/*.mdc`** de cada tecnologia — regras de código.

**Regra absoluta**: nunca inventar regras de negócio, financeiras, estados de
entrega, permissões ou workflow. Requisitos `pending` NÃO devem ter comportamento
definido silenciosamente.

---

## 3. Arquitetura

### 3.1 Backend — 4 camadas obrigatórias

- **HTTP**: routes, controllers (finos), Form Requests (validação de transporte),
  API Resources (envelopes estáveis), middleware. Nada de regra de negócio aqui.
- **Application**: `app/Services/`, `app/Actions/`, `app/DTOs/` — orquestração de
  use cases, transações, invariantes.
- **Domain**: `app/Models/` (Eloquent com métodos de negócio), enums de estado,
  `DeliveryStateMachine`, Value Objects, policies, eventos de domínio.
  **Nunca depende de HTTP/DB**.
- **Infrastructure**: `app/Repositories/`, `app/Integrations/` (providers abstratos),
  jobs, listeners, migrations, notifications.

### 3.2 Flutter — Clean Architecture orientada a features

Camadas por feature: **presentation** (widgets/telas), **application** (BLoC/Cubit),
**domain** (models + interfaces de use cases), **data** (repositories + data sources
remotos/locais). Infra compartilhada em `core/`.

Regras:
- Widgets NÃO chamam API/SQL nem executam workflows de domínio.
- Telas se comunicam via estado (Cubit).
- Repositories escondem persistência da UI e coordenam local/remoto.
- **DTOs remotos ≠ entidades locais ≠ estado de UI**; conversão em mappers/repositories.
- SDKs externos isolados atrás de interfaces (mapa, GPS, notificações, pagamento).
- Organizar por domínio de produto (feature-first).

```text
flutter/lib/
├── core/          # network, storage, auth, errors, location, sync, models
├── features/      # auth, delivery, tracking (+ business, driver, negotiation, payments, profile)
│   └── <feature>/{presentation, domain, data}
└── app/           # bootstrap, rotas, tema (Prompt 8)
```

---

## 4. Fronteira cliente/servidor (autoridade)

- **Laravel é autoridade** para: autenticação, autorização, preço final, estado de
  entrega, negociação, pagamentos, refunds, payouts e aceite de sincronização.
- **Flutter** = cliente + **cache operacional local**. Nunca fonte de verdade para
  estado crítico/financeiro. Pode fazer validação de UX, mas o servidor revalida.
- Flutter **nunca envia valores financeiros autoritativos calculados só na UI**.

---

## 5. Domínio central

### 5.1 Máquina de estados da entrega

Fluxo nominal:
```
DRAFT → OPEN → ASSIGNED → DRIVER_ACCEPTED → GOING_TO_PICKUP → AT_PICKUP
      → PICKED_UP → IN_TRANSIT → AT_DESTINATION → DELIVERED
```
Negociação: `OPEN → NEGOTIATING → ASSIGNED → DRIVER_ACCEPTED → ...`
Falha/devolução: `PICKED_UP/IN_TRANSIT/AT_DESTINATION → DELIVERY_FAILED
      → RETURN_REQUIRED → RETURN_IN_PROGRESS → RETURNED → CANCELLED`
Cancelamento (pré-coleta): `DRAFT/OPEN/NEGOTIATING/ASSIGNED/DRIVER_ACCEPTED → CANCELLED`

Valores wire (com underscore) usados no cliente: `DRAFT`, `OPEN`, `NEGOTIATING`,
`ASSIGNED`, `DRIVER_ACCEPTED`, `GOING_TO_PICKUP`, `AT_PICKUP`, `PICKED_UP`,
`IN_TRANSIT`, `AT_DESTINATION`, `DELIVERED`, `DELIVERY_FAILED`, `RETURN_REQUIRED`,
`RETURN_IN_PROGRESS`, `RETURNED`, `CANCELLED`.

Regras: toda transição é validada no servidor e registrada como `DeliveryEvent`
(auditoria); estado renderizado SEMPRE a partir de estado sincronizado (server/local),
nunca de flags ad hoc de UI.

### 5.2 Negociação

- **Offer** (proposta do motoboy): status `PENDING | ACCEPTED | REJECTED | EXPIRED | CANCELLED`.
- **CounterOffer** (contraproposta): status `PENDING | ACCEPTED | REJECTED | EXPIRED | CANCELLED | SUPERSEDED`.
- Janela de aceite configurável; uma proposta vencedora encerra as demais
  (concorrência resolvida no servidor).

### 5.3 Invariantes financeiros

- Preço final, comissão, refund e payout validados/persistidos no servidor.
- Snapshots históricos imutáveis (exceto ajuste auditado explícito).
- **Monetário = String + currency** (ex.: `"25.00"`/`BRL`) — **nunca float** para
  cálculo autoritativo. No Flutter, `double` só para exibição formatada.

### 5.4 Prova de entrega (PoD)

- Entrega só é concluída com prova configurada (assinatura/foto + dados).
- Nunca aceitar status vindo só do cliente.
- No Flutter: captura local (signature pad PNG / image_picker) + enfileiramento na
  SyncQueue (offline-first).

### 5.5 Motoboy multi-entregas

- Um motoboy pode ter **várias entregas ativas** simultaneamente; nunca assumir
  1 motoboy = 1 entrega. Cada entrega tem estado independente.

---

## 6. Regras não-negociáveis (engenharia)

- **Auditabilidade**: toda mudança de estado vira evento; finanças imutáveis;
  ações sensíveis rastreadas ao ator + razão.
- **Idempotência**: operações críticas retryáveis exigem `Idempotency-Key`
  (min 8, máx 255 chars); retry seguro sem efeito duplicado.
- **Consistência transacional**: aceite concorrente serializado; dupla atribuição
  prevenida no DB; pagamento+comissão atômicos.
- **Separação de preocupações**: sem regras em controllers/jobs/widgets.
- **Erros explícitos**: nunca engolir exceções; distinguir 401/403/409/422/429/5xx/
  timeouts/conectividade/conflict de sync; nunca mostrar stack trace ao usuário;
  falha de conectividade NÃO vira erro permanente quando a ação é enfileirável.
- **Segurança**: tokens em secure storage; nunca logar tokens/senhas; sem segredos
  hardcoded; HTTPS fora de dev.

---

## 7. Contrato HTTP (base `/api/v1`, bearerAuth)

### 7.1 Autenticação

- `POST /auth/login` `{identifier, password}` → `data.user + data.token` (Sanctum Bearer).
- `POST /auth/register` (role business/driver com campos específicos).
- `POST /auth/refresh`, `POST /auth/logout`, `POST /auth/forgot-password`, `POST /auth/reset-password`.
- `GET /me` → identidade + papéis + contexto (business/driver). `PATCH /me` atualiza perfil.

### 7.2 Entregas

- `GET /deliveries` (lista por papel), `POST /deliveries` (criar), `GET/PUT /deliveries/{id}`.
- `POST /deliveries/{id}/publish`, `/cancel`, `/accept` (body `offer_id`).
- Transições do motoboy: `/arrive-pickup`, `/pickup`, `/arrive-destination`,
  `/complete` (exige prova), `/fail`, `/return/start`, `/return/confirm`.
- Documentado (nem tudo implementado no backend Stage 4): `GET /driver/offers`,
  `GET /driver/deliveries`, counter-offers, evidence, driver/location.

### 7.3 Erros

- 409: `{error:{code,message,request_id}}`; 422: `{errors:{field:[...]}}`.
- 401/403/409/422/429/5xx tratados distintamente no cliente.

### 7.4 Sincronização offline — `POST /sync/batch`

```json
{ "device_id":"...", "operations":[{ "operation_id":"...", "entity_type":"DELIVERY",
  "entity_id":"...", "operation_type":"CONFIRM_PICKUP",
  "client_created_at":"2026-08-16T12:10:00Z", "client_sequence":42, "payload":{} }] }
```
Resposta: `{ "data":[{ "operation_id":"...", "status":"PROCESSED",
  "server_entity_version":11, "server_timestamp":"..." }] }`
Status: `PROCESSED | ALREADY_PROCESSED | CONFLICT | RETRY | FAILED`.


---

## 8. Estado da implementação — Flutter (Prompts 1–7)

> **Flutter 3.47.0 / Dart 3.13.0** disponíveis (`flutter` no PATH). Todos os prompts
> validados com `flutter analyze` (No issues found) e `flutter test`
> (**197 testes passando**).

### 8.1 Prompt 1 — Estrutura e Clean Architecture

- Estrutura criada em `lib/core/`, `lib/features/`, `lib/app/` (com `.gitkeep`).
- Dependências essenciais no `pubspec.yaml` (ver seção 10).

### 8.2 Prompt 2 — DTOs (`lib/core/models/`)

- `json_utils.dart` — helpers de parsing tolerante (datas→UTC, monetário→String).
- `auth_response_dto.dart` — `UserDto` + `AuthResponseDto` (token Sanctum).
- `delivery_dto.dart` — `DeliveryDto` + `DeliveryItemDto` + `DeliveryAddressDto` +
  `RecipientDto` + `offers` (List<OfferDto>) + `copyWith` completo.
- `offer_dto.dart`, `counter_offer_dto.dart` — negociação/preços (String + currency).
- `sync_operation_dto.dart` — `SyncOperationDto`, `SyncBatchRequestDto`,
  `SyncBatchResultDto`, `SyncBatchResponseDto` (tolera `data:[...]` e `data.results`).
- Regra: DTOs espelham o OpenAPI, toleram campos desconhecidos, não decidem regras.

### 8.3 Prompt 3 — Cliente HTTP centralizado (`lib/core/network/` + `lib/core/errors/`)

- `api_client.dart` — interface `ApiClient` (get/post/put/patch/delete) + `ApiResponse`.
- `dio_api_client.dart` — `DioApiClient`; base URL `http://localhost:8000/api/v1`
  (override via `--dart-define=API_BASE_URL`); timeouts; headers JSON.
- `auth_interceptor.dart` — Bearer via `TokenProvider` (secure storage); preserva header.
- `idempotency_interceptor.dart` — `X-Idempotency-Key` em POST/PUT/PATCH
  (UUID auto; chave explícita preservada; valida min 8 / máx 255).
- `error_mapper.dart` — DioException → `ApiException` tipada (401/403/409/422/429/5xx/
  timeout/conectividade), mensagens seguras, sem stack traces.
- `core/errors/api_exception.dart` — `sealed class ApiException` + `UnauthorizedException`,
  `ForbiddenException`, `ConflictException` (com `code`), `ValidationException`
  (`fieldErrors`), `RateLimitException`, `ServerException`, `NetworkException`.
- `core/auth/token_provider.dart` — `TokenProvider` + `TokenStore` (read/save/clear);
  `secure_storage_token_provider.dart` implementa com flutter_secure_storage.

### 8.4 Prompt 4 — Banco local e Motor de sincronização

- `core/storage/local_database.dart` — `LocalDatabase` (Hive): boxes
  `deliveries_cache`, `sync_queue`, `app_meta`; `deviceId()` estável; factories
  `deliveryCache()`/`syncQueue()`.
- `core/storage/delivery_cache_repository.dart` — cache de entregas (upsert/byId/all/
  byStatus/remove/clear).
- `core/sync/sync_operation.dart` — model durável `SyncOperation` (operation_id,
  device_id, entidade, payload, criado_em, tentativas, próximo_retry, status, erro,
  schema_version) + enum `SyncOperationStatus` (pending/retry/conflict/failed) +
  `copyWith` com sentinela + `toDto()`.
- `core/sync/sync_queue.dart` — interface `SyncQueue` (enqueue idempotente, pending,
  markProcessed/Retry/Conflict/Failed).
- `core/sync/hive_sync_queue.dart` — impl Hive; **backoff exponencial limitado**
  (1m→cap 1h) e **máx. tentativas** (default 10 → falha permanente).
- `core/sync/sync_worker.dart` — `SyncWorker.sync()` envia `POST /sync/batch`;
  PROCESSED/ALREADY_PROCESSED → remove; CONFLICT → marca conflito; RETRY/desconhecido/
  sem-resultado → retry; FAILED → permanente; rede/5xx/429 → retry de todas;
  401/403 → não queima tentativas (erro em `SyncResult.error`).
- `core/sync/sync_service.dart` — facade com guarda de execução concorrente.


### 8.5 Prompt 5 — Autenticação e Sessão (`lib/features/auth/`)

- **domain**: `AuthUser`, `AuthSession`, `RegisterParams`+`AuthRole`, interface `AuthRepository`.
- **data**: `AuthRemoteDataSource` (+impl: login/register/refresh/logout/me),
  `AuthRepositoryImpl` (persiste/limpa token, restore com `/me` + limpa token em 401),
  `UserMapper`.
- **presentation**: `AuthCubit` com estados `AuthUnauthenticated | AuthAuthenticating |
  AuthAuthenticated | AuthError`; `LoginScreen` (validação email/telefone + senha ≥ 8,
  SnackBar de erro, loading, redirecionamento para `AppRoutes.dashboard`).
- `app/routes/app_routes.dart` — `splash, login, register, dashboard, feed, deliveryDetail`.

### 8.6 Prompt 6 — Feature de Entregas (`lib/features/delivery/`)

> Grande parte do domínio/data/application/presentation **já existia**; completei com
> testes, corrigi 2 bugs e reescrevi 1 teste malformado.

- **domain**: `Delivery` + `DeliveryStatus` (wire values com underscore — **bug
  corrigido**), `DeliveryAddress`, `Recipient`, `DeliveryItem`, `Offer` (+`pendingOffer`),
  `DeliveryRepository` (resultados `DeliveryListResult`/`DeliveryLoadResult`/
  `DeliveryActionResult`), `ProofOfDelivery`/`ProofType`, use cases
  (ListAvailableDeliveries, GetDelivery, AcceptOffer, RegisterPickupArrival,
  ConfirmPickup, ConfirmDelivery).
- **data**: `DeliveryMapper`, `DeliveryRemoteDataSource` (GET /deliveries,
  accept/arrive-pickup/pickup/complete com idempotency), `DeliveryRepositoryImpl`
  (**offline-first**: aceite exige rede; transições tentam servidor e, offline,
  aplicam localmente + enfileiram na SyncQueue com `operation_type` ARRIVE_PICKUP/
  CONFIRM_PICKUP/COMPLETE e payload `{delivery_id, action, proof?}`).
- **application**: `DeliveryListCubit` (load/refresh/accept) e `DeliveryDetailCubit`
  (load/registerPickupArrival/confirmPickup/confirmDelivery) com estados
  **Loading | Local | Syncing | Synced | Failure**.
- **presentation**: `DeliveryFeedScreen` (feed com aceite, banner offline, retry),
  `DeliveryDetailScreen` (ações por estado: "Cheguei na coleta"→"Confirmar coleta"→
  "Confirmar entrega"; banner sync local/sincronizado), `ProofOfDeliveryModal`
  (assinatura PNG + foto via `PhotoPicker` isolado), `SignaturePad` (**bug corrigido**:
  dimensões infinitas em scrollable → fallback), `delivery_labels.dart`
  (`formatCurrency` pt_BR + `deliveryStatusLabel`).
- Plataforma: `image_picker` adicionado; modal usa `ImagePicker` por trás da interface.

### 8.7 Prompt 7 — Localização e Mapa

- `core/location/location_point.dart` — `LocationPoint` (lat/lon/accuracy/speed/
  heading/recordedAt/`deliveryId`/`clientEventId`) + `isValid()` (precisão/idade).
- `core/location/location_service.dart` — interface `LocationService` +
  `LocationPermissionStatus` (granted/denied/deniedForever/restricted/unknown).
- `core/location/geolocator_location_service.dart` — impl com `geolocator`
  (requestPermission, permissionStatus, isGpsEnabled, currentPosition one-shot,
  `track(deliveryId, distanceFilterMeters)` com contexto da entrega).
- `features/tracking/presentation/widgets/delivery_map.dart` — `DeliveryMap`
  (flutter_map/OSM): marcadores Coleta/Destino/Entregador, `CameraFit.bounds`,
  rota estimada (`showRoute`), `tileProvider` injetável (testes sem rede).
- Plataforma: permissões Android (`ACCESS_FINE/COARSE_LOCATION`) e iOS
  (`NSLocationWhenInUseUsageDescription` + Always) configuradas.
- Dependências: `geolocator`, `flutter_map`, `latlong2` adicionadas.

### 8.8 Prompt 8 — Bootstrap, rotas e tema (`lib/main.dart` e `lib/app/`)

- `main.dart` — `main()` assíncrono (`WidgetsFlutterBinding.ensureInitialized()`),
  `AppBootstrap.create()` (Hive/banco local, Secure Storage, ApiClient) e
  `runApp(App(...))`; removida a página de exemplo `MyHomePage` (contador).
- `app/bootstrap/app_bootstrap.dart` — **composition root**: `AppDependencies` +
  `AppBootstrap.create()` (aceita injeções para testes: diretório do banco, token
  store e API client fakes). Conecta `LocalDatabase` → `TokenStore` → `ApiClient`
  (Dio) → `AuthRepositoryImpl`/`AuthCubit` → `SyncWorker`/`SyncService` →
  `DeliveryRepositoryImpl`/`DeliveryListCubit`/`DeliveryDetailCubit`.
- `app/app.dart` — widget `App`: `MultiBlocProvider` (AuthCubit, DeliveryListCubit,
  DeliveryDetailCubit) + `MaterialApp` (título **'Delivery App'**, `AppTheme.light`,
  `initialRoute` Splash, `routes` + `onGenerateRoute` + `onUnknownRoute`→Splash).
- `app/routes.dart` — tabela `appRoutes` (`/` splash, `/login`, `/dashboard`,
  `/deliveries/feed`) + `appOnGenerateRoute` resolvendo `/deliveries/:id` →
  `DeliveryDetailScreen(deliveryId)`.
- `app/routes/app_routes.dart` — helpers `deliveryDetailFor(id)` e `deliveryIdFrom(name)`.
- `app/theme/app_theme.dart` — tema Material 3 (seed `0xFF00695C`, AppBar centralizado).
- `app/pages/delivery_dashboard_screen.dart` — **Dashboard de Entregas** (wrapper do
  app-layer que dispara `DeliveryListCubit.load()` e renderiza `DeliveryFeedScreen`).
- `features/auth/presentation/screens/splash_screen.dart` — **Splash**: chama
  `AuthCubit.restoreSession()` e redireciona para `/deliveries/feed` (autenticado)
  ou `/login` (sem sessão / erro).
- Rotas `/register` declaradas em `AppRoutes` mas sem tela (MVP) — registradas junto
  com a feature de cadastro.
- **Primeira tela**: Splash → **Login** (sem sessão) ou **Dashboard de Entregas** (com sessão).
- Testes: `test/app/{routes_test, app_bootstrap_test, delivery_dashboard_screen_test}.dart`,
  `test/features/auth/splash_screen_test.dart` e `widget_test.dart` (smoke test do App
  completo: Splash → Login sem token).


---

## 9. Estrutura atual — `flutter/lib/` e `flutter/test/`

```text
flutter/lib/
├── main.dart                                  # bootstrap: AppBootstrap.create() + runApp(App)
├── app/                                       # Prompt 8 — bootstrap, rotas, tema
│   ├── app.dart                               # widget App (MultiBlocProvider + MaterialApp)
│   ├── routes.dart                            # appRoutes + appOnGenerateRoute
│   ├── routes/app_routes.dart                 # splash, login, register, dashboard, feed, deliveryDetail + helpers
│   ├── bootstrap/app_bootstrap.dart           # AppDependencies + AppBootstrap.create()
│   ├── pages/delivery_dashboard_screen.dart   # Dashboard de Entregas (feed + load)
│   └── theme/app_theme.dart                   # tema Material 3 (seed 0xFF00695C)
├── core/
│   ├── auth/        token_provider.dart, secure_storage_token_provider.dart
│   ├── errors/      api_exception.dart
│   ├── location/    location_point.dart, location_service.dart, geolocator_location_service.dart
│   ├── models/      json_utils, auth_response_dto, delivery_dto, offer_dto,
│   │                counter_offer_dto, sync_operation_dto
│   ├── network/     api_client, dio_api_client, auth_interceptor,
│   │                idempotency_interceptor, error_mapper
│   ├── storage/     local_database, delivery_cache_repository
│   └── sync/        sync_operation, sync_queue, hive_sync_queue, sync_worker, sync_service
└── features/
    ├── auth/        domain/{auth_user, auth_session, register_params, auth_repository}
    │                data/{auth_remote_data_source, auth_repository_impl, user_mapper}
    │                presentation/{auth_cubit, auth_state, screens/login_screen}
    ├── delivery/    domain/{delivery, delivery_repository, proof_of_delivery, use_cases}
    │                data/{delivery_mapper, delivery_remote_data_source, delivery_repository_impl}
    │                presentation/{delivery_list_cubit|state, delivery_detail_cubit|state,
    │                delivery_labels, screens/{delivery_feed_screen, delivery_detail_screen},
    │                widgets/{proof_of_delivery_modal, signature_pad}}
    └── tracking/    presentation/widgets/delivery_map.dart
                    (domain/ e data/ vazios — prontos para a próxima etapa)
```

```text
flutter/test/                        # 197 testes (todos passando)
├── app/      app_bootstrap, routes, delivery_dashboard_screen + widget_test (smoke do App)
├── core/     models/ auth_response_dto, delivery_dto, offer_dto, counter_offer_dto, sync_operation_dto
│             network/ auth_interceptor, idempotency_interceptor, error_mapper, dio_api_client
│             sync/    sync_operation, hive_sync_queue, sync_worker
│             storage/ delivery_cache_repository, local_database
│             location/ location_point
└── features/ auth/    auth_repository, auth_cubit, login_screen, splash_screen
              delivery/ delivery_repository, delivery_list_cubit, delivery_detail_cubit,
                        delivery_labels, delivery_feed_screen, delivery_detail_screen,
                        proof_of_delivery_modal
              tracking/ delivery_map
```

---

## 10. Dependências do Flutter (`pubspec.yaml`)

| Pacote | Versão | Uso |
|---|---|---|
| `flutter_bloc` | ^9.1.1 | Estado (única estratégia) |
| `dio` | ^5.11.0 | Cliente HTTP centralizado |
| `hive` / `hive_flutter` | ^2.2.3 / ^1.1.0 | Banco local / cache offline-first |
| `flutter_secure_storage` | ^11.0.0 | Tokens/sessão |
| `uuid` | ^4.6.0 | IDs, operation_id, client_event_id |
| `intl` | ^0.20.3 | Formatação moeda/data (pt_BR) |
| `equatable` | ^2.1.0 | (disponível; ainda não usado) |
| `image_picker` | ^1.2.3 | Captura de foto na prova de entrega |
| `geolocator` | ^14.0.3 | GPS/permissões/rastreamento |
| `flutter_map` + `latlong2` | ^8.3.1 / ^0.10.1 | Mapa (OSM, sem API key) |
| `flutter_lints` | ^6.0.0 | Lints (dev) |

---

## 11. Backend Laravel — estado atual (referência)

- Implementado até **Stage 4**: auth Sanctum (login/register/refresh/logout, /me),
  deliveries (CRUD, publish, cancel), máquina de estados + `DeliveryStateMachine`,
  `CreateDeliveryAction`, `DispatchService`, transições do motoboy (arrive-pickup,
  pickup, arrive-destination, complete, fail, return), sync de operações
  (`POST /sync`), middleware `IdempotencyKeyMiddleware` (`X-Idempotency-Key`).
- Rotas em `laravel/routes/api.php`; migrations 001–033 + personal_access_tokens.
- Testes backend: 12/12 passando.
- **Divergência**: o endpoint de sync do backend (Stage 4) lê campos diferentes do
  contrato OpenAPI (`entity`/`operation`/`created_at`); o contrato canônico é o
  **OpenAPI** (`entity_type`/`operation_type`/`client_created_at`) — seguir o OpenAPI.


---

## 12. Verificações atuais (2026-08-17)

- `flutter analyze` → **No issues found!**
- `flutter test` → **All tests passed!** (197 testes)
- Dica de execução: `cd flutter && flutter test`; para capturar saída longa use
  `flutter test 2>&1 | tee /tmp/t.log | tail` (a captura de shell pode truncar).
- Permissões de plataforma já configuradas (GPS Android/iOS).

---

## 13. Próximos passos sugeridos (baseline itens restantes)

1. ✅ **Bootstrap do app** — **concluído no Prompt 8** (ver seção 8.8): `main.dart`
   assíncrono com `AppBootstrap.create()`, widget `App` com `MultiBlocProvider` +
   `MaterialApp`, rotas/`onGenerateRoute`, tema Material 3 e Splash com
   `restoreSession()` — primeira tela = Login ou Dashboard de Entregas.
2. **Tracking feature** — `TrackingCubit`/repositório ligando `LocationService.track()`
   à SyncQueue (entidade `LOCATION`, offline-first) + tela "Mapa/rota" com `DeliveryMap`.
3. **Notifications** (`lib/core/notifications/`) — provider abstrato (FCM), token no
   backend, deduplicação, navegação para estado sincronizado.
4. **Negociação** (offers/counter-offers) — feature `negotiation`.
5. **Perfil** (`features/profile`), **Driver/Business**, **Payments**.
6. **Testes E2E/integration** dos fluxos críticos (login → oferta → coleta → entrega).

---

## 14. Divergências e decisões documentadas

- **Idempotency-Key**: OpenAPI usa `Idempotency-Key`; o middleware Laravel lê
  `X-Idempotency-Key` (também aceita `idempotency_key`/`sync_token` no body).
  O cliente envia `X-Idempotency-Key` (header que o backend processa).
- **operation_type de sync**: o OpenAPI usa tipos semânticos (`CONFIRM_PICKUP` etc.);
  o backend Stage 4 espera `STATE_TRANSITION` + `payload.action`. O cliente segue o
  **OpenAPI** e inclui `payload.action` para compatibilidade.
- **`GET /driver/offers`** e counter-offers não estão nas rotas do backend Stage 4
  (documentados em `docs/docs/api/*`); o feed usa `GET /deliveries` como fonte atual.
- **Monetário**: sempre String + currency; `double` apenas para formatação visual.
- **Estados de UI de sync**: `local | sincronizando | sincronizado | falha` — a UI
  diferencia "salvo localmente" de "confirmado pelo servidor".

