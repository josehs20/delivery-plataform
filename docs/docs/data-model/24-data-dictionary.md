# 24 — Dicionário de Dados

## Identificadores

O projeto deve adotar um único formato de PK para as entidades da aplicação. A escolha concreta deve ser centralizada na documentação de arquitetura Laravel e não variar por tabela sem justificativa.

## Enumerações

### DeliveryStatus

```text
DRAFT
OPEN
NEGOTIATING
ASSIGNED
DRIVER_ACCEPTED
GOING_TO_PICKUP
AT_PICKUP
PICKED_UP
IN_TRANSIT
AT_DESTINATION
DELIVERED
RETURN_REQUIRED
RETURN_IN_PROGRESS
RETURNED
DELIVERY_FAILED
CANCELLED
```

### OfferStatus

```text
PENDING
ACCEPTED
REJECTED
EXPIRED
CANCELLED
```

### CounterOfferStatus

```text
PENDING
ACCEPTED
REJECTED
EXPIRED
CANCELLED
SUPERSEDED
```

### DriverApprovalStatus

```text
PENDING
APPROVED
REJECTED
SUSPENDED
```

### DriverOperationalStatus

```text
AVAILABLE
BUSY
SUSPENDED
OFFLINE
```

### PaymentStatus

```text
PENDING
AUTHORIZED
CAPTURED
FAILED
CANCELLED
REFUNDED
PARTIALLY_REFUNDED
```

### RefundStatus

```text
PENDING
PROCESSING
COMPLETED
FAILED
CANCELLED
```

### SyncOperationStatus

```text
PENDING
PROCESSING
PROCESSED
RETRY
CONFLICT
FAILED
```

## Dinheiro

Nunca calcular dinheiro usando `float` ou `double`.

Todos os valores devem possuir:
- `amount` decimal;
- `currency`;
- contexto de arredondamento documentado.

## Coordenadas

- latitude: -90..90;
- longitude: -180..180;
- preservar precisão suficiente para uso operacional;
- registrar accuracy quando fornecida pelo dispositivo.

## Timestamps

Tudo persistido em UTC.

Conversão para timezone do usuário somente na apresentação.

## JSON

Usar somente quando:
- estrutura é variável;
- é um snapshot histórico;
- é um payload externo;
- metadados não exigem relacionamento/consulta relacional frequente.

Não esconder em JSON atributos que necessitam de FK, constraint ou busca frequente.

## Snapshots

Snapshots preservam valores históricos, incluindo:
- endereço contratado;
- preço final;
- comissão;
- payload externo de gateway.

Snapshots não devem ser alterados silenciosamente pelo cadastro atual.

## IDs de provedores

Nunca usar identificador de gateway/map provider como PK interna. Manter `provider`, `provider_reference` e identificador interno separados.
