# 27 — Preparação para Contratos de API

## Objetivo

Definir o que a camada HTTP precisa representar com base no modelo de dados, sem ainda congelar todos os endpoints.

## Criar entrega

O request deve representar:

```json
{
  "origin": {
    "address": "...",
    "latitude": -20.0,
    "longitude": -40.0
  },
  "destination": {
    "address": "...",
    "latitude": -20.1,
    "longitude": -40.1
  },
  "recipient": {
    "name": "...",
    "phone": "..."
  },
  "items": [
    {
      "name": "...",
      "quantity": 1
    }
  ],
  "pricing": {
    "mode": "CALCULATED"
  },
  "pickup_deadline": "2026-08-15T18:00:00Z"
}
```

O backend deve normalizar, validar e gerar snapshots.

## Aceitação

A aceitação deve receber apenas a intenção do motoboy. O backend determina:
- se a oferta ainda é válida;
- se a entrega ainda está aberta;
- se outro motoboy ganhou;
- valor final;
- atribuição;
- fechamento das ofertas restantes.

## Contraproposta

Request:
- delivery_id;
- amount;
- message opcional;
- idempotency key.

Backend valida:
- negociação aberta;
- motoboy elegível;
- prazo;
- valor válido;
- capacidade operacional mínima exigida pelo domínio.

## Operações críticas

Operações críticas devem suportar idempotência:
- aceitar;
- aceitar contraproposta;
- cancelar;
- confirmar coleta;
- finalizar entrega;
- registrar evento offline;
- capturar pagamento;
- estornar;
- liberar payout.

## Financeiro

Nunca aceitar do frontend como autoridade:
- comissão;
- valor líquido do motoboy;
- estorno final;
- status financeiro definitivo.

Esses valores são calculados/verificados no backend.
