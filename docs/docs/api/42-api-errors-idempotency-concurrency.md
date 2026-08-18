# 42 — Erros, Idempotência e Concorrência

## Conflitos

Use HTTP 409 para conflitos de estado.

```json
{
  "error": {
    "code":"DELIVERY_ALREADY_ASSIGNED",
    "message":"A entrega já foi atribuída a outro motoboy.",
    "request_id":"..."
  }
}
```

## Idempotency-Key

Obrigatória em comandos com efeito potencialmente duplicável:
- aceitar entrega;
- aceitar contraproposta;
- confirmar coleta;
- concluir entrega;
- iniciar/confirmar devolução;
- pagamento;
- refund;
- operações de sync.

A mesma chave com payload diferente deve retornar `IDEMPOTENCY_CONFLICT`.

## Concorrência

Usar conforme necessidade:
- transação;
- row-level lock;
- unique constraint;
- version check;
- idempotência.

Casos críticos:
- um vencedor por entrega;
- uma contraproposta vencedora;
- conclusão única;
- captura financeira única;
- refund limitado;
- sync sem duplicação.
