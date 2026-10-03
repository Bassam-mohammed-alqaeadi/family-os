# Children Roster — Controlled Staging Release and Verification

> **Status:** Owner-authorized for a controlled synthetic-staging release on 2026-10-03; not deployment evidence.
> **Scope:** Migration `005_family_children_roster.sql` and the narrowly scoped Children Control Centre roster API. This operation creates only synthetic families, memberships and child roster profiles. It does **not** create a child account, device enrollment, location signal or policy-enforcement receipt.

## 0. Authorization record

| Decision | Record |
|---|---|
| Owner direction | Controlled Children Roster staging release approved on 2026-10-03. |
| Authorized scope | Exact reviewed SHA, additive migration `005`, synthetic-only HTTP verifier, and optional read-only audit/outbox evidence. |
| Explicit exclusions | Flutter roster connection, remote-authoritative UI claims, device/location/policy implementation, real data, production, public/beta release and deletion tooling. |
| Completion evidence | A later operator record must contain only reviewed SHA, operator/approver, pass/fail check labels, migration/checksum outcome, readiness result and temporary-ingress removal confirmation. |

This authorization does not replace the exact-SHA preflight below and does not establish that a deployment, migration or verifier run has occurred.

## 1. Preconditions

1. The Staging Owner selects the exact reviewed branch SHA that includes migration `005`, its manifest checksum, `verify:staging:children-roster`, and passing CI. Record only the SHA and pass/fail status in the approved evidence store.
2. Follow `11_CONTROLLED_STAGING_OPERATOR_CONNECTION_CHECKLIST.md` and `03_RENDER_POSTGRES_RELEASE_AND_ROLLBACK_RUNBOOK.md`. The Render web service and database must remain synthetic-only.
3. Keep automatic deployment disabled. Render Dashboard holds `DATABASE_URL` and all OIDC settings; never put them in a shell history, repository, CI setting, transcript, screenshot or evidence record.
4. Use four fresh, distinct synthetic OIDC principals: primary guardian A, co-guardian B, child C and unrelated principal X. Their subjects, emails, tokens and raw responses are not retained.
5. Confirm the staging database has no unreviewed migration history and that a rollback/backup decision has been recorded. This migration is additive and immutable; it must never be edited after review.

## 2. Controlled sequence

1. Manually deploy the exact reviewed SHA through Render. The service Start Command remains `npm start`.
2. Confirm `/health/live` is `200`. Before migration, `/health/ready` may correctly be `503 database_schema_not_ready`.
3. In an approved short-lived operator session with protected database access, run `npm ci && npm run migrate` once against the Render staging database. Do not run migrations from application startup, build steps, GitHub Actions, or an auto-deploy hook.
4. Remove temporary migration/database ingress immediately after the migration command. Confirm `/health/live` and `/health/ready` both return `200`.
5. From a local interactive terminal, run the authenticated roster verifier. It refuses non-HTTPS/localhost targets, blank or malformed tokens, and duplicate synthetic subjects before any HTTP request:

   ```bash
   STAGING_EXECUTION_ACK=synthetic-authorized-roster-mutations \
   STAGING_API_BASE_URL='https://approved-staging-origin.example' \
   npm run verify:staging:children-roster
   ```

6. For the required durable audit/outbox correlation check, temporarily authorize the approved operator `/32` only, then run the same command with `STAGING_AUDIT_OUTBOX_ACK=synthetic-read-only-database-evidence`. The command prompts for the database URL without echo and uses a read-only transaction after the HTTP mutations succeed:

   ```bash
   STAGING_EXECUTION_ACK=synthetic-authorized-roster-mutations \
   STAGING_AUDIT_OUTBOX_ACK=synthetic-read-only-database-evidence \
   STAGING_API_BASE_URL='https://approved-staging-origin.example' \
   npm run verify:staging:children-roster
   ```

   Remove the `/32` immediately on either pass or failure. The verifier reports check labels only; do not retain its in-memory family or correlation identifiers, tokens, URLs, raw payloads or database values.

## 3. Required passing outcomes

The verifier establishes, with synthetic data only:

- primary guardian creation of a durable child roster profile;
- exact replay of that creation returns the original profile without a second `family.child_created` audit event;
- changed input under the same idempotency key is rejected;
- primary and active co-guardian roster reads are allowed, while co-guardian mutation is denied;
- child is denied the parent control-centre roster and cannot create roster profiles;
- an unrelated principal is denied;
- a second synthetic family cannot be read by the first family guardian;
- one server correlation connects the roster creation to exactly one audit event and, when the read-only evidence option is enabled, exactly one pending outbox event.

A pass is evidence for this narrow roster contract only. It is not permission to mark Flutter as remote-authoritative, use real family data, deploy to production, expose device/location facts, or claim policy delivery/enforcement.

## 4. Evidence and cleanup

Retain only the release SHA, migration-name/checksum pass/fail state, verifier check labels, timestamp and the statement that temporary ingress was removed. Do not retain account identifiers, family IDs, child IDs, JWTs, database URL, API origin, logs or request/response bodies.

The synthetic records created by this verifier follow the same bounded retention and replacement rules in `12_STAGING_EXECUTION_EVIDENCE.md`. Do not delete them with direct SQL or manually modify audit/outbox/migration records.
