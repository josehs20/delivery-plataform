# 23 — Índices e Constraints

## Objetivo

Definir os índices e invariantes persistentes que complementam as regras de domínio.

## Identity

### users
- unique em e-mail normalizado quando presente;
- unique em telefone normalizado quando presente;
- índice em status.

### businesses
- unique em documento fiscal normalizado;
- índice em status.

### business_users
- unique `(business_id, user_id)`;
- índice `(user_id, status)`.

## Driver

### drivers
- unique `user_id`;
- unique documento normalizado;
- índice `(operational_status, online_status)`;
- índice `last_online_at`.

### driver_documents
- índice `(driver_id, verification_status)`;
- índice `expires_at`.

### driver_vehicles
- unique placa normalizada;
- índice `(driver_id, status)`.

### driver_service_preferences
- unique `driver_id`;
- índice `enabled`.

## Delivery

### deliveries
- `(business_id, created_at DESC)`;
- `(status, created_at DESC)`;
- `(current_driver_id, status)` se `current_driver_id` existir;
- `(pickup_deadline, status)`;
- índice geoespacial para origem quando a estratégia estiver aprovada.

### delivery_offers
- `(delivery_id, status)`;
- `(driver_id, status)`;
- `(delivery_id, available_until)`.

### counter_offers
- `(delivery_id, status)`;
- `(driver_id, created_at DESC)`;
- índice/constraint para impedir duas contrapropostas vencedoras.

### delivery_assignments
- índice `(driver_id, status)`;
- índice `(delivery_id, status)`;
- constraint parcial para uma única atribuição ativa por `delivery_id`.

### delivery_events
- `(delivery_id, occurred_at)`;
- `(event_type, occurred_at)`;
- unique parcial `(source, idempotency_key)` quando a chave existir.

### delivery_locations
- `(delivery_id, recorded_at DESC)`;
- `(driver_id, recorded_at DESC)`;
- MySQL Spatial/GiST conforme estratégia aprovada.

## Finance

### payments
- `(delivery_id, status)`;
- unique por `(provider, provider_payment_reference)` quando o gateway garantir unicidade.

### payment_transactions
- unique por `(provider, provider_reference, transaction_type)` quando aplicável.

### refunds
- `(payment_id, status)`.

### commissions
- índice `delivery_id`; constraint conforme regra de comissão final.

### driver_payouts
- `(driver_id, status)`;
- unique/constraint para pagamento final de uma delivery.

## Sync

### sync_operations
- unique `(client_id, operation_id)`;
- `(device_id, status)`;
- `(status, created_at)`.

## Audit

### audit_logs
- `(entity_type, entity_id, occurred_at DESC)`;
- `(actor_type, actor_id, occurred_at DESC)`.
