# 30 — Contrato de Autenticação

## Endpoints

### `POST /api/v1/auth/login`

```json
{"identifier":"usuario@example.com","password":"senha"}
```

Retorna usuário, papéis e token.

### `POST /api/v1/auth/logout`

Encerra a sessão atual.

### `POST /api/v1/auth/refresh`

Renova a autenticação segundo a estratégia adotada.

### `POST /api/v1/auth/forgot-password`

Solicita recuperação.

### `POST /api/v1/auth/reset-password`

Redefine senha com token válido.

### `GET /api/v1/me`

Retorna identidade e contexto autorizado.

## Regras

- Rate limit no login e recuperação.
- Tokens nunca aparecem em logs.
- Role nunca é confiada ao cliente.
- Usuário bloqueado não pode executar operações protegidas.
- MFA administrativo deve seguir política de segurança.
