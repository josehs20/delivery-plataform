# 38 — Sincronização Offline

## `POST /api/v1/sync/batch`

```json
{
  "device_id":"...",
  "operations":[
    {
      "operation_id":"...",
      "entity_type":"DELIVERY",
      "entity_id":"...",
      "operation_type":"CONFIRM_PICKUP",
      "client_created_at":"2026-08-16T12:10:00Z",
      "client_sequence":42,
      "payload":{}
    }
  ]
}
```

## Resposta

```json
{
  "data":[
    {
      "operation_id":"...",
      "status":"PROCESSED",
      "server_entity_version":11,
      "server_timestamp":"2026-08-16T12:11:02Z"
    }
  ]
}
```

Status:
`PROCESSED`, `ALREADY_PROCESSED`, `CONFLICT`, `RETRY`, `FAILED`.

## Regras

1. `operation_id` único por dispositivo.
2. Retry deve ser idempotente.
3. Servidor revalida autorização e estado.
4. Timestamp do cliente não substitui tempo do servidor.
5. Conflitos são explícitos.
6. Falha em uma operação não bloqueia automaticamente as outras.
7. Upload de evidências possui fluxo seguro próprio.
