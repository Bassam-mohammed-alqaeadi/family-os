# Guardian Continuity Decision — Primary Handover Before Recovery

> **Status:** Primary-guardian transfer implemented as a server-governed Foundation API contract. Lost-account/dispute recovery remains intentionally unavailable.
> **Updated:** 2026-09-29

## Decision

A primary guardian must never be removed, replaced or promoted through a generic membership role-edit route. The safe initial continuity capability is a two-party transfer case:

```text
Current active primary guardian
  → nominates one active co-guardian
  → case waits within a deployment-owned expiry window
  → nominated co-guardian accepts with their own verified principal
  → Render atomically demotes prior primary, promotes nominee,
    updates family primary reference, writes audit and outbox evidence
```

The transfer can be cancelled only by its initiating, still-active primary guardian before acceptance. One pending transfer exists per family. A candidate cannot self-promote, a child cannot be nominated, a stranger cannot accept, and the prior primary cannot remove the new primary after completion.

## Implemented boundary

- Schema: `003_guardian_continuity.sql`.
- API: `POST /v1/families/:familyId/guardian-transfers`, then `/accept` or `/cancel`.
- Eligibility: active `primary_guardian` initiator and active `co_guardian` candidate in the same family.
- Expiry: `GUARDIAN_TRANSFER_TTL_HOURS`, a deployment-owned 1–168 hour policy; no hard-coded user data or timer result.
- Evidence: versioned continuity case plus a minimal audit/outbox event for request, cancel, completion or expiry.
- Atomic completion: the family primary reference and both active guardian roles change in one PostgreSQL transaction.

## Explicit non-capabilities

This does **not** claim to solve a lost account, an absent/deceased/unsafe primary guardian, coercion, guardian dispute, legal custody proof, age/consent edge cases, support review, authentication recovery, identity re-verification, notification delivery or public Flutter flow. Those cases require a separately authorized recovery/support process with human escalation, retention, privacy and incident ownership.

A UI must show this transfer only after Render/OIDC are real and must truthfully surface pending, cancelled, expired, failed and unavailable states. Until then, no Flutter screen may imply that guardian transfer or recovery is live.

## Why this is the best next slice

It preserves family continuity without allowing a local role switch, a raw admin credential, an unverified client claim, or a dangerous “remove primary” action. It also creates a durable event boundary for a later recovery service without pretending that recovery is already solved.
