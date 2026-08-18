# 37 — Localização e Rastreamento

### `POST /api/v1/driver/location`

```json
{
  "latitude":-20.123456,
  "longitude":-40.456789,
  "accuracy":8.2,
  "speed":32.4,
  "heading":90.0,
  "recorded_at":"2026-08-16T12:00:00Z",
  "client_event_id":"..."
}
```

### `POST /api/v1/driver/location/batch`

Envia pontos acumulados durante offline.

### `GET /api/v1/deliveries/{id}/tracking`

Retorna localização autorizada.

## Regras

- localização tem acesso restrito;
- pontos antigos devem ser identificáveis pela data/hora;
- baixa precisão deve ser marcada;
- despacho utiliza localização recente;
- retenção deve obedecer à política de privacidade.
