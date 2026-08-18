# Laravel — 09. Eventos e Filas

## Quando usar eventos

Eventos representam fatos do domínio, por exemplo:

- DeliveryCreated
- DeliveryPublished
- OfferAccepted
- CounterOfferCreated
- DeliveryAssigned
- DriverArrivedAtPickup
- DeliveryPickedUp
- DeliveryCompleted
- DeliveryFailed
- DeliveryCancelled
- ReturnConfirmed
- PaymentConfirmed
- RefundRequested

## Quando usar filas

Filas devem ser usadas para trabalho não crítico ao retorno imediato da API, como:

- envio de notificações;
- processamento de imagens;
- geocodificação assíncrona quando aplicável;
- webhooks;
- sincronização;
- cálculos pesados futuros.

## Retries

Jobs devem possuir retries limitados, backoff e tratamento de falhas. Operações não idempotentes não devem ser reexecutadas cegamente.

## Notificações em tempo real

WebSocket pode transportar eventos de atualização, mas o banco continua sendo a fonte de verdade. O cliente deve conseguir recuperar o estado via API depois de reconectar.
