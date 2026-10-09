# Foundation Wave Precondition Register

> **Status:** Local, fail-closed foundation scaffold is allowed; deployment and Flutter production integration remain blocked.
> **Updated:** 2026-09-29
> **Authority:** `PRV2-031`, `92_EXECUTION_AUTHORIZATION_GATE.md`, `16_RUNTIME_TRUTH_POLICY.md`, `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md`

## Implementation posture

The authorized work is intentionally split into two states:

1. **Safe local foundation implementation:** permitted now. It contains no operational credential, no default identity, no cloud resource, no Firebase SDK and no client claim of capability.
2. **Connected Render production implementation:** prohibited until the open deployment, data, identity, cost and incident ownership records below are resolved.

This distinction lets the platform make verifiable progress without pretending a service has been configured or released.

## Accepted technical foundation decisions

| Area | Local foundation decision | Why it is safe now |
|---|---|---|
| Runtime | Node 22 + Express process that binds to Render-provided `PORT`. | Matches the useful Render operating pattern from Guardian-Eye without inheriting Firebase persistence. |
| Durable state | PostgreSQL-compatible schema accessed only by the Render API. | Keeps Family OS source of record and family authorization in the required Render-owned boundary. |
| Identity boundary | Provider-neutral OIDC issuer/audience/JWKS verification server-side. | No provider/project/secret is embedded; an unconfigured server fails closed. |
| Family authorization | Principal → account → active membership → role check for every family route. | Prevents request-payload subject/role/family escalation. |
| Mutation reliability | Database transaction + idempotency record + audit record + outbox event. | Establishes the required atomicity and evidence path before asynchronous capabilities exist. |
| Client behavior | No Flutter code changed yet. | The app cannot claim a working account or parental-control backend before a real service exists. |
| Firebase | No integration. | The reference project does not satisfy Family OS no-cost, privacy, provider or billing approval requirements. |

## Open preconditions that block connected deployment

| ID | Precondition | Current status | Required evidence before Render deployment |
|---|---|---|---|
| FW-P1 | Render account/service/database location | Partially selected | Oregon is the candidate synthetic-staging region; named infrastructure/privacy owner and residency rationale remain required. See `10_FREE_TIER_STAGING_ADMISSION_UPDATE.md`. |
| FW-P2 | Cost and usage ownership | Partially selected | Free web/PostgreSQL are candidates only; named cost owner, usage/spend thresholds, expiry/shutdown rule and plan acknowledgement remain required. |
| FW-P3 | Identity and recovery threat model | Partially selected | Firebase Auth Spark is a synthetic-token-issuer candidate; exact sign-in/recovery/revocation process, project owner, audience values and escalation owner remain required. |
| FW-P4 | Data classification and retention | Partially designed | Classification/retention/deletion/legal-hold mapping for account, family, child and audit data; privacy owner confirmation. |
| FW-P5 | Delivery and incident operations | Partially designed | Manual reviewed deployment, Render secret ownership, migration/rollback and a synthetic logical backup/restore runbook, alert route and incident commander/support owner. Free PostgreSQL has no provider backups. |
| FW-P6 | External Flutter validation environment | Open | Flutter SDK/Android/iOS-capable environment and integration-test owner outside the constrained Arena workspace. |
| FW-P7 | Firebase test-issuer admission | Partially selected | The narrow Spark-token-issuer record is in `10_FREE_TIER_STAGING_ADMISSION_UPDATE.md`; it authorizes no Firebase persistence, Admin, FCM, Functions, Storage or client authority. |

## Guardian-Eye information use record

The Owner-provided second project was used as a read-only source of architecture and test lessons, recorded in `00_GUARDIAN_EYE_REFERENCE_ASSESSMENT.md`. Its Render runtime convention, principal derivation, transaction/idempotency, code-hash, membership and notification-evidence patterns informed this foundation.

The following were deliberately not copied or configured: the reference Firebase project, service account, Firestore, Cloud Functions, Storage, Firebase Admin dependency, FCM transport, token, data, billing assumption, role semantics or secret. This is a boundary decision, not an absence of review.

## Promotion criteria for the local scaffold

A future Foundation Wave card may promote this code to connected integration only when all of the following are true:

- `backend` contract tests and static checks are green in CI;
- a controlled PostgreSQL environment successfully applies migration(s), with a tested rollback/restore path;
- readiness reports `200` only after a real database and approved OIDC verifier are configured;
- negative tests prove unauthenticated, invalid-token, cross-family, non-primary, duplicate, stale/revoked and idempotency-conflict denial paths;
- secret exposure scans and repository review find no actual configuration or credentials;
- a Flutter integration plan displays unavailable/failed/blocked truthfully and makes no device-control, notification-delivery or account-recovery claim; and
- FW-P1 through FW-P6 evidence is recorded and owned.

Until then, this work is a **tested local service boundary**, not a deployed backend, authenticated app experience or release candidate.
