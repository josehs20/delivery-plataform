# Laravel — 11. Localização, Rotas e Mapas

## Abstração

Criar interfaces para:

- GeocodingProvider;
- RoutingProvider;
- DistanceProvider, quando necessário.

## Responsabilidades do backend

- validar coordenadas;
- receber posições;
- associar posição a entrega;
- persistir histórico segundo política;
- fornecer posições autorizadas;
- integrar cálculo de rota quando necessário.

## Proximidade

A seleção de motoboys próximos deve ser realizada no backend. Não confiar na lista calculada pelo Flutter.

## Privacidade

Rastreamento deve estar vinculado a uma finalidade operacional e ao período de execução. Evitar rastrear continuamente fora de entregas sem justificativa de negócio.

## Provedor

Fornecedor externo ainda não está congelado. A implementação deve permitir substituição.
