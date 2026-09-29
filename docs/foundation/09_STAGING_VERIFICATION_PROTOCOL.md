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

## 8. Migration, backup and rollback checks

| ID | Action | Expected authoritative result |
|---|---|---|
| STG-OPS-001 | Apply migrations from empty staging database. | Ordered, checksum-attested schema history is durable and readiness succeeds only after all expected migrations. |
| STG-OPS-002 | Attempt a second migration run while the first holds the database advisory lock. | The second run fails before schema work; only one migration process can mutate history. |
| STG-OPS-003 | Deploy an API revision compatible with a later additive schema. | Controlled rollback retains safe compatibility; no manual schema edit. |
| STG-OPS-004 | Perform an approved synthetic-data backup/restore drill. | Restored environment has expected migration history and authorization invariants; test results recorded. |
| STG-OPS-005 | Force invalid database credentials or database outage. | Liveness/readiness/protected operations accurately fail; no fallback store or local identity. |
| STG-OPS-006 | Rotate/revoke a staging test OIDC principal or issuer key according to provider procedure. | Invalid/revoked tokens are rejected; no cached bypass beyond documented verification behavior. |

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
