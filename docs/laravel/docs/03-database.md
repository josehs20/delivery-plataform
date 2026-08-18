# Laravel — 03. Banco de Dados

## Banco principal

MySQL.

## Requisitos

- Integridade referencial.
- Índices nos campos de busca operacional.
- Unique constraints para identificadores de negócio que realmente sejam únicos.
- Foreign keys apropriadas.
- Timestamps consistentes.
- Soft delete somente quando fizer sentido jurídico/operacional; não utilizar indiscriminadamente.
- Migrações reversíveis sempre que razoável.

## Tabelas conceituais

```text
users
businesses
business_users
drivers
driver_documents
vehicles
driver_capabilities
driver_service_preferences
deliveries
delivery_items
delivery_addresses
offers
counter_offers
delivery_status_histories
payments
refunds
commissions
payouts
driver_locations
proof_of_deliveries
delivery_failures
delivery_returns
notifications
sync_events
audit_logs
configurations
```

## Índices importantes

Considerar índices para:

- deliveries.status
- deliveries.business_id
- deliveries.driver_id
- deliveries.created_at
- offers.delivery_id/status
- counter_offers.delivery_id/status
- driver_locations.driver_id/recorded_at
- payments.delivery_id/status
- notifications.user_id/read_at
- sync_events.external_event_id/status

Para busca geográfica, usar mecanismo espacial apropriado se adotado pelo provedor de banco/extensão (por exemplo MySQL Spatial). A escolha deve ser documentada como ADR antes da implementação.

## Concorrência

Atribuição de entrega e operações financeiras devem usar transação e locking/constraints adequados. Nunca depender somente de consulta seguida de update sem proteção.

## Auditoria

Históricos operacionais importantes devem ser append-only sempre que possível. Correções administrativas devem gerar novo evento em vez de apagar o histórico original.
