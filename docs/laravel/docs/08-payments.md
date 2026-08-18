# Laravel — 08. Pagamentos

## Abstração

Criar interface de provedor: `PaymentProviderInterface`. O domínio não deve conhecer SDK específico.

Operações conceituais:

- authorize/charge;
- capture quando aplicável;
- refund;
- payout;
- webhook handling.

## Entidades

Payment, Refund, Commission e Payout devem possuir ciclo de vida próprio.

## Webhooks

Webhooks devem:

- autenticar assinatura do PSP quando suportado;
- registrar evento bruto de forma segura;
- usar idempotência;
- processar assincronamente quando apropriado;
- ser reprocessáveis;
- nunca confiar somente no cliente mobile para confirmação financeira.

## Financeiro

Registrar snapshot do valor contratado e composição financeira:

```text
gross_amount
platform_fee
gateway_fee
driver_amount
refunded_amount
```

Os nomes finais devem ser definidos conforme o schema do projeto.

## Pendência

PSP ainda não definido. Não acoplar implementação a um fornecedor específico.
