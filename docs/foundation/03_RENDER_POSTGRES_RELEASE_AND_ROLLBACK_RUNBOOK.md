# Render / PostgreSQL Foundation Release and Rollback Runbook

> **Status:** Controlled-integration procedure only. It does not authorize deployment by itself.
> **Updated:** 2026-09-29
> **Applies to:** `backend/` Foundation API and its Render-owned PostgreSQL schema.

## 1. Purpose and boundaries

This runbook is the operational path for promoting the fail-closed Foundation API after the outstanding ownership preconditions in `01_FOUNDATION_WAVE_PRECONDITION_REGISTER.md` are resolved.

It does not permit Firebase Admin credentials, Firestore, Functions, Storage, FCM, Native device control, billing, AI, realtime, customer release or Flutter production claims. It uses one Render web service and one co-located PostgreSQL-compatible database only.

## 2. Named ownership required before an operator starts

Do not begin deployment until the release record names:

- infrastructure owner and on-call/incident owner;
- Render organization/project, approved web/database region and data-residency rationale;
- budget/cost owner, selected plan and alert threshold;
- privacy/retention owner and database backup retention decision;
- approved OIDC issuer, audience, recovery/revocation owner and key-rotation contact; and
- release operator and rollback approver.

The service must not be created in a personal or legacy project merely because credentials are available.

## 3. Preflight checks

Run from a clean checkout of the approved commit:

```bash
node scripts/verify-no-service-account-keys.mjs
cd backend
npm ci
npm run check
npm test
```

Confirm all of the following before any production mutation:

1. The release branch/commit is reviewed and Backend CI plus Credential Guard are green.
2. The new database is empty or its current migration version is recorded.
3. A restore test has been performed for the target database/backup policy, or the deployment is blocked.
4. Render secret values are available to the named operator only—not in `.env`, GitHub variables, Flutter, tickets or chat.
5. `OIDC_ISSUER`, `OIDC_AUDIENCE` and `OIDC_JWKS_URL` identify one approved issuer and match its documented recovery posture.
6. `DATABASE_URL` points to the co-located Family OS database, using encrypted transport where supported by the selected service.

## 4. Controlled database migration

Migrations never run automatically at API process start. The release operator runs them once against the intended database:

```bash
# Run only in an authorized session where DATABASE_URL is injected from the secret manager.
# Do not paste a connection string into shell history, source files, tickets or chat.
cd backend
npm run migrate
```

The migration runner obtains a database-scoped PostgreSQL advisory lock before it inspects or changes schema history. A simultaneous migration run fails before schema work rather than racing another release. It validates the reviewed migration manifest and each SQL file's immutable SHA-256 digest, then records filename plus checksum in `schema_migrations`. Verify the recorded migration/checksum set and inspect the resulting schema through an authorized database session. A missing or mismatched digest keeps readiness closed; never rewrite an applied migration to force a match. The Foundation API requires:

- `001_foundation.sql` — account/family/membership/audit/outbox/idempotency tables; and
- `002_membership_lifecycle.sql` — membership version/status-change/reason evidence; and
- `003_guardian_continuity.sql` — expiry-bound, two-party primary-guardian transfer cases.

No operator should manually edit a previously applied migration. Corrections are a new, reviewed forward migration.

## 5. Render service configuration

Create a Node 22 web service rooted at `backend/` with:

```text
Build command: npm ci
Start command: npm start
Health path: /health/live
Bind address: 0.0.0.0
Port: supplied by Render as PORT (local default is 10000)
```

Set these values in Render’s secret environment manager only:

```text
DATABASE_URL
OIDC_ISSUER
OIDC_AUDIENCE
OIDC_JWKS_URL
GUARDIAN_TRANSFER_TTL_HOURS
NODE_ENV=production
```

A liveness success is not release proof. `/health/ready` must return `200` only after the exact database and OIDC configuration are ready. If it returns `503`, halt the release; do not change the Flutter client to hide the failure.

## 6. Post-deployment verification

Perform the following through a controlled test identity and non-production family data:

1. Verify `/health/live` returns `200`, then `/health/ready` returns `200`.
2. Verify a missing/invalid token is denied; a fabricated role or family id cannot create access.
3. Create a test family with an idempotency key and repeat it; verify the same result is returned.
4. Verify a cross-family read is denied.
5. Invite, accept, revoke and remove a non-primary test membership; verify a removed member loses subsequent family access.
6. Verify a primary membership cannot be removed by the ordinary revoke endpoint.
7. Inspect audit and outbox rows by identifiers only; do not export raw family data, tokens or request payloads into release logs.
8. Confirm operational logs contain correlation/request identifiers and status codes, never bearer tokens, OIDC subjects, key material or raw product payloads.

Do not enable a Flutter production client until these checks are recorded as passed and its unavailable/error/retry states are reviewed.

## 7. Rollback and failure handling

### API deployment failure before migration

Redeploy the last known-good API artifact. Do not leave an unready service publicly described as available.

### API deployment failure after a compatible migration

Prefer redeploying the previous compatible API version. Foundation migrations are additive, so a prior API version is expected to remain compatible with the new schema. Verify this in staging before relying on it in production.

### Data/schema incident

1. Stop write traffic through the API or place the service into an explicit unavailable state.
2. Preserve minimal incident evidence without copying credentials, tokens or family payloads.
3. Notify the named incident/privacy owners.
4. Restore from the approved backup only under the documented recovery authority.
5. Apply a reviewed corrective forward migration rather than mutating production history.
6. Re-run the complete post-deployment verification sequence before reopening writes.

### Identity incident

If the issuer, audience, JWKS endpoint or provider recovery posture is suspect, leave readiness unavailable or remove the service from traffic. Do not accept locally decoded tokens, switch to a test verifier, or bypass verification to maintain availability.

## 8. Completion evidence

A release record must contain the commit SHA, migration names, operator/approver, verified region/database identity, backup/restore evidence, readiness result, negative authorization results, audit/outbox verification result, monitoring/incident route and any known limitations. It must contain no secret values or family payloads.
