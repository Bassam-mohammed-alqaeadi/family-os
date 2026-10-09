# Staging Continuity and Reset Decision

> **Status:** Active Owner decision for the single Family OS synthetic staging track.
> **Updated:** 2026-09-29
> **Scope:** Non-production Foundation staging only. No customer data, legacy-resource reuse, Flutter production connection, Recovery/Support, or release claim is authorized.

## 1. One logical staging environment

The Owner directs Family OS to keep one **logical** isolated staging environment for ongoing Foundation experiments until a separately approved Production environment is created. This avoids parallel test environments and preserves one clear evidence trail.

This does not mean that a Free Render PostgreSQL instance can be retained indefinitely:

- a Free Render PostgreSQL resource has a provider-enforced expiry and is not a production datastore;
- no Free database resource, credential, synthetic family or test identity is carried into Production;
- when the Free database reaches its provider lifecycle boundary or must be discarded for a security/integrity reason, the Owner destroys/recreates that resource inside the same logical Staging track, records the replacement, re-applies reviewed migrations, and recreates only synthetic test data;
- this resource replacement is not a second Staging environment and does not authorize legacy/Guardian-Eye reuse or production promotion.

## 2. Current checksum-mismatch decision

The first migration attempt reported a checksum mismatch for `001_foundation.sql`. A database reset cannot remedy a source checksum mismatch because `npm run migrate` verifies reviewed migration-file content against the release manifest before it can apply that migration.

The required order is:

1. Keep external database access closed.
2. Create a fresh temporary checkout of deployed commit `091534260653d468f38898434ea63f22830290af`.
3. Run `npm ci`, `npm run check`, `npm test`, and the local migration-file SHA-256 preflight before any database connection.
4. Only if that source preflight passes, add the temporary `/32` database ingress and run `npm run migrate`.

Editing an applied migration, manifest checksum or `schema_migrations` row to force a match is prohibited.

## 3. Reset decision tree after source verification

| Condition | Authorized action |
|---|---|
| Local source preflight fails | Discard the temporary checkout. Do not expose the database, modify database objects, or retry with edited source. |
| Local source preflight passes and `npm run migrate` succeeds | Remove the temporary `/32` ingress; continue with readiness and synthetic verification. No reset is needed. |
| Local source preflight passes, but migration reports a **recorded database-history checksum mismatch** | Stop. Do not update/delete `schema_migrations` manually. Because this staging database has no accepted real data, the preferred reset is to destroy/recreate the Free Render PostgreSQL resource in the same logical Staging track, update Render's internal `DATABASE_URL`, then repeat the exact-SHA migration. |
| Provider/resource reset is required | Record new creation/expiry dates, credential rotation, migration outcome and non-secret resource identifier. Recreate synthetic data only after migrations/readiness succeed. |

A direct SQL `DROP SCHEMA` script is intentionally not the default recovery path. It cannot solve a local source checksum mismatch, makes evidence ambiguity more likely, and is less reliable than replacing a disposable Free database after explicit staging-reset approval.

## 4. Runtime truth

Before schema success, the expected condition remains:

```text
/health/live  = 200
/health/ready = 503 database_schema_not_ready
```

Only manifest-attested migrations plus complete configuration may produce `/health/ready = 200`. This decision does not turn staging into Production or authorize data carryover at launch.
