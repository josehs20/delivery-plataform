# ADR-006 — Despacho por proximidade geográfica

## Status

Accepted

## Contexto

O motoboy pode trabalhar em qualquer região. A prioridade para receber uma nova entrega é estar próximo da origem.

## Decisão

O despacho utilizará localização recente do motoboy e consulta geoespacial para identificar candidatos.

Critérios mínimos:

- disponibilidade;
- aprovação/bloqueio;
- localização recente;
- distância configurada;
- demais regras operacionais.

A região cadastrada do motoboy não será uma barreira no MVP.

## Evolução futura

O ranking poderá incorporar:

- ETA;
- quantidade de entregas;
- capacidade;
- confiabilidade;
- prioridade;
- otimização de rotas.

Esses critérios não serão implementados automaticamente no MVP.
