# 18 — Localização e Despacho Geográfico

## 1. Objetivo

Definir como a plataforma identifica motoboys próximos, acompanha a operação e mantém abstração sobre o provedor de mapas/rotas.

## 2. Princípio operacional

O motoboy pode trabalhar em qualquer região. No MVP, a região de cadastro não limita sua atuação.

Para disponibilização de uma entrega, o fator principal é a **proximidade atual do motoboy em relação à origem da entrega**, combinada com disponibilidade e demais critérios operacionais.

## 3. Localizações necessárias

### Origem da entrega

Obrigatória:

- latitude;
- longitude;
- endereço textual.

### Destino

Obrigatório:

- latitude;
- longitude;
- endereço textual.

### Motoboy

Quando disponível:

- latitude;
- longitude;
- timestamp;
- precisão.

## 4. Elegibilidade mínima para receber oferta

Um motoboy deve, no mínimo:

1. estar autenticado;
2. estar habilitado/aprovado;
3. estar disponível;
4. possuir localização recente suficiente;
5. estar dentro da distância de oferta configurada;
6. não estar bloqueado;
7. cumprir eventuais regras de segurança/legalidade configuradas.

A plataforma não deve assumir que o município cadastrado restringe a atuação.

## 5. Distância de oferta

A distância máxima para envio deve ser configurável.

Não hardcode valores de negócio.

Conceitualmente:

```text
pickup_location
      ↓
geospatial query
      ↓
active/recent driver locations
      ↓
eligible drivers
      ↓
rank by proximity
      ↓
offer
```

## 6. Ordenação

No MVP, a distância é o principal fator de ordenação.

A arquitetura deve permitir adicionar posteriormente:

- ETA;
- tipo de veículo;
- capacidade;
- quantidade de entregas ativas;
- confiabilidade;
- pontuação;
- área operacional;
- regras de prioridade.

O MVP não deve implementar um algoritmo complexo de otimização de frota.

## 7. Localização durante a entrega

O rastreamento contínuo será relevante durante a execução da entrega.

Fora de uma entrega ativa, não manter rastreamento contínuo sem justificativa operacional e base legal/documental.

A frequência de envio deve ser configurável e deve considerar:

- bateria;
- dados móveis;
- precisão;
- custo;
- necessidade de acompanhamento.

## 8. Localização offline

O GPS do dispositivo pode continuar fornecendo posição sem internet.

Quando offline:

1. registrar posições relevantes localmente;
2. associar timestamps;
3. armazenar precisão quando disponível;
4. sincronizar posteriormente;
5. respeitar ordenação temporal e idempotência.

## 9. Abstração de fornecedor

Criar abstrações:

- `MapProviderInterface`;
- `RoutingProviderInterface`;
- `GeocodingProviderInterface`.

A regra de negócio nunca deve depender diretamente de classes do fornecedor.

Exemplos de implementação possíveis:

- Google Maps;
- Mapbox;
- fornecedor futuro.

A escolha concreta pode ser definida em infraestrutura sem modificar o domínio.

## 10. Navegação

O aplicativo pode encaminhar o motoboy para navegação externa ou utilizar SDK integrado, conforme decisão técnica do MVP.

A navegação é uma capacidade de infraestrutura/UX e não deve controlar a máquina de estados da entrega sozinha.

## 11. Privacidade

Localização é dado sensível operacionalmente e deve possuir:

- finalidade definida;
- controle de acesso;
- retenção definida;
- trilha de auditoria quando necessário.

## 12. Atualização da localização do comércio

O comércio pode visualizar a última localização conhecida do motoboy durante a entrega.

O frontend deve indicar quando a posição estiver:

- atual;
- atrasada;
- indisponível.

Não apresentar uma posição antiga como se fosse atual.
