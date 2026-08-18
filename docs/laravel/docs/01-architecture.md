# Laravel — 01. Arquitetura

## Objetivo

Definir a arquitetura do backend Laravel responsável por autenticação, domínio de entregas, negociação, pagamentos, localização, notificações, sincronização, auditoria e administração.

## Princípios

- O backend é a autoridade sobre regras de negócio, estados e finanças.
- Controllers devem ser finos e não conter regras de domínio complexas.
- Casos de uso devem ser explícitos e testáveis.
- Domínio deve ser desacoplado de detalhes de infraestrutura quando houver benefício claro.
- Operações críticas devem ser transacionais.
- Eventos externos e jobs devem ser idempotentes quando houver possibilidade de repetição.
- Integrações externas devem ser abstraídas por interfaces.
- Não criar microserviços no MVP sem necessidade operacional comprovada.

## Arquitetura recomendada

Usar uma arquitetura modular dentro de um monólito Laravel:

```text
HTTP/API
  ↓
Controllers
  ↓
Application / Use Cases
  ↓
Domain Services / Policies / State transitions
  ↓
Repositories / Eloquent / Infrastructure
  ↓
MySQL / Redis / Storage / External Providers
```

A separação exata entre Domain, Application e Infrastructure deve ser mantida simples: não criar abstrações vazias apenas por padrão.

## Módulos de domínio sugeridos

- Identity
- Business
- Driver
- Delivery
- Pricing
- Negotiation
- Payment
- Location
- Notification
- Synchronization
- Audit
- Administration

## Estrutura de diretórios sugerida

```text
app/
├── Domain/
│   ├── Delivery/
│   ├── Negotiation/
│   ├── Payment/
│   ├── Driver/
│   ├── Business/
│   └── Shared/
├── Application/
│   ├── Delivery/
│   ├── Negotiation/
│   ├── Payment/
│   └── ...
├── Http/
│   ├── Controllers/Api/
│   ├── Requests/
│   └── Resources/
├── Infrastructure/
│   ├── Payments/
│   ├── Maps/
│   ├── Notifications/
│   └── Persistence/
└── Policies/
```

## Decisão

Laravel permanecerá como monólito modular no MVP, permitindo futura extração de componentes somente quando houver necessidade comprovada.
