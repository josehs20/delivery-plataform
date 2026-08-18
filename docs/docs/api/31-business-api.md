# 31 — API de Comércio

### `GET /api/v1/business/me`
Retorna o comércio associado ao usuário.

### `PUT /api/v1/business/me`
Atualiza dados permitidos.

### `GET /api/v1/business/addresses`
Lista endereços.

### `POST /api/v1/business/addresses`
Cria endereço. Para endereço operacional, latitude e longitude são obrigatórias.

```json
{
  "label":"Principal",
  "postal_code":"29000-000",
  "state":"ES",
  "city":"Vitória",
  "district":"Centro",
  "street":"Rua X",
  "number":"100",
  "reference":"Próximo à praça",
  "latitude":-20.3155,
  "longitude":-40.3128
}
```

### `PUT /api/v1/business/addresses/{id}`

### `DELETE /api/v1/business/addresses/{id}`

Aplicar desativação/remoção conforme integridade e histórico.

## Regras

- Usuário só acessa negócios aos quais está vinculado.
- Não confiar em `business_id` enviado se o contexto autenticado já o determina.
- Entregas sempre pertencem ao comércio autenticado.
