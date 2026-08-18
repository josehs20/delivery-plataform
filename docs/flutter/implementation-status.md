---

## Parcial

- **Offers/counter-offers**: o DTO e o aceite existem; a UI de negociação
  (histórico de contrapropostas, aceitar/rejeitar) depende de endpoints
  `counter-offers` que o backend Stage 4 não implementa.
- **Admin**: a listagem de entregas do backend já cobre `admin` (todas as
  entregas); funcionalidades administrativas dedicadas (aprovar motoboy,
  financeiro, auditoria) dependem de endpoints não implementados.
- **Notificações**: sem SDK de push nem endpoint de registro de token no
  backend — apenas o princípio documentado (navegar para estado sincronizado).
- **Histórico/ganhos do motoboy**: histórico de entregas encerradas funciona
  (aba Histórico); ganhos/payouts dependem de endpoints financeiros do backend.

---

## Pendente

- Feature `negotiation` completa (contrapropostas na UI).
- Feature `payments` (revisão/pagamento do comércio).
- Testes de integração/E2E contra o Laravel em execução local
  (login → criação → oferta → coleta → entrega → sync).

---

## Bloqueado (backend Stage 4 não implementa)

- `GET /api/v1/driver/offers` — lista de ofertas elegíveis para o motoboy.
- `POST /api/v1/driver/availability` — status online/offline.
- Endpoints de counter-offers (`POST /deliveries/{id}/counter-offers`, etc.).
- `POST /api/v1/driver/location` direto (o sync de LOCATION funciona via `/sync`).
- Endpoints administrativos (`/admin/*`), financeiros (`/payments`, `/payouts`,
  `/refunds`) e de notificações.
- `POST /api/v1/sync/batch` conforme OpenAPI (o backend serve `/sync`).

---

## Testes executados

```bash
cd flutter
flutter pub get
flutter analyze     # No issues found!
flutter test        # All tests passed! (244)
```

---

## Comandos utilizados

```bash
cd /home/jose/Documentos/projetos/delivery-platform/flutter
flutter analyze
flutter test
```

---

## Próximos passos

1. Implementar contrapropostas quando o backend expor `counter-offers`.
2. Implementar status online/offline quando `POST /driver/availability` existir.
3. Implementar notificações push (FCM) + registro de token quando houver
   endpoint de dispositivo no backend.
4. Testes E2E/integration com o Laravel rodando (login → entrega → sync).
5. Definir em ADR as versões mínimas de Android/iOS para release.

# Flutter Implementation Status

> **Data**: 2026-08-17
> **Escopo**: Auditoria integral da documentação Flutter, do código em `flutter/`,
> das regras `.mdc` e do contrato real do Laravel — seguida das correções e
> implementações executadas na ordem de dependência.

---

## Implementado

### Core / Infraestrutura
- Clean Architecture orientada a features (`lib/core`, `lib/features`, `lib/app`).
- DTOs em `lib/core/models/` (auth, delivery, offer, counter-offer, sync) com
  parsing tolerante (`json_utils.dart`) e monetário sempre String + currency.
- Cliente HTTP centralizado (`DioApiClient`) com interceptors de autenticação
  (Bearer via secure storage), idempotência (`X-Idempotency-Key`) e
  mapeamento tipado de erros (401/403/409/422/429/5xx/conectividade/timeout).
- Banco local Hive (`deliveries_cache`, `sync_queue`, `app_meta`, `device_id`).
- Fila de sincronização durável (`HiveSyncQueue`): backoff exponencial limitado,
  máx. tentativas, idempotência por `operation_id`, conflitos explícitos.
- **Sincronização corrigida para o contrato real do Laravel**: `POST /api/v1/sync`
  com `{operations: [{id, idempotency_key, entity, operation, payload,
  created_at}]}` e `X-Device-Id` no header; resposta `data.results` tolerada.
  (Antes o cliente enviava `POST /sync/batch` no shape do OpenAPI — o backend
  real não aceita.)
- `onUnauthorized` global: 401 em requisição autenticada desloga e volta ao
  Login (tratamento de sessão expirada/revogada).
- Localização (`core/location`) encapsulada (geolocator) e mapa `DeliveryMap`
  (flutter_map/OSM).

### Autenticação / Sessão
- Login (email/telefone + senha), restauração de sessão (`/me`), refresh e
  logout (repositório + UI).
- **Cadastro (`/register`)** implementado para `business` e `driver` com campos
  específicos conforme o `RegisterRequest` do Laravel.
- **Navegação por papel**: `splash → sessão → auth → role → dashboard correto`
  (`business → /business`, `driver → /driver`, `admin → /deliveries/feed`).
- Perfil (`/profile`): exibe identidade/papéis, edita nome/email/telefone e
  senha via `PATCH /me` (`ProfileCubit`).

### Comércio (`features/business`)
- Dashboard "Minhas entregas" (`GET /deliveries`) com FAB "Nova entrega",
  perfil e logout.
- Criação de entrega (`CreateDeliveryScreen`): origem/destino com coordenadas,
  destinatário, itens (nome/categoria/quantidade/peso/notas), precificação
  CALCULATED/MANUAL e prazo de coleta — `POST /deliveries` (rascunho).
- Detalhe no contexto do comércio (`/business/deliveries/:id`): ofertas
  recebidas, **publicar** (`DRAFT → OPEN`), **cancelar** (motivos do contrato) e
  **confirmar devolução** (`RETURN_IN_PROGRESS → RETURNED`).

### Motoboy (`features/driver` + `features/delivery`)
- Dashboard "Minhas entregas" com abas Ativas/Histórico.
- Detalhe da entrega com a máquina de estados completa: cheguei na coleta,
  confirmar coleta, **cheguei ao destino**, **confirmar entrega** (prova:
  assinatura/foto), **registrar falha** (motivo obrigatório + descrição) e
  **iniciar devolução**; banner "Entrega concluída" para DELIVERED/RETURNED.
- **Rastreamento** (`features/tracking`): `TrackingCubit` conectando o GPS à
  SyncQueue (`entity_type=LOCATION`, offline-first) e tela com `DeliveryMap`
  (permissões/GPS desabilitado tratados explicitamente).

### Testes
- 244 testes passando (`flutter test`) e `flutter analyze` sem issues.
- Cobertura nova: sync contract (`/sync`), `onUnauthorized`, tracking cubit,
  create delivery cubit, register screen, role routes, dashboards (business e
  driver), ações novas do repositório (create/publish/cancel/arrive-destination/
  fail/start-return/confirm-return), perfil (`me`/`updateProfile`).

---

## Corrigido

1. **Motor de sincronização** usava `POST /sync/batch` (shape OpenAPI) — o
   Laravel real serve `POST /sync` com `entity`/`operation`/`created_at` e
   `X-Device-Id`. O cliente agora consome o contrato real (autoridade de aceite
   é o Laravel). Divergência documentada em
   `docs/flutter/docs/08-synchronization.md`.
2. **Feed "Entregas disponíveis"** era apresentado como aplicação completa. O
   backend retorna entregas **por papel** em `GET /deliveries` (comércio: as
   suas; motoboy: as atribuídas; admin: todas). A tela foi integrada aos
   dashboards corretos ("Minhas entregas") e o fluxo de aceite de oferta ficou
   no data layer (bloqueado na UI porque `GET /driver/offers` não existe no
   backend).
3. **Navegação por papel**: Splash/Login redirecionavam todos para
   `/deliveries/feed`. Agora cada papel vai para a área correta.
4. **Detalhe da entrega**: faltavam `arrive-destination`, `fail` e `return/start`;
   `complete` era oferecido a partir de `PICKED_UP` (estado inválido no backend).
5. **Logout/sessão expirada**: havia `logout` no repositório, mas sem ação na
   UI nem tratamento de 401 em sessão.
6. **Cadastro**: data layer existia, tela não.
7. **Perfil**: `PATCH /me` não era consumido.
