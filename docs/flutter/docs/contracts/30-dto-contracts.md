# DTOs Flutter

O Flutter deve possuir modelos de transporte separados dos modelos de domínio e das entidades locais.

## Principais

- AuthResponse
- BusinessDto
- DriverDto
- DeliveryDto
- DeliveryItemDto
- OfferDto
- CounterOfferDto
- PaymentDto
- TrackingPointDto
- NotificationDto
- SyncOperationDto

## Regras

- DTOs devem refletir o contrato OpenAPI.
- Parsing deve tratar campos desconhecidos sem quebrar o app quando possível.
- DTO não deve decidir regras de estado do domínio.
- Conversão DTO ↔ entidade deve ocorrer em mapper/repository apropriado.
