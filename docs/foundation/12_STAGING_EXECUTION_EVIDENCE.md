# Controlled Staging Execution Evidence

> **Status:** Active — runtime, authentication/authorization, membership hardening and immediate guardian-continuity checks reported; remaining continuity, audit/outbox and operations verification pending.
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
| Guardian continuity, immediate path | Owner reports successful pending transfer creation, unapproved acceptance denial, nominated co-guardian acceptance with role transition, former-primary authority denial and transfer cancellation. No API URL, resource ID, membership ID, token or raw response is retained here. | Partial pass — post-cancel, expiry and race checks remain |
| Guardian continuity, terminal/race path | Owner reports expected cancelled-transfer, one-hour-expiry and second-pending-transfer conflicts. The accept/cancel race completed safely with the former primary denied after the accepted transfer. A later purported accept/remove race used an unknown removal route and returned `404 route_not_found`; acceptance completed, but no removal raced it. | Incomplete — rerun with the reviewed `revoke` endpoint before acceptance |

## 2. Evidence not yet established

The following is intentionally unverified and must not be claimed yet:

- retained non-sensitive migration-name/checksum outcome for migrations `001_foundation.sql` through `004_audit_correlation.sql`;
- guardian-continuity post-cancellation acceptance denial, one-hour expiry/no-role-change behavior and controlled race behavior;
- audit/outbox and correlation protocol checks;
- encrypted logical dump/restore drill;
- synthetic-account/test-data cleanup at the defined lifecycle boundary.

## 3. Next controlled operation

After the reported membership and immediate guardian-continuity passes, the next controlled operation is to complete guardian continuity under `09_STAGING_VERIFICATION_PROTOCOL.md`. The Owner must:

1. retain only completed check names, opaque resource identifiers, HTTP status/error codes, correlation identifiers, timestamps and pass/fail status;
2. preserve the passing post-cancellation, expiry, second-pending and accept/cancel outcomes as minimal evidence;
3. create a new synthetic family/transfer and rerun the accept/remove race against the reviewed deployed API. The removal operation is `POST /v1/families/{familyId}/memberships/{candidateMembershipId}/revoke` with an approved non-sensitive `reasonCode`; there is no `/remove` route. Report separately which operation returned which HTTP status/error code and whether the winning membership response was `removed` or the winning transfer response was `completed`;
4. stop if `500`, dual-primary behavior or any other unreviewed code recurs; do not change database rows, schema, server clock or configuration to force a result;
5. retain no tokens, email addresses, Firebase subjects or raw request/response bodies in evidence; and
6. stop on any authorization, tenant-isolation, idempotency, lifecycle, audit/outbox or runtime-truth failure.

This record proves reported migration execution, post-migration runtime truth, authenticated authorization, membership lifecycle hardening and immediate guardian-continuity behavior only. It does not yet prove complete continuity, audit/outbox integrity, operational recovery, production readiness, Flutter connection or family-protective service operation.
