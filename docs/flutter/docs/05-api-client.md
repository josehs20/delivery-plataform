# Flutter — 05. Cliente de API

## Requisitos

- cliente HTTP único;
- interceptors/middleware para autenticação;
- timeout configurável;
- retry somente quando seguro;
- tratamento de 401/403/409/422/429/5xx;
- serialização/deserialização tipada;
- correlação de requisição quando aplicável.

## Contratos

Os models de API devem refletir contratos documentados pelo backend, mas não devem espalhar DTOs diretamente por toda a UI.

## Erros

Mapear códigos de erro do backend para erros de domínio/apresentação. Não mostrar stack trace ao usuário.

## Idempotência

Operações críticas que possam ser repetidas pelo dispositivo devem incluir identificador de operação/evento quando o contrato exigir.
