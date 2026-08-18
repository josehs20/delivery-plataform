# DOMAIN-DATA-MODEL-CLOSURE

## Status

BASELINE PARA REVISÃO

Este documento marca a transição do domínio conceitual para o modelo relacional. Ainda não significa que migrations estejam autorizadas a ser implementadas em produção.

## O que está fechado

- entidades principais;
- relações principais;
- snapshots históricos;
- controle de atribuição;
- ofertas e contrapropostas;
- eventos;
- evidências;
- devoluções;
- pagamentos, refunds, comissões e payouts;
- sincronização;
- auditoria;
- índices conceituais;
- ordem inicial de migrations.

## O que ainda deve ser decidido antes das migrations finais

1. formato definitivo de PK;
2. MySQL Spatial ou estratégia geográfica alternativa;
3. PSP de pagamento;
4. política de autorização/captura;
5. detalhes de retenção de localização;
6. valores/configurações operacionais.

## Regra

Não criar migrations definitivas de produção antes de revisar `28-data-model-validation.md` e transformar as pendências acima em ADRs aprovados.
