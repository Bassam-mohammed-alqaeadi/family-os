# Render Infrastructure Templates

`foundation-staging.render.yaml.example` is an infrastructure-as-code **template**, not a deployable Blueprint and not a claim that staging exists.

## Security properties encoded by the template

- A single Node 22 Foundation web service rooted at `backend/`.
- Explicit `npm ci`, `npm start`, liveness path and manual deploy trigger.
- A separate Render PostgreSQL database referenced through Render's `fromDatabase.connectionString`, never a committed connection string.
- Database external IP access disabled with `ipAllowList: []`; the web service uses Render private networking.
- `OIDC_*` and `GUARDIAN_TRANSFER_TTL_HOURS` are dashboard-supplied `sync: false` variables. They are not values in Git.
- No Firebase, Firebase Admin, Firestore, Storage, Functions, FCM, provider key, Flutter setting, recovery/support resource, background worker or customer-data path.

## Why it contains placeholders

`OWNER_REQUIRED_RENDER_REGION`, `OWNER_REQUIRED_WEB_PLAN` and `OWNER_REQUIRED_POSTGRES_PLAN` intentionally make the template invalid until the accountable infrastructure/cost/privacy owners accept the corresponding records in `docs/foundation/08_CONTROLLED_STAGING_ACTIVATION_RECORD.md`.

This avoids silently creating a billable resource in an unreviewed region or environment. Do not replace placeholders based on the current developer location, a legacy project, an old Render blueprint or a credential file.

## Controlled use after admission approval

1. Confirm all `STG-OWN`, `STG-ID`, `STG-SEC`, `STG-OPS` and `STG-QA` evidence records are accepted.
2. Copy/adopt the template only in the approved Render project/environment. Keep it separate from the root `render.yaml` until the review authorizes Blueprint synchronization.
3. Replace the three owner-required placeholders with approved region/plan values; perform a second review that confirms the web/database regions match.
4. Enter OIDC and transfer-policy values directly through Render's secret environment UI. Do not add values to this file or Git history.
5. Deploy the reviewed commit manually; apply migrations through the controlled runbook, then execute the staging verifier and full synthetic-data protocol.

The template does not authorize production deployment, public access, Flutter connection, Recovery/Support code or use of real family data.
