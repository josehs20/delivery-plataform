# ADR-004 — Concorrência na atribuição e negociação

## Status

Accepted

## Contexto

Uma entrega pode ser disponibilizada a vários motoboys e mais de um pode tentar aceitar simultaneamente.

## Decisão

A atribuição deve ser decidida transacionalmente no backend.

A garantia de uma única atribuição ativa deve ser reforçada por:

- transação;
- locking apropriado;
- constraints de banco quando aplicável;
- idempotência;
- validação do estado.

A mesma abordagem deve existir para aceite de contraproposta e comandos críticos equivalentes.

## Consequências

O Flutter não pode ser considerado autoridade para saber quem venceu a corrida.
