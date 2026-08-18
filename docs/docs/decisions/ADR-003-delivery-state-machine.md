# ADR-003 — Máquina de estados da entrega

## Status

Accepted

## Decisão

`Delivery` possui máquina de estados explícita e transições controladas.

Nenhum componente cliente poderá alterar o estado livremente.

Estados principais:

DRAFT → OPEN → NEGOTIATING/ASSIGNED → DRIVER_ACCEPTED → GOING_TO_PICKUP → AT_PICKUP → PICKED_UP → IN_TRANSIT → AT_DESTINATION → DELIVERED.

Falha/devolução:

DELIVERY_FAILED → RETURN_REQUIRED → RETURN_IN_PROGRESS → RETURNED → CANCELLED.

## Consequências

- transitions devem ser testadas isoladamente;
- API deve expor comandos sem permitir alteração arbitrária de status;
- histórico deve registrar fatos importantes.
