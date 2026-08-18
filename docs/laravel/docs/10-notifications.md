# Laravel — 10. Notificações

## Canais

- Push notification.
- WebSocket.
- E-mail/SMS somente quando futuramente aprovados.

## Eventos mínimos

- nova oferta;
- aceite;
- contraproposta;
- contraproposta aceita/rejeitada;
- chegada à coleta;
- coleta;
- em rota;
- chegada ao destino;
- entrega concluída;
- falha;
- cancelamento;
- devolução;
- pagamento/repasse quando pertinente.

## Regras

Notificação é derivada de evento. Não deve substituir persistência do estado.

Evitar notificações duplicadas quando o mesmo evento for processado novamente.
