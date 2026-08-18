# Flutter — 01. Arquitetura

## Objetivo

Definir uma arquitetura Flutter para Android e iOS, orientada a features e preparada para operação offline-first.

## Princípios

- UI não contém regras de negócio críticas.
- API remota não é a única fonte de dados para a tela.
- Repositories abstraem fontes local/remota.
- Operações offline são persistidas localmente antes de confirmação.
- O backend é a autoridade final.
- Features devem ser modularizadas.

## Estrutura sugerida

```text
lib/
├── core/
│   ├── network/
│   ├── storage/
│   ├── auth/
│   ├── errors/
│   ├── location/
│   └── notifications/
├── features/
│   ├── auth/
│   ├── business/
│   ├── driver/
│   ├── delivery/
│   ├── negotiation/
│   ├── tracking/
│   ├── payments/
│   └── profile/
└── app/
```

Cada feature pode seguir:

```text
presentation
domain
data
```

A complexidade de cada feature deve justificar as camadas; evitar boilerplate sem benefício.

## Fonte de estado

Durante online, dados podem ser atualizados por API/WebSocket. Durante offline, a UI deve continuar lendo o estado local.
