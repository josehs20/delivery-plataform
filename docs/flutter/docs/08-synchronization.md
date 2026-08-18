# Flutter — 08. Motor de Sincronização

## Componentes

- SyncQueue
- SyncWorker
- LocalRepository
- RemoteRepository
- AttachmentUploader
- SyncConflictHandler

## Contrato implementado pelo Laravel (autoridade de aceite)

> O OpenAPI (`/docs/openapi/openapi.yaml`) documenta `POST /sync/batch` com
> `operation_id/entity_type/operation_type/client_created_at`. **O backend real
> (Stage 4) serve `POST /api/v1/sync`** com o shape abaixo e o cliente Flutter
> segue o contrato real (o Laravel é a autoridade de aceite da sincronização).

### Requisição — `POST /api/v1/sync`

Headers:
- `Authorization: Bearer <token>` (obrigatório);
- `X-Device-Id: <device_id>` (identificador estável do dispositivo);
- `X-Idempotency-Key: <uuid>` (gerado automaticamente pelo interceptor).

Corpo:

```json
{
  "operations": [
    {
      "id": "<operation_id>",
      "idempotency_key": "<operation_id>",
      "entity": "delivery",
      "operation": "UPDATE",
      "priority": 5,
      "created_at": "2026-08-16T12:10:00Z",
      "payload": {
        "delivery_id": "...",
        "action": "confirm-pickup",
        "proof": {}
      }
    }
  ]
}
```

- `entity`: `delivery | location | proof | event` (lowercase).
- `operation`: `CREATE | UPDATE | DELETE`. Transições de entrega são enviadas
  como `UPDATE`; a semântica fica em `payload.action`
  (`arrive-pickup | pickup | arrive-destination | complete | fail | return-start`).
- `idempotency_key`: igual ao `operation_id` (estável, reutilizado em retries —
  ADR-005); o servidor deduplica por `(client_id, operation_id)`.

### Resposta

```json
{
  "data": {
    "results": [
      {
        "operation_id": "...",
        "status": "PROCESSED",
        "server_entity_version": 11,
        "server_timestamp": "2026-08-16T12:11:02Z"
      }
    ]
  }
}
```

Status: `PROCESSED | ALREADY_PROCESSED | FAILED` (o parse também tolera
`CONFLICT | RETRY` documentados no OpenAPI).

## Fila

Cada item deve possuir:

- event_id;
- entidade;
- entidade_id;
- operação/tipo;
- payload;
- criado_em;
- tentativas;
- próximo_retry;
- status;
- erro;
- versão de schema.

## Ordem

Respeitar dependências entre eventos quando existirem. Exemplo: não sincronizar
`DELIVERY_COMPLETED` antes de garantir que a criação/atribuição da entrega seja
conhecida pelo servidor ou que o evento traga contexto suficiente.

## Retry

Usar backoff. Não entrar em loop infinito agressivo.

## Duplicidade

O mesmo `event_id` pode ser reenviado sem duplicar o efeito no servidor.

## Anexos

Upload de fotos deve ser retomável e separado do evento quando necessário. O
evento pode ficar em estado aguardando mídia se a regra exigir a evidência antes
da conclusão.

