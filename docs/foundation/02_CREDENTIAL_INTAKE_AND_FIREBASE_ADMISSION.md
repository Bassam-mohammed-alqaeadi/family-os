# Credential Intake and Firebase Admission Record

> **Status:** Service-account key material rejected from repository and current Foundation runtime.
> **Updated:** 2026-09-29
> **Authority:** `16_RUNTIME_TRUTH_POLICY.md`, `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md`, `92_EXECUTION_AUTHORIZATION_GATE.md`

## Intake decision

The Owner supplied two files identified as Firebase Admin SDK service-account JSON credentials. These files are cryptographic private credentials, not ordinary project configuration.

They have **not** been copied into this repository, added to Render, used by the Foundation API, printed in logs, or used to select/configure a Firebase project. The current source tree contains no Firebase Admin dependency and no Firebase client/server configuration.

A repository credential guard and ignore rules now reject this category of file before it can become source control history. This is intentional even with standing Owner authorization: a private key must not become a durable application artifact, CI variable, test fixture, Flutter asset, or default deployment input.

## Why current use is rejected

The files cannot safely authorize the present Foundation Wave because they do not establish:

1. a Family OS-specific Firebase project, region, ownership, data-processing and billing record;
2. a least-privilege identity suited to a single approved capability;
3. the Firebase product/provider flow, quota and current no-cost eligibility;
4. a recovery, revocation, key-rotation, secret-access and incident-owner runbook;
5. permission to use Firestore, Functions, Storage or Firebase Admin as the product system of record; or
6. a safe separation between the prior application/project and Family OS family, child, audit and entitlement data.

A Firebase Admin service account is particularly unsuitable as a shortcut for Flutter identity, application authorization or database access. The Family OS API continues to verify an approved OIDC token server-side and keeps account/family/membership authorization in Render-owned PostgreSQL state. Standard OIDC/JWKS verification does not require committing an Admin SDK key.

## Immediate security handling

Treat both supplied keys as potentially exposed credential material because they were transferred outside their intended cloud-secret store. The Firebase/Google Cloud project owner should revoke or rotate each corresponding service-account key in the provider console, verify service impact, and update only the legitimate workload that still needs it.

No key replacement should be sent to Git, chat, Flutter assets or source files. If a later, separately approved Firebase auxiliary integration genuinely requires a credential, use a narrowly scoped service identity, store it only in the provider/Render secret manager, restrict access to the single workload, record an expiry/rotation owner, and never make it available to the Flutter client.

## What this means for Firebase Auth evaluation

Firebase Authentication on the Spark plan is now **selected only as a prospective synthetic-staging token issuer**, recorded in `10_FREE_TIER_STAGING_ADMISSION_UPDATE.md`. It is not a selected production identity/recovery system and it remains unconfigured until `STG-ID-01` and `STG-ID-02` have named owners and dated acceptance evidence.

The narrow staging use must name the exact enabled sign-in method and recovery route, confirm current pricing/quota, prohibit phone/SMS and billing-required paths, document consent/privacy and an exit path, and bind issuer/audience/JWKS values only through Render Dashboard configuration. Firebase ID-token validation by the Render API uses public signing keys and does not require an Admin SDK service-account key. This selection does not authorize Firestore, Functions, Storage, FCM, Firebase Admin, or client-side authorization.

## Existing Flutter application disposition

The prior Flutter application will not be deleted wholesale. It remains valuable implementation and UX evidence while the Render foundation is built. Broad deletion would destroy traceability and create no production capability. Instead, each legacy Firebase/mock/hard-coded surface will be audited and either:

- retained only as clearly labelled local preview/test evidence;
- replaced by a real Render API contract when that slice is authorized and configured; or
- retired through a reviewed migration/removal card after dependencies and user journeys are understood.

This preserves the user-requested product continuity while preventing the prior app’s Firebase assumptions from silently becoming Family OS production architecture.

## Automated repository safeguard

`scripts/verify-no-service-account-keys.mjs` scans tracked files for service-account key filenames/markers and for the controlled local Firebase client-configuration filenames adopted by the Flutter-connected Foundation gate, without printing file contents. `.github/workflows/credential_guard.yml` runs it on pull requests and pushes. A guard pass confirms only that no prohibited private credential or controlled client configuration is tracked; it is not an authorization to use Firebase.
