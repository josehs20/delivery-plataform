# 10 — Localização e Rastreamento

## 1. Componentes

Separar quatro conceitos:

1. GPS: obtenção de coordenadas do dispositivo.
2. Mapas: apresentação visual.
3. Routing: cálculo de rota.
4. Tracking: envio e armazenamento de posições.

## 2. Provedor externo

O MVP utilizará uma API externa para simplificar mapas/rotas.

Criar abstrações como:

- MapProviderInterface;
- GeocodingProviderInterface;
- RoutingProviderInterface.

O domínio não deve depender diretamente de um fornecedor.

## 3. Origem e destino

Entregas devem guardar endereço textual e coordenadas.

## 4. Rastreamento do motoboy

O rastreamento contínuo deve ocorrer durante entregas ativas conforme política de privacidade e configuração operacional.

Fora de uma entrega ativa, o sistema não deve depender de rastreamento contínuo no MVP.

## 5. Periodicidade

O intervalo de atualização é uma decisão operacional configurável. O aplicativo deve suportar envio por intervalo de tempo e ser preparado para estratégias adaptativas futuras.

## 6. Offline

Quando sem conectividade:

- capturar localmente;
- armazenar com timestamp;
- marcar como pendente;
- sincronizar posteriormente.

## 7. Privacidade

A localização deve ser coletada apenas para finalidades justificadas pelo serviço e segundo a política de privacidade.

## 8. Mapa offline

O aplicativo do motoboy deve ser preparado para suportar dados de mapa disponíveis offline. O fornecedor e a estratégia final de regiões offline deverão ser definidos na implementação.
