# ADR-009 — Abstração de fornecedores externos

## Status

Accepted

## Decisão

Mapas/rotas, pagamentos, notificações e storage externo devem ser acessados por interfaces/ports internas.

O domínio não poderá importar SDK de fornecedor diretamente.

## Motivo

Permitir troca de fornecedor, testes com mocks/fakes e evitar dependência estrutural do domínio em um produto externo.
