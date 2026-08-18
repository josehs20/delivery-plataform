# 21 — Modelo Relacional

## Objetivo

Definir o modelo relacional oficial derivado do domínio fechado. Este documento orienta migrations, Foreign Keys, índices, constraints, repositories e consultas.

## Princípios

1. MySQL é a fonte transacional do backend.
2. A PK deve usar o padrão de identificador adotado pelo projeto de forma consistente.
3. Valores monetários usam `numeric/decimal`, nunca `float/double`.
4. Timestamps são persistidos em UTC.
5. Invariantes críticas devem ser protegidas por transações e, quando possível, pelo banco.
6. Histórico operacional e financeiro é append-oriented; não apagar eventos ou transações.
7. Snapshot é usado quando uma informação precisa permanecer exatamente como era no momento da contratação.

## Contextos principais

### Identity
`users`, `roles`, `permissions`, `role_permissions`, `user_roles`, `user_sessions`.

### Commerce
`businesses`, `business_users`, `business_addresses`.

### Driver
`drivers`, `driver_documents`, `driver_vehicles`, `driver_capacities`, `driver_service_preferences`.

### Delivery
`deliveries`, `delivery_items`, `delivery_offers`, `counter_offers`, `delivery_assignments`, `delivery_events`, `delivery_locations`, `delivery_evidences`, `delivery_failures`, `delivery_cancellations`, `delivery_returns`.

### Finance
`payments`, `payment_transactions`, `refunds`, `commissions`, `driver_payouts`.

### Platform
`notifications`, `sync_operations`, `audit_logs`.

## Agregado principal

`Delivery` é o agregado operacional principal. A alteração do estado da entrega deve passar por uma operação de domínio transacional. Tabelas filhas não devem permitir alterações que quebrem as invariantes do agregado.

## Relações críticas

- Business 1:N Delivery
- Delivery 1:N DeliveryItem
- Delivery 1:N DeliveryOffer
- Delivery 1:N DeliveryEvent
- Delivery 1:N DeliveryLocation
- Delivery 1:N DeliveryEvidence
- Delivery 1:N DeliveryFailure
- Delivery 1:N DeliveryCancellation
- Delivery 1:N DeliveryReturn
- Delivery 1:N Payment
- Driver 1:N DeliveryAssignment
- Driver 1:N DeliveryLocation
- DeliveryOffer 1:N CounterOffer

## Invariantes

1. Uma entrega possui no máximo uma atribuição ativa.
2. Uma entrega não pode ser aceita duas vezes por motoboys diferentes.
3. Uma contraproposta aceita encerra a negociação correspondente.
4. Uma entrega entregue é terminal, exceto fluxo de pós-entrega explicitamente documentado.
5. Uma devolução só pode ser confirmada quando o fluxo de devolução estiver aberto.
6. Um pagamento não pode ser capturado duas vezes pela mesma operação.
7. Um repasse final para uma entrega não pode ser liquidado duas vezes.
8. Um evento com a mesma chave de idempotência não pode ser processado duas vezes.
9. O destino contratado deve ser preservado mesmo se o endereço original do cadastro mudar.
10. O valor financeiro contratado deve ser preservado mesmo se as regras comerciais mudarem depois.
