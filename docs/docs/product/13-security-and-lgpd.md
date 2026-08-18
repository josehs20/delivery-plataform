# 13 — Segurança e LGPD

## 1. Princípio

A plataforma tratará dados pessoais, documentos, contatos, endereços, localização e dados financeiros. A segurança deve ser parte da arquitetura, não uma etapa posterior.

## 2. Autenticação

Suportar:

- credenciais;
- recuperação de acesso;
- gestão de sessão;
- revogação de sessão quando necessário.

O mecanismo exato de OTP/2FA pode ser adotado posteriormente, com preferência por elevar a proteção da área administrativa.

## 3. Autorização

Toda API deve validar:

- identidade;
- papel;
- ownership do recurso;
- permissões;
- estado da operação.

## 4. Dados sensíveis

Tratar com cuidado especial:

- CPF;
- CNH/documentos;
- telefone;
- endereço;
- localização;
- informações financeiras.

## 5. Localização

Coletar somente o necessário para operação, segurança e auditoria. Definir política de retenção antes da produção.

## 6. Armazenamento de arquivos

Documentos e provas de entrega devem ser armazenados de forma privada, com acesso autorizado e referências não previsíveis.

## 7. API

Aplicar:

- validação de payload;
- autorização;
- rate limiting;
- logs de segurança;
- proteção contra replay quando aplicável;
- idempotência nas operações críticas.

## 8. Financeiro

Nunca confiar no valor calculado pelo cliente. O backend deve recalcular ou validar o valor oficial e consultar a transação do provedor.

## 9. Auditoria

Registrar ações administrativas e operações críticas.

## 10. LGPD

A implementação deverá considerar princípios como:

- finalidade;
- necessidade;
- transparência;
- segurança;
- prevenção;
- prestação de contas.

Também devem ser definidas posteriormente:

- política de privacidade;
- política de retenção;
- fluxo de exclusão/anonimização;
- gestão de consentimentos quando aplicável;
- tratamento de solicitações de titulares.

Este documento não substitui análise jurídica especializada.
