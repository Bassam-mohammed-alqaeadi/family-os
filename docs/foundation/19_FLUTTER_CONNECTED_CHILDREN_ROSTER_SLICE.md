# Flutter-connected Children Roster — bounded vertical slice

> **Status:** Owner-authorized, implementation in progress — 2026-10-04
> **Authorization trigger:** Synthetic Children Roster staging PASS recorded in [`18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md`](18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md).
> **Scope:** One authenticated, read-only Children Roster view in the existing isolated Foundation Gate composition root.

## 1. Decision

The Owner has unblocked remote-authoritative Flutter integration following the controlled Children Roster staging PASS. This is a **separate, intentionally narrow decision** for the second API read that was excluded from the earlier family-discovery gate.

It authorizes only this flow:

```text
Synthetic Android-emulator Flutter session
  -> existing synthetic Firebase Email/Password sign-in
  -> existing server-authoritative GET /v1/me/families discovery
  -> user selects one server-returned active family
  -> current in-process ID token
  -> GET /v1/families/{familyId}/children over approved HTTPS staging origin
  -> truthful, volatile Children Roster view or an explicit failure/denial state
  -> sign-out clears volatile state
```

The API, not the client, remains the authority for membership, guardian eligibility, family scope and availability. The selected family ID is only an opaque server-returned route parameter; it is never entered, created or trusted by the user/client.

## 2. Included scope

- Reuse `app/lib/foundation_gate/`, its local-only configuration boundary and the synthetic Android-emulator environment accepted in [`14_FLUTTER_CONNECTED_FOUNDATION_GATE_ADMISSION_PACKET.md`](14_FLUTTER_CONNECTED_FOUNDATION_GATE_ADMISSION_PACKET.md) and [`15_FLUTTER_CONNECTED_FOUNDATION_IMPLEMENTATION_PLAN.md`](15_FLUTTER_CONNECTED_FOUNDATION_IMPLEMENTATION_PLAN.md).
- Add one typed, read-only client for `GET /v1/families/{familyId}/children`.
- Display exactly the roster projection returned by that endpoint: child display name and age. IDs and internal timestamps remain volatile implementation data and are not rendered.
- Build a polished parent Children Roster surface with family context, source truth, loading, empty, denied, unavailable, network-failure, retry, family-switch and sign-out states.
- Present primary-guardian and co-guardian differences as **server-returned display context** only; neither branch may replace server authorization.
- Protect against malformed client configuration, malformed server payloads and unsafe family-path values before a request.
- Add focused unit/widget/isolation tests and preserve the dedicated Foundation Gate CI path.

## 3. Explicit exclusions

This decision does **not** authorize:

- `POST /children`, add/edit/delete child UI, client idempotency keys, or any Flutter mutation;
- a third API read, family-detail/membership reads, invitation, revocation, guardian transfer, recovery or support flows;
- changes to the default mock-first Flutter bootstrap, local SQLite/KV state, seeded data or legacy child-list route;
- offline roster caching, background refresh/sync, local persistence, analytics, crash reporting, telemetry, screenshots, or error/body logging;
- device pairing, device health, location, battery, policy configuration/delivery/applied/verified claims, notifications, native enforcement, FCM, billing, AI, realtime, Flutter Web, iOS, physical-device distribution, production, public/beta release or real data;
- Firebase Admin, Firestore, Functions, Storage, service accounts, secrets or tracked client configuration.

A convenient feature, missing field or test account does not expand this decision.

## 4. Truthful user experience contract

The surface is a roster control centre **for profile roster truth only**. It must never imply device, policy, location, activity, health or enforcement truth that the endpoint does not provide.

| State | Required experience |
|---|---|
| Guardian receives non-empty `200` | Show the selected family context, a visible “server roster / current session” source statement, the server-returned child names and ages, and a clear statement that device/policy connections are not part of this slice. |
| Guardian receives empty `200` | Show a respectful setup-empty state. No client-side add-child action is offered. |
| Primary guardian | Identify the view as roster-only; explain that child creation and management are unavailable in this Flutter slice. |
| Co-guardian | Identify the view as read-only; do not imply that viewing grants mutation capability. |
| Child receives `403` | Show a generic access-denied state and no parent roster card, child list or family/membership detail. The server is decisive. |
| `401` | Clear all volatile family/roster state, sign out through the provider, and show a generic sign-in-again state. |
| `503` or rate limit | Clear authoritative roster state and show an unavailable state. Do not show stale roster data. |
| Network/invalid response | Show a generic connection state without the endpoint, token, body or exception detail. |

The implementation must use responsive layout, semantic labels, touch targets, dynamic type and Arabic/English copy with correct RTL/LTR direction. No server error body, correlation ID, ID token, family ID, child ID, Firebase subject, endpoint or raw timestamp is rendered.

## 5. Runtime/data boundary

- The roster source exists only in volatile controller state and is cleared on sign-out, `401`, `503`, retry reset, disposal and app restart.
- An ID token is requested from the existing provider only immediately before the roster request. It is never retained in model/controller state, logs, errors, UI, test output, clipboard or persistence.
- The client permits a roster request only for a strict UUID returned by prior family discovery and constructs the HTTPS URI without allowing an injected path/query/fragment.
- HTTP status is mapped to typed generic states. Only `200` with the exact minimal `{"children": [...]}` response shape is accepted.
- The client does not inspect token claims or decide whether a role may access the roster. The `403` result is the authorization outcome.

## 6. Required automated verification

Before an Owner-run emulator check, Foundation Gate CI must prove:

1. the typed roster client sends exactly one HTTPS GET to the selected server-returned family path with a transient bearer header;
2. a strict minimal roster response maps to volatile child view models only;
3. extra/malformed payload fields, invalid UUIDs, unexpected status codes and transport failures do not produce roster UI;
4. child/unrelated `403` produces no parent roster state;
5. `401` signs out and clears family and roster state;
6. `503`/rate limiting clears roster state rather than showing cached authority;
7. empty roster, family switch, retry and sign-out states have focused widget coverage;
8. primary/co-guardian copy does not expose a mutation affordance; and
9. source isolation still rejects default app bootstrap, local persistence, legacy domains, tracked configuration and mutation paths.

The global Flutter CI baseline remains separate and must not be weakened, bypassed or represented as green because this isolated suite passes.

## 7. Owner-only manual verification and evidence

After dedicated CI passes, the Owner may run this flow only on the approved encrypted Android-emulator workstation with synthetic identities/configuration already governed by the Foundation Gate documents.

Record labels only:

```text
synthetic guardian roster read: pass/fail
synthetic co-guardian read-only roster: pass/fail
synthetic child denial: pass/fail
empty roster state: pass/fail
401 clear/sign-out: pass/fail
503/unavailable state: pass/fail
network failure state: pass/fail
Arabic and English / phone and enlarged-text review: pass/fail
volatile state cleared on sign-out: pass/fail
local configuration retained or removed under the approved synthetic-data hold: status only
```

Do not store identities, passwords, tokens, configuration values, origins, response bodies, screenshots containing data, family/child IDs or raw logs in Git, CI, chat or evidence.

## 8. Exit boundary

A passing isolated build and Owner-only manual check establish only a synthetic, Android-emulator, read-only Flutter rendering of the already staged roster contract. They do not authorize mutations, the default app migration, local/remote data mixing, a device/policy feature claim, production or a public release.
