# 35 — Ofertas e Contrapropostas

### `GET /api/v1/driver/offers`

Retorna ofertas elegíveis e vigentes.

O backend filtra por disponibilidade, localização recente, status e regras configuradas.

### `GET /api/v1/deliveries/{id}/offers`

Comércio consulta ofertas relacionadas à sua entrega.

### `POST /api/v1/deliveries/{id}/accept`

Aceita oferta. `Idempotency-Key` obrigatória.

A primeira aceitação válida vence; concorrência é resolvida no servidor.

### `POST /api/v1/deliveries/{id}/counter-offers`

```json
{"amount":"32.50","currency":"BRL","message":"Consigo executar por esse valor."}
```

O motoboy pode fazer nova contraproposta depois de rejeição enquanto a negociação continuar aberta.

### `GET /api/v1/deliveries/{id}/counter-offers`

Retorna histórico conforme autorização.

### `POST /api/v1/counter-offers/{id}/accept`

Aceita proposta do comércio. Transação deve marcar proposta vencedora, encerrar as demais, criar atribuição e congelar o valor.

### `POST /api/v1/counter-offers/{id}/reject`

Rejeita proposta. Negociação pode continuar.
