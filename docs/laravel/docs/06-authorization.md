# Laravel — 06. Autorização

## Papéis principais

- business
- driver
- admin

## Regras

Toda operação deve validar:

1. autenticidade;
2. papel/permissão;
3. propriedade/relação com o recurso;
4. estado atual;
5. regra de negócio.

## Policies

Usar Policies/Gates para autorização contextual, sem colocar toda a regra de negócio nelas.

Exemplo conceitual:

```text
business pode cancelar delivery?
→ usuário pertence ao business
→ delivery pertence ao business
→ estado permite cancelamento
→ motivo válido
→ executar Use Case
```

## Admin

Admin pode executar ações especiais, mas cada intervenção deve possuir auditoria explícita.
