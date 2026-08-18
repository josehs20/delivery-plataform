# Laravel — 02. Domínio e Entidades

## Fonte de verdade

As regras de negócio estão em `/docs/business-rules`, `/docs/domain` e `/docs/use-cases`. Este documento descreve como representá-las no backend.

## Entidades principais

- User
- Business
- BusinessUser
- Driver
- DriverDocument
- Vehicle
- Delivery
- DeliveryItem
- DeliveryAddress
- Offer
- CounterOffer
- DeliveryStatusHistory
- Payment
- Refund
- Commission
- Payout
- DriverLocation
- ProofOfDelivery
- DeliveryFailure
- DeliveryReturn
- Notification
- SyncEvent
- AuditLog

## Agregados sugeridos

### Delivery

Agregado central. Deve controlar transições de estado e referências a ofertas, pagamento, itens e evidências.

### Negotiation

Representada por Offer e CounterOffer, vinculadas a uma Delivery. A aceitação vencedora precisa ser atômica.

### Payment

Agregado financeiro separado do domínio operacional. Nunca usar campos da Delivery como única fonte de verdade financeira.

## Objetos de valor

Quando útil, utilizar objetos de valor ou casts para:

- Money
- Coordinates
- Address
- DeliveryStatus
- PaymentStatus
- OfferStatus
- FailureReason

## Identificadores

IDs internos podem ser UUID/ULID. Definir uma estratégia única para todo o sistema antes das migrations finais. Identificadores públicos não devem expor sequências previsíveis quando isso gerar risco.

## Dinheiro

Nunca usar float para valores monetários. Preferir decimal no banco e Value Objects/inteiros em centavos no domínio, conforme padrão escolhido para o projeto.

## Máquina de estados

Toda mudança de status deve passar por um serviço de transição ou mecanismo equivalente. Não permitir alteração arbitrária de `status` diretamente em controllers ou models sem validação.
