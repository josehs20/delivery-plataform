# 32 — Plano de Implementação API-First

## Ciclo 1 — Fundação

### Laravel
- instalar/configurar MySQL;
- configurar autenticação;
- rodar migrations;
- criar seed mínimo de roles;
- health check;
- request id;
- tratamento de erros.

### Flutter
- configurar ambientes;
- criar camada de HTTP abstrata;
- armazenamento seguro de sessão;
- cliente de API;
- tratamento de erros do contrato.

## Ciclo 2 — Identidade

- usuários;
- comércio;
- motoboy;
- login;
- autorização.

## Ciclo 3 — Delivery

- criação;
- publicação;
- consulta;
- aceitação;
- contraproposta.

## Ciclo 4 — Execução

- chegada;
- coleta;
- tracking;
- destino;
- prova;
- conclusão;
- falha;
- devolução.

## Ciclo 5 — Offline

- SQLite;
- fila;
- sync/batch;
- idempotência;
- conflitos.

## Ciclo 6 — Financeiro

- cotação;
- pagamento;
- comissão;
- refund;
- payout.

## Regra

Cada ciclo deve possuir testes automatizados e critérios de aceite antes de avançar.
