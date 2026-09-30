# Controlled Staging Execution Evidence

> **Status:** Active — controlled rollback and final synthetic-data cleanup remain; all other reviewed Foundation staging evidence is owner-reported complete.
> **Updated:** 2026-10-01
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
| Guardian continuity, immediate path | Owner reports successful pending transfer creation, unapproved acceptance denial, nominated co-guardian acceptance with role transition, former-primary authority denial and transfer cancellation. No API URL, resource ID, membership ID, token or raw response is retained here. | Partial pass — post-cancel, expiry and race checks remain |
| Guardian continuity, terminal/race path | Owner reports expected cancelled-transfer, one-hour-expiry and second-pending-transfer conflicts. The accept/cancel race completed safely with the former primary denied after the accepted transfer. A fresh accept/remove race completed with accepted transfer, stale former-primary denial and exactly one primary guardian. | Pass — reported full Guardian Continuity protocol |
| Audit API authorization | Owner reports audit-envelope access allowed to synthetic primary/co-guardian and denied to synthetic child/unrelated principal, with correlation IDs present. No API URL, family ID, token, subject or event payload is retained here. | Pass — reported API-boundary evidence |
| Audit/outbox durable correlation | Owner reports a read-only verifier pass for one synthetic mutation correlation: one durable audit event, one durable outbox event, one-to-one linkage, preserved server correlation and pending outbox state. Temporary database `/32` access was removed after the check. | Pass — reported database-boundary evidence |
| Log privacy review | Owner reports no accepted/denied request logs emitted for the reviewed synthetic paths and no sensitive values found. Correlation IDs remain available in API/database evidence rather than mandatory per-request logs. | Pass — reported metadata-minimizing logging behavior |
| Migration history/advisory lock | Owner reports exact four-entry manifest-attested migration history, advisory-lock acquisition and rejection of a concurrent migration before schema work. Temporary database `/32` access was removed after the check. | Pass — reported operational evidence |
| Database outage truthfulness | Owner reports controlled unreachable-database configuration resulted in liveness `200`, readiness `503 database_unavailable` and authenticated protected-operation `503 service_not_ready`; the real internal database value was restored and both health endpoints returned `200`. | Pass — reported operational evidence |
| OIDC principal lifecycle | Owner reports a disposable synthetic principal was valid-but-unrelated before disablement, fresh sign-in was denied after disablement, the same pre-disable token reached actual expiry and was rejected, no identity fallback was observed, and the principal was deleted. | Pass — reported stateless-JWT lifecycle evidence |
| Encrypted logical backup/restore | Owner reports an encrypted-at-rest synthetic logical dump using a temporary `/32`, isolated local Docker restore, manifest-attested history, guardian/primary and audit/outbox invariant passes, followed by `/32`, container and dump cleanup. | Pass — reported recovery-drill evidence |

## 2. Evidence not yet established

The following is intentionally unverified and must not be claimed yet:

- retained non-sensitive migration-name/checksum outcome for migrations `001_foundation.sql` through `004_audit_correlation.sql`;
- compatible deployment/rollback operational evidence for the existing additive `004_audit_correlation.sql` revision;
- synthetic-account/test-data cleanup at the defined lifecycle boundary.

## 3. Next controlled operation

After the reported backup/restore pass, the next controlled operation is a compatible deploy/rollback for the existing additive `004_audit_correlation.sql` revision under `09_STAGING_VERIFICATION_PROTOCOL.md`. The Owner must:

1. deploy the approved pre-`004` API revision to the unchanged synthetic staging database; this is an application rollback only, never a schema rollback or manual database change;
2. prove staging liveness, readiness and the non-mutating denied-authentication baseline on that revision, then return to the reviewed current revision and prove the same health/baseline checks;
3. retain no database URL, dump contents, tokens, email addresses, Firebase subjects, URLs or raw request/response/log bodies in evidence;
4. record only deployed revision labels, health/baseline pass/fail, restoration status, timestamps and any non-sensitive error code; and
5. stop on any deployment, readiness, authentication-baseline or restoration failure.

This record proves reported migration execution, post-migration runtime truth, authenticated authorization, membership lifecycle hardening, full guardian-continuity behavior, durable audit/outbox correlation, log privacy, migration locking, database-outage truthfulness, OIDC lifecycle behavior and backup/restore recovery. It does not yet prove compatible deployment/rollback, final synthetic-data cleanup, production readiness, Flutter connection or family-protective service operation.
