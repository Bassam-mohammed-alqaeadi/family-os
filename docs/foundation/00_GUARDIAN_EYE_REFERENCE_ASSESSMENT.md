# Guardian-Eye Reference Assessment for Foundation Wave

> **Status:** Reviewed as an implementation reference; not imported as Family OS production infrastructure
> **Reviewed:** 2026-09-29
> **Source:** `Bassam-mohammed-alqaeadi/Guardian-Eye`, branch `feature/design-system-integration`
> **Scope:** Render/Firebase material made available by the Owner. This assessment preserves useful engineering evidence while enforcing Family OS decisions `PRV2-020`, `PRV2-021` and `PRV2-031`.

## 1. Reference inventory reviewed

The reference branch contains:

- A Node/Express Render web-service blueprint in `guardian_backend/render.yaml` and a backend API/test suite.
- Firebase Auth/Firestore/Functions/FCM client and server paths.
- A Firestore family/membership/device/pairing/notification data model and access-rule suite.
- Pairing, invitation, device binding, notification and backend test scenarios.
- Emulator, sync-conflict, observability and scale documentation.

No credentials, service-account key or secret was copied into Family OS. The public example key and placeholder environment files are not operational configuration.

## 2. Reusable engineering patterns

| Reference pattern | Family OS Foundation Wave use |
|---|---|
| Backend treats verified token subject—not a client role field—as the actor identity. | Retain. Render API resolves a verified principal, then authorizes family/membership/role scope in its own durable datastore. |
| Family root plus explicit membership lifecycle; client cannot self-escalate. | Retain. Use the approved primary-guardian/co-guardian/child model, not legacy gender-bound roles. |
| Time-bound invitation/pairing lifecycle with expiry, revoke, bounded retry and idempotency. | Retain as a contract/test pattern. Device pairing itself remains outside the authorized Foundation Wave. |
| Store only a pairing-code hash and reveal a plaintext code once. | Retain for the later device slice; do not add device pairing implementation now. |
| Atomic membership/device binding and conflict tests. | Retain the transaction/idempotency/cross-family testing discipline. Foundation implements only account/family/membership/audit. |
| Notification state distinguishes requested/backend accepted/failed and does not claim user receipt. | Retain. FCM implementation remains explicitly excluded from this wave. |
| Outbox, retry/backoff, bounded fanout and minimized operational logging. | Retain. Family OS will implement Render-owned outbox/audit from the beginning. |
| Tests cover unauthenticated, cross-family, expired, replay and conflict paths. | Retain and adapt to PostgreSQL/Render contracts. |

## 3. Reference paths that cannot become Family OS production paths

| Reference component | Reason | Family OS treatment |
|---|---|---|
| Firestore as family/membership/device/policy system of record | Violates `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md`. | Replace with Render-connected PostgreSQL-compatible durable state and Render authorization. |
| Firebase Cloud Functions as core workflow engine | Core/background workloads may require billing and are reserved for Render. | Replace with Render web service/outbox/worker design. |
| Firebase Storage as product storage | Explicitly excluded without a later decision. | No reuse. |
| Direct Flutter Firestore/Functions writes | Bypasses Render-owned authorization/data truth. | No reuse. Flutter will call Render API only when Foundation integration is implemented. |
| Existing Firebase project configuration/service account assumptions | Project billing, region, data, provider settings and permissions are not Family OS approval records. | Do not copy. No secret or project identifier becomes Family OS configuration. |
| FCM fanout implemented from Firebase/Functions/Firestore data | Foundation Wave excludes Firebase/FCM and notification transport. | Preserve delivery-state lessons only; revisit after a separate Firebase approval record. |
| Legacy father/mother role semantics | They are evidence from an older product, not V2 product law. | Use primary guardian/co-guardian/child scopes. |

## 4. Render reference decision

The Guardian-Eye Render service is useful evidence for a lightweight Node service with a health endpoint, environment-managed secrets and automated backend tests. Family OS will reuse those operational principles while creating a new service boundary:

```text
Family OS Flutter client
  → Render API
  → Render-authorized OIDC principal verification
  → PostgreSQL-compatible family/membership/audit/outbox state
```

Family OS does **not** reuse the reference backend’s `firebase-admin` persistence path. A new Family OS service must fail closed when identity or database configuration is absent rather than falling back to local/demo identities.

## 5. Firebase status after reference review

No Firebase SDK/integration is approved or added by this review.

Firebase Authentication may be evaluated later only as an optional token issuer under the exact constraints in `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md`: selected provider remains accepted under current no-cost terms, no phone/SMS or billing-required flow, Render owns roles/family/authorization, and an approval record covers pricing, privacy, quota, fallback and kill switch.

The reference repository alone does not establish those conditions for Family OS.

## 6. Foundation Wave implementation implications

1. Start with provider-neutral OIDC token-verification boundaries configured only through Render secrets/environment, not Firebase credentials in Flutter or Git.
2. Model account, family, membership, role scope, audit and outbox in Render-connected PostgreSQL-compatible persistence.
3. Require idempotency keys for family/membership mutations and retain append-only audit/outbox links.
4. Build contract tests for unauthorized, cross-family, stale/revoked membership, duplicate and conflict paths before a Flutter production integration.
5. Keep device pairing, FCM, billing, export/delete workers, AI and Native capabilities disabled/unimplemented until their separate authorization slices.

## 7. Decision result

Guardian-Eye is an approved **reference source for architecture, contracts, tests and operational lessons**. It is not a source of Family OS production credentials, Firebase database/functions/storage architecture or role policy. This is the precise way to use the Owner-provided second-project information without violating the active Render/Firebase and runtime-truth policies.

## 8. Controlled-staging reference re-check

**Re-checked:** 2026-09-29

**Reference revision:** `feature/design-system-integration` at `baf96afbc7d8dfbe913b37ddb970a0299f084ed0`

**Method:** Repository metadata and configuration shape only. No secret, service-account content, project identifier or environment value was copied into this repository, chat evidence or Render.

The reference still provides a useful Node web-service pattern, but its Render configuration expects Firebase project/service-account environment material and its backend depends on `firebase-admin`. Its environment documentation/configuration does not supply Family OS's required, accountable evidence for Render project/service ownership, PostgreSQL region/residency, cost limits, OIDC ownership, secret-access boundaries, rollback/restore or incident operation.

**Staging admission decision:** this re-check closes **none** of `STG-OWN-01` through `STG-QA-01`. A Firebase service-account dependency is expressly unsuitable for the Family OS Render-first Foundation boundary and is a stop condition for connected staging. The reference remains architecture evidence only; it cannot be adopted as a Family OS staging environment or configuration source.

## 9. Non-sensitive configuration-schema comparison

**Reviewed files:** `guardian_backend/render.yaml`, `guardian_backend/.env.example`, `firebase.json`, `.firebaserc`, `firebase/functions/package.json`, and `lib/core/firebase/guardian_firebase_environment.dart` at the revision above. Only file paths, configuration-key names and structural facts were inspected; no value, project identifier, API key, token, service-account material or client configuration was copied.

| Reference configuration shape | Family OS treatment |
|---|---|
| `guardian_backend/render.yaml` declares `PORT`, `FIREBASE_SERVICE_ACCOUNT_KEY` and `FIREBASE_PROJECT_ID`. It has no Render PostgreSQL resource block and no explicit automatic-deploy control. | Reuse only the generic Render `PORT` convention. Reject the Firebase Admin/project variables. Family OS uses its own PostgreSQL resource plus manual deployment with auto-deploy disabled. |
| `guardian_backend/.env.example` declares `PORT`, `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_KEY_PATH` and `RENDER_EXTERNAL_URL`. | None of its Firebase or public-endpoint variables are Family OS configuration. Do not copy them. |
| `.firebaserc` maps a Firebase project and `firebase.json`/Functions material establish a Firebase deployment surface. | Do not adopt the mapping, project or deployment configuration. Family OS uses a new, isolated synthetic Firebase Auth project only. |
| Firebase Functions dependencies include `firebase-admin` and `firebase-functions`. | Explicitly excluded. The Family OS API verifies synthetic Firebase ID tokens through public JWKS; it does not use Firebase Admin, Functions or Firebase persistence. |
| Flutter Firebase environment material belongs to the reference client. | No Flutter configuration is copied; connected Flutter work remains blocked pending staging verification. |

The Owner explicitly decided on 2026-09-29 to create **new, empty, isolated** Render and Firebase resources for Family OS staging. Existing Guardian-Eye/legacy services, databases, Firebase projects, data and configuration are not eligible for reuse, migration or linkage.

The only dashboard configuration schema for the new Family OS staging service is:

```text
NODE_ENV=staging
PORT=<Render supplied; do not manually set unless Render requires it>
DATABASE_URL=<new Family OS staging Render PostgreSQL internal URL>
OIDC_ISSUER=https://securetoken.google.com/<new-synthetic-firebase-project-id>
OIDC_AUDIENCE=<new-synthetic-firebase-project-id>
OIDC_JWKS_URL=https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
GUARDIAN_TRANSFER_TTL_HOURS=1
```

This is a schema, not a source for real values. The actual database URL and project identifier stay in the Owner-controlled provider dashboards/evidence store and never enter source control, CI logs, chat or Flutter assets.
