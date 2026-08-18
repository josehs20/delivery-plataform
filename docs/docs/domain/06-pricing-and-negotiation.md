# 06 — Precificação e Negociação

## 1. Objetivo

Permitir que a plataforma ofereça preço calculado ou que o comércio publique um valor manual, com possibilidade de contrapropostas quando o período inicial de aceite terminar sem atribuição.

## 2. Modos de preço

### Calculado

O backend calcula um preço sugerido com base nas regras vigentes.

### Manual

O comércio informa diretamente o valor que deseja oferecer.

## 3. Snapshot

A entrega deve preservar:

- método de precificação;
- valor sugerido;
- valor ofertado;
- valor final contratado;
- composição conhecida do cálculo no momento da contratação.

## 4. Oferta

A entidade de oferta deve suportar:

- delivery_id;
- driver_id;
- valor da oferta quando aplicável;
- status;
- created_at;
- responded_at;
- expiration_at.

## 5. Contraproposta

Cada contraproposta representa uma tentativa de negociação.

Campos conceituais:

- id;
- delivery_id;
- driver_id;
- amount;
- status;
- created_at;
- responded_at;
- response_reason opcional.

## 6. Estados de contraproposta

- PENDING;
- ACCEPTED;
- REJECTED;
- EXPIRED;
- CANCELLED.

## 7. Negociação

Uma negociação termina quando:

- uma contraproposta é aceita;
- o comércio cancela;
- o prazo termina;
- um processo administrativo encerra a negociação.

## 8. Concorrência

A aceitação da oferta e a aceitação de uma contraproposta devem ser operações transacionais.

Nunca permitir dois motoboys vencedores.

## 9. Configurações

Manter configuráveis:

- timeout para aceite;
- timeout para negociação;
- raio/distância de oferta;
- valor mínimo;
- quantidade máxima de contrapropostas por janela, se uma regra futura for desejada;
- regras de preço.
