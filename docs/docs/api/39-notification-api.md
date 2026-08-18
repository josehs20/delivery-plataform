# 39 — Notificações

### `POST /api/v1/devices`
Registra dispositivo/push token.

### `DELETE /api/v1/devices/{id}`
Remove dispositivo.

### `GET /api/v1/notifications`
Lista notificações.

### `POST /api/v1/notifications/{id}/read`
Marca notificação como lida.

### `POST /api/v1/notifications/read-all`
Marca todas como lidas.

## Eventos

- nova oferta;
- contraproposta;
- proposta aceita;
- motorista atribuído;
- chegada à coleta;
- coleta;
- início de rota;
- chegada ao destino;
- entrega;
- falha;
- cancelamento;
- devolução;
- pagamento;
- repasse.

Push/WebSocket são mecanismos de atualização, nunca a fonte de verdade.
