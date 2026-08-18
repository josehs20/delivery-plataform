# 32 — API de Motoboy

### `GET /api/v1/driver/me`
Perfil operacional.

### `PUT /api/v1/driver/me`
Atualiza dados permitidos.

### `GET /api/v1/driver/documents`
Lista documentos.

### `POST /api/v1/driver/documents`
Registra documento e referência de arquivo.

### `GET /api/v1/driver/vehicles`
Lista veículos.

### `POST /api/v1/driver/vehicles`
Cadastra veículo.

### `PUT /api/v1/driver/vehicles/{id}`
Atualiza veículo.

### `GET /api/v1/driver/preferences`
Retorna capacidade e preferências.

### `PUT /api/v1/driver/preferences`
Atualiza capacidade, categorias, limite de distância e quantidade máxima de entregas simultâneas.

### `POST /api/v1/driver/availability`

```json
{"available":true}
```

## Regras

- Motoboy não aprovado/suspenso não recebe novas corridas.
- Disponibilidade não significa aceitação automática.
- O motoboy pode atuar em qualquer região.
- Proximidade atual é usada no despacho.
