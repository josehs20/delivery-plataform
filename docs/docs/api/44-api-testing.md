# 44 — Testes do Contrato da API

## Cobertura mínima

### Auth
- sucesso;
- falha;
- bloqueio;
- expiração;
- recuperação.

### Delivery
- criação;
- publicação;
- edição permitida/proibida;
- cancelamento;
- transições inválidas.

### Offers
- elegibilidade;
- aceite;
- concorrência;
- contraproposta;
- rejeição;
- reoferta;
- aceite de contraproposta.

### Execução
- chegada;
- coleta;
- destino;
- prova;
- conclusão;
- falha;
- devolução.

### Financeiro
- cotação;
- pagamento;
- webhook;
- webhook duplicado;
- refund;
- comissão;
- payout.

### Offline
- lote;
- duplicação;
- conflito;
- retry;
- processamento parcial.

### Segurança
- isolamento entre comércios;
- isolamento entre motoristas;
- privilégios administrativos;
- IDOR;
- rate limit.

### Concorrência

Duas requisições simultâneas para aceitar a mesma entrega devem produzir exatamente um vencedor.
