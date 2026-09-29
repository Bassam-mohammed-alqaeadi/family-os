# Free-Tier Controlled Staging Admission Update

> **Status:** Owner admission accepted for manual synthetic-staging connection; connected staging is not yet created.
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

The selection was subsequently accepted by the Owner who issued the 2026-09-29 staging attestations. That Owner is the sole accountable operator for infrastructure, security, cost, identity, operations, QA/privacy, test-data cleanup, and incident coordination for this synthetic environment. The owner assignment is recorded in Section 5; it does not claim that a provider resource or secret has already been configured.

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

The enabled staging sign-in method is **Email/Password only** for synthetic test accounts. Phone/SMS, real-user accounts, Firebase recovery claims and all other providers are excluded. The Owner must create/revoke the synthetic principals, retain tokens only in the approved operator session, and record only the protocol's minimal non-secret evidence. No valid Firebase token should be copied into chat, source control, Render logs, test evidence, or Flutter assets.

## 4. Remaining admission evidence

| Record | Accepted owner decision | Execution evidence still required |
|---|---|---|
| STG-OWN-01 | The single Staging Owner owns the Render service, database and incident coordination. Oregon is approved for this synthetic environment. | Record the actual Render organization/project and non-secret service identifier after creation. |
| STG-OWN-02 | The single Staging Owner approves Oregon for disposable synthetic data and authorizes reset/destruction within 30 days. | Record the created database identifier, creation date and scheduled destruction date. |
| STG-OWN-03 | The single Staging Owner accepts Free web/PostgreSQL limits and owns costs. No paid upgrade is authorized by this record. | Capture dashboard usage/spend-control state and the shutdown action before traffic is allowed. |
| STG-ID-01 | Firebase Auth Spark is approved only as the synthetic Email/Password test-token issuer under the single Staging Owner. | Record the Family OS-specific synthetic Firebase project identifier and review issuer/audience/JWKS values in the Render dashboard. |
| STG-ID-02 | The single Staging Owner creates/revokes only synthetic Email/Password principals; phone/SMS and real users are prohibited. | Record the synthetic-principal labels and revocation/cleanup result without tokens, subjects or email addresses. |
| STG-SEC-01 | The single Staging Owner is the only secret-access holder. Secrets are dashboard-only; no break-glass path is authorized. | Record dashboard access review plus rotation/revocation action without secret values. |
| STG-OPS-01 | The single Staging Owner is migration, rollback and logical dump/restore operator. Dump artifacts are encrypted in an owner-controlled store outside Git, chat, Render logs and source. | Execute and record a synthetic-only migration, restore drill, deletion date and minimal pass/fail evidence. |
| STG-QA-01 | The single Staging Owner is verification and QA/privacy operator. Only synthetic data may be retained, no later than environment destruction. | Record test-data creation, cleanup and destruction confirmation using opaque identifiers only. |

## 5. Owner attestation accepted

On **2026-09-29**, the Owner accepted sole accountability for this environment's infrastructure, security, cost, identity, operations, QA/privacy, incident coordination, synthetic-data destruction, and the encrypted external logical dump/restore store. The Owner also approved all of the following:

- a temporary synthetic-only environment that is deleted within 30 days;
- Render Free Web Service and Free PostgreSQL in Oregon;
- manual, owner-operated logical dump/restore rather than a provider backup feature; and
- Firebase Auth Spark synthetic Email/Password principals only, with no SMS, phone or real-user accounts; and
- no reuse, migration, linkage or configuration copying from existing Guardian-Eye/legacy Render, database or Firebase resources. New Family OS-specific synthetic resources are required.

This is dated admission evidence for the decisions in Section 4. It does not create a Render/Firebase resource, expose a secret, or make a production/recovery/Flutter claim.

## 6. Controlled next action

The pre-connection operator checklist is `11_CONTROLLED_STAGING_OPERATOR_CONNECTION_CHECKLIST.md`. It prepares a manual, one-commit-at-a-time connection without automatic deploys. The Owner must record the actual provider identifiers, expiry/deletion date and dashboard access/usage evidence at execution time. After resources and configuration genuinely exist, execute the activation and verification protocol; do not infer success from a configured dashboard form.

Current truthful state:

```text
Owner admission: accepted for synthetic staging
Connected Render/Firebase staging: not created
Application identity verification: intentionally unconfigured
Flutter connection: not authorized
```
