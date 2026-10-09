# Foundation Staging Verification Protocol

> **Status:** Pre-execution protocol. Execute only after `08_CONTROLLED_STAGING_ACTIVATION_RECORD.md` inputs are accepted.
> **Data rule:** Synthetic identities and families only; record minimal test evidence, never secrets/tokens/raw payloads.
> **Scope:** Current Foundation API through guardian transfer. This protocol does not verify Recovery/Support, device control, notifications, billing, AI, realtime, native enforcement or release capability.

## 1. Evidence record format

For each check, retain only:

```text
verification id
reviewed commit SHA
staging environment identifier (non-secret)
migration version set
synthetic principal label (not token/subject)
synthetic family/resource opaque identifier where needed
observed HTTP status + error/state code
correlation/request identifier
operator, timestamp and pass/fail
```

Do not retain bearer tokens, OIDC subjects, database URLs, request body data, service keys, raw audit payloads, email addresses, child data or screenshots containing them.

## 2. Preconditions

All conditions must be true before a test request is sent:

- STG-OWN-01 through STG-QA-01 in the activation record are accepted.
- Credential Guard and Backend CI passed for the tested commit.
- The target is a staging hostname, not localhost, legacy project, production or Flutter endpoint.
- The PostgreSQL target is empty/synthetic and migration history is verified.
- Dedicated test OIDC principals exist for: primary guardian A, co-guardian B, child C and unrelated principal X.
- Test tokens are obtained through an approved secure process and kept out of source/logs/evidence.

Before valid-token or mutation checks, run the non-mutating baseline command:

```bash
STAGING_EXECUTION_ACK=synthetic-only \
STAGING_API_BASE_URL='https://approved-staging-origin' \
npm --prefix backend run verify:staging
```

It verifies liveness, readiness and denial of missing/invalid credentials only; it carries no valid identity, creates no data and cannot replace this full protocol.

After the baseline passes and only after the four synthetic Firebase Email/Password principals exist, the reviewed authenticated verifier may execute the first **intentional** mutation batch. It prompts for Guardian A and unrelated Principal X Firebase ID tokens without echoing them, creates one synthetic family, and verifies primary access, tenant isolation and idempotency. It is not a replacement for membership, continuity, audit/outbox or operations checks.

On PowerShell, run it from an up-to-date local operator checkout only:

```powershell
$env:STAGING_EXECUTION_ACK = 'synthetic-authorized-mutations'
$env:STAGING_API_BASE_URL = 'https://approved-staging-origin'
npm --prefix backend run verify:staging:authenticated
Remove-Item Env:STAGING_EXECUTION_ACK
Remove-Item Env:STAGING_API_BASE_URL
```

The verifier prints only check names, an opaque family ID and correlation IDs. Never retain or paste its prompted tokens, emails, Firebase subjects, raw request/response bodies or credentials.

After the authorization verifier passes, the membership hardening verifier creates a separate synthetic family and checks invitation revocation, post-revocation denial, active-child removal/lost access, co-guardian authority denial, primary-continuity protection and concurrent conflicting invitation control. It requires all four fresh synthetic Firebase ID tokens:

```powershell
$env:STAGING_EXECUTION_ACK = 'synthetic-authorized-mutations'
$env:STAGING_API_BASE_URL = 'https://approved-staging-origin'
npm --prefix backend run verify:staging:membership
Remove-Item Env:STAGING_EXECUTION_ACK
Remove-Item Env:STAGING_API_BASE_URL
```

A concurrency result other than exactly one successful invitation and one explicit `membership_already_exists` conflict is a stop condition. Do not correct the database manually or continue to guardian transfer tests after such a failure.

## 3. Runtime truth checks

| ID | Action | Expected result | Failure meaning |
|---|---|---|---|
| STG-RT-001 | Request `/health/live` before identity/database setup. | `200 live` only if process starts. | Runtime cannot start; do not continue. |
| STG-RT-002 | Request `/health/ready` before all config/schema is present. | `503 not_ready`; no false healthy response. | Runtime truth failure; stop. |
| STG-RT-003 | Apply all expected migrations with manifest-matching recorded checksums and configure approved OIDC/database secrets. | `/health/ready` becomes `200 ready`. | Dependency/schema/config/integrity problem; do not bypass. |
| STG-RT-004 | Remove/alter one required non-secret configuration in a controlled test. | Readiness and protected operations fail closed. | Configuration fail-open; stop. |
| STG-RT-005 | Start against a database missing an expected migration. | `503 database_schema_not_ready`. | Migration/readiness integrity failure; stop. |

## 4. Principal and tenant isolation checks

| ID | Action | Expected authoritative result |
|---|---|---|
| STG-AUTH-001 | Call a protected route without a bearer token. | `401 authentication_required` or equivalent verified-auth failure; no family information. |
| STG-AUTH-002 | Call with expired, wrong-audience or invalid-signature staging token. | `401 invalid_token`; no fallback identity. |
| STG-AUTH-003 | Create a family using primary guardian A with a unique idempotency key. | One active primary membership, family/audit/outbox evidence created atomically. |
| STG-AUTH-004 | Principal X reads/changes that family by guessed/known ID. | `403 family_access_denied` without membership/family detail leakage. |
| STG-AUTH-005 | Reuse the family creation idempotency key with identical intent. | Same authoritative outcome, no duplicate family/event. |
| STG-AUTH-006 | Reuse the same key with different intent. | `409 idempotency_key_reused`; no side effect. |
| STG-AUTH-007 | Restart/redeploy the service and repeat an already completed idempotent request. | Durable replay behavior remains correct; no in-memory-only dependency. |

## 5. Membership lifecycle checks

| ID | Action | Expected authoritative result |
|---|---|---|
| STG-MEM-001 | Primary A invites co-guardian B. | Pending membership only; no active authority for B before acceptance. |
| STG-MEM-002 | X or C attempts to accept B’s invitation. | Denied; pending membership unchanged. |
| STG-MEM-003 | B accepts under the exact verified principal. | Active co-guardian membership, version/audit/outbox update. |
| STG-MEM-004 | Co-guardian B attempts to invite/remove privileged members contrary to current policy. | Denied; no role escalation. |
| STG-MEM-005 | Primary A revokes a pending child invitation. | `revoked`; later acceptance is denied. |
| STG-MEM-006 | Primary A removes active child C. | `removed`; C immediately loses subsequent family access while evidence remains durable. |
| STG-MEM-007 | Any ordinary endpoint attempts to remove/demote the active primary. | `primary_guardian_continuity_required`; no authority gap. |
| STG-MEM-008 | Submit conflicting/repeated membership mutations concurrently using distinct keys. | At most one permitted transition persists; failures are explicit/audited. |

## 6. Guardian continuity checks

| ID | Action | Expected authoritative result |
|---|---|---|
| STG-GC-001 | Primary A creates transfer to active co-guardian B. | One `pending_acceptance` transfer with configured expiry; no role change yet. |
| STG-GC-002 | A stranger or child attempts to accept. | `403 guardian_transfer_acceptance_denied`; transfer remains pending. |
| STG-GC-003 | B accepts before expiry. | Transaction atomically changes family primary reference, A to co-guardian, B to primary, continuity case/audit/outbox state. |
| STG-GC-004 | Former A attempts to remove current primary B. | Denied; former primary cannot bypass new authority. |
| STG-GC-005 | Current primary creates a transfer then cancels it. | `cancelled`; cancelled transfer cannot later complete. |
| STG-GC-006 | Let a staging transfer expire, then attempt acceptance. | `guardian_transfer_expired`; no role/reference change. |
| STG-GC-007 | Race acceptance against revoke/remove/cancel/another transfer in controlled synthetic tests. | No two active primaries, no stale completion, explicit terminal/conflict state and durable evidence. |

## 7. Audit, outbox and privacy checks

| ID | Action | Expected authoritative result |
|---|---|---|
| STG-AUD-001 | Correlate family/membership/guardian transfer actions to database audit/outbox identifiers. | Every allowed mutation has minimal linked evidence in the same durable boundary. |
| STG-AUD-002 | Inspect service logs for test failures and accepted actions. | Logs have correlation/status/error class only; no bearer token, service key, raw subject, family payload or secret. |
| STG-AUD-003 | Confirm audit endpoint authorization as child, co-guardian and primary according to the current policy. | Child denied; permitted guardian result contains only approved audit envelope data. |
| STG-AUD-004 | Simulate outbox consumer unavailability without changing source state. | Mutation remains durable; no claim that downstream delivery/resolution occurred. |

After API audit authorization passes, the reviewed audit/outbox verifier may inspect exactly one synthetic family/correlation pair through a temporary external database `/32` entry. It starts an explicit `READ ONLY` PostgreSQL transaction and runs only the two correlation queries needed to prove durable one-to-one audit/outbox linkage and pending outbox state. It neither changes source state nor sends delivery work.

On PowerShell, use a fresh local operator checkout and an interactive terminal only:

```powershell
$env:STAGING_EXECUTION_ACK = 'synthetic-read-only-database-evidence'
npm --prefix backend run verify:staging:audit-outbox
Remove-Item Env:STAGING_EXECUTION_ACK
```

It prompts without echo for the external staging database URL, an opaque synthetic family ID and one server-generated mutation correlation ID. It prints check names and row counts only. Remove the `/32` entry immediately after it completes, successful or not; do not use this access for a database correction or a manual query batch.

## 8. Migration, backup and rollback checks

| ID | Action | Expected authoritative result |
|---|---|---|
| STG-OPS-001 | Apply migrations from empty staging database. | Ordered, checksum-attested schema history is durable and readiness succeeds only after all expected migrations. |
| STG-OPS-002 | Attempt a second migration run while the first holds the database advisory lock. | The second run fails before schema work; only one migration process can mutate history. |
| STG-OPS-003 | Deploy an API revision compatible with a later additive schema. | Controlled rollback retains safe compatibility; no manual schema edit. |
| STG-OPS-004 | Perform an approved synthetic-data backup/restore drill. | Restored environment has expected migration history and authorization invariants; test results recorded. |
| STG-OPS-005 | Force invalid database credentials or database outage. | Liveness/readiness/protected operations accurately fail; no fallback store or local identity. |
| STG-OPS-006 | Rotate/revoke a staging test OIDC principal or issuer key according to provider procedure. | Invalid/revoked tokens are rejected; no cached bypass beyond documented verification behavior. |

For STG-OPS-001/002, the reviewed local verifier obtains the same database-scoped advisory lock used by the migration runner, checks the recorded manifest/checksum set, then starts a second migration runner. The second runner must stop before schema work. It creates no schema/data change during the locked run.

On PowerShell, use an interactive local terminal and temporary `/32` database ingress only:

```powershell
$env:STAGING_EXECUTION_ACK = 'synthetic-operational-verification'
npm --prefix backend run verify:staging:migration-lock
Remove-Item Env:STAGING_EXECUTION_ACK
```

It prompts without echo for the external staging database URL and prints check names plus the migration count only. Remove `/32` immediately on completion or failure. Do not run `npm run migrate` manually as a substitute, and do not modify `schema_migrations`.

For STG-OPS-003, an actual additive schema revision exists: `004_audit_correlation.sql`. The controlled application-only rollback pair is pre-`004` commit `fc4c05f1989ac7c2f310af47cd089fe58c3942c8` and current post-`004` commit `52e81f51d83c2eaf85901ae096a6063ed2544c3d`. Before either dashboard deployment, use a fresh local checkout of that exact SHA and run its dependency install, source check and tests. In Render Dashboard, manually deploy the pre-`004` revision against the unchanged four-migration staging database; do not change environment variables and do not run migrations at build, startup, CI or manually. Wait for deployment completion, then run the non-mutating baseline verifier from that exact pre-`004` checkout. It must prove `live=200`, `ready=200` and missing/invalid-authentication denial. Next manually deploy the current post-`004` revision and run the same baseline from its exact checkout. Record only revision labels, baseline pass/fail, timestamp and restoration status. No `/32`, token, database URL, data mutation, direct database access or schema rollback is involved. Any deployment or baseline failure is a stop condition: immediately return to the last known healthy reviewed application revision, retain only a non-sensitive error class, and do not attempt a database correction.

For STG-OPS-004, use an owner-controlled fully encrypted, local and non-cloud-synced volume plus an isolated temporary PostgreSQL Docker container. This drill never restores into, resets or otherwise mutates the live staging database. It is an operator-controlled synthetic-data recovery check, not a provider-backup claim.

1. Confirm Docker is available and select a `postgres:<major>` image whose `pg_dump` client is the same major version as, or newer than, the staging PostgreSQL version. Record neither the source connection values nor Docker output.
2. Create a unique local recovery directory on the confirmed encrypted volume and a unique container name. Do not use a repository directory, a cloud-synced path, a shared mount or a published Docker port.
3. Start the restore target without `-p`/`--publish`, with `POSTGRES_HOST_AUTH_METHOD=trust` only inside this isolated disposable container, and database name `family_os_restore`. This local trust configuration is not permitted on staging, a network-exposed container or any reusable database.
4. Add the current operator's exact `/32` external database ingress immediately before the dump. Build a short-lived local `pg_service.conf` from interactive prompts for host, port, database and user; it must contain no password or full database URL. Invoke `pg_dump -W` through the matching Docker image using that service name, so the database password is entered only at the no-echo client prompt and is never placed in a command, environment variable or file. Produce a custom-format dump only in the encrypted recovery directory. Suppress and do not retain raw client/container output.
5. In a `finally` cleanup path, delete the temporary service configuration and remove the `/32` ingress immediately after the dump attempt, whether it succeeds or fails. Never use public ingress. On dump failure, also delete any partial dump and stop.
6. Copy the completed dump into the isolated target container and run `pg_restore --clean --if-exists --no-owner --no-privileges --exit-on-error`. Any restore error is a stop condition; do not correct restored rows manually.
7. Run the reviewed local verifier against the restore container only. It makes no network request and emits only check names plus migration count:

```powershell
$env:STAGING_EXECUTION_ACK = 'synthetic-operational-verification'
$env:STAGING_RESTORE_CONTAINER = 'family-os-restore-unique-local-label'
npm --prefix backend run verify:staging:backup-restore
Remove-Item Env:STAGING_EXECUTION_ACK
Remove-Item Env:STAGING_RESTORE_CONTAINER
```

The verifier requires manifest-exact migration history; one valid active primary guardian and matching family primary reference for every restored family; completed guardian transfers aligned with that primary; and one-to-one correlated audit/outbox evidence where a correlation ID is present. It accepts no source database URL, token or Firebase credential.

8. Destroy the temporary Docker container, delete the local dump and recovery directory, and verify the `/32` rule is absent. Full-disk encryption protects the temporary artifact at rest, but ordinary deletion is not a claim of physical-media sanitization. Evidence records only pass/fail, check names, migration count, timestamps and successful cleanup status.

For STG-OPS-005, first preserve the real internal database value solely in the Render Dashboard, replace `DATABASE_URL` temporarily with the syntactically valid non-secret unreachable test value below, then manually restart/redeploy the same service revision:

```text
postgresql://staging-db-outage.invalid:5432/family_os
```

Run the reviewed local outage verifier with a fresh synthetic active-guardian token:

```powershell
$env:STAGING_EXECUTION_ACK = 'synthetic-operational-verification'
$env:STAGING_API_BASE_URL = 'https://approved-staging-origin'
npm --prefix backend run verify:staging:database-outage
Remove-Item Env:STAGING_EXECUTION_ACK
Remove-Item Env:STAGING_API_BASE_URL
```

It must prove `live=200`, `ready=503 database_unavailable` and an authenticated protected request receives `503 service_not_ready`. Immediately restore the exact original internal database value in Render Dashboard, redeploy/restart, and prove `live=200` plus `ready=200`. Never put the real database value into the command, a file, chat or CI.

For STG-OPS-006, use a new disposable Firebase Email/Password synthetic principal, not an existing A/B/C/X test principal. First sign in locally and verify its current valid token is authenticated but denied as unrelated. Then disable the principal in Firebase, confirm a fresh sign-in/refresh fails, and retain no credential or Firebase identifier. A third-party stateless JWT verifier cannot immediately learn Firebase account disablement; the already-issued token may remain signature-valid until its own `exp`. After it expires, probe the same token and require `401 invalid_token`. This bounded behavior must be recorded honestly, not described as immediate server-side revocation.

On PowerShell, the reviewed local probe uses a no-echo token prompt:

```powershell
$env:STAGING_EXECUTION_ACK = 'synthetic-operational-verification'
$env:STAGING_API_BASE_URL = 'https://approved-staging-origin'
$env:STAGING_OIDC_EXPECTATION = 'valid_unrelated'
npm --prefix backend run verify:staging:oidc-principal

# After provider disablement and the original token's expiry:
$env:STAGING_OIDC_EXPECTATION = 'expired_or_invalid'
npm --prefix backend run verify:staging:oidc-principal

Remove-Item Env:STAGING_EXECUTION_ACK
Remove-Item Env:STAGING_API_BASE_URL
Remove-Item Env:STAGING_OIDC_EXPECTATION
```

No token, test password, Firebase API key or token-based probe belongs in CI/CD, source or retained logs.

## 9. Pass, block and escalation rules

### Pass

Foundation staging verification passes only when every applicable check is recorded as pass, no secret/data exposure occurred, backup/restore evidence is accepted, and all failures produce the expected fail-closed/truthful state.

### Block

Any of the following blocks staging completion and connected Flutter work:

- readiness false-positive;
- missing/unaudited mutation;
- duplicate side effect/replay flaw;
- cross-family read/write or client role escalation;
- primary-guardian invariant breach;
- unredacted secret/token/family data in logs/evidence;
- migration inconsistency, direct-database correction or untested restore;
- provider/Firebase service-account bypass; or
- a public/customer/recovery/support claim beyond test evidence.

### Escalation

Stop traffic to staging if it is exposed, preserve minimum correlation/migration/config evidence, notify the named incident owner, revoke any potentially exposed staging secret through its secret manager, and reopen the relevant activation/admission control. Do not hot-fix authority by editing database rows or accepting a bypass token.

## 10. Completion statement template

Only after all checks pass may an authorized operator record:

```text
“Foundation staging verification passed for <commit> using synthetic data only.
This verifies the listed Foundation authorization/migration/runtime checks.
It does not authorize production deployment, Recovery/Support implementation,
Flutter production claims, Native enforcement, FCM, billing, AI, realtime or release.”
```
