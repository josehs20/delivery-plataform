# ADR-010 — Múltiplas entregas ativas por motoboy

## Status

Accepted

## Contexto

O produto permite que um motoboy aceite mais de uma entrega.

## Decisão

A relação entre `Driver` e `Delivery` é um-para-muitos no contexto operacional, condicionada às regras de capacidade e disponibilidade.

Cada entrega mantém máquina de estados própria.

No MVP não haverá otimização automática da sequência de entregas.

## Consequências

O rastreamento e a interface devem identificar claramente qual entrega está sendo executada em cada ação.

O domínio deve evitar inferir que uma mudança de uma entrega altera automaticamente as demais.
