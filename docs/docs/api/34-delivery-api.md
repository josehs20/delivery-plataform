# 34 — Contrato de Entrega

## Criar — `POST /api/v1/deliveries`

```json
{
  "origin": {
    "address":"Rua de origem, 100",
    "latitude":-20.3155,
    "longitude":-40.3128,
    "reference":"Porta lateral"
  },
  "destination": {
    "address":"Estrada Rural X, s/n",
    "latitude":-20.4200,
    "longitude":-40.5000,
    "reference":"Depois da ponte"
  },
  "recipient": {
    "name":"João da Silva",
    "phone":"27999999999"
  },
  "items":[
    {
      "name":"Caixa de produtos",
      "category":"GENERAL",
      "quantity":2,
      "approximate_weight":5.0,
      "notes":"Manter em posição vertical"
    }
  ],
  "pricing":{"mode":"CALCULATED"},
  "pickup_deadline":"2026-08-16T18:00:00Z"
}
```

Regras:
- origem e destino com coordenadas;
- um ou mais itens;
- preço calculado ou definido pelo comércio;
- novas solicitações offline não são permitidas no MVP.

## Editar — `PUT /api/v1/deliveries/{id}`

Somente em estados editáveis.

## Publicar — `POST /api/v1/deliveries/{id}/publish`

Valida dados, preço e requisito financeiro; publica oferta, altera estado, registra evento e notifica.

## Cancelar — `POST /api/v1/deliveries/{id}/cancel`

```json
{"reason":"NO_LONGER_NEEDED","description":"..."}
```

O backend determina taxa, estorno e necessidade de devolução.

## Execução

`POST /api/v1/deliveries/{id}/accept`

`POST /api/v1/deliveries/{id}/arrive-pickup`

`POST /api/v1/deliveries/{id}/pickup`

`POST /api/v1/deliveries/{id}/arrive-destination`

`POST /api/v1/deliveries/{id}/complete`

`POST /api/v1/deliveries/{id}/fail`

`POST /api/v1/deliveries/{id}/return/start`

`POST /api/v1/deliveries/{id}/return/confirm`

## Regra

Cada comando valida autenticação, autorização, estado, pré-condições, idempotência, concorrência, transação, evento e notificação.
