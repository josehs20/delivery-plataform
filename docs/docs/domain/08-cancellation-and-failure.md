# 08 — Cancelamento, Falha e Devolução

## 1. Princípio

Cancelamento e falha são eventos de domínio e devem produzir efeitos operacionais e financeiros rastreáveis.

## 2. Cancelamento pelo comércio

O comércio pode solicitar cancelamento quando permitido pelo estado.

Deve informar:

- motivo;
- descrição quando necessária.

Depois da coleta, o cancelamento exige devolução.

## 3. Cancelamento pelo motoboy

O motoboy pode cancelar conforme a política aplicável.

Deve registrar:

- motivo;
- descrição quando necessária;
- localização;
- data/hora;
- evidência quando necessária.

O cancelamento deve ser usado como indicador operacional e pode impactar reputação/qualificação futura.

## 4. Motivos sugeridos

- RECIPIENT_ABSENT;
- WRONG_ADDRESS;
- RECIPIENT_REFUSED;
- ACCESS_DENIED;
- VEHICLE_PROBLEM;
- PACKAGE_PROBLEM;
- WEATHER;
- SAFETY_ISSUE;
- OTHER.

## 5. Falha

Uma falha não é automaticamente um cancelamento. Ela representa uma tentativa de execução que não conseguiu completar a entrega.

## 6. Evidências

De acordo com o motivo, podem ser exigidos:

- foto;
- localização;
- descrição;
- contato/registro operacional;
- outras evidências configuradas.

## 7. Devolução após coleta

Quando uma entrega com mercadoria coletada precisar ser cancelada:

```text
RETURN_REQUIRED
→ RETURN_IN_PROGRESS
→ RETURNED
→ CANCELLED
```

O comércio deve confirmar o recebimento do item.

## 8. Proteção contra perda de mercadoria

Uma entrega não deve entrar diretamente em `CANCELLED` quando houver mercadoria em posse do motoboy. Primeiro devem ser satisfeitas as obrigações de devolução ou de tratamento administrativo.

## 9. Impactos operacionais

Cancelamentos e falhas podem alimentar:

- reputação;
- métricas de qualidade;
- indicadores de operação;
- eventuais políticas financeiras.

A fórmula de reputação não está definida no MVP.
