# 05 — Ciclo de Vida da Entrega

## 1. Máquina de estados

Estados propostos:

```text
DRAFT
  ↓
OPEN
  ├──────────────→ CANCELLED
  ↓
NEGOTIATING
  ├──────────────→ CANCELLED
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

Fluxos alternativos:

```text
PICKED_UP / IN_TRANSIT
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

## 2. Definição dos estados

### DRAFT

Entrega sendo montada e ainda não publicada.

### OPEN

Entrega publicada e aguardando aceite.

### NEGOTIATING

Janela de contrapropostas ativa.

### ASSIGNED

Motoboy vencedor atribuído.

### DRIVER_ACCEPTED

Aceite confirmado no domínio.

### GOING_TO_PICKUP

Motoboy deslocando-se para origem.

### AT_PICKUP

Motoboy registrou chegada à origem.

### PICKED_UP

Mercadoria recebida pelo motoboy.

### IN_TRANSIT

Transporte em andamento.

### AT_DESTINATION

Motoboy registrou chegada ao destino.

### DELIVERED

Prova válida registrada e entrega concluída.

### DELIVERY_FAILED

Tentativa de entrega não concluída.

### RETURN_REQUIRED

Existe obrigação de devolver mercadoria.

### RETURN_IN_PROGRESS

Devolução em andamento.

### RETURNED

Comércio confirmou recebimento da devolução.

### CANCELLED

Entrega encerrada por cancelamento.

## 3. Transições permitidas

| De | Para | Atores |
|---|---|---|
| DRAFT | OPEN | Comércio/Admin |
| OPEN | NEGOTIATING | Sistema |
| OPEN | ASSIGNED | Sistema/Motoboy/Admin |
| OPEN | CANCELLED | Comércio/Admin |
| NEGOTIATING | ASSIGNED | Comércio/Admin |
| NEGOTIATING | CANCELLED | Comércio/Admin |
| ASSIGNED | DRIVER_ACCEPTED | Sistema |
| DRIVER_ACCEPTED | GOING_TO_PICKUP | Motoboy |
| GOING_TO_PICKUP | AT_PICKUP | Motoboy |
| AT_PICKUP | PICKED_UP | Motoboy |
| PICKED_UP | IN_TRANSIT | Motoboy |
| IN_TRANSIT | AT_DESTINATION | Motoboy |
| AT_DESTINATION | DELIVERED | Motoboy/Admin |
| PICKED_UP | DELIVERY_FAILED | Motoboy/Admin |
| IN_TRANSIT | DELIVERY_FAILED | Motoboy/Admin |
| DELIVERY_FAILED | RETURN_REQUIRED | Sistema/Regra |
| RETURN_REQUIRED | RETURN_IN_PROGRESS | Motoboy |
| RETURN_IN_PROGRESS | RETURNED | Comércio/Admin |
| RETURNED | CANCELLED | Sistema/Admin |
| ASSIGNED | CANCELLED | Conforme política |
| DRIVER_ACCEPTED | CANCELLED | Conforme política |

A matriz pode ser expandida conforme as políticas finais de cancelamento.

## 4. Regras de transição

Toda transição deve validar:

- estado atual;
- ator;
- permissão;
- pré-condições;
- evidências requeridas;
- regras financeiras;
- concorrência;
- idempotência.

## 5. Histórico

Toda transição importante deve gerar `DeliveryEvent` com:

- delivery_id;
- actor_id;
- actor_type;
- event_type;
- old_state;
- new_state;
- latitude quando disponível;
- longitude quando disponível;
- metadata;
- created_at.

## 6. Múltiplas entregas

A existência de várias entregas ativas para um mesmo motoboy não altera o ciclo de cada entrega. Cada uma mantém seu próprio estado.
