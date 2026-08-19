# Delivery Platform — Status da Implementação (Views & Backend)

> **Documento de contexto para agentes/IA.** Consolida o que **já foi implementado**
> e o que **era esperado** em **views (Flutter)** e **backend (Laravel)**, conforme os
> contratos canônicos de `/docs`. Use este arquivo como ponto de partida antes de
> qualquer implementação — ele sintetiza as duas frentes e aponta divergências e gaps.

**Gerado em:** 2026-08-18
**Fonte principal:** `docs/ARCHITECTURE-CONTEXT.md`, `docs/LEARNED-CONTEXT.md`,
`docs/PROJECT-CONTEXT.md`, `docs/flutter/docs/*`, `docs/docs/api/*`,
`laravel/routes/api.php` e `flutter/lib/**`.

---

## 1. Fontes de verdade (ordem de autoridade)

1. `/docs/**` — produto/negócio canônico (domain, data-model, api, business-rules, decisions, openapi).
2. `/docs/flutter/docs/**` — spec técnica do Flutter (14 documentos).
3. `/docs/laravel/docs/**` — spec técnica do backend.
4. `.cursor/rules/*.mdc` — regras de código por tecnologia.

**Regra absoluta:** nunca inventar regra de negócio, regra financeira, estado de
entrega, permissão ou workflow. Requisitos `pending` NÃO devem ter comportamento
definido silenciosamente. O **Laravel é autoridade** para estado, preço, negociação,
pagamentos, refunds, payouts e aceite de sincronização — o **Flutter é cliente**
(cache operacional local).

---

## 2. Resumo executivo

| Área | Esperado (contrato) | Implementado | Gap principal |
|---|---|---|---|
| **Auth backend** | login/register/refresh/logout/forgot-password/reset-password + `GET/PATCH /me` | Todos implementados, **incluindo `POST /auth/logout` registrado e protegido por Sanctum** (revoga o token, 200) | — |
| **Entregas backend** | CRUD + publish + cancel + transições do motoboy + eventos + tracking | CRUD + publish + cancel + aceite + 7 transições (`arrive-pickup`, `pickup`, `arrive-destination`, `complete`, `fail`, `return/start`, `return/confirm`) | Sem `GET /deliveries/{id}/events` nem `GET /deliveries/{id}/tracking` |
| **Negociação backend** | offers/counter-offers (listar, aceitar, rejeitar, contrapropor) | Somente aceite via `offer_id` em `POST /deliveries/{id}/accept` | Sem endpoints de contraproposta; sem `GET /driver/offers` |
| **Sync backend** | `POST /api/v1/sync/batch` (contrato OpenAPI) | `POST /api/v1/sync` com shape próprio (`entity`/`operation`/`created_at`) | Divergência de contrato documentada; cliente segue o backend real |
| **Financeiro backend** | quote/payment/webhooks/refund/payout | **Não implementado** | Bloqueia telas de Revisão/pagamento e Ganhos |
| **Admin backend** | `/admin/*` (aprovar motoboy, financeiro, auditoria) | ✅ **implementado em 2026-08-18** — 13 rotas (`metrics`, drivers pending/approve/reject/suspend, deliveries+assign/cancel, payments, refunds, payouts, audit-logs) protegidas por `can:access-admin` | — |
| **Notificação backend** | `/devices`, `/notifications`, read/read-all | **Não implementado** | Push sem endpoint de registro de token |
| **Views comércio** | 15 telas MVP | 7 telas + criação de entrega | Revisão/pagamento e Ofertas/contrapropostas |
| **Views motoboy** | 16 telas MVP | 6 telas + feed integrado | Ofertas, status online/offline, documentos, veículo, ganhos |

---

## 3. Backend Laravel — O QUE ERA ESPERADO (contrato `/docs/docs/api/*`)

Base: `/api/v1`, `bearerAuth` (Sanctum), `Idempotency-Key` em comandos críticos,
envelope `{"data": {...}}`, erro `{"error": {code, message, request_id}}`.

### 3.1 Autenticação (`30-auth-api.md`)
| Endpoint | Esperado |
|---|---|
| `POST /auth/login` | `{identifier, password}` → `{user, roles, token}` |
| `POST /auth/register` | role `business`/`driver` com campos específicos |
| `POST /auth/logout` | encerra sessão atual |
| `POST /auth/refresh` | renova autenticação |
| `POST /auth/forgot-password` / `POST /auth/reset-password` | recuperação de senha |
| `GET /me` + `PATCH /me` | identidade/contexto autorizado + atualização |

### 3.2 Comércio (`31-business-api.md`)
`GET/PUT /business/me` · `GET/POST /business/addresses` · `PUT/DELETE /business/addresses/{id}`

### 3.3 Motoboy (`32-driver-api.md`)
`GET/PUT /driver/me` · `GET/POST /driver/documents` · `GET/POST /driver/vehicles` ·
`PUT /driver/vehicles/{id}` · `GET/PUT /driver/preferences` · `POST /driver/availability` `{available}`

### 3.4 Consulta de entregas (`33-delivery-query-api.md`)
`GET /business/deliveries[?status&created_from&driver_id&recipient&cursor]` ·
`GET /business/deliveries/{id}` · `GET /driver/deliveries` · `GET /driver/deliveries/{id}` ·
`GET /driver/offers` · `GET /deliveries/{id}/events` · `GET /deliveries/{id}/tracking`

### 3.5 Entregas (`34-delivery-api.md`)
`POST /deliveries` (origem/destino/recipiente/items/pricing/pickup_deadline) ·
`PUT /deliveries/{id}` (só editáveis) · `POST /deliveries/{id}/publish` ·
`POST /deliveries/{id}/cancel` `{reason, description}` ·
`POST /deliveries/{id}/accept` ·
`POST /deliveries/{id}/arrive-pickup` · `/pickup` · `/arrive-destination` · `/complete` (exige proof) ·
`/fail` (exige reason) · `/return/start` · `/return/confirm`

### 3.6 Ofertas e contrapropostas (`35-offer-and-counteroffer-api.md`)
`GET /driver/offers` · `GET /deliveries/{id}/offers` · `POST /deliveries/{id}/accept` ·
`POST /deliveries/{id}/counter-offers` `{amount, currency, message}` ·
`GET /deliveries/{id}/counter-offers` · `POST /counter-offers/{id}/accept` · `POST /counter-offers/{id}/reject`

### 3.7 Financeiro (`36-payment-api.md`)
`GET /deliveries/{id}/quote` · `POST /deliveries/{id}/payment` ·
`POST /payments/webhooks/{provider}` · `GET /business/payments` ·
`GET /driver/payouts` · `GET /driver/payouts/{id}` · `POST /deliveries/{id}/refund`

### 3.8 Localização (`37-location-api.md`)
`POST /driver/location` · `POST /driver/location/batch` · `GET /deliveries/{id}/tracking`

### 3.9 Sync (`38-sync-api.md`)
`POST /sync/batch` com `{device_id, operations:[{operation_id, entity_type, entity_id,
operation_type, client_created_at, client_sequence, payload}]}` → status
`PROCESSED | ALREADY_PROCESSED | CONFLICT | RETRY | FAILED`.

### 3.10 Notificações (`39-notification-api.md`)
`POST /devices` · `DELETE /devices/{id}` · `GET /notifications` ·
`POST /notifications/{id}/read` · `POST /notifications/read-all`

### 3.11 Evidências (`40-evidence-api.md`)
`POST /uploads` · `POST /deliveries/{id}/evidence` · `complete` exige prova configurada.

### 3.12 Admin (`41-admin-api.md`)
`GET /admin/drivers/pending` · `POST /admin/drivers/{id}/approve|reject|suspend` ·
`GET /admin/deliveries` · `POST /admin/deliveries/{id}/assign|cancel` ·
`GET /admin/payments|refunds|payouts` · `GET /admin/audit-logs`

---

## 4. Backend Laravel — O QUE JÁ FOI IMPLEMENTADO

### 4.1 Rotas reais em `laravel/routes/api.php`

**Público (sem auth)**
- `POST /auth/login`, `POST /auth/register`, `POST /auth/refresh`,
  `POST /auth/forgot-password`, `POST /auth/reset-password` (rate limit `throttle:5,1`)
- `GET /health` · `GET /docs` (serve o openapi.yaml)

**Protegido (`auth:sanctum`)**
- `GET /me`, `PATCH /me`
- `GET /deliveries` (listagem **por papel**: business=suas, driver=atribuídas, admin=todas, paginado)
- `POST /deliveries` (`can:create-delivery`, cria DRAFT via `CreateDeliveryAction`)
- `GET /deliveries/{id}`, `PUT /deliveries/{id}` (somente DRAFT)
- `POST /deliveries/{id}/publish` (`DRAFT → OPEN` + dispatch)
- `POST /deliveries/{id}/accept` (`can:accept-delivery` + idempotency; concorrência serializada com `lockForUpdate`)
- `POST /deliveries/{id}/arrive-pickup|pickup|arrive-destination|complete|fail|return/start`
  (`can:transition-delivery` + idempotency; `complete` exige `proof`, `fail` exige `reason`)
- `POST /deliveries/{id}/return/confirm` (business confirma devolução)
- `POST /deliveries/{id}/cancel` (business, `can:cancel-delivery`, com motivo/descrição)
- `POST /sync` (somente role `driver`; processa fila offline)

**⚠️ Rota ausente:** `POST /auth/logout` existe no `AuthController` mas **não está
registrada nas rotas** → o app Flutter que chama `POST /auth/logout` recebe 404 hoje.

### 4.2 Camadas e componentes implementados

| Camada | Artefatos |
|---|---|
| **Domain** | `DeliveryStateMachine` (transições completas), `Enums/DeliveryStatus|OfferStatus|CounterOfferStatus|PaymentStatus`, `Services/DeliveryTransitionResolver`, `Services/DispatchService`, `Actions/CreateDeliveryAction`, exceção de transição inválida |
| **HTTP** | 4 controllers (`Auth`, `Me`, `Delivery`, `Sync`), 14+ Form Requests, middleware `IdempotencyKeyMiddleware`, policy `DeliveryPolicy`, rule `Ulid` |
| **Infra/Dados** | 36+ migrations (usuários, roles, business, driver, deliveries, ofertas, contrapropostas, atribuições, eventos, evidências, falhas, cancelamentos, devoluções, payments, refunds, commissions, payouts, notifications, sync_operations, audit_logs) e 34+ Models Eloquent (com `HasUuidPrimaryKey`) |
| **DTOs** | `CreateDeliveryData`, `UpdateDeliveryData`, `AcceptDeliveryData`, `CompleteDeliveryData`, `FailDeliveryData`, `CreateCounterOfferData`, `LocationPointData`, `SyncOperationData` |

### 4.3 Regras de engenharia já aplicadas no backend
- **Audit trail** (ADR-008): toda transição grava `DeliveryEvent` via `recordEvent()`.
- **Idempotência** (ADR-005): `X-Idempotency-Key` no middleware; sync deduplicado por
  `(client_id, operation_id)` → `ALREADY_PROCESSED`.
- **Concorrência** (ADR-004): aceite/transições usam `lockForUpdate` em transação.
- **Sync parcial tolerante**: falha de uma operação não bloqueia as demais;
  processa `delivery (STATE_TRANSITION)`, `location (CREATE/UPDATE)`,
  `proof (CREATE)`, `event (CREATE)`.
- **Autorização por papel** nas rotas (`can:create-delivery`, `can:accept-delivery`,
  `can:transition-delivery`, `can:update-delivery`, `can:cancel-delivery`) e checks
  de propriedade nos controllers (anti-IDOR).

---

## 5. Backend — LACUNAS em relação ao contrato

### 5.1 Endpoints do contrato que NÃO existem no backend
| Grupo | Endpoints faltantes |
|---|---|
| **Logout** | ~~`POST /auth/logout`~~ ✅ **registrado** em 2026-08-18 (protegido por `auth:sanctum`, revoga o token atual, resposta `{"data":{"message":"Successfully logged out"}}` 200) |
| **Comércio** | `GET/PUT /business/me`, `/business/addresses` CRUD |
| **Motoboy** | `GET/PUT /driver/me`, `/driver/documents`, `/driver/vehicles`, `/driver/preferences`, `POST /driver/availability` |
| **Ofertas** | `GET /driver/offers`, `GET /deliveries/{id}/offers` |
| **Contrapropostas** | `POST/GET /deliveries/{id}/counter-offers`, `POST /counter-offers/{id}/accept|reject` |
| **Eventos/Tracking** | `GET /deliveries/{id}/events`, `GET /deliveries/{id}/tracking` |
| **Financeiro** | quote, payment, webhooks, `GET /business/payments`, `GET /driver/payouts`, refund |
| **Localização direta** | `POST /driver/location`, `POST /driver/location/batch` (hoje só via `/sync`) |
| **Notificações** | `/devices`, `/notifications`, read/read-all |
| **Evidências/uploads** | `POST /uploads`, `POST /deliveries/{id}/evidence` (hoje via `/sync` proof ou `complete`) |
| **Admin** | ~~todo o grupo `/admin/*`~~ ✅ **implementado em 2026-08-18** (`AdminController` + `AdminPolicy` + gate `access-admin` + rotas: metrics, drivers pending/approve/reject/suspend, deliveries + assign/cancel, payments, refunds GET/POST, payouts, audit-logs) |

### 5.2 Notas de implementação incompleta
- `forgotPassword` cria o token mas **não dispara e-mail** (TODO).
- `GET /deliveries` do **business** não filtra por status/data/recipiente
  (contrato prevê filtros); o feed do comércio usa a listagem simples.
- O backend usa **`ASSIGNED`** como estado após aceite e exige confirmação
  (`ASSIGNED → DRIVER_ACCEPTED`), enquanto o contrato OpenAPI/Flutter trata o aceite
  como `DRIVER_ACCEPTED` — a máquina de estados cobre ambos, mas o `accept` atual
  manda para `ASSIGNED` (segue os testes backend).
- Migrations 026–033 (payments, refunds, commissions, payouts, notifications,
  sync_operations, audit_logs) existem, mas **não há controllers/rotas** consumindo
  payments/refunds/payouts/notifications.

---

## 6. Views Flutter — O QUE ERA ESPERADO (`docs/flutter/docs/03-screens.md`)

Toda tela operacional deve prever: **loading, conteúdo, vazio, erro, offline,
sincronizando, sucesso.**

### 6.1 Comércio — MVP (15 telas)
1. Splash/Bootstrap
2. Login
3. Cadastro
4. Dashboard
5. Perfil/estabelecimento
6. Criar entrega
7. Seleção de itens
8. Destino no mapa
9. Definição de preço
10. Revisão/pagamento
11. Ofertas e contrapropostas
12. Detalhes da entrega
13. Rastreamento
14. Histórico
15. Detalhes de cancelamento/devolução

### 6.2 Motoboy — MVP (16 telas)
1. Splash/Bootstrap
2. Login/cadastro
3. Status online/offline
4. Perfil
5. Documentos
6. Veículo/capacidade
7. Lista de ofertas
8. Detalhes da oferta
9. Contraproposta
10. Minhas entregas
11. Mapa/rota
12. Coleta
13. Destino
14. Prova de entrega
15. Falha/devolução
16. Histórico
17. Ganhos

### 6.3 Fluxo nominal (comércio)
`Login → Dashboard → Nova entrega → Origem/Destino → Itens → Preço → Revisão →
Pagamento → Oferta publicada → Ofertas/contrapropostas → Entrega em andamento → Conclusão`

### 6.4 Fluxo nominal (motoboy)
`Login → Disponibilidade → Ofertas próximas → Detalhes → Aceitar ou contrapropor →
Minhas entregas → Coleta → Rota → Destino → Prova de entrega → Conclusão`

---

## 7. Views Flutter — O QUE JÁ FOI IMPLEMENTADO

### 7.1 Telas existentes (`flutter/lib/`)
| Tela | Arquivo | Status |
|---|---|---|
| Splash (restaura sessão + navega por papel) | `features/auth/presentation/screens/splash_screen.dart` | ✅ |
| Login (email/telefone + senha, validação, erro, loading) | `features/auth/presentation/screens/login_screen.dart` | ✅ |
| Cadastro (business e driver, campos por papel) | `features/auth/presentation/screens/register_screen.dart` | ✅ |
| Dashboard de Entregas (app-layer wrapper) | `app/pages/delivery_dashboard_screen.dart` | ✅ |
| Feed de entregas (cards, banner offline, retry) | `features/delivery/presentation/screens/delivery_feed_screen.dart` | ✅ |
| Detalhe da entrega — **motoboy** (máquina de estados: cheguei na coleta, coleta, cheguei ao destino, entrega com prova, falha, devolução) | `features/delivery/presentation/screens/delivery_detail_screen.dart` | ✅ |
| Dashboard **comércio** — "Minhas entregas", FAB "Nova entrega", perfil/logout | `features/business/presentation/screens/business_dashboard_screen.dart` | ✅ |
| Criar entrega — origem/destino com coordenadas, destinatário, itens, pricing CALCULATED/MANUAL, prazo | `features/business/presentation/screens/create_delivery_screen.dart` | ✅ |
| Detalhe **comércio** — ofertas recebidas, publicar, cancelar (motivos), confirmar devolução | `features/business/presentation/screens/business_delivery_detail_screen.dart` | ✅ |
| Dashboard **motoboy** — abas Ativas/Histórico | `features/driver/presentation/screens/driver_dashboard_screen.dart` | ✅ |
| **Painel Administrativo** (`admin`) — shell responsivo (NavigationRail/Drawer) com 5 módulos: Visão Geral (métricas), Aprovação de Motoboys (modal de documentos + aprovar/rejeitar), Gestão de Entregas (busca/filtros + atribuir/cancelar), Financeiro & Reembolsos (pagamentos/reembolsos/repasses + novo reembolso) e Logs de Auditoria | `features/admin/presentation/screens/admin_dashboard_screen.dart` + módulos | ✅ |
| Perfil — identidade/papéis, editar nome/email/telefone/senha (`PATCH /me`) | `features/profile/presentation/screens/profile_screen.dart` | ✅ |
| Rastreamento — GPS + mapa, offline-first na SyncQueue | `features/tracking/presentation/screens/tracking_screen.dart` | ✅ |
| Widgets: `DeliveryCard`, `ProofOfDeliveryModal` (assinatura/foto), `SignaturePad`, `DeliveryMap` | `.../widgets/*.dart` | ✅ |

### 7.2 Camadas e infraestrutura do Flutter
- **Core**: DTOs (`core/models`), HTTP centralizado Dio + interceptors (auth Bearer,
  idempotência `X-Idempotency-Key`, erro tipado 401/403/409/422/429/5xx), Hive local
  (`deliveries_cache`, `sync_queue`, `app_meta`), SyncQueue durável com backoff e máx.
  tentativas, SyncWorker/SyncService, `LocationService` (geolocator) e `DeliveryMap`
  (flutter_map/OSM), token em secure storage.
- **Auth**: `AuthCubit` (unauthenticated/authenticating/authenticated/error),
  `AuthRepositoryImpl` (restore via `/me`, logout, 401 global → login).
- **Delivery**: `DeliveryListCubit`/`DeliveryDetailCubit` com estados
  `Loading|Local|Syncing|Synced|Failure`; use cases; repositório offline-first
  (aceite exige rede; transições offline aplicam localmente + enfileiram sync).
- **Business**: `BusinessDeliveryCubit` (create/publish/cancel/confirm-return).
- **Tracking**: `TrackingCubit` conecta GPS → SyncQueue (`entity_type=LOCATION`).
- **Profile**: `ProfileCubit` (`me`/`updateProfile`).
- **Bootstrap/rotas**: `AppBootstrap.create()` (composition root), `App` com
  `MultiBlocProvider` + `MaterialApp`, rotas nomeadas + parametrizadas
  (`/deliveries/:id`, `/business/deliveries/:id`, `/deliveries/:id/tracking`),
  guard de sessão (perda de auth → Login), tema Material 3.

---

## 8. Views Flutter — LACUNAS em relação às telas esperadas

### 8.1 Comércio
| Tela esperada | Situação |
|---|---|
| Splash/Bootstrap, Login, Cadastro, Dashboard | ✅ implementadas |
| Perfil/estabelecimento | ⚠️ parcial — perfil do usuário feito; dados de estabelecimento dependem de `GET /business/me` (não existe no backend) |
| Criar entrega | ✅ (itens/preço/destino **inline** em uma única tela) |
| Seleção de itens (tela dedicada) | ❌ (fluxo simplificado dentro de Criar entrega) |
| Destino no mapa (tela dedicada) | ❌ (coordenadas digitadas; mapa só no rastreamento) |
| Definição de preço (tela dedicada) | ❌ (seletor CALCULATED/MANUAL inline; quote não é consultado) |
| Revisão/pagamento | ❌ — **bloqueado**: backend financeiro não existe |
| Ofertas e contrapropostas | ❌ — **bloqueado**: backend de counter-offers não existe; comércio vê ofertas recebidas no detalhe |
| Detalhes da entrega | ✅ |
| Rastreamento | ✅ (mapa do motoboy; comércio sem consumo de `GET /deliveries/{id}/tracking`) |
| Histórico (comércio) | ⚠️ parcial — dashboard lista entregas sem filtro/tab dedicada |
| Detalhes de cancelamento/devolução | ⚠️ parcial — cancelar (motivos) + confirmar devolução no detalhe; sem fluxo visual de devolução no comércio |

### 8.2 Motoboy
| Tela esperada | Situação |
|---|---|
| Splash/Bootstrap, Login/cadastro, Perfil, Minhas entregas, Mapa/rota, Coleta, Destino, Prova de entrega, Falha/devolução, Histórico | ✅ implementadas |
| Status online/offline | ❌ — **bloqueado**: `POST /driver/availability` não existe |
| Documentos | ❌ — **bloqueado**: `GET/POST /driver/documents` não existem |
| Veículo/capacidade | ❌ — **bloqueado**: `GET/POST /driver/vehicles`, `GET/PUT /driver/preferences` não existem |
| Lista de ofertas | ❌ — **bloqueado**: `GET /driver/offers` não existe (feed usa `GET /deliveries` por papel) |
| Detalhes da oferta | ❌ (depende de `GET /driver/offers`) |
| Contraproposta | ❌ — **bloqueado**: endpoints de counter-offers não existem |
| Ganhos | ❌ — **bloqueado**: `GET /driver/payouts` não existe |

> **Regra MVP (offline):** o comércio NÃO deve criar oferta de marketplace offline;
> o motoboy opera offline nas entregas já atribuídas. Isso está respeitado.

### 8.3 Admin
| Tela esperada | Situação |
|---|---|
| Painel Administrativo (app móvel/web) | ✅ **implementado em 2026-08-18** — `AdminDashboardScreen` (shell com NavigationRail/Drawer + 5 módulos com Cubits próprios); admin NÃO cai no feed genérico |
| Gestão completa (aprovação de motoboys, financeiro, auditoria) | ✅ **implementada em 2026-08-18** — backend `/admin/*` completo e telas Flutter para cada módulo (dados do backend) |

---

## 9. Divergências conhecidas e decisões documentadas

| # | Divergência | Detalhe |
|---|---|---|
| 1 | **Sync contract** | OpenAPI define `POST /sync/batch` (`entity_type`/`operation_type`/`client_created_at`); o backend real serve `POST /sync` (`entity`/`operation`/`created_at`, header `X-Device-Id`). **O Flutter segue o backend real** (autoridade). |
| 2 | **`POST /auth/logout`** | ✅ **Resolvido em 2026-08-18**: rota registrada em `routes/api.php` (protegida por `auth:sanctum`), revoga o token Sanctum atual e responde `{"data":{"message":"Successfully logged out"}}` 200. Coberto por `tests/Feature/Api/V1/AuthLogoutTest.php`. |
| 3 | **Aceite e estados** | Backend: aceite → `ASSIGNED` (e `ASSIGNED → DRIVER_ACCEPTED` exige confirmação). OpenAPI/Flutter wire value: `DRIVER_ACCEPTED` direto. A máquina de estados cobre os dois; os testes backend validam o caminho `ASSIGNED`. |
| 4 | **Idempotency-Key** | Contrato usa `Idempotency-Key`; middleware Laravel lê `X-Idempotency-Key` (aceita também `idempotency_key` no body). O cliente envia `X-Idempotency-Key`. |
| 5 | **`GET /driver/offers`** | Documentado no contrato, inexistente no backend Stage 4; o feed usa `GET /deliveries`. |
| 6 | **Monetário** | Sempre String + currency (`"25.00"`/`BRL`) nas duas pontas; `double` só para exibição formatada. |
| 7 | **Estados de UI de sync** | `local | sincronizando | sincronizado | falha de sync`; a UI diferencia "salvo localmente" de "confirmado pelo servidor". |
| 8 | **Localização** | `POST /driver/location` não existe como rota direta; o rastreamento é offline-first via SyncQueue (`entity_type=LOCATION`) → `POST /sync`. |

---

## 10. Estado dos testes (verificação executada)

### Flutter (`cd flutter`)
- `flutter analyze` → **No issues found!**
- `flutter test` → **263 testes passando.**
  - Cobertura: DTOs, interceptors/error_mapper, sync queue/worker, storage, auth
    (repository/cubit/screens), delivery (repository/cubits/screens/modal),
    business (dashboard/create cubit), driver (dashboard), tracking (cubit/map),
    profile, routes/bootstrap, widget smoke test, **feature admin completa**
    (repository/mappers, 5 Cubits, dashboard shell, fluxo de sessão admin e
    guardas anti-loading no Splash/Login).
- Executado em 2026-08-18.

### Backend (`cd laravel`)
- Suítes de Feature (`tests/Feature/Api/V1/`): **`DeliveryTest` (12)** +
  **`AuthLogoutTest` (4)** + **`AdminTest` (18: 403 para driver/business em
  todas as rotas `/admin/*`, métricas, aprovar/rejeitar/suspender motoboy,
  filtros de entregas, atribuir/cancelar, pagamentos, reembolsos, repasses,
  auditoria)**.
- Unit: `DeliveryStateMachineTest` (13 casos) + `DomainEnumsAndModelsTest`.
- **Re-execução em 2026-08-18 via Docker (`docker compose exec app php artisan
  test` com MySQL 8.4): 49 testes passando (207 assertions).**

---

## 11. Estrutura atual (resumo)

```text
delivery-platform/
├── IMPLEMENTATION-STATUS.md          ← este arquivo (raiz, para leitura de IA/agente)
├── docs/                             # fonte de verdade canônica (product/domain/api/decisions)
│   ├── docs/                         # domínio, data-model, api, business-rules, decisions, openapi
│   ├── flutter/                      # specs técnicas Flutter (docs/ + rules/.mdc)
│   └── laravel/                      # specs técnicas Laravel (docs/ + rules/.mdc)
├── laravel/                          # backend (Stage 4+)
│   ├── app/{Domain,DTOs,Http,Models,Policies,Providers,Rules}
│   ├── database/migrations/          # 36+ migrations
│   ├── routes/api.php                # auth + me + deliveries + sync
│   └── tests/                        # DeliveryTest (12) + unit state machine
└── flutter/                          # app (Prompts 1–8 + extensões)
    ├── lib/{app,core,features}       # bootstrap/rotas/tema + infra + features
    ├── test/                         # 244 testes
    └── pubspec.yaml                  # flutter_bloc, dio, hive, secure_storage, uuid, intl,
                                      # image_picker, geolocator, flutter_map, latlong2
```

---

## 12. Próximos passos recomendados (em ordem de dependência)

1. **Backend — correção rápida:** registrar `POST /auth/logout` em `routes/api.php`.
2. **Backend — oferecer filtros/consultas:** `GET /deliveries/{id}/events`,
   `GET /deliveries/{id}/tracking`, filtros em `GET /deliveries` (business).
3. **Backend — feature Negotiation:** `GET /driver/offers`,
   counter-offers (criar/listar/aceitar/rejeitar) com janela de aceite e encerramento
   de propostas concorrentes; depois habilitar UI de ofertas/contrapropostas.
4. **Backend — feature Driver profile:** `/driver/me`, `/driver/documents`,
   `/driver/vehicles`, `/driver/preferences`, `POST /driver/availability`;
   depois telas de Documentos, Veículo/capacidade e Status online/offline.
5. **Backend — feature Financeiro:** quote, payment, webhooks, refund, payouts;
   depois telas de Revisão/pagamento e Ganhos.
6. **Backend — Notificações:** `/devices`, `/notifications`; depois provider FCM
   no Flutter (`core/notifications`) com deduplicação e navegação para estado
   sincronizado.
7. **Admin:** grupo `/admin/*` + tela administrativa (fora do escopo mobile MVP?).
8. **Flutter — testes E2E/integration** contra o Laravel rodando localmente
   (login → criar → publicar → aceite → coleta → entrega → sync offline/online).
9. **ADR pendente:** definir versões mínimas de Android/iOS antes do primeiro release.

---

*Fim do documento. Revisar quando o backend evoluir para além do Stage 4 ou quando
novas telas forem adicionadas.*






