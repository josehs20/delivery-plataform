# Delivery Platform — Implementation Package

Este pacote consolida a especificação do produto e os artefatos necessários para iniciar a implementação.

## Camadas

```text
docs/                  Produto, domínio, dados, API e decisões
laravel/               Backend Laravel, migrations e regras Cursor
flutter/               Aplicativo Flutter e regras Cursor
```

## Ordem de leitura

1. `docs/product/`
2. `docs/business-rules/`
3. `docs/domain/`
4. `docs/data-model/`
5. `docs/api/`
6. `docs/openapi/openapi.yaml`
7. `laravel/docs/`
8. `flutter/docs/`
9. `.cursor/rules/` de cada tecnologia
10. `docs/implementation/`

## Implementação

O código incluído é apenas baseline/scaffolding. Regras de negócio ainda devem ser implementadas conforme os documentos e testes.

## Próximos passos no Cursor

1. Criar/confirmar projeto Laravel.
2. Configurar MySQL.
3. Rodar e revisar migrations.
4. Implementar autenticação.
5. Implementar Delivery e máquina de estados.
6. Implementar offers/counter-offers com concorrência.
7. Implementar testes.
8. Configurar Flutter e API client.
9. Implementar armazenamento local e sync.
10. Integrar as funcionalidades por fatias verticais.
