# Flutter-connected Foundation — Isolated Implementation Plan

> **Status:** Draft for Owner review — no connected client implementation or local Firebase artifact is authorized by this document alone.
> **Prerequisite evidence:** Server-side `GET /v1/me/families` is deployed and owner-reported passing on synthetic staging; isolated Foundation Gate CI is green; the legacy global Flutter CI remains explicitly red and out of this slice's scope.
> **Scope authority:** `14_FLUTTER_CONNECTED_FOUNDATION_GATE_ADMISSION_PACKET.md`.
> **Decision required:** Accept / Reject this implementation plan.

## 1. Objective

Implement the smallest Android-emulator-only, synthetic-only Flutter flow that proves a client can use Firebase Email/Password identity to call the server-authoritative Family OS Foundation API:

```text
local synthetic sign-in
  -> Firebase ID token in process
  -> GET /v1/me/families over HTTPS
  -> minimal server-returned active-family selection
  -> sign out and volatile-state clear
```

The goal is not a replacement for the existing Family OS application, not a production login, and not a UI migration. It is a contained evidence slice.

## 2. Non-negotiable boundaries

The implementation must not add or enable:

- real identities, real family/child data, Production or public distribution;
- Flutter Web, iOS, physical-device distribution, CORS changes, deep links or background operation;
- family/membership/guardian mutations, invitations, recovery, support, notifications, device control, billing, AI, realtime or offline synchronization;
- local family/audit payload persistence, SQLite/KV usage, analytics, Crashlytics, telemetry or token logging;
- Firebase Admin, Firestore, Functions, Storage, FCM or a service-account key; or
- a dependency on the legacy mock-first application bootstrap, seeded identity/family data or local role fallback.

The existing global Flutter CI remains red. The isolated `Foundation Gate CI` is a scoped acceptance signal only and must never be described as the global application CI passing.

## 3. Composition and configuration model

### 3.1 Tracked isolated entry point

Tracked code remains under:

```text
app/lib/foundation_gate/
app/test/foundation_gate/
```

The tracked `main.dart` starts an explicitly **unconfigured** safe shell. It must not import Firebase, a local configuration file, the default `app/lib/main.dart`, a local persistence package, or any legacy feature/domain bootstrap.

This guarantees that repository/CI execution never needs Firebase configuration values and cannot accidentally contact staging.

### 3.2 Local-only connected bootstrap

After this plan is accepted and only on the Owner's encrypted, non-cloud-synced Android-emulator workstation, the Owner may manually create an ignored local bootstrap file beneath:

```text
app/lib/foundation_gate/local/
```

It must be ignored by Git and rejected by configuration guard if a known Firebase client configuration file is tracked. The local bootstrap is responsible only for:

1. initializing the approved Firebase Android client SDK from the manually provisioned native Android configuration;
2. creating a typed `FoundationGateConfiguration` containing the approved HTTPS staging API origin; and
3. passing that configuration to the isolated Foundation Gate composition root.

It must not be sent to this agent, pasted in chat, committed, attached, placed in CI, copied to a script/command argument, or kept as evidence.

### 3.3 Configuration types

Tracked code may define configuration interfaces and an `UnconfiguredFoundationGateConfiguration` implementation, but it must not contain actual Firebase project values, API origins, app IDs, API keys, emails, passwords, tokens or database values.

The connected local bootstrap may provide only:

```text
Firebase SDK initialization
approved HTTPS staging API origin
```

No database host, Render internal hostname, direct PostgreSQL value or Firebase Admin endpoint is valid client configuration.

## 4. Proposed runtime components

| Component | Responsibility | Prohibited responsibility |
|---|---|---|
| `FoundationGateApp` | Own the isolated Material UI and volatile view state. | Legacy shell/bootstrap, persistence, telemetry or product navigation. |
| `FoundationGateSessionController` | Explicit finite state machine for sign-in, discovery, failure and sign-out. | Local role/family authorization or data caching. |
| `FirebaseEmailPasswordIdentity` | Ask Firebase Auth SDK to sign in/out and supply a current in-process ID token. | Logging, token export, token persistence or server authorization. |
| `FamilyDiscoveryApiClient` | HTTPS request to exactly `GET /v1/me/families`; parse the minimal response. | Calls to database/Firebase Admin, mutations or fallback identity. |
| `FoundationGateConfiguration` | Validate approved HTTPS staging origin before any request. | Carry credentials or values in tracked code. |

Dependencies may be introduced only after this plan is accepted, limited to the reviewed Firebase client packages and an HTTPS client package required for this slice. Dependency additions need a lockfile review and must pass Foundation Gate CI.

## 5. State machine and user experience

### 5.1 Allowed states

```text
unconfigured
signed_out
signing_in
loading_families
family_selected
no_active_family
sign_in_failed
session_invalid
access_denied
service_unavailable
network_unavailable
```

The default tracked entry point stops at `unconfigured`. The connected local bootstrap may enter `signed_out` only after Firebase initialization and configuration validation succeed.

### 5.2 Permitted flow

1. The user enters a **synthetic** Email/Password locally in the emulator.
2. The controller requests Firebase sign-in.
3. The controller obtains the current Firebase ID token only in process.
4. The API client makes one HTTPS `GET /v1/me/families` request with that token in `Authorization: Bearer`.
5. On `200` with one or more entries, show only server-returned `displayName` and display-only `role`; selection retains the associated family ID only in volatile state for a later authorized read.
6. On `200` with an empty collection, show a generic no-active-family state.
7. Sign-out calls Firebase sign-out and clears all in-memory email/password/token/family/selection/error detail state.

The initial implementation does **not** call `GET /v1/families/{familyId}`. That second read is deferred until the first discovery/sign-out flow has independent acceptance evidence.

### 5.3 Error mapping

| Condition | Client state | Information that must not be shown |
|---|---|---|
| Firebase sign-in failure | `sign_in_failed` | Provider raw error, email, password, token or project value. |
| API `401` | `session_invalid`, followed by state clear/sign-out | Token claims or verification detail. |
| API `403` | `access_denied` | Family/membership existence or role rationale. |
| API `503` | `service_unavailable` | Database/configuration details or cached family data. |
| Network/transport failure | `network_unavailable` | Request header, token, endpoint details or raw exception. |
| Unconfigured/invalid origin | `unconfigured` | Local configuration values. |

No exception message, response body, correlation ID, family ID, Firebase subject or request header is surfaced in UI, logs or test evidence.

## 6. Data handling and privacy rules

- Email/password fields exist only in the visible sign-in form and are cleared after every submitted attempt, success, sign-out, app state reset and disposal.
- Tokens are returned transiently from the identity adapter to the API client; they are not copied to model state, logs, analytics, error objects, clipboard, local storage, URL/deep link or test assertion output.
- The app retains no family collection beyond controller memory and clears it on sign-out, `401`, `503`, app restart and disposal.
- The client displays a role only as data returned by the server; it cannot enable a mutation or decide access.
- Test doubles use synthetic symbolic values only and never real Firebase configuration or credentials.

The Firebase SDK/OS may maintain its own provider session artifact. This plan makes no hardware-storage, device-attestation, immediate revocation or native-enforcement claim.

## 7. Required automated tests

The isolated test suite must cover with fake identity/API adapters:

1. default tracked entry is unconfigured and makes no network/Firebase call;
2. configuration rejects absent, malformed, non-HTTPS and unapproved API origins before any request;
3. successful synthetic sign-in/discovery renders only the minimal family projection;
4. empty server discovery renders a generic no-active-family state;
5. `401` clears volatile state and invokes sign-out;
6. `403`, `503` and transport failures render generic mapped states without raw error text;
7. sign-out clears volatile form/session/family state;
8. no mutation API path is present in the isolated API client; and
9. source-level guard test confirms the isolated composition does not import legacy bootstrap/local-persistence modules.

The dedicated Foundation Gate CI must analyze and run only these isolated tests successfully. Its success does not waive the global Flutter CI baseline.

## 8. Manual synthetic verification after implementation

Only after CI is green and local client configuration is manually provisioned may the Owner run the Android emulator flow with a fresh synthetic principal.

Record only:

```text
local Firebase sign-in: pass/fail
server family discovery: pass/fail
empty/unrelated behavior: pass/fail
401 handling: pass/fail
503 handling: pass/fail
sign-out volatile-state clear: pass/fail
local configuration removed/retained under approved hold: status only
```

Never record emails, passwords, tokens, family IDs, API origin, Firebase identifiers, raw API/provider bodies, screenshots containing them or local configuration file contents.

## 9. Acceptance checklist

- [ ] Owner accepts this implementation plan without scope expansion.
- [ ] Firebase provider controls and encrypted-workstation readiness are confirmed in `14_FLUTTER_CONNECTED_FOUNDATION_GATE_ADMISSION_PACKET.md`.
- [ ] Precise ignored local configuration paths and Credential Guard remain effective.
- [ ] Dependency/package review is complete before client package additions.
- [ ] Isolated implementation and all listed tests pass in Foundation Gate CI.
- [ ] No Firebase/local configuration material is tracked or sent outside the Owner workstation.
- [ ] Manual Android-emulator synthetic verification passes.
- [ ] Gate evidence is reviewed before considering any second API read or broader Flutter scope.

## 10. Owner decision

```text
Implementation plan decision: [ Accept / Reject ]
Decision date: [ YYYY-MM-DD ]
Scope changes accepted: [ none / review reference ]
```

Rejecting this plan, withdrawing the gate, an exposure, an integrity event, or reaching 2026-10-31 without a valid subsequent decision requires the retained synthetic-data cleanup procedure; it does not permit a workaround or production shortcut.
