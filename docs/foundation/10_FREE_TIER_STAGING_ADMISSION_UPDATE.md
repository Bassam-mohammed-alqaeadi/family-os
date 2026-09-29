# Free-Tier Controlled Staging Admission Update

> **Status:** Owner-directed platform/provider selection recorded; connected staging remains blocked.
> **Updated:** 2026-09-29
> **Scope:** Disposable, synthetic Foundation verification only. This is not a production, beta, customer, Flutter-connected, Recovery/Support, or release decision.
> **Authority:** Owner direction; `05_SYSTEM_OPERATING_PROMPT.md`; `08_CONTROLLED_STAGING_ACTIVATION_RECORD.md`.

## 1. Selection recorded

| Area | Owner-directed selection | Admission state |
|---|---|---|
| Hosting | Render | Selected for controlled staging only. |
| Web compute | Render Free Web Service | Candidate for a disposable synthetic environment only. |
| Durable state | Render Free PostgreSQL | Candidate for a disposable synthetic environment only. |
| Candidate region | Oregon | Selected from the Owner-provided Oregon/Frankfurt alternatives for the test environment. The web service and database must be co-located. This is a performance-oriented test choice, not a production residency finding. |
| Test token issuer | Firebase Authentication, Spark plan | Selected only as a prospective source of synthetic test ID tokens. |
| Secrets | Render Dashboard environment configuration | Required. No secret is placed in Git, Flutter, chat, fixture, CI output, or the Blueprint. |
| Source deployment link | GitHub connection to Render | Allowed only as a deployment-control-plane connection; automatic deployment remains disabled for controlled staging. |

The selection does **not** name an accountable infrastructure, cost, privacy, identity, operations, security, or QA owner. Consequently, it does not by itself close any `STG-*` record.

## 2. Free-tier boundary

Render's free plans are compatible only with a **temporary synthetic test environment**. They are not accepted for production. The free web service can spin down after inactivity and can restart; the free PostgreSQL offering is limited to one active free database per workspace, 1 GB storage, no provider backups, and expires after 30 days. The database is deleted after its post-expiry grace period unless upgraded.

Accordingly:

1. The environment must be labelled disposable and contain only synthetic accounts/families.
2. An owner must record the expected expiration date, destruction decision, workspace usage/spend controls, and cleanup confirmation before creation.
3. `STG-OPS-01` cannot pass merely because Free PostgreSQL exists: the operator must separately approve and execute a synthetic-only logical backup/restore drill or select a plan with suitable backup controls.
4. A Free service's sleep, restart, lack of shell/one-off jobs, and lack of high availability are expected staging constraints—not evidence of a runtime defect or a production-ready operating model.

## 3. Firebase Authentication test-issuer boundary

Firebase Authentication on Spark is selected only for synthetic test principals. It does **not** authorize Firebase Admin, Firestore, Realtime Database, Storage, Functions, FCM, phone/SMS authentication, client-side family authority, or any Firebase data store as Family OS truth.

The existing API still requires server-side verified identity for every protected route. GitHub deployment credentials/webhooks authenticate Render's access to source code; they do not authenticate a Family OS user or replace application token verification.

For a later approved synthetic Firebase project, Firebase ID-token verification can use the existing provider-neutral verifier with dashboard-configured values only:

```text
OIDC_ISSUER=https://securetoken.google.com/<synthetic-firebase-project-id>
OIDC_AUDIENCE=<synthetic-firebase-project-id>
OIDC_JWKS_URL=https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
```

`<synthetic-firebase-project-id>` is not a secret, but it is deliberately not recorded here until an identity owner creates and approves a Family OS-specific synthetic project. The public JWKS endpoint contains signing public keys; it is not a substitute for, or reason to retain, an Admin SDK service-account key. The API independently verifies issuer, audience, token signature, expiry, and subject before it maps the subject to Render/PostgreSQL-owned family authority.

The exact enabled sign-in method, test-principal creation/revocation process, recovery/compromise treatment, token handling procedure, retention, and project owner remain open under `STG-ID-01` and `STG-ID-02`. No valid Firebase token should be copied into chat, source control, Render logs, test evidence, or Flutter assets.

## 4. Remaining admission evidence

| Record | Current state after this update | Still required before resource creation |
|---|---|---|
| STG-OWN-01 | Platform and candidate region selected; owner not named. | Render organization/project, service owner, incident contact. |
| STG-OWN-02 | Oregon selected for synthetic staging; privacy/destruction owner not named. | Residency rationale, database owner, reset/destruction approval. |
| STG-OWN-03 | Free plans selected; cost control is incomplete. | Cost owner, workspace usage/spend thresholds, shutdown rule, acknowledgement of free-tier expiry. |
| STG-ID-01 | Firebase Auth Spark selected as a synthetic token-issuer candidate. | Family OS-specific test project, identity owner, issuer/audience/JWKS review, test-client ownership. |
| STG-ID-02 | Open. | Synthetic-principal lifecycle, revocation, token custody and no-real-user assurance. |
| STG-SEC-01 | Dashboard-only secret placement selected. | Named secret-access list, rotation/revocation procedure, break-glass prohibition. |
| STG-OPS-01 | Free tier prevents a provider-backup assumption. | Migration operator, rollback approver, synthetic logical backup/restore procedure, evidence store, incident route. |
| STG-QA-01 | Synthetic-only rule selected. | QA/privacy owner, verification operator, retention/cleanup evidence and destruction confirmation. |

## 5. Controlled next action

Do not create Render resources, connect Firebase credentials, set a project identifier, or enable an automatic deployment until all records above have named owners and dated acceptance evidence. Once that exists, use the existing non-deployable Render template with `autoDeployTrigger: 'off'`, enter the non-source configuration manually in the Render dashboard, deploy one reviewed commit manually, and follow the activation and verification protocol.

Until then, the truthful state is:

```text
Platform/provider selection: recorded
Connected Render/Firebase staging: not created
Application identity verification: intentionally unconfigured
Flutter connection: not authorized
```
