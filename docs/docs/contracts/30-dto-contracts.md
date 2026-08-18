# 30 — Contratos de DTOs

## Objetivo

Definir DTOs estáveis entre HTTP, aplicação e domínio. DTOs não são modelos Eloquent e não devem conter persistência.

## Backend — DTOs principais

### CreateDeliveryData

- origin
- destination
- recipient
- items
- pricing
- pickup_deadline

### UpdateDeliveryData

Somente campos editáveis em estados permitidos.

### AcceptDeliveryData

- delivery_id
- idempotency_key

### CreateCounterOfferData

- delivery_id
- amount
- currency
- message

### FailDeliveryData

- delivery_id
- reason
- description
- evidence_ids

### CompleteDeliveryData

- delivery_id
- recipient_name
- evidence_ids
- notes

### LocationPointData

- latitude
- longitude
- accuracy
- speed
- heading
- recorded_at
- client_event_id

### SyncOperationData

- operation_id
- device_id
- entity_type
- entity_id
- operation_type
- client_created_at
- client_sequence
- payload

## Regras

- DTO deve ser imutável após construção quando possível.
- DTO valida formato, não substitui regras do domínio.
- DTO nunca deve aceitar campos administrativos ou financeiros não autorizados.
- Valores monetários devem ser string/decimal no contrato HTTP.
- IDs devem ser UUID válidos.
