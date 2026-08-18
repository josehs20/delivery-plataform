# Laravel — 04. API REST

## Princípios

- API versionada, por exemplo `/api/v1`.
- JSON consistente.
- Resources para respostas públicas.
- Form Requests para validação de entrada.
- Códigos HTTP semânticos.
- Erros padronizados.
- Paginação para coleções.
- Idempotency-Key em operações onde repetição possa gerar efeitos duplicados.

## Endpoints conceituais

### Autenticação

```text
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password
GET  /api/v1/me
```

### Comércio

```text
GET  /api/v1/business
PATCH /api/v1/business
```

### Motoboy

```text
GET   /api/v1/driver/profile
PATCH /api/v1/driver/profile
POST  /api/v1/driver/documents
POST  /api/v1/driver/availability
```

### Entregas

```text
POST /api/v1/deliveries
GET  /api/v1/deliveries
GET  /api/v1/deliveries/{delivery}
POST /api/v1/deliveries/{delivery}/publish
POST /api/v1/deliveries/{delivery}/cancel
POST /api/v1/deliveries/{delivery}/accept
POST /api/v1/deliveries/{delivery}/counter-offers
POST /api/v1/deliveries/{delivery}/counter-offers/{counterOffer}/accept
POST /api/v1/deliveries/{delivery}/counter-offers/{counterOffer}/reject
POST /api/v1/deliveries/{delivery}/arrive-pickup
POST /api/v1/deliveries/{delivery}/pickup
POST /api/v1/deliveries/{delivery}/arrive-destination
POST /api/v1/deliveries/{delivery}/complete
POST /api/v1/deliveries/{delivery}/fail
POST /api/v1/deliveries/{delivery}/return/confirm
```

### Localização

```text
POST /api/v1/deliveries/{delivery}/locations
```

### Sincronização

```text
POST /api/v1/sync/events
POST /api/v1/sync/attachments
GET  /api/v1/sync/status
```

## Contrato de erro

Usar formato consistente, por exemplo:

```json
{
  "message": "Mensagem legível",
  "code": "DELIVERY_INVALID_TRANSITION",
  "errors": {}
}
```

Nunca retornar stack trace ou detalhes internos em produção.
