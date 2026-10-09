# Controlled Foundation Staging Activation Record

> **Status:** Prepared for activation; no Render service, PostgreSQL database, OIDC issuer, secret or customer data has been configured by this record.
> **Prompt discipline:** Produced under `05_SYSTEM_OPERATING_PROMPT.md`.
> **Updated:** 2026-09-29
> **Scope:** Family/membership/revocation/guardian-transfer foundation verification only. Recovery/Support implementation remains blocked by `07_RECOVERY_SUPPORT_ADMISSION_PACKET.md`.

## 1. Staging purpose

Staging exists to prove that the existing Foundation API behaves truthfully with real process boundaries:

```text
approved development OIDC issuer
  → Render staging API
  → Render staging PostgreSQL
  → migrations + authorization + audit/outbox verification
```

It is not a beta, a production fallback, a customer environment, a place for copied Firebase data, a support channel or a shortcut around the Recovery/Support admission gate.

## 2. Environment invariants

| Invariant | Required staging behavior |
|---|---|
| Isolation | Separate Render project/service/database from production and from any legacy/Guardian-Eye data source. No shared customer database, schema or service-account identity. |
| Data | Synthetic test accounts/families only. No child, guardian, device, billing, location, support or customer data. |
| Identity | Dedicated development/test OIDC issuer/client/audience if an issuer is approved. Tokens must be short-lived test artifacts; none are committed, logged or copied into Flutter. |
| Secrets | `DATABASE_URL`, OIDC values and any provider secret are held solely in Render/provider secret managers. No chat, source file, fixture, GitHub variable, Flutter asset or CI output. |
| Runtime truth | `/health/live` may report process liveness. `/health/ready` must remain `503` until configuration, PostgreSQL connectivity and all expected migrations are truly available. |
| Public exposure | No public product claim, family onboarding, app integration, support form, telemetry of real users or production hostname. |
| Destroyability | The environment and test data can be destroyed/recreated without affecting any user, release, entitlement or legal record. |

## 3. Activation inputs — must be recorded by accountable owners

This table is intentionally not pre-filled. Guessing a region, provider, budget or owner from a repository or location would make the staging record untrustworthy.

| Record | Value/evidence required | Accountable owner | Status |
|---|---|---|---|
| STG-OWN-01 | Render organization/project, service owner, incident/on-call contact. | Sole Staging Owner | Owner acceptance recorded; actual project/service identifier pending creation. |
| STG-OWN-02 | PostgreSQL region, residency rationale, database owner and destruction/reset approval. | Sole Staging Owner | Oregon synthetic-only/destruction decision accepted; actual database/date pending creation. |
| STG-OWN-03 | Cost owner, selected staging plan, spend/usage alert and shutdown threshold. | Sole Staging Owner | Free-plan boundary accepted; dashboard usage/spend evidence pending. |
| STG-ID-01 | Development OIDC issuer, audience, JWKS endpoint, test-client ownership and subject lifecycle. | Sole Staging Owner | Firebase Spark Email/Password test-issuer boundary accepted; project/config evidence pending. |
| STG-ID-02 | Test principal creation/revocation process; no real user identities. | Sole Staging Owner | Synthetic-only lifecycle accepted; created/revoked labels and cleanup evidence pending. |
| STG-SEC-01 | Secret access list, rotation/revocation process and break-glass prohibition. | Sole Staging Owner | Dashboard-only, single-access-holder and no-break-glass policy accepted; dashboard evidence pending. |
| STG-OPS-01 | Backup/restore scope, migration operator, rollback approver and evidence store. | Sole Staging Owner | Manual encrypted logical dump/restore policy accepted; drill evidence pending. |
| STG-QA-01 | Test-data lifecycle, verification operator, evidence retention and cleanup confirmation. | Sole Staging Owner | Synthetic-only/free-resource expiry-replacement boundary accepted; test and cleanup evidence pending. |

A connected environment is authorized only for the manual, synthetic resource-creation procedure in `11_CONTROLLED_STAGING_OPERATOR_CONNECTION_CHECKLIST.md`. It remains **unverified** until every row's provider/execution evidence exists. The Owner’s admission does not permit invented identifiers, secret values, direct database state edits, production data, customer access or a success claim before the protocol passes.

The Owner-directed free-tier/Render/Firebase decision, detailed attestation and remaining execution evidence are recorded in `10_FREE_TIER_STAGING_ADMISSION_UPDATE.md`.

## 4. Staging configuration contract

The service configuration is intentionally the same security shape as production, with staging-specific values:

```text
NODE_ENV=staging
PORT=<Render supplied>
DATABASE_URL=<Render staging PostgreSQL secret>
OIDC_ISSUER=https://securetoken.google.com/<synthetic-firebase-project-id>
OIDC_AUDIENCE=<synthetic-firebase-project-id>
OIDC_JWKS_URL=https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
GUARDIAN_TRANSFER_TTL_HOURS=1  # synthetic staging only
```

No Firebase Admin key, Firebase database URL, Firestore configuration, Cloud Function, Storage bucket, FCM token, payment key, AI key or static Flutter secret belongs in this contract.

The API start/build contract remains:

```text
working directory: backend
Node runtime: 22
build: npm ci
start: npm start
liveness path: /health/live
readiness path: /health/ready
```

A manual-adoption IaC template lives at `infra/render/foundation-staging.render.yaml.example`. It encodes the approved synthetic Oregon/Free boundary, private database networking, dashboard-only configuration placeholders and disabled automatic deployment. Follow `11_CONTROLLED_STAGING_OPERATOR_CONNECTION_CHECKLIST.md`; it does not create resources merely by existing in the repository.

Migrations run by an authorized operator, exactly once per target database, through `npm run migrate`; application startup must never apply them automatically.

## 5. Activation sequence

### Phase A — before resources exist

1. Close STG-OWN/STG-ID/STG-SEC/STG-OPS/STG-QA evidence records.
2. Confirm Credential Guard, Backend CI, `npm run check` and `npm test` pass on the exact release commit.
3. Review the current migration list and rollback/restore procedure; no destructive reset without explicit staging-data approval.
4. Verify that Recovery/Support scope remains design-only and that no Flutter client points to staging as a user-facing service.

### Phase B — controlled infrastructure creation

1. Create isolated staging PostgreSQL and web service in the approved location/project.
2. Configure secrets directly in the approved secret manager with least-privilege access.
3. Deploy the exact reviewed commit. Confirm liveness only.
4. Apply migrations explicitly and verify `schema_migrations` contains the current checksum-attested manifest: `001_foundation.sql` through `004_audit_correlation.sql`.
5. Configure the approved test OIDC issuer; then, and only then, require `/health/ready` to return `200`.

### Phase C — controlled verification

Execute every check in `09_STAGING_VERIFICATION_PROTOCOL.md` using synthetic data. Record identifiers, versions, pass/fail result and timestamp only—never tokens, secrets, raw request bodies or family data.

### Phase D — closure or teardown

- If all checks pass, mark **Foundation staging verification complete**, not production-ready and not Recovery/Support-authorized.
- If any authorization, audit, migration, readiness, secret or backup/restore control fails, remove staging from traffic, preserve minimal diagnostic evidence and resolve through a new reviewed change.
- Destroy or reset synthetic test data under STG-QA-01. Do not carry test families into later environments.

## 6. Explicit stop conditions

Stop activation immediately when any of the following occurs:

- a real secret/key/token is asked to be committed, pasted into chat/source, placed in Flutter or made available to CI logs;
- the only available identity mechanism is a broad Firebase Admin/service-account credential;
- region, cost, retention, rollback, incident or secret ownership is unknown;
- production/legacy/customer data would be copied into staging;
- readiness is forced to `200` without database/schema/OIDC proof;
- an operator attempts direct database edits to create a family, role, membership or guardian state; or
- staging is proposed as a public beta, customer support system or Recovery/Support workaround.

## 7. Staging claim vocabulary

| Allowed statement | Prohibited statement |
|---|---|
| “Foundation staging verification is pending/active/passed/failed.” | “Family OS is launched/production-ready/protecting families.” |
| “A synthetic API request was accepted and audited in staging.” | “A real guardian has been recovered or a family is protected.” |
| “OIDC verification works for dedicated test identities.” | “Account recovery is available to users.” |
| “Database restore drill passed for synthetic staging data.” | “Customer data recovery/compliance has been proven.” |

## 8. Outcome

```text
Staging plan: READY FOR OWNED ACTIVATION
Staging resources: NOT CREATED BY THIS RECORD
Connected identity/database: NOT CONFIGURED
Recovery/Support code: NOT AUTHORIZED
Flutter production integration: NOT AUTHORIZED
```
