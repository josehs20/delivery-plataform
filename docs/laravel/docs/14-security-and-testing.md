# Laravel — 14. Segurança, Observabilidade e Testes

## Segurança

- OWASP como referência.
- validação de entrada;
- autorização por recurso;
- rate limiting;
- proteção de segredos;
- logs sem dados sensíveis desnecessários;
- controle de acesso ao storage;
- assinatura de webhooks;
- proteção contra replay quando aplicável.

## Observabilidade

Registrar:

- request/correlation ID;
- duração;
- erros;
- falhas de jobs;
- eventos de domínio críticos;
- integrações externas.

Nunca registrar tokens, senhas ou dados sensíveis em texto puro nos logs.

## Testes

Cobrir pelo menos:

### Unitários

- cálculo de preço;
- transições de estado;
- permissões;
- regras de cancelamento;
- contrapropostas.

### Feature/API

- criação de entrega;
- publicação;
- concorrência de aceite;
- contraproposta;
- conclusão;
- falha;
- devolução;
- pagamento;
- estorno;
- sync idempotente.

### Integração

- PSP;
- provider de mapas;
- push/websocket;
- storage.

## Critério

Nenhuma regra crítica deve ser considerada implementada sem teste automatizado correspondente.
