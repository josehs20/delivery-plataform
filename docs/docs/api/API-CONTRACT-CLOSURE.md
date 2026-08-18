# API CONTRACT CLOSURE

Versão: 6.0

## Status

BASELINE DEFINIDA PARA REVISÃO E IMPLEMENTAÇÃO.

## Decisões congeladas

- API versionada em `/api/v1`.
- Laravel é fonte de verdade.
- autenticação/autorização no backend.
- Delivery como agregado operacional.
- ofertas e contrapropostas.
- múltiplas entregas por motoboy.
- concorrência para aceitação.
- idempotência.
- tracking.
- sync offline.
- evidências.
- pagamentos.
- estornos.
- notificações.
- administração.

## Pendências parametrizáveis

- PSP definitivo;
- provedor de mapas;
- comissão;
- timeout de oferta;
- timeout de contraproposta;
- distância de elegibilidade;
- frequência de GPS;
- limites de upload;
- retenção de localização.

Esses itens não devem ser hardcoded como regras de negócio.
