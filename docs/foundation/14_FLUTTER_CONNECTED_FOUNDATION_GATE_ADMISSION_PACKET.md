# Flutter-connected Foundation — Gate Admission Packet

> **Status:** Draft for Owner review — no implementation authorization.
> **Decision deadline:** 2026-10-15.
> **Synthetic-data retention boundary:** 2026-10-31.
> **Scope authority:** `09_STAGING_VERIFICATION_PROTOCOL.md`, `12_STAGING_EXECUTION_EVIDENCE.md`, `02_CREDENTIAL_INTAKE_AND_FIREBASE_ADMISSION.md`.
> **Decision required:** Go / No-Go / Defer. Silence is **not** Go.

## 1. Decision requested

The Owner is asked to decide whether to authorize a tightly bounded **Flutter-connected Foundation slice** on the existing Family OS synthetic staging environment.

A `Go` decision authorizes only the work explicitly listed in this packet. It does **not** authorize production, real users, customer data, Flutter Web, iOS, native device enforcement, push notifications, background execution, offline family-data caching, billing, AI, realtime, Recovery/Support, a public release, or any broader Family OS capability.

A `No-Go` decision, or no accepted decision by 2026-10-15, starts the retained-synthetic-data retirement procedure before the 2026-10-31 deadline.

## 2. Why a separate gate is required

The Foundation API has owner-reported synthetic staging evidence for authorization, guardian continuity, migration integrity, audit/outbox correlation, runtime truth, OIDC token lifecycle, backup/restore, and compatible application rollback. That evidence establishes backend Foundation behavior only.

It does not establish that a Flutter client can:

- obtain and refresh an identity token without exposing it;
- configure Firebase Auth without accepting prohibited credential material;
- discover the signed-in principal's families safely;
- render server-authoritative authorization/availability failures safely;
- avoid storing family data or tokens in logs, analytics, crash reports or an unintended cache; or
- operate across a selected client platform without expanding the current scope.

This gate exists to resolve those client-specific admission questions before code is written.

## 3. Proposed scope

### 3.1 Included, if and only if this gate is accepted

The first slice is proposed as an **Android emulator-only, synthetic-only, read-only connected flow**:

```text
Local Flutter debug build on Android emulator
  -> Firebase Email/Password sign-in with a synthetic principal
  -> obtain Firebase ID token in process
  -> call Family OS staging API over HTTPS
  -> discover the principal's active families server-side
  -> display one selected active-family summary
  -> display explicit signed-out / 401 / 403 / 503 states
  -> sign out and clear in-app state
```

The client must treat the API as the sole authority for identity verification, family membership, role and readiness. A role returned by the API may be displayed, but never used as a client-side authorization decision.

### 3.2 Explicitly excluded

The following remain prohibited for this gate even after `Go`:

- Flutter Web, browser CORS work, iOS, physical-device distribution or store release;
- real people, child data, real family data, customer support or production identity;
- account recovery, support-mediated recovery, disputes or lost-account handling;
- family creation, invitations, acceptance, revocation, guardian transfer or any other Foundation mutation from Flutter;
- Firebase Admin SDK, service accounts, Firestore, Functions, Storage, FCM, Analytics, Crashlytics, Remote Config, App Check, billing or Google Cloud workload credentials;
- local persistence of family/audit payloads, offline mode, background sync, screenshots in test evidence, telemetry or crash-reporting export;
- hard-coded family IDs, membership IDs, roles, bearer tokens, Firebase project values or database values; and
- claims of production readiness, security certification or native enforcement.

### 3.3 Non-goals and stop rule

A new screen, a convenient SDK feature, a missing API, or a request to test a real account does not expand this gate. Any scope expansion requires a new written decision.

Stop immediately if a token, password, Firebase project value, API response body, family identifier, email address, Firebase subject, database URL or credential enters source control, CI, a retained log, a screenshot, chat or an analytics/crash-reporting sink.

## 4. Existing API gap: family discovery

### 4.1 Finding

The current API supports an authorized direct read:

```text
GET /v1/families/{familyId}
```

but it does not support secure discovery of the signed-in principal's active families. A Flutter client must not receive a hard-coded family ID, request an ID manually, or create a family simply to bootstrap the read-only flow.

### 4.2 Proposed endpoint — review only

```text
GET /v1/me/families
```

This endpoint is proposed for the gate; it does not exist and is not approved for implementation until the Owner accepts this packet.

#### Request

```text
GET /v1/me/families?limit=<1..20>&cursor=<opaque-optional>
Authorization: Bearer <Firebase ID token>
```

- `limit` is optional and defaults to a conservative server-owned value; values outside `1..20` are rejected before database evaluation.
- `cursor`, when present, is an opaque server-defined pagination token. It must not encode a Firebase subject, account ID, family ID, role, raw timestamp or any client-trusted authorization state in readable form.
- The endpoint accepts no family ID, membership ID, role, account ID or subject from the caller.

#### Successful response

```json
{
  "families": [
    {
      "id": "opaque-family-uuid",
      "displayName": "server-stored-family-name",
      "role": "primary_guardian | co_guardian | child"
    }
  ],
  "nextCursor": null
}
```

The example is structural only. It is not test data and no identifier/value belongs in evidence.

The response must contain only the minimum fields needed to select and display an active family:

- family ID for a subsequent authorized family read;
- display name for the selector/summary; and
- the current membership role for display only.

It must not return an OIDC/Firebase subject, account ID, membership ID, membership status/reason, other members, child information, audit events, timestamps, outbox state, internal versions, correlation IDs or a family state explanation.

#### Server-authoritative selection rule

The server derives the principal only from the already verified token. It joins the server-owned account, active membership and active family state. A family appears only when all of the following hold:

```text
verified principal -> matching account
matching account -> active family membership
active membership -> active family
```

Suspended/archived families and invited, revoked or removed memberships are omitted. The endpoint returns `200` with an empty `families` collection when the verified principal has no eligible active family; it does not disclose whether another account/family/membership exists.

#### Required failure behavior

| Condition | Required result |
|---|---|
| Missing, malformed, expired, wrong-audience or invalid-signature token | Existing fail-closed `401` verified-auth error; no identity fallback. |
| Valid token with no eligible family | `200` with an empty collection only. |
| Runtime/database not ready | Existing `503 service_not_ready`; no local fallback or stale cached family data. |
| Invalid limit/cursor | Explicit client-input validation error before store evaluation; no family detail. |
| Read request | No mutation, no idempotency key requirement, no outbox work and no fabricated audit write. |

Existing defensive response headers (`Cache-Control: no-store`, `Referrer-Policy: no-referrer`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`) continue to apply.

### 4.3 Data and performance review requirement

The current schema already has active-membership constraints, but its existing lookup index is not automatically proof that principal-first family discovery performs acceptably at a broader scale. The gate may implement a measured synthetic query plan and, only if justified, propose a reviewed additive index migration.

No index, migration or schema change is authorized by this packet draft. A later additive migration would require its own manifest, compatibility, deployment and verification review; it is not to be created merely to satisfy this gate.

### 4.4 Required API verification before Flutter connection

Before any Flutter client uses the endpoint, backend work must include:

1. OpenAPI contract update and contract coverage test;
2. direct API tests proving primary/co-guardian/child discovery is limited to the caller's active families;
3. tests proving unrelated, removed, revoked and invited identities receive no family data;
4. suspension/archive tests proving ineligible family state is not discoverable through the endpoint;
5. input-boundary tests for `limit` and cursor;
6. readiness and invalid-token fail-closed tests; and
7. a log/privacy review confirming no token, subject, email, response body or identifier is emitted.

The approved backend branch must pass Credential Guard and Backend CI before deployment. Any staging operation remains synthetic-only and uses the existing controlled release procedure.

## 5. Firebase material and client-configuration policy

### 5.1 Classification

| Category | Examples | Policy |
|---|---|---|
| **Private credentials — prohibited** | Firebase/Google service-account JSON, private keys, passwords, ID tokens, refresh tokens, database URLs | Never in Flutter source/assets, repository, CI, chat, logs, screenshots, command arguments or environment variables. Never requested by this gate. |
| **Controlled client configuration — locally provisioned only** | Android Firebase app configuration, Firebase app/project identifiers, client API key, staging API origin | These values are not server-authority credentials, but are controlled project metadata for this program. They are not pasted into chat, Git, CI, public docs, logs or committed source. |
| **Server runtime configuration — Dashboard only** | OIDC issuer/audience/JWKS endpoint, Render `DATABASE_URL` | Remains manually injected only through Render Dashboard. Flutter does not receive database configuration and does not configure API authorization. |

No classification converts a client API key into a secret or into an authorization mechanism. API key restrictions reduce accidental misuse; server-side OIDC verification and Family OS authorization remain mandatory.

### 5.2 Required local provisioning pattern

If this gate is accepted, Firebase Android client configuration may be provisioned **manually by the Owner** from the isolated Family OS Firebase project to an encrypted local development workstation only.

Before any local file is obtained:

1. add a precise Git ignore rule for the native Firebase configuration file and any generated local Flutter options file;
2. verify with `git status --ignored` and Credential Guard that no configuration/private material is tracked;
3. use a local, untracked configuration path only; do not copy values into Dart source, launch scripts, `--dart-define`, CI variables, `.env`, test fixtures, screenshots or issue comments;
4. prevent IDE, shell history, diagnostics and crash/analytics SDKs from exporting the values; and
5. remove the local configuration file when the gate ends, synthetic staging is retired, or an exposure is suspected.

The configuration file must never be supplied to this agent, committed, attached, copied into a shared workspace or retained as gate evidence.

### 5.3 Firebase provider controls required before local use

The Owner must confirm in Firebase/Google Cloud Dashboard, without recording project values here:

- only Email/Password is enabled for the synthetic staging project;
- phone/SMS, anonymous sign-in and unapproved federated providers remain disabled;
- no Firebase Admin key is created, imported or used for this client flow;
- no Firestore, Functions, Storage, FCM, Analytics, Crashlytics or other excluded product is enabled for this slice;
- any Android client API key has the narrowest provider-supported Android application and API restrictions compatible with Firebase Auth; and
- an exposure response is defined: disable/rotate the affected client configuration where possible, delete local files, revoke/disable synthetic identities as appropriate, and suspend the gate pending review.

Do not claim that Android application/API restrictions replace authentication or authorization.

### 5.4 Token handling rules

Flutter must obtain the token only through the Firebase Auth SDK in process and send it only as an HTTPS `Authorization: Bearer` header to the approved staging origin.

The first slice must:

- keep tokens out of logs, exceptions, diagnostics, analytics, crash reports, deep links, screenshots, clipboard and persistence;
- keep family/audit response payloads in volatile in-memory view state only;
- clear in-app state on sign-out, authentication failure, readiness failure and app restart for this first slice;
- never parse a token to derive a local role or family authorization decision; and
- handle `401`, `403` and `503` as server-authoritative states with generic, non-enumerating UX.

A mobile OS/SDK may retain its own provider session artifacts. This packet does not claim hardware-backed storage, device attestation, native enforcement or immediate provider-side token revocation.

## 6. Platform and networking boundary

### 6.1 Proposed platform

The proposal is Android emulator only. It avoids silently admitting Flutter Web/browser CORS behavior, iOS signing/provisioning, device distribution, push/deep-link paths and physical-device data retention.

A later platform must receive its own admission decision.

### 6.2 Network boundary

- The client calls the approved HTTPS staging API origin only; it never calls `localhost`, a database host, Render internal hostname or Firebase Admin endpoint.
- The client uses no direct PostgreSQL connection and no `/32` database ingress.
- The server, not the client, verifies Firebase tokens against the configured issuer/audience/JWKS policy.
- Flutter Web is out of scope. No CORS policy change is authorized by this packet.
- The client must fail closed with a generic unavailable state if the configured API origin is absent, malformed, non-HTTPS or outside the approved staging origin.

## 7. UX and error-state contract

The first connected slice must make server truth visible without leaking data:

| Server state | Client treatment |
|---|---|
| Valid identity, active family | Show only the server-returned minimal family summary. |
| Valid identity, no eligible family | Show a generic empty state; do not imply whether prior/revoked/invited memberships exist. |
| `401` | Clear volatile session view and show a generic sign-in-again state. |
| `403` | Show a generic access-denied state; do not display family/membership existence details. |
| `503` | Show a generic temporarily-unavailable state; do not use cached family data as authority. |
| Network failure | Show a generic connection failure; do not retry mutations because no mutations are in scope. |

No server error body, token claim, correlation ID, family ID, email address or Firebase subject is shown in the UI or retained as test evidence.

## 8. Entry criteria for implementation

A `Go` decision requires all of the following to be accepted and recorded by label/status only:

- [ ] Owner accepts this packet's Android-emulator, synthetic-only, read-only scope.
- [ ] Owner accepts the 2026-10-15 decision deadline and 2026-10-31 cleanup boundary.
- [ ] Firebase client configuration policy is accepted, including no Git/CI/chat/log handling and local removal requirement.
- [ ] Provider controls in section 5.3 are confirmed without recording configuration values.
- [ ] The exact approved staging API origin is manually provisioned locally without being committed or reported.
- [ ] The proposed family-discovery contract is accepted or explicitly rejected with an alternative server-authoritative bootstrap design.
- [ ] Any API implementation receives separate backend review, tests, CI and controlled staging deployment.
- [ ] Flutter design names no mutation path, no role-enforcement logic, no cache/offline mode and no telemetry sink.
- [ ] A named Owner accepts responsibility for local synthetic identities, emulator cleanup and the retention deadline.

Any unchecked entry criterion is a `No-Go` for implementation.

## 9. Success criteria for the later connected verification

If implementation is accepted later, the connected verification must prove only:

1. a synthetic Email/Password principal can sign in locally without credential/token logging;
2. the API, not Flutter, determines authenticated family discovery;
3. unrelated/no-membership identities receive an empty non-enumerating result or the documented generic denial state;
4. invalid/expired token causes safe `401` treatment with no identity fallback;
5. unavailable runtime causes safe `503` treatment with no cached-authority fallback;
6. sign-out clears application view state; and
7. no prohibited material appears in Git, CI, logs, screenshots or retained evidence.

This verification does not authorize a public beta, real user test, production environment or release.

## 10. Decision and deadline

| Decision | Meaning | Required next action |
|---|---|---|
| **Go** | Authorize only the scoped design/API/Flutter implementation process above. | Create a separately reviewed implementation plan; do not skip backend/API tests or security configuration review. |
| **No-Go** | Do not implement the client slice. | Retire retained synthetic principals/test data under `12_STAGING_EXECUTION_EVIDENCE.md` before 2026-10-31. |
| **Defer** | No implementation authorization. | Treat as No-Go unless the Owner explicitly renews the retention decision before the cleanup boundary; no automatic extension exists. |

```text
Owner decision: [ Go / No-Go / Defer ]
Decision date: [ YYYY-MM-DD ]
Scope changes accepted: [ none / listed review reference ]
```

A decision must be recorded no later than **2026-10-15**. Without an accepted Go decision, no Flutter-connected work begins and the retained synthetic staging environment proceeds to cleanup by **2026-10-31**.
