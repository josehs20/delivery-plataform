# 40 — Evidências

### `POST /api/v1/uploads`

Cria upload ou fluxo de upload seguro.

Validar autenticação, autorização, tamanho, MIME, extensão e armazenamento.

### `POST /api/v1/deliveries/{id}/evidence`

```json
{
  "type":"PROOF_OF_DELIVERY_PHOTO",
  "file_id":"...",
  "captured_at":"2026-08-16T12:20:00Z",
  "latitude":-20.0,
  "longitude":-40.0
}
```

### Conclusão

`POST /deliveries/{id}/complete` deve exigir os dados da prova de entrega definidos pelo MVP, incluindo nome do recebedor, foto e localização quando aplicável.

Evidências usadas em decisões críticas não devem ser substituídas silenciosamente.
