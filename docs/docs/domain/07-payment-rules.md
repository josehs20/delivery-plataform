# 07 — Regras de Pagamento

## 1. Objetivo

Controlar pagamento da entrega, comissão da plataforma, estorno e repasse ao motoboy.

## 2. Separação de conceitos

Não confundir:

- valor da entrega;
- valor da mercadoria transportada;
- comissão da plataforma;
- taxa do gateway;
- valor destinado ao motoboy;
- estorno.

## 3. Fluxo principal

```text
Comércio
  ↓
PSP/Gateway
  ↓
Pagamento autorizado/confirmado
  ↓
Entrega em execução
  ↓
Entrega concluída
  ↓
Aplicação de comissão
  ↓
Valor de repasse
```

O provedor de pagamento específico não está fechado neste documento. A arquitetura deve abstrair o PSP.

## 4. Entidades conceituais

### Payment

Representa uma cobrança relacionada à entrega.

### Refund

Representa um estorno relacionado a um pagamento.

### Commission

Representa a parcela da plataforma.

### Payout

Representa o repasse destinado ao motoboy.

## 5. Regras

- Todo pagamento deve possuir identificador interno e referência externa quando existir.
- Valores devem usar representação monetária segura.
- Não usar ponto flutuante para cálculos financeiros críticos.
- O valor da comissão deve ser persistido como snapshot.
- Alterações posteriores de configuração não devem alterar transações históricas.
- Estornos precisam indicar motivo e origem.
- Repasse não deve acontecer antes das condições definidas para conclusão.

## 6. Cancelamento

Quando uma entrega for cancelada, o sistema deve consultar a política do estado para determinar:

- estorno total;
- estorno parcial;
- nenhuma alteração;
- análise administrativa.

O valor e o status do estorno devem ficar registrados.

## 7. Dinheiro

Pagamento em dinheiro da taxa da plataforma fica fora do fluxo primário do MVP. Caso seja implementado futuramente, deve ser um fluxo distinto do valor da mercadoria.

## 8. Provedor de pagamento

Criar abstração capaz de suportar futuramente diferentes PSPs. Nenhuma tela Flutter deve incorporar regras específicas de um gateway.
