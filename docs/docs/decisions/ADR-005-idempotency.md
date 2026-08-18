# ADR-005 — Idempotência de operações críticas

## Status

Accepted

## Contexto

Aplicativos móveis podem repetir requests devido a perda de conectividade ou timeout.

## Decisão

Comandos críticos devem possuir mecanismo de idempotência usando identificador único por operação.

Aplicável especialmente a:

- aceitação;
- contraproposta;
- coleta;
- entrega;
- falha;
- devolução;
- pagamento;
- estorno;
- repasse;
- sincronização offline.

## Consequências

Requests repetidos devem devolver o resultado já processado ou erro de conflito controlado, sem duplicar efeitos.
