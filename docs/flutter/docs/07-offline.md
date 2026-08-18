# Flutter — 07. Offline-first

## Operações offline do motoboy

- visualizar entrega já sincronizada;
- registrar chegada;
- confirmar coleta;
- registrar localização;
- registrar chegada ao destino;
- registrar prova de entrega;
- registrar falha;
- iniciar/registrar devolução;
- finalizar quando permitido pelas regras.

## Comércio

No MVP, nova solicitação exige conectividade. Histórico e dados previamente sincronizados continuam acessíveis.

## Regra fundamental

Antes de apresentar sucesso definitivo ao usuário em uma operação offline, persistir o evento localmente. A UI deve diferenciar:

`salvo localmente` de `confirmado pelo servidor`.

## Conectividade

Monitorar estado da rede apenas como sinal auxiliar. Não depender exclusivamente de ping para determinar se uma API está disponível.
