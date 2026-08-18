# Flutter — 09. Localização e Mapas

## Requisitos

- solicitar permissões adequadamente;
- lidar com localização negada;
- distinguir GPS indisponível de internet indisponível;
- registrar coordenadas com timestamp;
- evitar consumo excessivo de bateria;
- rastrear somente quando permitido e necessário.

## Navegação

Integrar com provider externo inicialmente, mas encapsular o fornecedor em uma interface própria.

## Offline

O app deve manter as informações de destino e, quando o fornecedor e a estratégia escolhida suportarem, dados de mapa necessários offline.

## Proximidade

O aplicativo pode mostrar distância localmente, mas a decisão oficial de elegibilidade da oferta é do backend.
