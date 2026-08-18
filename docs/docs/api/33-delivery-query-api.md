# 33 — API de Consulta de Entregas

## Comércio

`GET /api/v1/business/deliveries`

Filtros: `status`, `created_from`, `created_to`, `driver_id`, `recipient`, `cursor`.

`GET /api/v1/business/deliveries/{id}`

## Motoboy

`GET /api/v1/driver/deliveries`

`GET /api/v1/driver/deliveries/{id}`

`GET /api/v1/driver/offers`

## Eventos

`GET /api/v1/deliveries/{id}/events`

## Tracking

`GET /api/v1/deliveries/{id}/tracking`

## Regras

- Coleções devem ser paginadas.
- Dados pessoais devem ser minimizados.
- Não expor localização sem contexto autorizado.
- IDs não concedem acesso por si só; evitar IDOR.
