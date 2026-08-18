# Laravel — 05. Autenticação e Sessão

## Estratégia

A autenticação da API deve usar mecanismo apropriado para aplicações mobile e API, como Laravel Sanctum, salvo decisão posterior documentada.

## Requisitos

- Login seguro.
- Logout/invalidação conforme estratégia.
- Recuperação de senha.
- Controle de sessão/dispositivo.
- Rate limiting.
- Não armazenar senha em texto puro.

## Separação por papel

Autenticação identifica o usuário. Autorização determina se ele pode acessar uma operação. Nunca confundir os dois conceitos.

## Dados sensíveis

Tokens, documentos e dados pessoais devem possuir controles de acesso e armazenamento adequados.

## Administrador

A conta administrativa deve possuir camada adicional de proteção, preferencialmente 2FA.
