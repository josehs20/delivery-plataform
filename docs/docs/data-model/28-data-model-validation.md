# 28 — Validação do Modelo de Dados

## Checklist antes das migrations

### Delivery

- [ ] estado inicial definido
- [ ] estados terminais definidos
- [ ] uma única atribuição ativa
- [ ] histórico de atribuições preservado
- [ ] preço final preservado
- [ ] destino preservado

### Offers e CounterOffers

- [ ] período de oferta configurável
- [ ] encerramento correto
- [ ] primeira aceitação vencedora respeitando concorrência
- [ ] contrapropostas encadeadas
- [ ] uma única vencedora
- [ ] propostas não vencedoras encerradas

### Multiple deliveries

- [ ] motorista pode possuir várias entregas
- [ ] limite configurável
- [ ] MVP não possui otimização automática
- [ ] futuras regras de rota não quebram o modelo

### Finance

- [ ] autorização/captura ainda deve ser alinhada ao PSP
- [ ] comissão parametrizável
- [ ] snapshot financeiro
- [ ] estorno auditável
- [ ] payout idempotente

### Location

- [ ] provedor escolhido através de abstração
- [ ] estratégia geoespacial aprovada
- [ ] frequência de tracking configurável
- [ ] retenção definida antes de produção
- [ ] privacidade documentada

### Offline

- [ ] operações offline permitidas claramente definidas
- [ ] operation_id idempotente
- [ ] retry/backoff
- [ ] conflitos tratados
- [ ] fotos sincronizáveis

## Pendências que não bloqueiam o modelo conceitual

- PSP definitivo;
- provedor de mapas definitivo;
- frequência exata do GPS;
- valores comerciais;
- timeouts operacionais;
- raio inicial de despacho.

Essas configurações devem ficar fora de migrations hardcoded sempre que possível.
