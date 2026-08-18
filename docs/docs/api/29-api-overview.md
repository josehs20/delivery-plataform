# 29 — Visão Geral do Contrato da API

## Objetivo

Definir a API REST versionada que conecta Laravel aos aplicativos Flutter.

## Base

`/api/v1`

## Headers

```http
Authorization: Bearer <token>
Accept: application/json
Content-Type: application/json
X-Request-Id: <uuid>
Idempotency-Key: <unique-key>
```

`Idempotency-Key` é obrigatória em comandos críticos que podem ser repetidos por retry.

## Datas

Usar ISO-8601 com timezone explícito. Persistência em UTC.

## Dinheiro

Nunca usar float. Utilizar `amount` + `currency`.

```json
{"amount":"32.50","currency":"BRL"}
```

## Sucesso

```json
{"data":{},"meta":{}}
```

## Erro

```json
{
  "error": {
    "code": "DELIVERY_INVALID_STATE",
    "message": "A operação não pode ser realizada no estado atual.",
    "details": {},
    "request_id": "..."
  }
}
```

## Códigos principais

`AUTHENTICATION_ERROR`, `AUTHORIZATION_ERROR`, `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `INVALID_STATE`, `IDEMPOTENCY_CONFLICT`, `RATE_LIMITED`, `PAYMENT_ERROR`, `PROVIDER_ERROR`, `SYNC_CONFLICT`, `INTERNAL_ERROR`.

## Regra fundamental

O cliente nunca é autoridade para preço, pagamento, atribuição ou estado. A resposta do servidor confirma o resultado real.
