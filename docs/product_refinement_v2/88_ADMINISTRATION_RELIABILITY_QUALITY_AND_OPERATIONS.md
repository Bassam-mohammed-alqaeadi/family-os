# Administration, Trust & Operations Reliability, Quality & Operations — Gate G3

> **Status:** Product-readiness technical design complete
> **Purpose:** Define the quality bar before the platform claims a family is connected, a device is healthy, a notification arrived, a purchase is active, data was deleted, or support resolved a problem.

## 1. Quality philosophy

The family trust spine fails when it grants the wrong adult access, loses a guardian recovery path, says a child device is protected when it is stale, turns a local demo into apparent family truth, drops an urgent item, activates a plan from an unverified purchase, or claims deletion/support resolution without evidence.

Reliability means authoritative identity and membership, clear asynchronous states, safe recovery, minimised data operations, commercial honesty and explainable failure—not merely an attractive onboarding or settings flow.

## 2. Verification layers

| Layer | Required verification |
|---|---|
| Domain/unit tests | Authority hierarchy, membership/role/invitation/continuity transitions, setup tasks, device/health states, Today eligibility, privacy/billing/support lifecycle. |
| Contract tests | Render API/event/outbox schemas, tenant/family scope, idempotency/version conflicts, device evidence, notification attempts, data-job and entitlement states. |
| Authorization/security tests | Cross-family isolation, role escalation, invitation/token replay, recovery abuse, session revocation, pairing compromise, support access and destructive-action confirmation. |
| Persistence/migration tests | Restarts, partial writes, corrupt/local cache recovery, schema migrations, event replay, projection rebuild and audit continuity. |
| Widget/accessibility tests | Arabic RTL/LTR, localized dates/currency/terms, large text, screen reader, keyboard, reduced motion, child explanation, clear pending/limited/restricted/destructive states. |
| Integration tests | Identity/family/membership, device enrollment/health, Today projection, notification orchestration/reconciliation, privacy job propagation, receipt verification and support request loop. |
| Provider/store/device tests | Store/provider sandbox lifecycle, server verification/webhook/event ingestion, approved FCM device lifecycle, supported native capability and device replacement/reset. |
| End-to-end family tests | Create/join/recover family, invite co-guardian, child connection/transparency, repair device, Today priority, notification preference, privacy request, plan state and support recovery. |
| Operations tests | Queue retry/dead letter, endpoint rotation, provider outage, billing reconciliation, export/delete partial completion, audit reconstruction, incident containment and rollback. |

## 3. Mandatory failure and abuse scenarios

### Identity, membership and recovery

- An invitation is forwarded, replayed, expires, is revoked while open, or is accepted after its role/child scope changes.
- Two adults concurrently edit membership/role or attempt primary-guardian continuity; only the authorized version can become effective and affected people receive safe explanation.
- An account loses a device/session, changes recovery factors, is compromised, requests deletion, or has an unresolved family/child responsibility.
- A co-guardian/child tries a direct route/API call to read billing, adult privacy, recovery or another child’s data.
- A support person attempts to access a family without an explicit, auditable, least-privilege support basis.

### Setup and devices

- Setup is paused/resumed across devices, a local cache is stale, and a demo is opened after a real family exists; no fake setup completion/family context appears.
- A pairing code is expired, scanned by the wrong account, used twice, intercepted, or a device is already assigned/replaced/reset.
- Device capability/permission changes while a guardian views the Device Center; health/freshness becomes limited/stale rather than silently green.
- A device reports late, duplicate, malformed, compromised or cross-family capability/health evidence.
- Unlink/replacement races with a queued device event/policy/notification; old credentials cannot write new truth.

### Today and notifications

- A source event is duplicated, out of order, revoked, hidden by role/consent, stale, dismissed, or superseded; Today remains source-correct and does not mutate the owner outcome.
- An empty/new family sees a useful setup/no-data state, not seeded children, static suggestions or a fake family pulse.
- Quiet hours cross time zones/daylight-saving; urgency/fatigue/digest rules conflict; emergency/SOS policy remains separate.
- A notification endpoint/token rotates, device is offline, FCM/APNs transport collapses/reorders/drops a message, channel permission is denied, or retry expires.
- A push attempt, provider acceptance, client receipt/open and underlying action outcome remain visibly distinct.

### Privacy, billing and support

- Collection/visibility consent changes while an export/delete/forget request, Today projection, report/assistant retrieval or provider job is in progress.
- A data request includes retention-bound records, partial provider/index/cache propagation, expired export package, retry failure or account deletion interaction.
- A purchase is pending, cancelled, duplicated/replayed, refunded, restored on another device/platform, reconciled late, in grace/hold or conflicts with a client cache.
- The client receives a store success callback while Render verification fails or has not happened; entitlement stays pending/unavailable.
- A plan change/limit risks hiding safety/privacy/recovery capability; product behavior remains non-coercive and makes the limitation explicit.
- Help content is stale/unavailable, diagnostics are rejected/redacted, support case submission fails, no agent is available, a case is reopened or support response is mistaken for resolution.

## 4. Observability and support

| Operational signal | Question answered |
|---|---|
| Account/recovery lifecycle | Are sign-in/recovery/deletion requests secure, completing safely and being rate-limited without locking families out? |
| Membership/continuity lifecycle | Are invitations, role changes, revocations and guardian-continuity transitions authorized, expiring and auditable? |
| Device enrollment/health | Are pairing, credential rotation, capability/permission/last-seen states and repair flows working per platform/version? |
| Setup completion truth | Which setup tasks are verified, deferred, limited or failing—and is any UI showing a false completion state? |
| Today projection health | Are source items authorized, fresh, deduplicated, relevant, routed correctly and rebuilding without family leakage? |
| Notification transport | Did Render evaluate/queue/attempt transport, did endpoint/client receipt occur where supported, and did source reconciliation recover a miss? |
| Data lifecycle | Are export/delete/forget requests authorized, propagating, retention-limited, expiring or failing transparently? |
| Entitlement reconciliation | Did catalog/receipt/provider events produce a verified/pending/expired/refund/restore state without duplicate grants? |
| Support operations | Are help assets current, diagnostics consented/minimised, cases queueing/receiving/resolving and support access audited? |
| Audit integrity | Can authorized operations reconstruct who changed what/when/outcome without broad family-content access? |

Support diagnostics must expose only IDs, state/version/error class and approved metadata needed for recovery. They must not turn Today, device health, notification, billing or privacy diagnostics into a backdoor for raw child/family content.

## 5. Release and operational requirements

### Required operational controls

- Feature/capability gates and kill switches for account/recovery, pairing, notification transport, billing provider, data jobs and support integrations.
- Idempotent queues with retry/backoff, expiry, dead-letter diagnostics and safe replay/reconciliation for every external/asynchronous workflow.
- Versioned policy/schema/catalog/provider integration changes with staged rollout, rollback and family-visible truth when degraded.
- Secrets, receipts, device credentials, support attachments and diagnostic access protected by least privilege, rotation and access audit.
- A documented ownership/escalation model for incidents affecting authorization, data exposure/deletion, billing entitlement, notification transport or device enrollment.

### Release progression

| Ring | Purpose | Evidence required |
|---|---|---|
| Internal simulation | Validate contracts, state machines, demo isolation and error paths. | Automated tests, seeded failure cases, audit/projection checks. |
| Controlled integration/device lab | Validate account/membership, device pairing/capability, approved notification/billing sandbox paths. | Supported platform matrix, server verification/reconciliation, recovery evidence. |
| Invited family pilot | Validate clarity, role safety, setup/repair, Today usefulness, data/billing/support recovery. | Consentful feedback, incident triage, no unsupported commercial/delivery claims. |
| Limited rollout | Observe asynchronous jobs, entitlement, notification and support operations under real conditions. | Metrics, alert thresholds, runbooks, rollback and data/financial incident readiness. |
| General availability | Publish only supported capabilities/terms and maintain dependable recovery. | Verified release checklist, support/policy coverage and operating ownership. |

## 6. Slice release checklist

An Administration slice cannot release before proving:

1. Render-enforced account/family/role/child/device authorization and cross-family isolation.
2. Versioned/idempotent lifecycle with pending, limited, failed, recovery and audit states.
3. Demo/local/offline state cannot be confused with shared production truth.
4. Supported native/store/notification/provider capability matrix and user-facing limitation language.
5. Today and notification state remain linked to the authoritative source and never claim delivery/resolution alone.
6. Privacy/access/export/delete/forget behavior, retention limits and support-safe diagnostics are real for any data it claims to manage.
7. Verified entitlement/receipt/reconciliation, pricing/terms disclosure and non-coercive capability boundary for any commercial feature.
8. Accessibility, localization, RTL/LTR, time zone, calendar, currency and age-appropriate child explanation verification.
9. Incident, rollback, kill-switch, support and audit reconstruction readiness.

## 7. Product Ready versus Release Ready

Administration can be **Product Ready** once its direction, UX, contracts, reliability plan, parity boundaries and build sequence are complete. It remains **not Build Authorized, Feature Complete or Release Ready** until real Render services, supported integrations, end-to-end tests, operations and separate release gates prove the stated experience.
