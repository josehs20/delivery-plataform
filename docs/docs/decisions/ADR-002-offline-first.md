# ADR-002 — Offline-first para execução do motoboy

## Status

Accepted

## Contexto

O serviço será utilizado em áreas com baixa ou nenhuma conectividade. O motoboy precisa continuar executando entregas já recebidas.

## Decisão

Adotar abordagem offline-first no aplicativo do motoboy.

O servidor permanece como autoridade. O cliente mantém dados e operações locais em SQLite e sincroniza posteriormente.

No MVP, o comércio não poderá criar novas entregas offline.

## Consequências

- operações locais precisam de IDs idempotentes;
- transições precisam ser revalidadas no servidor;
- evidências precisam de armazenamento local temporário;
- UX deve informar claramente o estado da sincronização.
