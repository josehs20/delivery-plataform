# 29 — Implementação das Migrations

## Decisão

O MVP utilizará UUIDs como chaves primárias.

## Ordem

As migrations devem seguir `docs/data-model/26-migration-order.md`.

## Regras

1. MySQL é o banco alvo.
2. Foreign keys devem usar `uuid`.
3. Timestamps devem ser armazenados em UTC; usar colunas `DATETIME`/`TIMESTAMP` com estratégia consistente de timezone.
4. Valores monetários usam `decimal`, nunca `float/double`.
5. Índices críticos devem ser criados junto da tabela que protege a regra.
6. Índices geoespaciais só devem ser criados quando o MySQL Spatial for oficialmente adotado.
7. Migrations não devem inserir regras de negócio que pertençam ao domínio.
8. Constraints de integridade devem ser preferidas quando protegem invariantes simples.
9. Dados financeiros e auditoria não devem possuir deleção destrutiva em cascata.
10. `current_driver_id` em `deliveries`, caso implementado, deve permanecer consistente com a atribuição ativa.

## Campos JSON

Usar `json` para metadata, snapshots externos e estruturas variáveis, sem esconder relacionamentos centrais.

## Segurança

Não inserir secrets, tokens ou credenciais nas migrations.
