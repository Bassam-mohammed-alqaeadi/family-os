# Family Connection Implementation Sequence — Gate G3

> **Status:** Build-ready roadmap; Backend/Native/realtime implementation remains unauthorized.
> **Goal:** Build connection as closed, trustworthy family loops on Render rather than a collection of local messenger/calendar screens.
>
> **Superseded (owner decision 2026-10-10):** the "unauthorized" line above governed the foundation wave. The owner's approved SAFETY phase authorizes the native/realtime/notification work its slices require (see `docs/safety_phase/01_SAFETY_PHASE_PLAN.md`); the two-phone test comes after it, then education. Historical text kept as written.

## 1. Shared foundation

Before user-facing remote claims, establish Render family/role authorization, relationship/contact model, durable event/audit timeline, API/versioning, notification orchestration, realtime reconnect model, and the Firebase auxiliary-service approval mechanism.

## 2. Proposed vertical sequence

### Slice 1 — Calendar and task coordination loop

Guardian creates an event/task; correct members see it in local context; child completes/requests help; guardian reviews; Today/notification/activity update truthfully.

Why first: creates daily value without requiring calls/media transport and proves shared-family authority/timezone/task lifecycle.

### Slice 2 — Safe circle and contact-request loop

Child requests known contact; guardian approves/declines; invitation/relationship becomes active/paused/revoked with child explanation/audit.

Why next: establishes trust boundary before open messaging.

### Slice 3 — Family conversation loop

Family/approved contacts exchange messages using Render authoritative store, realtime synchronization, delivery/read truth, offline recovery and notification transport.

Why next: reuses relationships/events/notifications and proves real multi-device communication.

### Slice 4 — Check-in and location-in-communication loop

Child sends “I arrived” or guardian requests check-in; Security location consent/capability data drives a truthful response/acknowledgement/escalation loop.

Why next: it depends on the verified Security location foundation and connection delivery contracts.

### Slice 5 — Media/file sharing loop

A permitted person selects/captures, uploads, shares, receives, removes or reports a media/file asset under relationship/storage/privacy rules.

### Slice 6 — Calls

Implement selected real call transport only after platform/device/cost/privacy/quality/support decision. Start with direct family call state; group call, call play and transcription remain later slices.

### Slice 7 — Advanced coordination

Hijri/prayer/calendar intelligence, ChoreAI, subgroups, pins, locks, media transcript/stickers/backgrounds and other deferred systems begin only after their standalone capability/governance decisions.

## 3. Definition of done per slice

Each slice needs parent/co-guardian/child journeys, Render-authoritative data, role/relationship validation, delivery/receipt/acknowledgement distinction, offline/queue/retry/conflict/revocation/expiry recovery, timeline/notification/audit link, accessibility/timezone/localization verification, support/observability/rollback readiness, and actual-device proof for any native/realtime/push claim.

## 4. Authorization boundary

This sequence documents how to build real features with Render and limited approved Firebase assistance. It does not authorize starting Backend, Native, WebSocket, FCM, media or calling implementation before the owner authorizes the execution phase.
