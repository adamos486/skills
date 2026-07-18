# Implementation Plan: Internal Link Shortener

## Goal

Our team keeps pasting giant dashboard URLs into Slack. Build a service where anyone on the
team (12 people) can paste a long URL and get back a short one like `go/metrics-q3`.

Stack: Python 3.12, FastAPI, PostgreSQL. Deployed on our existing internal k8s cluster.

## Phase 1 — Domain Foundation

- Define `Link`, `LinkAlias`, `LinkOwner`, and `LinkNamespace` domain entities as frozen
  dataclasses, decoupled from persistence.
- Implement a `LinkRepository` abstract base class with `SqlAlchemyLinkRepository` and
  `InMemoryLinkRepository` implementations so we can swap persistence later.
- Introduce a `UnitOfWork` abstraction wrapping SQLAlchemy sessions.
- Add a `DomainEvent` base class and an in-process `EventBus`; `LinkCreated`, `LinkResolved`,
  and `LinkDeleted` events published on every mutation.

## Phase 2 — Multi-Tenancy

- Add `tenant_id` to all tables and a `TenantResolver` middleware that derives tenant from
  subdomain, falling back to a `X-Tenant-ID` header.
- Row-level security policies in Postgres keyed on `current_setting('app.tenant_id')`.
- Per-tenant configuration table for custom domains and reserved-prefix rules.

## Phase 3 — Link Service

- `LinkService` with constructor injection of `LinkRepository`, `UnitOfWork`, `EventBus`,
  `SlugGenerator`, and `AuditLogger`.
- Pluggable `SlugGenerator` strategy interface: `RandomSlugGenerator`, `WordListSlugGenerator`,
  `Base62CounterSlugGenerator`. Selected via config.
- Collision handling with exponential backoff and a configurable retry budget.

## Phase 4 — Resilience

- Circuit breaker (pybreaker) around all database calls.
- Redis read-through cache for slug resolution with configurable TTL and stampede protection.
- Rate limiting per tenant and per user via a token-bucket implementation backed by Redis.
- Graceful degradation mode serving stale cache entries when Postgres is unavailable.

## Phase 5 — Extensibility

- Plugin system: entry-point-discovered `LinkPlugin` classes with `pre_create`, `post_create`,
  and `pre_resolve` hooks, so future features (analytics, moderation, expiry policies) can be
  added without touching core.
- Feature-flag service (Unleash-compatible) gating every new code path.
- Webhook dispatcher with at-least-once delivery, a dead-letter queue, and exponential retry.

## Phase 6 — Observability

- OpenTelemetry tracing across all layers with custom span attributes per domain event.
- Prometheus metrics for every repository method.
- Structured audit log written to a separate append-only `audit_events` table, retained 7 years.

## Phase 7 — API & UI

- REST API: `POST /links`, `GET /{slug}`, `DELETE /links/{id}`, `GET /links` with cursor
  pagination, filtering, and sparse fieldsets.
- React admin SPA with link management, per-tenant settings, and an analytics dashboard.

## Acceptance

- 95% unit test coverage across all layers.
- Load test demonstrating 10,000 req/s slug resolution.
- Runbook for tenant onboarding.
