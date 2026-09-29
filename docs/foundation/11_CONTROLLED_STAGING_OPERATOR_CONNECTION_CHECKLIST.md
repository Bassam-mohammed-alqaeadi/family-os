# Controlled Staging Operator Connection Checklist

> **Status:** Ready for manual execution by the sole approved Staging Owner.
> **Updated:** 2026-09-29
> **Scope:** One disposable, synthetic Foundation staging environment. This checklist creates no resource by itself and does not authorize production, Flutter, Recovery/Support, customer data, Firebase Admin, Firestore, Functions, Storage, FCM, SMS, or public release claims.
> **Admission record:** `10_FREE_TIER_STAGING_ADMISSION_UPDATE.md`.

## 1. Execution rules

- Execute only in the approved Owner's Render/Firebase dashboards and approved encrypted operator workstation/store.
- Do not paste a password, token, database URL, service-account key, Firebase project identifier, raw payload, email address, or dump content into Git, chat, source files, CI output, screenshots, or this checklist.
- Record only the verification protocol's minimal metadata: timestamp, reviewed commit, opaque provider/resource identifier, status/error code, correlation/request identifier, operator and pass/fail.
- Keep the service and PostgreSQL database in **Oregon**. The Free plans are temporary test resources, not a release architecture.
- Keep automatic Render deploys disabled. A GitHub connection permits source retrieval only; every staging deployment remains a deliberate selection of one reviewed commit.
- Use the Foundation's current reviewed release commit. At execution, record that exact SHA rather than assuming the branch head is approved.

## 2. Render creation — owner-operated

1. In Render, create or select the isolated staging project owned by the Staging Owner. Do not use a legacy/customer/production project.
2. Create one Render PostgreSQL database:
   - region: `oregon`;
   - plan: `free`;
   - external IP allow list: private-only according to the approved template;
   - data: synthetic only;
   - record its non-secret provider identifier, creation date and destruction date no later than 30 days after creation.
3. Connect the GitHub repository through the Owner's Render dashboard and create the Foundation web service:
   - branch/reviewed commit: select manually at deployment time;
   - root directory: `backend`;
   - runtime: Node 22;
   - build: `npm ci`;
   - start: `npm start`;
   - liveness: `/health/live`;
   - region: `oregon`;
   - plan: `free`;
   - automatic deploy: disabled.
4. Use Render's internal database connection for `DATABASE_URL`. Do not copy either internal or external database URL into any repository, command history, evidence record, log, or chat.
5. Before allowing test traffic, set/verify the workspace usage and spend controls. No paid upgrade is authorized by this staging record. If the Free environment reaches a provider limit, suspend/tear it down instead of bypassing the cost boundary.

## 3. Firebase Authentication — owner-operated synthetic issuer

1. Create or select a **Family OS-specific synthetic Firebase project** on the Spark plan. It must not be a legacy, customer, production, or Guardian-Eye project.
2. Enable **Email/Password** only for synthetic test principals. Do not enable phone/SMS or use real people, real email identities, Firebase Admin, Firestore, Functions, Storage, FCM, or other Firebase products.
3. Create only the four protocol roles as synthetic identities: primary guardian A, co-guardian B, child C and unrelated principal X. Keep real email addresses, Firebase UIDs and tokens out of evidence.
4. Configure Render Dashboard environment values manually:

```text
NODE_ENV=staging
DATABASE_URL=<Render internal database URL>
OIDC_ISSUER=https://securetoken.google.com/<synthetic-firebase-project-id>
OIDC_AUDIENCE=<synthetic-firebase-project-id>
OIDC_JWKS_URL=https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
GUARDIAN_TRANSFER_TTL_HOURS=1
```

`GUARDIAN_TRANSFER_TTL_HOURS=1` is an explicitly staging-only value to make the expiry verification practical. It is not a production policy selection. The project identifier is configuration metadata, but record it only in the Owner-controlled provider evidence—not in the repository or this checklist.

5. Verify `/health/live` can report process liveness, while `/health/ready` remains `503` until database, all migrations and the complete identity configuration are genuinely available. A GitHub webhook is never an identity substitute.

## 4. Migrate, then establish runtime truth

1. With the service deployed but before valid-token mutation testing, run the reviewed `npm run migrate` command manually from an approved operator environment using the protected staging database connection. Do not add migration execution to application startup, builds, GitHub Actions or an automatic deploy hook. In particular, do **not** change the Render Start Command to `npm run migrate && npm start`: Free services can restart, so that would turn a reviewed release operation into a restart-time side effect.
2. If the Owner has no existing local source checkout, use the short-lived checkout protocol in Section 4.1. GitHub remains the source of the reviewed code; this creates no permanent source copy and needs no CI secret.
3. Record the migration manifest version/checksum set, not database credentials.
4. Confirm `/health/ready` is `200` only after all expected migrations, database connection and complete Firebase-token verification configuration exist.
5. Execute the non-mutating baseline verifier from `09_STAGING_VERIFICATION_PROTOCOL.md`. It must not create data or carry a valid token.
6. Only after the baseline passes, run the full synthetic verification protocol. Stop immediately on any false-ready, authorization, migration, audit/outbox, log-exposure, cost or backup/restore failure.

### 4.1 Short-lived checkout protocol when no local source exists

This is the approved migration path for the stated situation. Use an Owner-controlled workstation with Node 22 and an encrypted filesystem; do not use a shared shell, public notebook or CI runner.

1. Keep external database access closed while preparing the checkout. A public `0.0.0.0/0` rule is never an acceptable timeout workaround. If a temporary `/32` allow-list entry fails, stop and diagnose the IP/routing/URL path; do not widen the database exposure.
2. In a temporary directory, clone/fetch the exact GitHub release commit manually. Verify `git rev-parse HEAD` equals the SHA shown by the manual Render deployment before installing dependencies. Do not use `main`, a legacy branch or an unreviewed branch head.
3. Before opening any external database ingress, change into `backend/` and run `npm ci`, `npm run check`, and `npm test`. This validates the migration manifest/checksums without connecting to the database. For release `091534260653d468f38898434ea63f22830290af`, `db/migrations/001_foundation.sql` must hash to `18614988686dda9fbf71d79d9a75fe8da513e1e1c8f2763169ae20cc306d14e9`. A failure here is a source-integrity stop condition: discard the temporary checkout and create a fresh exact-SHA checkout; never edit the migration, manifest or database history to force a match.
4. Only after the source preflight passes, add a temporary allow-list entry for the workstation's current public IP only. Obtain the **external** staging connection value directly from Render; do not copy it into chat, source, shell history or an evidence record. Then supply it through the shell's secret-input mechanism. On a POSIX shell, the safe pattern is:

```bash
read -r -s DATABASE_URL
export DATABASE_URL
npm run migrate
unset DATABASE_URL
```

Do not paste the value into the command itself. Use the equivalent no-echo secret-input mechanism on another operating system.
5. Retain only the emitted migration names/checksum result and pass/fail status. If migration fails, do not paste raw errors that could disclose connection details; stop and record the error class only.
6. Remove the temporary external allow-list entry after the migration attempt. Remove the temporary checkout after its evidence is recorded. The application continues using Render's internal database connection only.

The migration runner itself acquires an advisory lock, verifies each reviewed SQL checksum, records checksum-attested history and rolls back a failed migration. That safety does not authorize repeated migration attempts from a service Start Command.

### 4.2 Interpret the pre-migration service state correctly

For the reviewed Foundation server, absent tables/schema metadata should yield `/health/live = 200` and `/health/ready = 503` with a fail-closed `database_schema_not_ready` dependency state. The Node process does not intentionally exit merely because migrations are absent. If Render reports an exited process instead, stop and retain only its non-sensitive exit/status classification; do not attribute it to schema absence without evidence.

## 5. External logical dump/restore drill

Free Render PostgreSQL does not provide provider backups. The Owner-approved replacement is a manual, synthetic-only logical dump/restore drill.

1. Complete the intended synthetic verification checkpoint first and record minimal non-secret evidence.
2. From an approved operator environment, create a logical PostgreSQL dump using the protected database connection already available to the operator. Encrypt the artifact at rest and place it only in the Owner-controlled encrypted store; never in Git, Render disk, CI, chat or logs.
3. Record artifact creation time, encryption/retention confirmation, source migration set and an opaque artifact reference. Do not record the database URL, path containing sensitive data, or dump contents.
4. At an approved synthetic reset point, restore into the same disposable staging database or a separately approved synthetic restore target. Do not restore into a production, legacy or customer system.
5. Re-check migration history, `/health/ready`, missing/invalid-token denial and the authorization invariants after restoration. Record pass/fail only.
6. Delete the dump after the Owner's documented retention period, always no later than environment destruction. Record deletion confirmation without retaining contents.

## 6. Teardown and truthful closure

- Delete Firebase synthetic users and remove/revoke the associated test project/access where appropriate.
- Destroy the Render web service and free PostgreSQL database by the recorded deadline, or earlier if any control fails.
- Delete the encrypted dump by its approved deadline and retain only the minimum non-sensitive verification evidence.
- A completed checklist can support the statement “Foundation staging verification passed using synthetic data only” only after every applicable check in `09_STAGING_VERIFICATION_PROTOCOL.md` is passed. It never authorizes production, public onboarding, Flutter integration, recovery/support, native enforcement, billing, FCM, realtime or release.
