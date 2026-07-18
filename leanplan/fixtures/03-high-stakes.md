# Implementation Plan: Refund Processing Service

## Goal

Support agents currently issue refunds by hand in the Stripe dashboard. Give them an internal
endpoint that issues a refund against an order, so refunds are logged and attributable.

Roughly 40 refunds/day. Agents are authenticated through our existing internal SSO.

Stack: Python 3.12, FastAPI, PostgreSQL, Stripe API.

## Work

1. `POST /refunds` accepting `{order_id, amount_cents, reason}`. Look up the order, verify the
   refund does not exceed the amount already captured, call Stripe, record the result.
2. Idempotency: caller supplies an `Idempotency-Key` header, stored unique in `refund_requests`.
   A repeat key returns the original result rather than issuing a second refund.
3. Persist every attempt — agent identity, order, amount, reason, Stripe refund id, outcome —
   to a `refund_events` table. Append-only; no updates or deletes.
4. Retry Stripe calls on 5xx and network timeouts with bounded exponential backoff, reusing the
   same idempotency key so a retry can never double-refund.
5. Reconciliation job comparing `refund_events` against the Stripe refunds list daily, alerting
   on any row where our state and Stripe's disagree.
6. Restrict the endpoint to the `support-agent` SSO group. Log denied attempts.

## Acceptance

- Refunding an order twice with the same idempotency key issues exactly one Stripe refund.
- A refund exceeding the captured amount is rejected before any Stripe call.
- A simulated Stripe timeout followed by a retry produces one refund, not two.
- A user outside `support-agent` receives 403 and the attempt is logged.
- Reconciliation flags an artificially introduced mismatch.
