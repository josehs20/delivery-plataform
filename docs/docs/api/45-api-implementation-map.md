# 45 — Mapa de Implementação Laravel

## Fluxo

```text
Route
  ↓
Controller
  ↓
Form Request / DTO
  ↓
Use Case / Application Service
  ↓
Domain
  ↓
Repository
  ↓
Infrastructure
```

## Exemplo

```text
POST /api/v1/deliveries/{id}/accept
        ↓
AcceptDeliveryController
        ↓
AcceptDeliveryRequest
        ↓
AcceptDeliveryUseCase
        ↓
transaction + concurrency
        ↓
DeliveryAssignment
        ↓
Domain Event
        ↓
Notification Job
```

## Regras

- controllers finos;
- domínio mantém invariantes;
- repositories acessam persistência, não decidem negócio;
- events não substituem transação;
- jobs assíncronos não podem deixar a operação principal inconsistente.
