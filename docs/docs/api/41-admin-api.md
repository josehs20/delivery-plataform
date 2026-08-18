# 41 — API Administrativa

## Motoboys

```text
GET  /api/v1/admin/drivers/pending
POST /api/v1/admin/drivers/{id}/approve
POST /api/v1/admin/drivers/{id}/reject
POST /api/v1/admin/drivers/{id}/suspend
```

## Entregas

```text
GET  /api/v1/admin/deliveries
POST /api/v1/admin/deliveries/{id}/assign
POST /api/v1/admin/deliveries/{id}/cancel
```

## Financeiro

```text
GET /api/v1/admin/payments
GET /api/v1/admin/refunds
GET /api/v1/admin/payouts
```

## Auditoria

```text
GET /api/v1/admin/audit-logs
```

## Regra

Atribuição manual deve respeitar as mesmas invariantes da atribuição automática. Toda intervenção importante gera auditoria.
