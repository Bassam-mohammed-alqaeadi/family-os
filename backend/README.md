# Family OS Foundation API

This directory is the **Render-first Foundation Wave backend**, not a replacement Flutter application and not a Firebase migration. It implements the first durable server boundary for:

- verified OIDC principal boundaries;
- family creation and primary-guardian membership;
- explicit co-guardian/child pending membership acceptance;
- tenant-scoped authorization;
- append-only family audit records and a durable outbox record in the same PostgreSQL transaction; and
- idempotency for mutations.

## Explicitly not implemented

This slice intentionally does not implement account registration/recovery UX, an identity provider, Firebase/Firebase Admin/Firestore/Cloud Functions/FCM, device pairing, Native enforcement, location, app usage, SOS, chat, calls, media, billing, AI, export/delete execution, realtime transport, Flutter production integration, or release deployment.

There is no demo identity fallback. When OIDC or PostgreSQL configuration is absent—or the required PostgreSQL migrations are not applied—`/health/ready` returns `503` and every protected endpoint fails closed. Test-only identities and in-memory state live only under `backend/test/`; the runtime server cannot load them.

## Local quality commands

```bash
cd backend
npm ci
npm run check
npm test
```

After an isolated staging service has been accepted and configured, run the non-mutating baseline verifier (it sends no valid token and creates no data):

```bash
STAGING_EXECUTION_ACK=synthetic-only \
STAGING_API_BASE_URL='https://approved-staging-origin' \
npm run verify:staging
```

It proves only liveness, readiness, missing-token denial and invalid-token denial. It is not a replacement for the full synthetic-data protocol in `docs/foundation/09_STAGING_VERIFICATION_PROTOCOL.md`.

A local process without secrets can be inspected safely:

```bash
npm start
# GET /health/live  -> 200
# GET /health/ready -> 503 (honest: configuration is absent)
```

## Required deployment configuration

Populate these values through Render’s secret environment configuration only; never commit a populated `.env` file.

| Variable | Purpose |
|---|---|
| `PORT` | Render port; defaults to `10000` locally. |
| `DATABASE_URL` | Render PostgreSQL-compatible connection URL. |
| `OIDC_ISSUER` | Exact issuer for the approved identity provider. |
| `OIDC_AUDIENCE` | Exact audience accepted by the Family OS API. |
| `OIDC_JWKS_URL` | HTTPS JWKS endpoint for server-side signature verification. |
| `GUARDIAN_TRANSFER_TTL_HOURS` | Deployment-owned transfer acceptance window, from 1 to 168 hours. |

The OIDC variables must be set together. The API verifies issuer, audience, signature and subject server-side; it never accepts a role, family id or subject supplied as authority by the client.

No issuer is selected by this code. Firebase Authentication remains an optional future token issuer only after the separately required no-cost/pricing/privacy/fallback approval; it is neither bundled nor configured here.

## Database migration

Migrations are deliberately explicit and are **not** executed by API startup:

```bash
DATABASE_URL='…' npm run migrate
```

The migration runner validates the ordered migration manifest and immutable SHA-256 digest of every SQL file, then records the same digest in `schema_migrations`. Readiness fails closed when a required migration is absent or its recorded digest does not match the reviewed API release. Migrations are never rewritten after application; corrective changes are new reviewed migrations. Apply them through the named deployment owner’s controlled release procedure after backup/rollback and region/cost ownership are recorded.

## HTTP contract (foundation-only)

The machine-readable contract is `openapi/foundation.v1.json`. It documents current local Foundation behavior, not a deployed service or Flutter production capability. Contract tests require every documented protected route to declare OIDC security and every mutation to require an idempotency key.

All protected routes require `Authorization: Bearer <OIDC access token>`. All mutation routes also require an `Idempotency-Key` unique to the operation payload.

| Method | Route | Contract |
|---|---|---|
| `GET` | `/health/live` | Process liveness only; no dependency claim. |
| `GET` | `/health/ready` | Returns `200` only when required config and database are genuinely available. |
| `POST` | `/v1/families` | Creates a family and active `primary_guardian` membership for the verified subject. |
| `GET` | `/v1/families/:familyId` | Returns only to an active family member. |
| `POST` | `/v1/families/:familyId/memberships` | Primary guardian creates a pending `co_guardian` or `child` membership for a known OIDC subject. There is no email/push invitation transport in this wave. |
| `POST` | `/v1/families/:familyId/memberships/:membershipId/accept` | Only the exact invited OIDC subject can accept. |
| `POST` | `/v1/families/:familyId/memberships/:membershipId/revoke` | Only the primary guardian can revoke a pending invitation or remove an active non-primary member. Requires an idempotency key and a non-sensitive machine `reasonCode`. The record and audit evidence remain durable. |
| `POST` | `/v1/families/:familyId/guardian-transfers` | Current primary guardian proposes handover to an active co-guardian. One transfer may await acceptance per family. |
| `POST` | `/v1/families/:familyId/guardian-transfers/:transferId/accept` | Only the nominated active co-guardian can complete an unexpired transfer. The primary pointer and both roles change atomically with audit/outbox evidence. |
| `POST` | `/v1/families/:familyId/guardian-transfers/:transferId/cancel` | Only the initiating current primary guardian can cancel a pending transfer. |
| `GET` | `/v1/families/:familyId/audit-events` | Guardian-only audit view; child membership is denied. |

The current known-subject invitation contract is a service boundary/testable safety slice, not a finished consumer invitation experience. A consent, discovery and delivery design is required before it is exposed in Flutter. Primary-guardian handover is available only through the two-party, expiry-bound guardian-transfer case; direct role editing is not exposed. Alternate guardian recovery after account loss, support-mediated disputes, and broad role/scope editing remain deliberately excluded until their own recovery/continuity evidence and operational process are designed.

## Render deployment preconditions still owned outside code

The code is ready for controlled integration testing, not for unattended deployment. Before creating a Render service/database, record: service/database region and data residency owner, cost owner/plan/limits, approved identity provider and recovery threat model, secrets/CI/deployment/rollback owner, incident owner, retention classification, and an external Flutter test environment. See `docs/foundation/00_GUARDIAN_EYE_REFERENCE_ASSESSMENT.md` and `docs/product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`.
