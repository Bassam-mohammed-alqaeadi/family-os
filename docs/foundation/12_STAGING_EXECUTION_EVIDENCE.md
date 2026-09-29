# Controlled Staging Execution Evidence

> **Status:** Active — migration retry reported successful; post-migration runtime and synthetic verification pending.
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
| Migration retry | Staging Owner reports that the corrected exact-SHA migration run completed successfully against the current synthetic staging database. | Reported pass — retain names/status only and confirm runtime health |

## 2. Evidence not yet established

The following is intentionally unverified and must not be claimed yet:

- retained non-sensitive migration-name/checksum outcome for migrations `001_foundation.sql` through `004_audit_correlation.sql`;
- readiness `200` after migration and complete identity configuration;
- confirmation that temporary `/32` ingress was removed and the migration checkout was deleted;
- Firebase synthetic-principal token verification;
- baseline staging verifier;
- authorization, tenant, lifecycle, audit/outbox and correlation protocol checks;
- encrypted logical dump/restore drill;
- test-data cleanup and environment destruction.

## 3. Next controlled operation

After the Owner-reported successful migration retry, the next controlled operation is to establish the post-migration runtime baseline. The Owner must:

1. retain only migration names/checksum outcome and pass/fail status;
2. remove the temporary database allow-list entry;
3. remove the temporary checkout;
4. report `/health/live` and `/health/ready` using status/error-code metadata only;
5. execute the non-mutating baseline verifier in `09_STAGING_VERIFICATION_PROTOCOL.md`; and
6. stop on any migration-integrity, connection, configuration or readiness failure.

This record proves reported migration execution plus the earlier pre-migration fail-closed state only. It does not yet prove a connected, identity-verified, production-ready, Flutter-connected or family-protective service.
