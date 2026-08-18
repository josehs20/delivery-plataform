# 36 — Contrato Financeiro

### `GET /api/v1/deliveries/{id}/quote`

Retorna preço calculado/sugerido.

```json
{
  "data": {
    "amount":"30.00",
    "currency":"BRL",
    "pricing_mode":"CALCULATED",
    "components":[
      {"type":"BASE","amount":"10.00"},
      {"type":"DISTANCE","amount":"20.00"}
    ]
  }
}
```

### `POST /api/v1/deliveries/{id}/payment`

Inicia/autorização de pagamento conforme PSP.

### `POST /api/v1/payments/webhooks/{provider}`

Recebe eventos do PSP. Validar assinatura, referência e idempotência.

### `GET /api/v1/business/payments`

Consulta pagamentos.

### `GET /api/v1/driver/payouts`

Consulta repasses.

### `GET /api/v1/driver/payouts/{id}`

Detalha repasse.

### `POST /api/v1/deliveries/{id}/refund`

Operação protegida por política financeira.

## Regras

O cliente nunca define comissão, payout, refund final ou status definitivo do pagamento.
