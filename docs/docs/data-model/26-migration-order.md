# 26 — Ordem de Migrations

## Fase 1 — Identity

1. users
2. roles
3. permissions
4. role_permissions
5. user_roles
6. user_sessions

## Fase 2 — Commerce

7. businesses
8. business_users
9. business_addresses

## Fase 3 — Driver

10. drivers
11. driver_documents
12. driver_vehicles
13. driver_capacities
14. driver_service_preferences

## Fase 4 — Delivery

15. deliveries
16. delivery_items
17. delivery_offers
18. counter_offers
19. delivery_assignments
20. delivery_events
21. delivery_locations
22. delivery_evidences
23. delivery_failures
24. delivery_cancellations
25. delivery_returns

## Fase 5 — Finance

26. payments
27. payment_transactions
28. refunds
29. commissions
30. driver_payouts

## Fase 6 — Platform

31. notifications
32. sync_operations
33. audit_logs

## Regras de migration

- Respeitar dependências de FK.
- Criar constraints críticas junto da estrutura que as suporta.
- Não inserir regras de negócio em seeds de produção sem necessidade.
- Seeds de desenvolvimento devem ser separadas de migrations.
- Rollback deve ser previsível.
- Mudanças de schema destrutivas devem exigir revisão explícita.
