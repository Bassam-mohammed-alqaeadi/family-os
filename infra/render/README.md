# Render Infrastructure Templates

`foundation-staging.render.yaml.example` is an infrastructure-as-code **template**, not a deployable Blueprint and not a claim that staging exists.

## Security properties encoded by the template

- A single Node 22 Foundation web service rooted at `backend/`.
- Explicit `npm ci`, `npm start`, liveness path and manual deploy trigger.
- A separate Render PostgreSQL database referenced through Render's `fromDatabase.connectionString`, never a committed connection string.
- Database external IP access disabled with `ipAllowList: []`; the web service uses Render private networking.
- `OIDC_*` and `GUARDIAN_TRANSFER_TTL_HOURS` are dashboard-supplied `sync: false` variables. They are not values in Git.
- No Firebase, Firebase Admin, Firestore, Storage, Functions, FCM, provider key, Flutter setting, recovery/support resource, background worker or customer-data path.

## Why it contains selected values but remains a template

The sole approved Staging Owner accepted the temporary synthetic-staging values `oregon` and `free` in `docs/foundation/10_FREE_TIER_STAGING_ADMISSION_UPDATE.md`. The matching web/database region protects the private-network latency boundary; it is not a production-residency decision.

The `.example` filename, disabled auto-deploy, missing dashboard-only configuration and the explicit operator checklist keep this from silently creating a resource. Do not copy a legacy project, credential file, Firebase Admin key or customer-data path into it.

## Controlled use after owner admission

1. Follow `docs/foundation/11_CONTROLLED_STAGING_OPERATOR_CONNECTION_CHECKLIST.md` manually and record provider identifiers/expiry only in the approved evidence store.
2. Copy/adopt the template only in the isolated approved Render project/environment. Keep it separate from the root `render.yaml` until a deliberate Blueprint synchronization review.
3. Confirm the web/database regions both remain `oregon`, plans both remain `free`, external database IP access is disabled, and automatic deployment is off.
4. Enter OIDC, database and transfer-policy values directly through Render's secret environment UI. Do not add values to this file or Git history.
5. Verify the reviewed branch head equals the recorded release SHA, deploy manually, apply migrations through the controlled runbook, then execute the staging verifier and full synthetic-data protocol.

A GitHub connection/webhook is a Render deployment-control-plane credential only. It does not authenticate API callers and cannot replace the server's OIDC issuer/audience/JWKS checks. Keep automatic deploy disabled so a reviewed commit is selected manually.

The Owner-directed free-tier staging proposal and its remaining evidence obligations are recorded in `docs/foundation/10_FREE_TIER_STAGING_ADMISSION_UPDATE.md`.

The template does not authorize production deployment, public access, Flutter connection, Recovery/Support code or use of real family data.
