# 16 — Modelo de Domínio

## 1. Objetivo

Este documento fecha o modelo conceitual do domínio para o MVP da plataforma de intermediação de entregas. Ele define entidades, responsabilidades, relacionamentos e invariantes antes da modelagem física do banco.

## 2. Contexto do domínio

O sistema conecta comércios a motoboys para contratação e execução de serviços de entrega sob demanda. O agregado operacional central é `Delivery`.

Princípios:

- `Delivery` controla o ciclo operacional do serviço.
- O backend Laravel é a autoridade sobre estado, preço contratado e fatos financeiros.
- O histórico de eventos é append-only para fatos de negócio relevantes.
- Propostas e contrapropostas possuem histórico próprio.
- Operações offline são representadas como eventos/commands idempotentes, não como alterações arbitrárias de estado.

## 3. Entidades principais

### 3.1 User

Representa uma identidade autenticável.

Responsabilidades:

- autenticação;
- identificação do ator;
- vínculo com perfis de negócio;
- controle de acesso.

Não deve conter regras específicas de entrega.

### 3.2 Business

Representa o comércio/estabelecimento contratante do serviço.

Relacionamentos principais:

- pertence a um ou mais `User` conforme o modelo de acesso adotado;
- possui endereços;
- cria `Delivery`;
- realiza pagamentos.

### 3.3 BusinessAddress

Representa endereço de origem pertencente a um comércio.

Deve suportar endereço textual e coordenadas geográficas.

### 3.4 Driver

Representa o motoboy operacional.

Responsabilidades:

- disponibilidade;
- aceitação/recusa de ofertas;
- negociação;
- execução da entrega;
- localização;
- evidências;
- devolução;
- consulta de ganhos.

Um `Driver` pode possuir várias `Delivery` ativas simultaneamente.

### 3.5 DriverDocument

Representa documentos do motoboy sujeitos a análise, validade e aprovação.

### 3.6 DriverVehicle

Representa a motocicleta utilizada na operação.

### 3.7 DriverCapacity

Representa limites e preferências operacionais informados pelo motoboy, como peso, volume e tipos de mercadoria.

A capacidade é informativa/operacional no MVP; ela não deve bloquear automaticamente o motoboy de aceitar uma entrega apenas por validação rígida, salvo regra futura explicitamente aprovada.

### 3.8 DriverLocation

Representa uma observação de localização do motoboy.

Deve armazenar, quando disponível:

- latitude;
- longitude;
- timestamp;
- precisão;
- origem da coleta;
- relação com a entrega ativa.

### 3.9 Delivery

Agregado principal do domínio operacional.

Responsabilidades:

- representar a contratação;
- controlar preço contratado;
- controlar origem e destino;
- controlar itens;
- controlar negociação;
- controlar atribuição;
- controlar estado;
- controlar coleta/entrega/devolução;
- referenciar pagamento;
- manter evidências e auditoria.

### 3.10 DeliveryItem

Representa cada item/volume descrito pelo comércio.

Uma entrega possui zero ou muitos itens durante a montagem, mas deve possuir pelo menos um item quando for publicada.

### 3.11 DeliveryAddress

Representa um endereço operacional associado à entrega, como origem ou destino.

O destino deve possuir endereço textual e coordenadas.

### 3.12 DeliveryOffer

Representa a oferta direta apresentada pela plataforma ao conjunto de motoboys elegíveis.

Pode conter:

- valor oferecido;
- janela/timeout;
- status;
- timestamps;
- contexto operacional.

### 3.13 CounterOffer

Representa uma contraproposta enviada por um motoboy.

Cada contraproposta pertence a:

- uma `Delivery`;
- um `Driver`.

A contraproposta possui valor, estado, timestamps e eventual resposta do comércio.

Um mesmo motoboy pode fazer novas contrapropostas enquanto a negociação estiver aberta.

### 3.14 DeliveryAssignment

Representa a atribuição efetiva do motoboy vencedor.

Deve permitir auditoria de:

- quem foi atribuído;
- método da atribuição;
- momento;
- referência à oferta/proposta vencedora;
- motivo de eventual intervenção administrativa.

O domínio deve garantir no máximo uma atribuição operacional ativa por entrega.

### 3.15 DeliveryEvent

Representa fato de domínio relevante.

Exemplos:

- entrega criada;
- publicada;
- negociação iniciada;
- proposta enviada;
- proposta aceita;
- motorista atribuído;
- chegada à coleta;
- coleta;
- início do transporte;
- chegada ao destino;
- entrega concluída;
- falha;
- devolução;
- cancelamento.

Eventos não devem ser usados como substituto do estado atual da entrega; o agregado mantém o estado atual e os eventos preservam o histórico.

### 3.16 DeliveryEvidence

Representa evidência vinculada a uma etapa da entrega.

Pode incluir:

- foto;
- localização;
- observação;
- metadados de captura;
- tipo de evidência.

### 3.17 DeliveryFailure

Representa uma tentativa de entrega que não foi concluída.

Possui motivo padronizado, descrição e evidências conforme a política.

### 3.18 DeliveryCancellation

Representa uma solicitação/decisão de cancelamento.

Deve preservar:

- ator;
- motivo;
- estado da entrega no momento;
- impacto financeiro;
- necessidade de devolução;
- evidências;
- timestamps.

### 3.19 DeliveryReturn

Representa o processo de devolução da mercadoria ao comércio após coleta, quando necessário.

Estados conceituais:

- required;
- in_progress;
- returned;
- confirmed.

### 3.20 Payment

Representa a operação de cobrança associada ao serviço.

Deve distinguir:

- valor contratado;
- valor pago/reservado;
- taxa do provedor;
- comissão da plataforma;
- valor destinado ao motoboy;
- estorno;
- estado financeiro.

### 3.21 Refund

Representa um estorno vinculado a um pagamento original.

### 3.22 Commission

Representa a remuneração da plataforma.

A comissão deve ser persistida como snapshot da contratação.

### 3.23 DriverPayout

Representa a obrigação/repasse devido ao motoboy após o resultado financeiro da entrega.

### 3.24 Notification

Representa uma notificação para um usuário, com canal, conteúdo, estado de entrega e timestamps.

### 3.25 SyncOperation

Representa uma operação originada no cliente para sincronização com o servidor.

Deve possuir identificador idempotente e estado de processamento.

### 3.26 AuditLog

Representa ação administrativa ou de segurança que exige rastreabilidade adicional ao histórico operacional.

## 4. Relacionamentos principais

```text
User
 ├── Business access/profile
 └── Driver access/profile

Business
 ├── BusinessAddress
 └── Delivery

Driver
 ├── DriverDocument
 ├── DriverVehicle
 ├── DriverCapacity
 ├── DriverLocation
 ├── DeliveryAssignment
 └── Delivery

Delivery
 ├── DeliveryAddress (origem/destino)
 ├── DeliveryItem
 ├── DeliveryOffer
 ├── CounterOffer
 ├── DeliveryAssignment
 ├── DeliveryEvent
 ├── DeliveryEvidence
 ├── DeliveryFailure
 ├── DeliveryCancellation
 ├── DeliveryReturn
 └── Payment

Payment
 ├── Refund
 ├── Commission
 └── DriverPayout
```

## 5. Invariantes

### INV-001
Uma entrega não pode possuir duas atribuições operacionais ativas.

### INV-002
Somente uma oferta/contraproposta válida pode vencer a negociação.

### INV-003
Quando uma proposta é aceita, as demais propostas abertas tornam-se sem efeito.

### INV-004
Uma entrega `DELIVERED` não pode retornar para estados operacionais anteriores.

### INV-005
Uma entrega com mercadoria coletada e cancelada deve seguir o fluxo de devolução aplicável.

### INV-006
Valores financeiros oficiais nunca devem ser derivados exclusivamente dos dados recebidos do aplicativo.

### INV-007
Uma sincronização repetida não pode produzir efeitos duplicados.

### INV-008
Uma evidência concluída deve permanecer vinculada à entrega e ao evento/etapa correspondente.

### INV-009
Uma contraproposta pertence a exatamente um motoboy e uma entrega.

### INV-010
Uma entrega publicada precisa possuir origem, destino com coordenadas, ao menos um item e uma definição válida de preço/oferta.

## 6. Agregados

### Aggregate: Delivery

Raiz do agregado:

`Delivery`

Entidades/objetos fortemente dependentes da vida da entrega:

- DeliveryItem;
- DeliveryAddress;
- DeliveryOffer;
- CounterOffer;
- DeliveryAssignment;
- DeliveryEvent;
- DeliveryEvidence;
- DeliveryFailure;
- DeliveryCancellation;
- DeliveryReturn.

### Aggregate: Business

Raiz:

`Business`

Entidades dependentes:

- BusinessAddress.

### Aggregate: Driver

Raiz:

`Driver`

Entidades dependentes:

- DriverDocument;
- DriverVehicle;
- DriverCapacity.

Localização pode ser persistida como série temporal própria, evitando carregar histórico inteiro do agregado Driver.

### Aggregate: Payment

Raiz:

`Payment`

Entidades dependentes:

- Refund;
- Commission;
- DriverPayout.

## 7. Comandos de domínio principais

- CreateDelivery
- PublishDelivery
- OpenNegotiation
- SubmitDriverAcceptance
- SubmitCounterOffer
- RejectCounterOffer
- AcceptOffer
- AcceptCounterOffer
- AssignDriver
- StartPickupTravel
- ArriveAtPickup
- ConfirmPickup
- StartTransit
- ArriveAtDestination
- CompleteDelivery
- RegisterDeliveryFailure
- RequestCancellation
- StartReturn
- ConfirmReturn
- ProcessPayment
- ProcessRefund
- ReleaseDriverPayout
- RecordDriverLocation
- SynchronizeOperation

## 8. Queries principais

- GetDeliveryDetails
- ListBusinessDeliveries
- ListDriverAvailableOffers
- ListDriverActiveDeliveries
- ListDeliveryOffers
- ListCounterOffers
- GetDriverCurrentLocation
- GetDeliveryTracking
- GetPaymentSummary
- GetDriverEarnings
- GetAuditHistory

## 9. O que pertence ao domínio versus infraestrutura

Pertence ao domínio:

- estados;
- transições;
- elegibilidade conceitual;
- negociação;
- preço contratado;
- regras de cancelamento;
- devolução;
- fatos financeiros.

Pertence à infraestrutura:

- provedor de mapas;
- PSP;
- push notification provider;
- storage de objetos;
- WebSocket provider;
- banco de dados;
- mecanismo de filas.

O domínio deve depender de abstrações para essas integrações.
