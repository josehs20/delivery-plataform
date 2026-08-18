# Backend Contracts

Contratos de aplicação e infraestrutura devem ser definidos por interfaces quando houver necessidade de desacoplamento:

- PaymentProviderInterface
- MapProviderInterface
- RoutingProviderInterface
- GeocodingProviderInterface
- NotificationProviderInterface
- FileStorageInterface

Regras de negócio não devem depender de SDKs de fornecedores diretamente.
