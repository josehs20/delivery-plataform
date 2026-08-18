# 12 — Notificações

## 1. Canais

- Push notification.
- WebSocket/tempo real quando online.
- Outros canais podem ser adicionados futuramente.

## 2. Eventos para comércio

- entrega publicada;
- motoboy atribuído;
- contraproposta recebida;
- contraproposta aceita;
- chegada à coleta;
- coleta concluída;
- início do transporte;
- chegada ao destino;
- entrega concluída;
- falha;
- cancelamento;
- devolução.

## 3. Eventos para motoboy

- nova entrega elegível;
- contraproposta aceita/rejeitada;
- entrega atribuída;
- alteração da entrega;
- entrega cancelada;
- necessidade de devolução;
- eventos administrativos relevantes.

## 4. Regras

- O backend decide quando uma notificação deve existir.
- O app deve tolerar notificações duplicadas.
- A ação iniciada a partir de uma notificação deve validar o estado atual no servidor.
- Push não é fonte de verdade; é apenas mecanismo de comunicação.

## 5. Offline

Quando o dispositivo estiver offline, a aplicação deve atualizar o estado local com base em eventos já recebidos e sincronizar assim que retornar a conectividade.
