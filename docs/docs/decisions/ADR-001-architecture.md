# ADR-001 — Arquitetura geral do produto

## Status

Accepted

## Contexto

O produto é uma plataforma de entregas on-demand com dois aplicativos móveis e backend centralizado. Existe necessidade de rastreamento, negociação, pagamento, múltiplas entregas e execução offline do motoboy.

## Decisão

Adotar arquitetura separada por contexto:

- Laravel como backend e autoridade de domínio;
- Flutter para Android/iOS;
- MySQL como banco transacional principal;
- Redis para cache, filas/coordenação e recursos de tempo real conforme necessidade;
- APIs REST;
- WebSockets para atualização em tempo real quando houver conectividade;
- SQLite/local database no Flutter para operação offline;
- abstrações para mapas, pagamentos, notificações e storage.

O domínio não deve ficar acoplado a fornecedores externos.

## Consequências

Positivas:

- separação clara de responsabilidades;
- backend como fonte de verdade;
- possibilidade de trocar fornecedores;
- suporte ao offline;
- escalabilidade independente por componente.

Negativas:

- maior complexidade de sincronização;
- necessidade de contratos de API rigorosos;
- testes de integração mais importantes.
