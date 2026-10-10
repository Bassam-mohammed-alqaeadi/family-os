# Administration, Trust & Operations Implementation Sequence — Gate G3

> **Status:** Build-ready roadmap; Backend, Native/device, notification, payment, provider and release implementation remain unauthorized.
> **Goal:** Build one reliable family trust spine on Render, then connect every product pillar to it through real state—not by retaining local mocks behind production-looking UI.
>
> **Superseded (owner decision 2026-10-10):** the "unauthorized" line above governed the foundation wave. The owner's approved SAFETY phase authorizes the backend/native/notification work its slices require (see `docs/safety_phase/01_SAFETY_PHASE_PLAN.md`); the two-phone test comes after it, then education. Historical text kept as written.

## 1. Shared platform foundation

Before any remote family promise, establish:

- Render account/session/recovery, family/membership/role/child scope and cross-family authorization;
- versioned setup/consent/audit/event/outbox foundations;
- device enrollment credential/capability/health contracts, even before a feature-specific native adapter;
- durable Today projection, notification preference/orchestration, privacy/data request and support-safe diagnostic patterns;
- entitlement catalog/verification/reconciliation boundary with no client-held commercial authority;
- queue/worker/retry/replay/observability/kill-switch foundations; and
- Firebase auxiliary-service approval records before any FCM implementation.

The goal is not to build every screen or vendor integration upfront. It is to create the minimum shared source-of-truth capable of closing one honest family loop at a time.

## 2. Proposed vertical sequence

### Slice 1 — Account, family and membership truth

A guardian establishes or recovers a verified account, creates/joins a family, receives explicit authority, and can invite a co-guardian with scope/expiry/acceptance/revocation/audit. Every read/mutation is Render-authorized by family/role/child scope.

**Why first:** No safety, learning, connection, intelligence, device or billing feature can be truthful without real family membership and recovery authority.

### Slice 2 — Progressive setup and child transparency

A guardian sees a server-backed setup queue, adds a child under authority, pauses/resumes safely, and the child receives an age-appropriate explanation of a visible link/data/rule context. A separated demo/no-data route cannot write or resemble live family state.

**Why next:** This proves truthful first value and consent/explanation patterns before any device/policy claim.

### Slice 3 — Device enrollment, capability and repair loop

A guardian begins a secure pairing flow; a supported device becomes registered only after identity/assignment/capability evidence; the platform shows verified/limited/stale/offline/repair/replace/unlink truth and audits each transition.

**Why next:** It becomes the shared device/capability substrate for Security, Learning and Family Connection rather than allowing each pillar to invent device status.

### Slice 4 — Today source-to-action loop

A real authorized event from the first implemented domain appears as one role-appropriate Today item. The guardian opens the owning domain, acts, and sees the independently verified state reflected in Today/activity history. Empty families see an honest setup/no-data state.

**Why next:** It validates the platform’s daily front door without implementing a fake aggregated dashboard.

### Slice 5 — Notification preference and reconciliation loop

A member sets eligible urgency/quiet/digest preferences; Render evaluates relevance/fatigue/time zone; an approved transport is attempted where supported; the client reconciles from authoritative source after offline/duplicate/collapsed/failed push conditions.

**Why next:** It makes attention delivery reliable enough for requests/device health and later Safety/Connection workflows while preserving the source-of-truth distinction.

### Slice 6 — Privacy, audit and data-request loop

An authorized guardian/child sees appropriate data transparency, changes a permitted scope or submits a governed export/correction/forget/delete request, and receives complete/partial/retention-limited/failed truth with a durable audit/support route.

**Why next:** Data lifecycle and consent need to be real before broad cross-pillar event history, intelligence retrieval or commercial scale.

### Slice 7 — Entitlement and billing loop

A guardian sees a real eligible catalog, starts a provider/store flow, Render verifies/reconciles the receipt or provider event, and the family receives verified entitlement/trial/change/restore/refund/expiry truth with help support. Safety/privacy/recovery remain non-coercively accessible.

**Why later:** Billing requires region/store/product/legal/tax/receipt/support operations and must not be simulated or rushed ahead of core family trust.

### Slice 8 — Support and operational recovery loop

A person reads current localized help, previews optional diagnostics, submits a real support case, sees a truthful case lifecycle, and an authorized operator can reconstruct minimal state and recover safely.

**Why later:** Support benefits from the real identity, device, audit, notification, privacy and entitlement contracts already proven by earlier slices.

### Slice 9 — Cross-pillar hardening

Apply the shared spine to Security policy/command receipts, Learning assignment/focus, Family Connection relationships/tasks/check-ins, and Intelligence source/feedback/data lifecycle. Complete cross-domain conflict, audit, notification and Today scenarios before broad feature expansion.

**Why last in this pillar:** The platform should reuse proven trust contracts, not create one-off authority/device/notification/data semantics per product area.

## 3. Definition of done per slice

Every slice requires all applicable conditions:

1. Render-authoritative family/role/child/device/purpose authorization and durable state.
2. An end-to-end guardian/co-guardian/child journey, with clear protected non-visibility where appropriate.
3. No hard-coded family/product result, optimistic client success, unlabelled fixture or demo-state leakage.
4. Versioned/idempotent request/event lifecycle with expiry, replay, race/conflict, offline, retry and recovery behavior.
5. Freshness/capability/consent/visibility/retention truth and independent owning-domain outcome where relevant.
6. Today, notification, activity/audit, privacy/data and support connection without making a transport/projection state the source of truth.
7. Accessibility, Arabic-first RTL/LTR, localisation, time zone/calendar, currency/terms and age-appropriate child explanation checks.
8. Security/privacy/abuse, least-privilege diagnostics, operations/observability, rollback/kill-switch and incident/support readiness.
9. Provider/store/device-lab validation and server-side verification/reconciliation whenever an external system is involved.

## 4. Deferred scope guardrails

- Do not ship generic profile/role selection as authorization.
- Do not ship QR-only pairing, fake heartbeats, default healthy badges, client-held device credentials or unverified device reports.
- Do not seed Today with fabricated child state, static recommendations or sample events in production.
- Do not use FCM/Firebase as membership, notification-resolution, audit or product-data truth.
- Do not ship a local-only privacy wipe/forget/export as account/family-wide data lifecycle completion.
- Do not display fixed plan prices, active trials, purchases, restores, refunds or receipts without live region/store/provider and Render verification.
- Do not make SOS, privacy/data rights, account recovery or essential safety contingent on a payment state.
- Do not ship a support chatbot/form that implies a person received/resolved a case without operations.

## 5. Authorization boundary

This sequence is a precise roadmap for future Render-based implementation. It does not authorize starting Render services, authentication, device pairing, FCM, payment SDKs, store/server verification, workers, remote data sync, customer-support integration, Native/device adapters, beta distribution or production release. Those steps need a separate Owner execution authorization after Product Refinement V2 closes.
