# 17 — Máquina de Estados da Entrega

## 1. Objetivo

Definir o ciclo de vida oficial de `Delivery`, incluindo estados, transições, atores, pré-condições, efeitos e exceções.

## 2. Estados

| Estado | Significado |
|---|---|
| DRAFT | Entrega em montagem, ainda não publicada. |
| OPEN | Entrega publicada e aguardando aceite direto. |
| NEGOTIATING | Janela de contrapropostas ativa. |
| ASSIGNED | Motoboy vencedor foi atribuído. |
| DRIVER_ACCEPTED | Aceite efetivado no domínio. |
| GOING_TO_PICKUP | Motoboy iniciou deslocamento para coleta. |
| AT_PICKUP | Motoboy registrou chegada ao local de coleta. |
| PICKED_UP | Mercadoria foi coletada. |
| IN_TRANSIT | Transporte para o destino em andamento. |
| AT_DESTINATION | Motoboy registrou chegada ao destino. |
| DELIVERED | Prova válida registrada e entrega concluída. |
| DELIVERY_FAILED | Tentativa de entrega não foi concluída. |
| RETURN_REQUIRED | É necessária devolução da mercadoria. |
| RETURN_IN_PROGRESS | Devolução está em execução. |
| RETURNED | Comércio confirmou recebimento da devolução. |
| CANCELLED | Entrega encerrada por cancelamento após resolução do fluxo aplicável. |

## 3. Fluxo nominal

```text
DRAFT
  ↓
OPEN
  ├───────────────┐
  │               │
  │              NEGOTIATING
  │               │
  └───────┬───────┘
          ↓
       ASSIGNED
          ↓
    DRIVER_ACCEPTED
          ↓
    GOING_TO_PICKUP
          ↓
       AT_PICKUP
          ↓
       PICKED_UP
          ↓
      IN_TRANSIT
          ↓
    AT_DESTINATION
          ↓
       DELIVERED
```

## 4. Fluxo de falha/devolução

```text
PICKED_UP / IN_TRANSIT / AT_DESTINATION
              ↓
       DELIVERY_FAILED
              ↓
       RETURN_REQUIRED
              ↓
     RETURN_IN_PROGRESS
              ↓
          RETURNED
              ↓
          CANCELLED
```

A necessidade de devolução depende do motivo e da política da ocorrência. Quando a mercadoria já foi coletada, cancelamento não pode ignorar a posse física do item.

## 5. Transições oficiais

### DRAFT → OPEN

Atores: Comércio/Admin.

Pré-condições:

- origem válida;
- destino válido com coordenadas;
- item válido;
- preço/oferta válido;
- demais campos obrigatórios preenchidos.

Efeitos:

- cria evento `DELIVERY_PUBLISHED`;
- inicia processo de descoberta de motoboys.

### OPEN → NEGOTIATING

Ator: Sistema.

Pré-condição:

- timeout de aceite direto expirou;
- nenhuma atribuição foi efetivada.

Efeito: contrapropostas passam a ser aceitas.

### OPEN → ASSIGNED

Atores: Motoboy/Sistema/Admin conforme operação.

Pré-condições:

- oferta ainda válida;
- entrega sem atribuição ativa;
- motoboy elegível;
- concorrência protegida.

### NEGOTIATING → ASSIGNED

Ator: Comércio/Admin.

Pré-condições:

- contraproposta válida;
- negociação aberta;
- pagamento/Reserva financeira compatível com o valor final.

### ASSIGNED → DRIVER_ACCEPTED

Ator: Sistema.

Uso: confirmação explícita do vínculo operacional quando a atribuição e o aceite forem etapas distintas.

### DRIVER_ACCEPTED → GOING_TO_PICKUP

Ator: Motoboy.

Efeito: início da atividade e rastreamento operacional.

### GOING_TO_PICKUP → AT_PICKUP

Ator: Motoboy.

Pré-condição: localização disponível ou registro manual permitido.

### AT_PICKUP → PICKED_UP

Ator: Motoboy.

Pré-condições:

- mercadoria recebida;
- evidência opcional conforme política.

### PICKED_UP → IN_TRANSIT

Ator: Motoboy.

### IN_TRANSIT → AT_DESTINATION

Ator: Motoboy.

### AT_DESTINATION → DELIVERED

Ator: Motoboy/Admin.

Pré-condições:

- prova de entrega válida;
- dados obrigatórios preenchidos;
- validações financeiras/operacionais necessárias concluídas.

### PICKED_UP / IN_TRANSIT / AT_DESTINATION → DELIVERY_FAILED

Ator: Motoboy/Admin.

Pré-condições:

- motivo informado;
- evidências conforme política.

### DELIVERY_FAILED → RETURN_REQUIRED

Ator: Sistema/Regra de negócio.

Quando a mercadoria estiver sob posse do motoboy e for necessária devolução.

### RETURN_REQUIRED → RETURN_IN_PROGRESS

Ator: Motoboy.

### RETURN_IN_PROGRESS → RETURNED

Ator: Comércio/Admin.

Pré-condição: confirmação do recebimento da mercadoria.

### RETURNED → CANCELLED

Ator: Sistema/Admin.

## 6. Cancelamentos sem coleta

Entregas em `OPEN` e `NEGOTIATING` podem ser canceladas diretamente pelo comércio/Admin conforme política.

Após atribuição, regras específicas de cancelamento determinam se:

- há taxa;
- há impacto de reputação;
- é exigida aprovação;
- há necessidade de devolução.

## 7. Regras de imutabilidade

Depois de `DELIVERED`:

- não permitir retorno para estados anteriores;
- alterações administrativas devem criar evento de auditoria;
- comprovantes não devem ser sobrescritos silenciosamente.

Depois de `CANCELLED`:

- não reabrir a mesma entrega no MVP;
- se for necessário novo serviço, criar nova entrega vinculada ao histórico, quando aplicável.

## 8. Idempotência das transições

Cada comando de transição deve aceitar uma chave idempotente quando executado por cliente/rede não confiável.

Repetir o mesmo comando processado não deve duplicar:

- evento;
- cobrança;
- estorno;
- atribuição;
- evidência.
