# ADR-008 — Eventos e auditoria

## Status

Accepted

## Decisão

Fatos operacionais relevantes serão registrados como eventos da entrega. Ações administrativas relevantes terão também registro de auditoria.

Eventos não substituem o estado atual do agregado.

O histórico deve permitir reconstruir a sequência operacional de uma entrega sem depender de logs de aplicação voláteis.
