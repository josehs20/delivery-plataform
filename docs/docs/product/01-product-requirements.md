# 01 — Requisitos do Produto

## 1. Visão

A plataforma é um marketplace B2B2C de intermediação de serviços de entrega sob demanda. Ela conecta estabelecimentos comerciais que precisam transportar mercadorias a motoboys disponíveis para executar a entrega.

O produto não é, no MVP, um marketplace de produtos. O objeto comercial da plataforma é o serviço de entrega.

## 2. Problema

Comércios precisam contratar entregas de forma rápida, transparente e rastreável, inclusive em regiões onde a conectividade é limitada. Motoboys precisam encontrar serviços próximos, decidir quais corridas conseguem executar e, quando necessário, negociar o valor.

## 3. Objetivo

Permitir que um comércio publique uma necessidade de entrega, que motoboys próximos recebam essa oportunidade, que um deles aceite ou negocie o valor, execute a coleta e a entrega, registre evidências e receba o repasse após a conclusão.

## 4. Atores

- Comércio: publica e acompanha entregas.
- Motoboy: executa entregas.
- Administrador: opera, supervisiona e intervém no sistema.

## 5. Plataforma

### Backend

- Laravel / PHP.
- MySQL como banco principal.
- Redis para cache, filas e recursos de tempo real quando aplicável.
- APIs REST.
- Eventos e filas assíncronas.
- WebSockets para atualizações em tempo real.
- Storage de documentos e evidências.

### Mobile

- Flutter / Dart.
- Android e iOS.
- Banco local para operação offline.
- GPS.
- Integração com provedor externo de mapas/rotas inicialmente.

## 6. Conceito central

A entidade de negócio principal é `Delivery` (Entrega).

Uma entrega relaciona:

- comércio;
- origem;
- destino;
- destinatário;
- itens;
- precificação;
- ofertas;
- contrapropostas;
- motoboy atribuído;
- estado operacional;
- localização;
- pagamento;
- evidências;
- falhas;
- cancelamento;
- devolução;
- histórico.

## 7. Fluxo principal

```text
Comércio
  ↓
Cria entrega
  ↓
Define preço ou solicita preço calculado
  ↓
Publica serviço
  ↓
Motoboys próximos recebem oferta
  ↓
Aceitação direta OU negociação
  ↓
Motoboy atribuído
  ↓
Vai à coleta
  ↓
Coleta
  ↓
Transporta
  ↓
Entrega
  ↓
Prova de entrega
  ↓
Entrega concluída
  ↓
Liberação financeira
```

## 8. Requisitos funcionais de alto nível

### Comércio

- RF-COM-001 — cadastrar conta.
- RF-COM-002 — autenticar.
- RF-COM-003 — cadastrar estabelecimento.
- RF-COM-004 — cadastrar origem padrão.
- RF-COM-005 — criar entrega.
- RF-COM-006 — selecionar múltiplos itens.
- RF-COM-007 — informar destino com coordenadas.
- RF-COM-008 — escolher preço calculado ou informar preço.
- RF-COM-009 — publicar entrega.
- RF-COM-010 — visualizar ofertas/aceites.
- RF-COM-011 — analisar contrapropostas.
- RF-COM-012 — aceitar contraproposta.
- RF-COM-013 — acompanhar entrega.
- RF-COM-014 — cancelar conforme regras.
- RF-COM-015 — consultar histórico.
- RF-COM-016 — confirmar devolução quando aplicável.

### Motoboy

- RF-MOT-001 — cadastrar conta.
- RF-MOT-002 — enviar documentos.
- RF-MOT-003 — cadastrar veículo.
- RF-MOT-004 — informar capacidade/restrições.
- RF-MOT-005 — ficar disponível/indisponível.
- RF-MOT-006 — receber ofertas de motoboys próximos.
- RF-MOT-007 — aceitar oferta.
- RF-MOT-008 — recusar oferta.
- RF-MOT-009 — enviar contraproposta.
- RF-MOT-010 — receber múltiplas entregas.
- RF-MOT-011 — confirmar chegada à coleta.
- RF-MOT-012 — confirmar coleta.
- RF-MOT-013 — atualizar localização.
- RF-MOT-014 — confirmar chegada ao destino.
- RF-MOT-015 — registrar prova de entrega.
- RF-MOT-016 — concluir entrega.
- RF-MOT-017 — registrar falha.
- RF-MOT-018 — iniciar e concluir devolução quando necessária.
- RF-MOT-019 — cancelar conforme regras.
- RF-MOT-020 — consultar histórico e ganhos.

### Administração

- RF-ADM-001 — autenticar.
- RF-ADM-002 — gerenciar usuários.
- RF-ADM-003 — aprovar motoboys.
- RF-ADM-004 — analisar documentos.
- RF-ADM-005 — consultar entregas.
- RF-ADM-006 — intervir em entregas.
- RF-ADM-007 — atribuir motoboy manualmente.
- RF-ADM-008 — analisar falhas e cancelamentos.
- RF-ADM-009 — acompanhar pagamentos/estornos/repasses.
- RF-ADM-010 — configurar regras do negócio.
- RF-ADM-011 — consultar auditoria.

## 9. Requisitos não funcionais de alto nível

- RNF-001 — regras críticas de negócio devem ser validadas no servidor.
- RNF-002 — operações críticas devem ser idempotentes ou transacionais.
- RNF-003 — aceitação concorrente deve ser protegida contra dupla atribuição.
- RNF-004 — o motoboy deve conseguir executar uma entrega já sincronizada sem internet.
- RNF-005 — dados locais devem sincronizar quando a conectividade retornar.
- RNF-006 — informações pessoais e localização devem possuir controles de segurança e retenção.
- RNF-007 — estados da entrega devem possuir transições válidas e auditáveis.
- RNF-008 — pagamentos devem ser processados de forma segura e rastreável.
- RNF-009 — integrações externas devem ser abstraídas para evitar acoplamento ao fornecedor.

## 10. Princípios do produto

1. O servidor é a autoridade para estados críticos.
2. O preço contratado deve ficar registrado como snapshot.
3. A negociação possui histórico.
4. A entrega possui máquina de estados.
5. O motoboy pode atuar em qualquer região; a proximidade atual influencia a oferta.
6. O motoboy pode possuir múltiplas entregas simultaneamente.
7. O offline é requisito arquitetural do aplicativo do motoboy.
8. Evidências devem acompanhar falhas e conclusões quando exigidas.
9. Funcionalidades fora do MVP não devem contaminar o fluxo principal.

## 11. Fora do escopo do MVP

- marketplace de produtos;
- aplicativo do consumidor final;
- chat completo;
- avaliações;
- cupons;
- fidelidade;
- múltiplos destinos numa mesma entrega;
- otimização avançada de rotas;
- IA para despacho;
- API pública;
- integrações ERP;
- franquias;
- publicidade;
- assinaturas avançadas.

## 12. Critérios gerais de aceite

O produto só pode ser considerado funcional quando for possível realizar, de ponta a ponta:

1. cadastro/aprovação;
2. criação da entrega;
3. seleção de múltiplos itens;
4. definição ou cálculo do preço;
5. publicação;
6. descoberta por motoboys próximos;
7. aceite ou negociação;
8. atribuição concorrente segura;
9. coleta;
10. rastreamento;
11. entrega;
12. prova;
13. conclusão;
14. processamento financeiro;
15. tratamento de cancelamento/falha;
16. devolução quando aplicável;
17. funcionamento offline da execução;
18. sincronização posterior.
