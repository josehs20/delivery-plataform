# Laravel — 07. Transações, Concorrência e Idempotência

## Atribuição de entrega

A aceitação deve ocorrer em uma única operação transacional.

Fluxo conceitual:

```text
BEGIN
  lock delivery
  verify state
  verify no active assignment
  persist driver assignment
  close competing offers
  create status history
  emit domain event/outbox event
COMMIT
```

A implementação exata pode usar `DB::transaction()` e mecanismos de locking/constraints adequados.

## Pagamentos

Uma confirmação externa recebida duas vezes não pode gerar dois pagamentos ou dois repasses. Utilizar identificador externo idempotente e constraint única quando apropriado.

## Sincronização

Cada evento do aplicativo deve possuir um ID único de cliente. O servidor registra processamento desse ID e não reaplica efeitos já confirmados.

## Estados

Toda transição deve validar o estado atual dentro da transação quando houver risco de corrida.

## Outbox

Para eventos críticos que precisam ser publicados após persistência, considerar padrão Outbox. Não publicar mensagem crítica antes do commit do dado que a sustenta.
