# Controlled Staging Execution Evidence

> **Status:** Active — post-migration runtime and non-mutating baseline pass reported; authenticated synthetic verification pending.
> **Updated:** 2026-09-29
> **Scope:** Family OS synthetic Foundation staging only. This record contains no database URL, credential, token, Firebase project identifier, test account identifier, raw payload or customer data.
> **Procedure:** `11_CONTROLLED_STAGING_OPERATOR_CONNECTION_CHECKLIST.md`

## 1. Owner-reported pre-migration evidence

| Evidence item | Recorded result | State |
|---|---|---|
| Staging database credential | A previously exposed credential was treated as compromised and rotated by the Staging Owner in Render. No credential value is recorded. | Pass — rotation reported |
| Service deployment | Manual deployment of `091534260653d468f38898434ea63f22830290af`. | Pass — deployed |
| Start command | `npm start`; no migration command was added to startup/build. | Pass |
| Render process | Running/live after deployment. | Pass |
| `/health/live` | `200 OK`. | Pass |
| `/health/ready` | `503` with `database_schema_not_ready` before migrations. | Pass — expected fail-closed state |
| Temporary migration ingress | External database access is currently closed after the Staging Owner removed a temporary broad rule and rotated the database credential. A public rule is not an accepted migration fallback. | Pass — closed; `/32` only after source preflight |
| First migration attempt | Failed with `migration_checksum_mismatch` for `001_foundation.sql`. No migration is treated as applied and no database history was edited. | Historical attempt — did not establish schema |
| Fresh source preflight | Exact deployed SHA, clean working tree, full test suite and reviewed `001_foundation.sql` checksum all reported as passing after Windows line-ending correction. | Pass |
| Migration retry | Staging Owner reports that the corrected exact-SHA migration run completed successfully against the current synthetic staging database. | Reported pass — retain names/status only |
| Temporary migration controls | Owner reports that temporary `/32` database ingress and the short-lived migration checkout were removed. | Pass — reported cleanup |
| Post-migration liveness | `/health/live` returned `200 OK`. | Pass — reported |
| Post-migration readiness | `/health/ready` returned `200 OK`. | Pass — reported |
| Non-mutating baseline verifier | Owner reports the baseline verifier passed. It tested health plus missing/invalid-token denial without valid identities or mutations. | Pass — reported |
| Synthetic identity availability | Owner reports successful Firebase Email/Password sign-in and ID-token issuance for the four designated synthetic principal labels (A, B, C and X). No identifiers, emails, tokens or project values are retained here. | Pass — authentication only; no Family OS role/authorization claim |
| Authorization and tenant isolation | Owner reports successful reviewed checks for primary-family creation/read, unrelated-principal denial and idempotent/conflicting request behavior. | Pass — reported; synthetic authorization evidence |
| Membership happy paths | Owner reports primary invitation and exact-principal acceptance for synthetic co-guardian and child membership, plus unrelated-principal membership denial. | Pass — reported |
| Membership hardening | Owner reports that the ten-check reviewed membership lifecycle verifier passed, including revocation/removal, authority boundaries and controlled concurrent-invitation behavior. No API URL, resource ID, token, email, subject or raw response is retained here. | Pass — reported |
| Token/CI handling | Owner confirms that authenticated checks used local interactive hidden prompts only. No Firebase ID token, synthetic password or Firebase Web API key entered CI/CD, source control or retained logs. | Pass — interactive-only boundary confirmed |

## 2. Evidence not yet established

The following is intentionally unverified and must not be claimed yet:

- retained non-sensitive migration-name/checksum outcome for migrations `001_foundation.sql` through `004_audit_correlation.sql`;
- Firebase synthetic-principal token verification;
- guardian-continuity, audit/outbox and correlation protocol checks;
- encrypted logical dump/restore drill;
- synthetic-account/test-data cleanup at the defined lifecycle boundary.

## 3. Next controlled operation

After the reported migration/runtime/baseline pass, the next controlled operation is authenticated synthetic verification under `09_STAGING_VERIFICATION_PROTOCOL.md`. The Owner must:

1. retain only the completed check names, opaque resource identifiers, HTTP status/error codes, correlation identifiers, timestamps and pass/fail status;
2. execute the remaining membership hardening checks before any guardian-transfer mutation: revoke a pending invitation, deny later acceptance, remove an active child and confirm immediate access loss, deny co-guardian escalation/removal authority, deny ordinary primary removal, and test controlled conflicting mutations;
3. retain no tokens, email addresses, Firebase subjects or raw request/response bodies in evidence; and
4. stop on any authorization, tenant-isolation, idempotency, lifecycle, audit/outbox or runtime-truth failure.

This record proves reported migration execution, post-migration runtime truth and a non-mutating denied-authentication baseline only. It does not yet prove a connected, identity-verified, production-ready, Flutter-connected or family-protective service.
