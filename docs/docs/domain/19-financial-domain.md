# 19 — Domínio Financeiro

## 1. Objetivo

Definir os conceitos financeiros necessários para a contratação, cobrança, comissão, estorno e repasse da plataforma.

## 2. Separação conceitual

O sistema deve separar:

```text
Preço/Negociação
      ↓
Obrigação financeira da entrega
      ↓
Pagamento/Reserva
      ↓
Comissão
      ↓
Repasse ao motoboy
```

Não misturar o valor da mercadoria transportada com a taxa do serviço de entrega, salvo quando uma funcionalidade futura explicitamente modelar isso.

## 3. Snapshot financeiro

No momento em que a entrega é contratada, persistir um snapshot contendo, conforme aplicável:

- modo de precificação;
- preço calculado;
- preço ofertado pelo comércio;
- contraproposta vencedora;
- valor contratado;
- comissão da plataforma;
- taxa do PSP conhecida;
- valor líquido previsto do motoboy;
- moeda.

Alterações posteriores nas configurações não podem alterar retroativamente o snapshot da entrega.

## 4. Payment

`Payment` representa a tentativa/obrigação de cobrança da taxa de entrega.

Estados conceituais:

- pending;
- authorized;
- paid;
- failed;
- cancelled;
- refunded;
- partially_refunded, se suportado.

A nomenclatura exata de estados do provedor deve ser mapeada para estados internos estáveis.

## 5. Regra de pagamento

O comércio paga ou autoriza o pagamento antes da execução final, conforme capacidade do PSP escolhido.

A liberação do repasse ao motoboy ocorre após a conclusão da entrega e das validações financeiras aplicáveis.

O domínio não deve depender de um fornecedor específico.

## 6. Commission

A comissão é o valor devido à plataforma.

Pode ser:

- percentual;
- fixa;
- híbrida.

A configuração deve ser administrável, mas o valor aplicado a uma entrega deve ser congelado no snapshot financeiro.

## 7. DriverPayout

Representa o valor a repassar ao motoboy.

Deve preservar:

- valor bruto;
- descontos/taxas aplicáveis;
- valor líquido;
- status;
- referência à entrega;
- referência à transação financeira;
- timestamps.

## 8. Refund

Estorno sempre referencia o pagamento original.

Deve possuir:

- valor;
- motivo;
- status;
- id externo do PSP;
- timestamps;
- ator/responsável, quando aplicável.

## 9. Dinheiro e mercadoria

No MVP, o pagamento da taxa de entrega deve utilizar método eletrônico suportado pela plataforma.

Pagamento em dinheiro da mercadoria, se implementado futuramente, deve ser um fluxo distinto de `Payment` da taxa de entrega.

## 10. Precisão monetária

Não utilizar `float`/`double` para cálculos financeiros.

Utilizar representação decimal/mínima unidade monetária apropriada e garantir arredondamento consistente.

## 11. Idempotência financeira

Os comandos financeiros devem ser idempotentes.

Reprocessar webhook ou comando não pode gerar:

- pagamento duplicado;
- estorno duplicado;
- comissão duplicada;
- repasse duplicado.

## 12. Webhooks do PSP

Webhooks devem:

1. ser autenticados/verificados;
2. possuir id externo único;
3. ser persistidos para auditoria;
4. ser processados de forma idempotente;
5. atualizar o estado interno por uma camada de aplicação;
6. gerar eventos internos quando aplicável.

## 13. Falha de entrega e financeiro

A política financeira de falha/cancelamento depende do estado da entrega e do motivo.

O domínio deve separar:

- decisão operacional;
- decisão financeira;
- processamento efetivo do estorno no PSP.

Isso permite que o sistema registre a decisão mesmo se o PSP estiver temporariamente indisponível.
