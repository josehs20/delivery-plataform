# 20 — Domínio Offline e Sincronização

## 1. Objetivo

Definir o comportamento do sistema quando o aplicativo Flutter perde conectividade, com foco no aplicativo do motoboy.

## 2. Princípio

Offline é um modo operacional suportado para uma entrega que já foi sincronizada no dispositivo.

O aplicativo não deve fingir que o servidor recebeu uma operação quando isso não ocorreu.

## 3. O que pode funcionar offline

Para uma entrega previamente sincronizada, o motoboy pode:

- consultar os dados essenciais;
- consultar origem/destino;
- utilizar GPS;
- consultar dados de navegação disponíveis localmente;
- registrar chegada à coleta;
- registrar coleta;
- registrar início do transporte;
- registrar chegada ao destino;
- registrar prova de entrega;
- registrar falha;
- registrar devolução;
- armazenar fotos/evidências;
- armazenar eventos para sincronização.

## 4. O que não pode ser assumido offline no MVP

O aplicativo não deve considerar concluídas no servidor, enquanto offline, operações como:

- criar nova entrega do comércio;
- aceitar uma nova oferta que ainda não foi disponibilizada localmente;
- aceitar contraproposta;
- alterar preço oficial;
- processar pagamento;
- processar estorno;
- atribuir entrega a outro motoboy.

Essas operações exigem confirmação do backend.

## 5. Local database

O aplicativo deve manter um banco local para dados necessários à operação.

Categorias:

- dados de referência;
- entregas sincronizadas;
- eventos locais;
- fila de sincronização;
- evidências pendentes;
- localização pendente.

## 6. SyncOperation

Toda operação offline que produzir efeito de domínio deve possuir identificador único.

Exemplo:

```text
sync_operation_id = UUID
```

A operação deve conter:

- tipo;
- agregado;
- ID do agregado;
- payload versionado;
- criado_em;
- tentativas;
- último erro;
- status local;
- confirmação do servidor.

## 7. Ordem dos eventos

Quando a ordem fizer parte da semântica do domínio, preservar:

- timestamp do dispositivo;
- sequência local por agregado;
- timestamp de recebimento no servidor.

O servidor é a autoridade final para validar transições.

## 8. Idempotência

Cada operação sincronizada deve ser deduplicável.

Repetir uma operação com o mesmo `sync_operation_id` não pode executar o comando novamente.

## 9. Conflitos

Conflitos devem ser resolvidos no servidor.

O cliente não pode unilateralmente sobrescrever estados críticos.

Exemplo:

```text
Flutter offline:
PICKED_UP

Servidor:
CANCELLED antes da sincronização
```

O servidor deve avaliar se a operação é válida para o estado atual e retornar conflito caso necessário.

## 10. Retry

A sincronização deve possuir:

- retry automático;
- backoff;
- limite configurável;
- estado de erro permanente;
- possibilidade de nova tentativa manual quando apropriado.

## 11. Evidências

Fotos e arquivos capturados offline devem ser armazenados localmente com referência ao evento correspondente.

O upload pode ocorrer em etapa posterior.

A conclusão local não deve ser confundida com confirmação de upload no servidor.

## 12. UX offline

A interface deve informar explicitamente:

- offline;
- operação salva localmente;
- sincronização pendente;
- sincronização concluída;
- erro de sincronização.

Nunca exibir `sincronizado` antes de confirmação do servidor.

## 13. Resultado da sincronização

Cada operação deve terminar em um de estados conceituais:

- pending;
- syncing;
- synced;
- conflict;
- failed;
- blocked.

## 14. Limites do MVP

O aplicativo do comércio não cria novas solicitações offline.

O aplicativo do motoboy executa offline apenas entregas já sincronizadas.

A negociação não deve ocorrer offline.

O pagamento definitivo não deve ocorrer offline.
