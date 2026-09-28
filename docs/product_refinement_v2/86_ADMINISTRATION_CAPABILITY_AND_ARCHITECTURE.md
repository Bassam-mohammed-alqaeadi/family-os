# Administration, Trust & Operations Capability & Architecture Readiness — Gate G3

> **Status:** Product-readiness technical design complete
> **Infrastructure boundary:** Render is the authoritative backend for identity, family, membership, device, entitlement, notification, privacy, audit and support state. Firebase is never a system of record and may be used only as an individually approved no-cost auxiliary service under `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md`.

## 1. Architecture outcome

The administration platform must make one dependable promise:

> **A family can understand who belongs, what is connected, what is effective, what needs attention and how to recover—without a local UI or payment/push attempt being mistaken for shared truth.**

The architecture distinguishes the following states:

| State | Meaning | Must not be mistaken for |
|---|---|---|
| Account identity | A verified user account/session and approved recovery posture. | Family membership or guardian authority. |
| Family membership | A server-authorized relationship, role and scope inside a family. | A client-selected role or an invitation draft. |
| Device enrollment | A verified device/family/child relationship with credentials and lifecycle. | An opened QR screen, local code or installed app. |
| Capability / health | Time-bound device evidence of what feature can work and why it is limited. | A generic “protected” or “connected” badge. |
| Preference | A user’s desired Today/notification/display/data setting. | Effective notification delivery, consent, policy enforcement or data deletion. |
| Entitlement | A Render-verified right derived from an approved commercial provider/store lifecycle. | A client callback, plan card or unverified receipt. |
| Data request | A governed request to access/export/correct/forget/delete. | Immediate completion across all stores/providers. |
| Support case | A real service request with a tracked operational state. | A local form submission or automatic human response. |

## 2. Render-first topology

```text
Primary guardian / co-guardian Flutter client     Child Flutter experience
                         │                         │
                    authenticated Render API and realtime/query boundary
                                         │
 ┌──────────────────────────────────────┼─────────────────────────────────────┐
 │ Account, session and recovery service │ Family/membership/role service      │
 │ Setup/consent/version service         │ Child and device relationship svc   │
 │ Device enrollment/capability/health   │ Today projection / attention service│
 │ Notification preference/orchestration │ Privacy/data lifecycle/audit service│
 │ Entitlement/catalog/receipt service   │ Help/support/diagnostic service      │
 │ Event/outbox/activity history         │ Queue/workers/operations controls    │
 └──────────────────────────────────────┴─────────────────────────────────────┘
                                         │
                   Render durable data, encrypted secrets, outbox and job queue
                 ┌──────────────────────┼──────────────────────┐
                 │                      │                      │
      Native/device adapters   approved billing/store adapters   approved FCM transport
      report verified facts    server-side receipt/status events  notification attempt only
```

The diagram defines responsibility boundaries, not a microservice mandate. An initial Render deployment may use a modular service/application and one durable datastore if its authorization, tenancy, outbox and audit boundaries remain intact.

## 3. Domain responsibilities

| Domain | Owns | Must not own |
|---|---|---|
| Account/session/recovery | Account identity, credentials/session references, recovery challenge lifecycle, account deletion request and security audit. | Granting family/guardian authority based only on sign-in. |
| Family/membership/roles | Family lifecycle, verified membership, primary/co-guardian/child scope, invitation/acceptance/revocation, guardian continuity and role audit. | A broad authentication bypass or silent role escalation. |
| Setup/consent/version | Setup task definitions/state, terms/privacy/consent version, pausable/resumable progress and truth of completion. | Converting an opened screen or demo action into verified capability. |
| Device enrollment/capability | Device identity/credentials, child assignment, enrollment code lifecycle, capability/permission/health evidence, replacement/unlink state. | Inventing native evidence or deciding product policy. |
| Today/attention | Authorized source projection, role relevance, grouping, freshness, display/defer/dismiss state and domain routing. | Owning Safety/Learning/Connection/Intelligence outcomes or generating sample family state. |
| Notification orchestration | Preference/recipient/urgency/quiet/fatigue evaluation, device endpoint lifecycle, transport attempts/retries and notification audit. | Source-of-truth delivery/read/resolution or SOS incident closure. |
| Privacy/data/audit | Data inventory/purpose/visibility/retention, access/export/correction/forget/delete request lifecycle, append-only audit and least-privilege support access. | A client-only delete, hidden behavioural archive or automatic legal conclusion. |
| Entitlement/billing | Product catalog reference, verified provider/store receipt, effective entitlement, limits, trial/renewal/refund/restore state and commercial audit. | Processing payment secrets in Flutter or using client receipt as authority. |
| Help/support | Localized help metadata, diagnostic-consent package, case lifecycle, permitted support access and user-visible status. | Pretending a human response/resolution exists or unrestricted family-data access. |

## 4. Core capability programme

| Capability | Required future work | User behaviour until proven |
|---|---|---|
| Account and recovery | Select/evaluate account identity method, server session/revocation/MFA/recovery/abuse model, deletion and support policy. | Existing welcome/login screens are local UI only; no signed-in/verified/recovery-complete claim. |
| Family and roles | Render membership/role model, invitation/acceptance, continuity/recovery safeguards, role-conflict handling and audit. | Client role selector/local father-mother state is non-authoritative and cannot grant access. |
| Setup and consent | Server setup task state, terms/privacy versioning, consent/age/locale policy and cross-device resume. | Local progress remains labelled local; no real completion percentage. |
| Device pairing and health | Secure enrollment token/QR lifecycle, account/child match, device credential/attestation decision, native capability reporting, last-seen/repair/unlink/replacement. | QR/pairing/health UI is pending/unsupported/local preview; no protected/current device claim. |
| Today projection | Render event ingestion/outbox, role-scoped projection/ranking, freshness/relevance/expiry, personal display-state and recovery. | No seeded family pulse, static child state or fake recommendation in production. |
| Notifications | Render preference/orchestration, endpoint registration/rotation, approved FCM transport, in-app reconciliation, quiet/fatigue/retry/expiry and audit. | A saved local toggle or push attempt is not a delivered/read/resolved event. |
| Privacy/data lifecycle | Render inventory/purpose/retention/consent, export/deletion/forget workers, cross-store/index/provider propagation, audit and support-safe diagnostics. | Local wipe/forget is not a family-wide deletion/export result. |
| Billing/entitlement | Choose compliant store/provider approach per region/platform, server receipt verification, signed event/notification intake, entitlement reconciliation, restore/refund/dispute/support policy. | Plans are informational/unavailable; no purchase/renewal/restore/active-plan claim. |
| Help and support | Help-content publication/review, case system, diagnostic minimization/consent, availability/SLA policy and recovery workflows. | Self-help may be shown if current; no case/human status without real operations. |

## 5. Identity, membership and device security requirements

- Render resolves account, family, membership, role, child and device scope for every read/mutation. Flutter role labels, local stores and route guards are presentation aids only.
- Family membership changes use a durable invitation/recovery/acceptance lifecycle; they are idempotent, time-limited, revocable and audit-linked.
- Primary-guardian continuity has a separately protected workflow requiring explicit authorization, verification, scoped transition and recovery/audit; ordinary role editing cannot perform it.
- Enrollment credentials/codes are short-lived, single-use as appropriate, scoped to the intended family/child/device flow, rate-limited and never treated as user identity by themselves.
- Device-specific credentials are revocable and rotate/re-enroll after replacement/reset/compromise. Device evidence reports source/time/integrity/capability and cannot overwrite a newer assignment/policy.
- Account security, invitation, recovery, pairing and support flows require abuse/rate-limit/replay protection, meaningful user notices and safe recovery rather than silent access denial.

## 6. Notification, billing and data-operation boundaries

### Notification

Render selects recipients and records the authoritative underlying event first. An approved FCM integration can carry a minimised transport request to a registered endpoint; it cannot authorize access, hold family truth, prove display/open/read/acknowledgement or close any Safety/Support/Privacy loop. Delivery must recover through in-app query/sync, including collapse/duplicate/out-of-order/offline conditions.

### Billing

Flutter may initiate a permitted store/provider flow and present a pending state. Render verifies/store-reconciles a receipt or signed lifecycle event, evaluates entitlement and then exposes effective capability. Purchase tokens, provider secrets, reconciliation and anti-fraud logic stay outside the client. A pending, cancelled, expired, refunded or conflicting purchase never activates entitlement optimistically.

### Privacy/data operations

Render owns request authorization, scope/retention impact evaluation, export/delete/forget work, downstream propagation and status. It records what is requested, completed, retention-bound, failed or pending without storing an unnecessary duplicate of sensitive source data. Provider/store/FCM operational logs and any future model context must be included in the governed inventory and lifecycle where applicable.

## 7. Operational architecture requirements

- Durable state mutations publish versioned events through a transactional outbox or equivalent; Today, notification, audit, support and entitlement projections process idempotently.
- Every projection has family/role visibility filters, schema/version, source freshness and rebuild/reconciliation strategy.
- Background jobs have idempotency, retry/backoff, expiry/dead-letter diagnostics and user-visible recovery state before use.
- Secrets, billing verification credentials, device credentials and support diagnostics use restricted storage/rotation/least-privilege access. They never ship in Flutter.
- Audit records are append-only and tamper-evident by design, with retention/access controls; they are not an unbounded raw-content archive.
- Administrative feature/capability gates can disable an integration or route safely while keeping current state honest and preserving recovery paths.

## 8. Architecture decisions deferred

The product-readiness phase does not choose an identity provider, MFA method, database/queue/object store, device-attestation technology, QR/token library, notification provider beyond the approved-boundary candidate, payment provider/store SDK, tax engine, customer-support vendor, status-page provider, analytics platform, data-export format/service, or the exact Render deployment topology. Each later choice must satisfy the contracts above, `16_RUNTIME_TRUTH_POLICY.md`, and `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md` before implementation authorization.
