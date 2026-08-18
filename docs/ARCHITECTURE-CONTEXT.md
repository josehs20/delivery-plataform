# Delivery Platform - Architecture Context & Project Understanding

**Date**: 2026-08-16  
**Version**: 1.0  
**Status**: Active Reference

---

## Executive Summary

This document establishes the canonical understanding of the **Delivery Platform** architecture, derived from the project's technical specifications, domain rules, and Laravel conventions. All code generation, implementation decisions, and architectural work MUST conform to these principles.

---

## 1. Project Identity

### Stack
- **Backend Framework**: Laravel 11/12
- **Language**: PHP 8.2+ with strict typing
- **Database**: MySQL
- **Architecture Pattern**: Domain-Driven Design (DDD) with layered architecture
- **Code Standards**: PSR-12 compliance

### Project Structure
```
delivery-platform/
├── docs/                      # Canonical product & business truth
│   ├── domain/               # Domain models, use cases, lifecycle
│   ├── data-model/           # Database schema, ER diagrams, data contracts
│   ├── api/                  # API specifications, contracts, error handling
│   ├── business-rules/       # Financial, delivery, negotiation rules
│   ├── decisions/            # Architecture Decision Records (ADRs)
│   └── laravel/              # Laravel-specific technical specs
├── laravel/                   # Backend implementation (Laravel 11/12)
│   ├── app/                  # Application code
│   ├── database/             # Migrations, seeders, factories
│   ├── tests/                # Test suites
│   └── .cursor/rules/        # AI coding rules & conventions
└── flutter/                   # Frontend client (read-only from backend perspective)
```

---

## 2. Architecture Foundation

### Mandatory 4-Layer Architecture

#### Layer 1: HTTP Layer
**Responsibility**: Request/Response handling, transport validation, serialization

- Routes (`routes/`)
- Controllers (`app/Http/Controllers/`)
- Form Requests (`app/Http/Requests/`)
- API Resources (`app/Http/Resources/`)
- Middleware (`app/Http/Middleware/`)

**Constraints**:
- Controllers MUST remain thin and orchestrate through application services
- All input validation happens here at the transport level
- HTTP request objects MUST NOT leak into domain/application layers
- Return stable response envelopes defined by API documentation

#### Layer 2: Application Layer
**Responsibility**: Use case orchestration, workflow coordination

- Application Services (`app/Services/`)
- Use Cases / Commands (`app/Actions/`, `app/UseCases/`)
- DTOs for command inputs/outputs (`app/DTOs/`)

**Constraints**:
- Orchestrate domain services and infrastructure
- Enforce business rules and invariants
- Handle transaction boundaries
- Coordinate external provider calls
- MUST NOT contain HTTP logic
- MUST NOT contain SQL queries directly (use repositories)

#### Layer 3: Domain Layer
**Responsibility**: Business logic, invariants, state transitions, domain policies

- Domain Models (`app/Models/` - Eloquent models with business methods)
- Domain Services (`app/Services/Domain/`)
- Value Objects (`app/ValueObjects/`)
- Enums (states, roles, types)
- Domain Policies (`app/Policies/`)
- Domain Events (`app/Events/Domain/`)

**Constraints**:
- Pure business logic independent of framework
- State machines and transitions explicitly defined
- Invariants enforced at object creation and state change
- Never depend on HTTP, database, or external APIs directly
- Use enums/value objects for constants (delivery states, roles, event types)

#### Layer 4: Infrastructure Layer
**Responsibility**: External integrations, persistence, async operations

- Repositories (`app/Repositories/`)
- External API Clients (`app/Integrations/`, `app/Services/Providers/`)
- Queue Jobs (`app/Jobs/`)
- Event Listeners (`app/Listeners/`)
- Database Migrations (`database/migrations/`)
- Notification Channels (`app/Notifications/`)

**Constraints**:
- Hidden behind interfaces/adapters
- Replaceable implementations
- External providers must be abstract (e.g., `PaymentGateway`, `GeocodeProvider`)
- Never leak provider-specific details to upper layers

---

## 3. Source of Truth & Dependency Rules

### Canonical Sources
1. **Business & Product Truth**: `/docs/**` 
   - Domain models, use cases, business rules, product requirements
   - API contracts and data contracts
   - All feature specifications

2. **Technical Specification for Laravel**: `/laravel/docs/**`
   - Laravel-specific implementation guidelines
   - Database schema decisions
   - API error handling standards
   - Authentication/authorization specifics

3. **Code Rules**: `/laravel/.cursor/rules/**`
   - Laravel conventions
   - Domain rules
   - Database & persistence rules
   - API rules

### Authority Boundaries
- **Laravel is authoritative for**:
  - Authentication & authorization
  - Delivery state machine & transitions
  - Pricing, negotiation, offers & counter-offers
  - Payment, commission, refund, payout processing
  - Audit trail & event persistence
  - Synchronization acceptance & validation

- **Flutter is a client** (read-only from backend):
  - NOT authoritative for delivery status
  - NOT authoritative for financial values
  - All client-supplied values MUST be validated on server

---

## 4. Core Domain Concepts

### Entities & Value Objects
- **Business**: Company/organization account holder
- **Driver**: Individual fulfilling deliveries, can have multiple active deliveries
- **Vehicle**: Transportation method assigned to driver
- **Delivery**: Order for transport with state machine
- **DeliveryItem**: Individual items in a delivery
- **Offer**: Initial driver bid/proposal
- **CounterOffer**: Business counter-proposal during negotiation
- **Payment**: Transaction record
- **Commission**: Business earnings from delivery
- **Refund**: Payment reversal with audit trail
- **Payout**: Commission payment to driver
- **ProofOfDelivery**: Completion evidence (photo, signature, etc.)
- **DriverLocation**: GPS tracking record
- **DeliveryEvent**: Audit trail entry (status change, attempt, etc.)
- **SyncEvent**: Offline synchronization record

### State Machine - Delivery Lifecycle
Every delivery follows an explicit, audited state machine:

```
PROPOSED → ACCEPTED → PICKUP_IN_PROGRESS → PICKED_UP 
        → IN_TRANSIT → DELIVERED / FAILED / RETURNED
```

**Rules**:
- Every transition MUST be explicitly validated
- Transition validation checks: actor, current state, preconditions, side effects
- Every transition persisted as `DeliveryEvent` (audit trail)
- Concurrent acceptance protected transactionally (only one driver wins)
- A driver may have multiple deliveries in parallel

### Offer & Counter-Offer Negotiation
- **Offer**: Driver's initial proposal with status (PENDING, ACCEPTED, REJECTED, EXPIRED)
- **CounterOffer**: Business response during negotiation (status: PENDING, ACCEPTED, REJECTED)
- Counter-offers become available only after configured acceptance window expires
- Once one proposal accepted, competing proposals must be closed
- Negotiation window has explicit business rules

### Financial Invariants
- Final price, commission, refund, payout values validated and persisted server-side
- Historical financial snapshots MUST remain immutable except for explicit audited adjustments
- Never recompute historical financial truth from current configuration
- Use decimal/numeric representations (never float) for money
- Every financial transaction must have audit trail

### Multi-Delivery Driver Behavior
- A single driver can have multiple active deliveries simultaneously
- Never assume 1 driver = 1 active delivery
- Each delivery maintains independent state machine
- Concurrent operations on multiple deliveries must be safe

### Proof of Delivery (PoD)
- Delivery marked complete only with configured proof-of-delivery data
- Never accept client-provided status string alone
- PoD data validated and persisted

---

## 5. Non-Negotiable Engineering Rules

### Auditability
- Every state change recorded as domain event
- Financial transactions immutable
- User actions traced to specific actor
- Rationale/reason documented for sensitive operations (cancellation, refund, etc.)

### Idempotency
- Retryable critical operations (payment, acceptance, state transitions) must be idempotent
- Use idempotency keys where defined in API contracts
- Safe to retry without side effects

### Transactional Consistency
- Concurrent delivery acceptance serialized transactionally
- Financial operations protected with transaction boundaries
- Double-assignment prevented at database level
- Payment + commission must be atomic

### Separation of Concerns
- Business logic MUST NOT live in controllers, jobs, listeners, API resources
- Domain logic belongs in domain/application services
- Infrastructure concerns (DB, APIs) hidden behind interfaces
- Each class has single, focused responsibility

### Never Invent Business Rules
- Explicitly marked "pending" features MUST NOT be implemented without user approval
- Do not silently assume financial behavior, permissions, or state transitions
- Read relevant `/docs/**` documentation before implementing

---

## 6. Database & Persistence

### Database Engine
- **Primary**: MySQL
- Migrations deterministic, reviewable, and reversible
- Foreign keys and constraints enforce integrity

### Financial Data Integrity
- Use `decimal`/`numeric` types (never floating point)
- Immutable historical records
- Never use cascading deletes for audit/financial tables
- Soft deletion only where domain explicitly requires it

### Timestamp Handling
- Store in UTC
- Use `created_at`, `updated_at` consistently
- Record state change timestamps as audit events

### Indexing Strategy
- Index status columns for filtering
- Index ownership columns (driver_id, business_id)
- Index proximity/tracking lookups (driver location)
- Index negotiation columns (offer status, counters)
- Index audit queries (event_type, created_at)

### Schema Features
- Support multiple active deliveries per driver
- Explicit one-to-many models (DeliveryItems, Offers, CounterOffers, Events, Locations)
- Immutable audit history
- No cascading deletes for critical data

---

## 7. API Design

### Principles
- Design from documented use cases, NOT database tables alone
- Use explicit versioning (e.g., `/api/v1`)
- Return stable response envelopes defined by documentation
- Consistent HTTP status code usage
- Error shapes consistent across endpoints

### Validation & Authorization
- Form Requests validate transport-level input (format, type, presence)
- Policies/permissions authorize before business execution
- Domain/application services enforce business rules
- Never accept client-provided authoritative values:
  - Final delivery status
  - Commission amounts
  - Payout values
  - Refund amounts
  - Authoritative pricing

### Performance
- Paginate list endpoints that grow
- Deliberate eager loading to avoid N+1 queries
- Aggregations computed server-side
- Cache strategies where beneficial

### Data Exposure
- Never expose internal fields, secrets, provider IDs, sensitive personal data
- Use API resources/DTOs for serialization
- Encrypt sensitive data in transit (HTTPS)
- Rate limiting on critical endpoints

---

## 8. Code Quality Standards

### PHP & Laravel
- **PSR-12** compliance (code style)
- **Strict typing**: `declare(strict_types=1);` in new files
- Descriptive class, method, variable names
- Avoid hidden side effects in accessors
- Typed properties and return types
- Immutable DTOs for command inputs where appropriate

### Domain Safety
- Enums/value objects for constants (delivery states, payment states, roles)
- Never use magic strings for domain concepts
- Validate invariants at object construction
- Explicit state transitions

### Testing
- Automated tests for behavior, not implementation details
- Test state transitions with pre/post conditions
- Test concurrent scenarios for critical operations
- Test financial calculations exactly

### Documentation
- Update `/docs/**` before or with implementation
- Update API docs for new endpoints
- Document ADR decisions for architectural changes
- Inline comments for non-obvious domain logic

---

## 9. Security & Authentication

### Authentication
- Use Laravel's configured authentication mechanism (no ad hoc replacement)
- Passwords hashed with framework-supported mechanism
- Tokens/sessions with expiration and revocation
- Rate limiting on login attempts
- No password/token logging

### Authorization
- Policies/permissions checked before operations
- User context passed through application stack
- Authorization failures logged safely

### Sensitive Data
- Never log: passwords, access tokens, refresh tokens, OTP secrets, payment secrets
- Phone/email verification as separate authentication concern
- Stronger requirements for administrative accounts

---

## 10. External Integrations

All external provider integrations MUST be replaceable through interfaces:

- **Payment Processing**: Behind `PaymentGateway` interface
- **Geocoding/Mapping**: Behind `GeocodeProvider`, `RouteProvider` interfaces
- **Push Notifications**: Behind `PushNotificationProvider` interface
- **File Storage**: Behind `StorageProvider` interface
- **SMS/Email**: Behind `NotificationProvider` interface

**Rule**: Never couple domain logic to provider-specific implementations.

---

## 11. Implementation Priorities

### MVP Phase (Baseline Implementation)
1. Core domain models and state machine
2. Authentication and basic authorization
3. Delivery creation, acceptance, state transitions
4. Basic pricing and offer system
5. Financial ledger and audit trail
6. Proof of delivery collection

### Post-MVP (Negotiation, Advanced Features)
- Offer/counter-offer workflow
- Complex pricing rules
- Geographic dispatch optimization
- Offline-first synchronization
- Advanced payment splitting
- Return/cancellation workflows

---

## 12. Documentation & Decisions

### Architecture Decision Records (ADRs)
Located in `/docs/decisions/`:
- ADR-001: Layered architecture with DDD
- ADR-002: Offline-first capability with sync
- ADR-003: Delivery state machine design
- ADR-004: Concurrency & transactional safety
- ADR-005: Idempotency patterns
- ADR-006: Geospatial dispatch
- ADR-007: Financial snapshot immutability
- ADR-008: Audit event trail
- ADR-009: Provider abstraction pattern
- ADR-010: Multiple active deliveries per driver
- ADR-011: Primary key strategy

### Reference Documentation
- **Domain Models**: `/docs/domain/16-domain-model.md`
- **State Machine**: `/docs/domain/17-delivery-state-machine.md`
- **API Contracts**: `/docs/api/*.md`
- **Data Model**: `/docs/data-model/*.md`
- **Business Rules**: `/docs/business-rules/04-business-rules.md`

---

## 13. Coding Workflow

### Before Implementation
1. Read relevant `/docs/**` specification
2. Check `/laravel/docs/**` for Laravel-specific guidance
3. Review `.cursor/rules/` for coding conventions
4. Identify which layer(s) need changes
5. Plan domain logic separately from transport/persistence

### During Implementation
1. Implement domain logic first (invariants, state machines, policies)
2. Add application services to orchestrate domain
3. Build HTTP layer (controllers, requests, resources) last
4. Write tests for behavior
5. Document new use cases and API changes

### Code Review Checklist
- ✓ Follows layer separation?
- ✓ Business logic in correct layer?
- ✓ Invariants enforced?
- ✓ State transitions validated?
- ✓ External providers abstracted?
- ✓ Tests cover behavior?
- ✓ Documentation updated?
- ✓ No magic strings (use enums)?
- ✓ Financial data decimal-safe?
- ✓ Audit trail complete?

---

## 14. Key References

**To understand the project, read in this order:**

1. `/docs/DOMAIN-CLOSURE.md` - Complete domain overview
2. `/docs/data-model/DOMAIN-DATA-MODEL-CLOSURE.md` - Complete data model
3. `/docs/domain/05-delivery-lifecycle.md` - Delivery workflow
4. `/docs/domain/17-delivery-state-machine.md` - State machine details
5. `/docs/api/29-api-overview.md` - API overview
6. `/laravel/docs/` - Laravel-specific implementation guides
7. `/laravel/.cursor/rules/` - Detailed technical rules

---

## 15. Questions & Clarifications

**For ambiguities not covered in `/docs/**`:**
- Ask before implementing
- Mark assumptions as "pending approval"
- Document rationale in ADR or code comments

**For urgent decisions:**
- Check most relevant ADR first
- Fall back to established patterns in codebase
- Document decision for future reference

---

## Approval & Adoption

**Document Status**: Active  
**Last Updated**: 2026-08-16  
**Next Review**: After major architectural change or new ADR

This document is derived from and must remain consistent with:
- `/docs/DOMAIN-CLOSURE.md`
- `/docs/data-model/DOMAIN-DATA-MODEL-CLOSURE.md`
- `/laravel/.cursor/rules/00-project-context.mdc`
- All architectural decision records in `/docs/decisions/`

---

**End of Document**
