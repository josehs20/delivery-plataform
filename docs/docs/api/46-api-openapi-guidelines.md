# 46 — Diretrizes OpenAPI

## Objetivo

Preparar uma especificação OpenAPI única para Laravel e Flutter.

## Deve declarar

- `/api/v1`;
- security schemes;
- paths;
- parameters;
- requestBodies;
- responses;
- schemas;
- enums;
- errors;
- pagination.

## Regras

1. Cada endpoint possui summary e descrição.
2. Schemas reutilizáveis ficam em `components/schemas`.
3. Erros usam schema comum.
4. Enums refletem os documentos de domínio.
5. Exemplos devem ser válidos.
6. OpenAPI representa o contrato real, não uma API idealizada.
7. Não duplicar regra de negócio em OpenAPI; apenas descrevê-la como constraint de contrato quando necessário.
