# Laravel — 12. Sincronização Offline

## Papel do servidor

O servidor recebe eventos gerados pelo aplicativo e decide se cada evento é:

- novo e aplicável;
- duplicado já processado;
- inválido;
- conflitante;
- não aplicável ao estado atual.

## Contrato de evento

Cada evento deve possuir, conceitualmente:

```json
{
  "event_id": "uuid",
  "device_id": "...",
  "user_id": "...",
  "entity": "delivery",
  "entity_id": "...",
  "type": "DELIVERY_PICKED_UP",
  "occurred_at": "...",
  "payload": {},
  "schema_version": 1
}
```

## Idempotência

`event_id` deve possuir unicidade apropriada no servidor. Reenvio do mesmo evento retorna resultado já processado sem duplicar efeitos.

## Ordenação

O servidor não deve confiar cegamente na ordem de chegada. Validar estado e timestamps/versão conforme regra de domínio.

## Anexos

Fotos e outras evidências podem ser sincronizadas separadamente do evento, com estado de upload.

## Conflitos

Conflitos críticos não devem ser resolvidos silenciosamente. Retornar código de conflito para o aplicativo registrar/mostrar o tratamento adequado.
