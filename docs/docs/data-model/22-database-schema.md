# 22 — Schema do Banco

## Convenções

- tabelas e colunas em `snake_case`;
- PK e FK consistentes;
- `created_at` e `updated_at` nas entidades mutáveis;
- UTC em timestamps;
- `json` apenas para estruturas realmente variáveis ou snapshots/payloads externos;
- índices devem existir para consultas críticas, mas não devem substituir modelagem correta.

## `users`

- `id` — PK
- `name`
- `email` nullable, normalizado e único quando informado
- `phone` nullable, normalizado e único quando informado
- `password_hash`
- `status`
- `email_verified_at`
- `phone_verified_at`
- `last_login_at`
- timestamps
- `deleted_at` conforme política

## `businesses`

- `id` — PK
- `legal_name`
- `trade_name`
- `document_number`
- `status`
- timestamps

## `business_users`

- `id`
- `business_id` FK
- `user_id` FK
- `role`
- `status`
- timestamps

Unique: `(business_id, user_id)`.

## `business_addresses`

- `id`
- `business_id` FK
- `label`
- `postal_code`
- `state`
- `city`
- `district`
- `street`
- `number`
- `complement`
- `reference`
- `latitude` obrigatório
- `longitude` obrigatório
- `is_primary`
- timestamps

A estratégia de geospatial pode utilizar MySQL Spatial, caso aprovada no ADR correspondente.

## `drivers`

- `id`
- `user_id` FK unique
- `national_document`
- `approval_status`
- `operational_status`
- `online_status`
- `last_online_at`
- `approved_at`
- timestamps

## `driver_documents`

- `id`
- `driver_id`
- `document_type`
- `document_number`
- `expires_at`
- `object_key`
- `verification_status`
- `verified_by`
- `verified_at`
- `rejection_reason`
- timestamps

## `driver_vehicles`

- `id`
- `driver_id`
- `vehicle_type`
- `brand`
- `model`
- `year`
- `color`
- `plate`
- `status`
- timestamps

## `driver_capacities`

- `id`
- `driver_id` unique
- `max_weight`
- `max_volumes`
- `notes`
- timestamps

## `driver_service_preferences`

- `id`
- `driver_id` unique
- `accepts_categories` json
- `excluded_categories` json
- `max_distance_km`
- `max_concurrent_deliveries`
- `enabled`
- timestamps

Essas preferências filtram ofertas; não substituem a decisão final do motoboy.

## `deliveries`

Campos centrais:

- `id`
- `business_id`
- `current_driver_id` nullable, somente se a denormalização for mantida
- `status`
- `pricing_mode`
- `currency`
- `suggested_amount`
- `merchant_offered_amount`
- `accepted_amount`
- `pickup_deadline`
- `origin_snapshot` json ou estrutura relacional imutável
- `destination_snapshot` json ou estrutura relacional imutável
- `recipient_name`
- `recipient_phone`
- `recipient_reference`
- `published_at`
- `accepted_at`
- `picked_up_at`
- `delivered_at`
- `cancelled_at`
- timestamps

A origem/destino efetivamente contratados não podem depender de consulta mutável ao cadastro atual.

## `delivery_items`

- `id`
- `delivery_id`
- `name`
- `description`
- `category`
- `quantity`
- `approximate_weight`
- `dimensions` json nullable
- `special_handling`
- `notes`
- timestamps

## `delivery_offers`

- `id`
- `delivery_id`
- `driver_id`
- `status`
- `offered_amount`
- `available_until`
- `sent_at`
- `responded_at`
- timestamps

## `counter_offers`

- `id`
- `delivery_id`
- `driver_id`
- `previous_counter_offer_id` nullable
- `amount`
- `status`
- `message`
- `valid_until`
- `responded_at`
- timestamps

## `delivery_assignments`

- `id`
- `delivery_id`
- `driver_id`
- `source_type`
- `source_reference_id`
- `agreed_amount`
- `status`
- `assigned_at`
- `accepted_at`
- `released_at`
- timestamps

Apenas uma atribuição pode estar ativa para uma entrega.

## `delivery_events`

- `id`
- `delivery_id`
- `event_type`
- `actor_type`
- `actor_id`
- `source`
- `idempotency_key`
- `metadata` json
- `occurred_at`
- timestamps

É append-only pela aplicação normal.

## `delivery_locations`

- `id`
- `delivery_id`
- `driver_id`
- `latitude`
- `longitude`
- `accuracy`
- `speed`
- `heading`
- `recorded_at`
- `received_at`
- `source`

## `delivery_evidences`

- `id`
- `delivery_id`
- `evidence_type`
- `object_key`
- `captured_at`
- `latitude`
- `longitude`
- `captured_by_type`
- `captured_by_id`
- `metadata` json
- timestamps

## `delivery_failures`

- `id`
- `delivery_id`
- `reason`
- `description`
- `reported_by_type`
- `reported_by_id`
- `requires_return`
- `resolution_status`
- timestamps

## `delivery_cancellations`

- `id`
- `delivery_id`
- `cancelled_by_type`
- `cancelled_by_id`
- `reason`
- `description`
- `financial_resolution`
- timestamps

## `delivery_returns`

- `id`
- `delivery_id`
- `initiated_by_type`
- `initiated_by_id`
- `status`
- `returned_at`
- `return_evidence_id`
- `merchant_confirmed_at`
- timestamps

## `payments`

- `id`
- `delivery_id`
- `payer_type`
- `payer_id`
- `provider`
- `provider_payment_reference`
- `amount`
- `currency`
- `status`
- `authorized_at`
- `captured_at`
- `failed_at`
- timestamps

## `payment_transactions`

- `id`
- `payment_id`
- `transaction_type`
- `provider`
- `provider_reference`
- `amount`
- `status`
- `payload_snapshot` json
- `occurred_at`
- timestamps

## `refunds`

- `id`
- `payment_id`
- `amount`
- `reason`
- `provider_reference`
- `status`
- `requested_at`
- `completed_at`
- timestamps

## `commissions`

- `id`
- `delivery_id`
- `commission_type`
- `rate`
- `fixed_amount`
- `calculated_amount`
- `currency`
- `snapshot` json
- timestamps

## `driver_payouts`

- `id`
- `driver_id`
- `delivery_id`
- `gross_amount`
- `platform_fee`
- `other_fees`
- `net_amount`
- `status`
- `available_at`
- `paid_at`
- `provider_reference`
- timestamps

## `notifications`

- `id`
- `user_id`
- `type`
- `title`
- `body`
- `data` json
- `channel`
- `status`
- `sent_at`
- `read_at`
- timestamps

## `sync_operations`

- `id`
- `client_id`
- `device_id`
- `operation_id`
- `entity_type`
- `entity_id`
- `operation_type`
- `payload` json
- `client_created_at`
- `received_at`
- `processed_at`
- `status`
- `retry_count`
- `error_code`
- `error_message`

Unique: `(client_id, operation_id)`.

## `audit_logs`

- `id`
- `actor_type`
- `actor_id`
- `action`
- `entity_type`
- `entity_id`
- `before_snapshot` json
- `after_snapshot` json
- `metadata` json
- `ip_address`
- `user_agent`
- `occurred_at`
- timestamps

Append-only.
