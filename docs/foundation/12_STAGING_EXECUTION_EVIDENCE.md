# Controlled Staging Execution Evidence

> **Status:** Active — pre-migration runtime evidence recorded; migrations and synthetic verification pending.
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
| Fresh source preflight | Exact deployed SHA, clean working tree, full test suite and reviewed `001_foundation.sql` checksum all reported as passing after Windows line-ending correction. | Pass — retry current database migration before considering reset |

## 2. Evidence not yet established

The following is intentionally unverified and must not be claimed yet:

- migrations `001_foundation.sql` through `004_audit_correlation.sql` applied with manifest-matching checksums;
- readiness `200` after migration and complete identity configuration;
- Firebase synthetic-principal token verification;
- baseline staging verifier;
- authorization, tenant, lifecycle, audit/outbox and correlation protocol checks;
- encrypted logical dump/restore drill;
- test-data cleanup and environment destruction.

## 3. Next controlled operation

The Staging Owner must first use a short-lived checkout of the exact deployed SHA to execute `npm ci`, `npm run check` and `npm test` **without any database ingress**. The source checksum preflight must pass before a temporary `/32` entry is added and `npm run migrate` is attempted again. Afterward, the Owner must:

1. retain only migration names/checksum outcome and pass/fail status;
2. remove the temporary database allow-list entry;
3. remove the temporary checkout;
4. report `/health/live` and `/health/ready` using status/error-code metadata only; and
5. stop on any migration-integrity, connection, configuration or readiness failure.

This record proves a pre-migration fail-closed state only. It does not prove a connected, verified, production-ready, Flutter-connected or family-protective service.
