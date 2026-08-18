# 43 — Segurança da API

## Regras

- autorização em toda leitura/mutação;
- não confiar em IDs para concessão de acesso;
- usar Form Requests/DTOs e allowlist de campos;
- rate limit em login, reset, contrapropostas, localização, uploads, sync e finanças;
- minimizar CPF, documentos, telefone e localização;
- nunca logar senha, bearer token, segredos ou dados de cartão;
- validar assinatura de webhooks;
- restringir CORS;
- mudanças incompatíveis exigem nova versão ou estratégia de compatibilidade.
