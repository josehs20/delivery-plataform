# 11 — Offline e Sincronização

## 1. Objetivo

Permitir que o motoboy continue executando uma entrega previamente sincronizada mesmo em áreas sem internet.

## 2. Princípio offline-first

O aplicativo não deve depender da disponibilidade da rede para cada ação operacional local.

Arquitetura conceitual:

```text
UI
 ↓
Repository
 ├── Local Data Source
 └── Remote Data Source
      ↓
   Sync Engine
```

## 3. Banco local

O aplicativo deve possuir armazenamento local para:

- entregas sincronizadas;
- itens;
- dados de destinatário;
- eventos;
- localização pendente;
- evidências;
- fila de sincronização;
- metadados necessários à execução offline.

## 4. Fila de sincronização

Conceito de entidade:

`SyncQueueItem`

Campos conceituais:

- id local;
- event_id/idempotency_key;
- entidade;
- operação;
- payload;
- prioridade;
- tentativas;
- last_attempt_at;
- status;
- created_at;
- synced_at.

## 5. Idempotência

O mesmo evento enviado mais de uma vez deve produzir o mesmo efeito lógico de uma única execução.

Isso é obrigatório para:

- mudanças de estado;
- coleta;
- conclusão;
- falha;
- devolução;
- upload de evidências;
- localização relevante.

## 6. Reintentos

Usar retry com backoff. Evitar loops agressivos que consumam bateria e dados.

## 7. Ordem dos eventos

Quando a ordem for importante, os eventos devem possuir informação suficiente para o servidor validar consistência e impedir transições impossíveis.

Exemplo: `DELIVERED` não deve ser aplicado antes de requisitos obrigatórios da entrega terem sido satisfeitos.

## 8. Aplicativo do comércio

No MVP, o comércio pode consultar dados locais offline, mas uma nova solicitação precisa de conectividade para chegar ao servidor e ser disponibilizada aos motoboys.

## 9. Aplicativo do motoboy

Deve funcionar offline para uma entrega já sincronizada, inclusive para:

- chegada;
- coleta;
- transporte;
- prova;
- falha;
- conclusão;
- evidências.

## 10. Mídia

Fotos devem:

1. ser salvas localmente;
2. possuir referência local;
3. entrar em fila;
4. ser enviadas quando possível;
5. ter confirmação do servidor;
6. permanecer pendentes até confirmação.

## 11. Conflitos

O servidor é a autoridade final. Conflitos devem ser resolvidos por regras de domínio, nunca pelo último valor recebido cegamente.
