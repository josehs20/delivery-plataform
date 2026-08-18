# Plataforma de Entregas — Documentação Oficial

Este diretório contém a especificação funcional e de domínio da plataforma de intermediação de serviços de entrega.

## Fonte de verdade

Os documentos deste diretório representam a fonte oficial de verdade do produto. Backend Laravel e aplicativo Flutter devem implementar o comportamento aqui definido sem duplicar ou contradizer regras.

## Ordem recomendada de leitura

1. [01-product-requirements.md](product/01-product-requirements.md)
2. [02-actors-and-permissions.md](product/02-actors-and-permissions.md)
3. [03-use-cases.md](use-cases/03-use-cases.md)
4. [04-business-rules.md](business-rules/04-business-rules.md)
5. [05-delivery-lifecycle.md](domain/05-delivery-lifecycle.md)
6. [06-pricing-and-negotiation.md](domain/06-pricing-and-negotiation.md)
7. [07-payment-rules.md](domain/07-payment-rules.md)
8. [08-cancellation-and-failure.md](domain/08-cancellation-and-failure.md)
9. [09-proof-of-delivery.md](domain/09-proof-of-delivery.md)
10. [10-location-and-tracking.md](domain/10-location-and-tracking.md)
11. [11-offline-and-synchronization.md](domain/11-offline-and-synchronization.md)
12. [12-notifications.md](domain/12-notifications.md)
13. [13-security-and-lgpd.md](product/13-security-and-lgpd.md)
14. [14-mvp-scope.md](product/14-mvp-scope.md)
15. [15-glossary.md](product/15-glossary.md)
16. [decisions.md](decisions/decisions.md)

## Status da documentação

- Estado: especificação inicial consolidada.
- Objetivo: fornecer base estável para arquitetura, banco, API, Flutter e regras `.mdc`.
- Itens ainda não decididos devem permanecer explicitamente marcados como pendentes.
