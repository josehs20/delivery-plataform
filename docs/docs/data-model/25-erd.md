# 25 — ERD

## Modelo conceitual

```mermaid
erDiagram
    USERS ||--o{ BUSINESS_USERS : belongs
    BUSINESSES ||--o{ BUSINESS_USERS : has
    BUSINESSES ||--o{ BUSINESS_ADDRESSES : has
    USERS ||--o| DRIVERS : profile
    DRIVERS ||--o{ DRIVER_DOCUMENTS : has
    DRIVERS ||--o{ DRIVER_VEHICLES : has
    DRIVERS ||--|| DRIVER_CAPACITIES : has
    DRIVERS ||--|| DRIVER_SERVICE_PREFERENCES : has
    BUSINESSES ||--o{ DELIVERIES : creates
    DRIVERS o|--o{ DELIVERIES : executes
    DELIVERIES ||--|{ DELIVERY_ITEMS : contains
    DELIVERIES ||--o{ DELIVERY_OFFERS : published
    DELIVERY_OFFERS ||--o{ COUNTER_OFFERS : contains
    DELIVERIES ||--o{ DELIVERY_ASSIGNMENTS : has
    DELIVERIES ||--o{ DELIVERY_EVENTS : emits
    DELIVERIES ||--o{ DELIVERY_LOCATIONS : tracks
    DELIVERIES ||--o{ DELIVERY_EVIDENCES : proves
    DELIVERIES ||--o{ DELIVERY_FAILURES : may_have
    DELIVERIES ||--o{ DELIVERY_CANCELLATIONS : may_have
    DELIVERIES ||--o{ DELIVERY_RETURNS : may_have
    DELIVERIES ||--o{ PAYMENTS : has
    PAYMENTS ||--o{ PAYMENT_TRANSACTIONS : has
    PAYMENTS ||--o{ REFUNDS : may_have
    DELIVERIES ||--o{ COMMISSIONS : generates
    DRIVERS ||--o{ DRIVER_PAYOUTS : receives
    DELIVERIES ||--o{ DRIVER_PAYOUTS : generates
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ AUDIT_LOGS : acts
```

## Observações

### `current_driver_id`

Se mantido em `deliveries`, é uma otimização de leitura. A fonte histórica continua sendo `delivery_assignments`. Alterações devem ocorrer na mesma transação.

### Origem e destino

A origem normalmente nasce do estabelecimento. O destino precisa ser um snapshot imutável da solicitação contratada.

### Geospatial

Avaliar MySQL Spatial para:
- localizar motoboys próximos;
- ordenar por distância;
- armazenar pontos de rastreamento;
- realizar consultas geográficas futuras.
