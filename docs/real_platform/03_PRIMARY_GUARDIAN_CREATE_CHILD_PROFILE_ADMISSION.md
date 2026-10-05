# Capability admission — Primary Guardian Create Child Profile

> **System:** Family Entry & Children Control.
>
> **Admission:** Approved by the product owner on **2026-10-04** for real implementation.
>
> **Scope:** One bounded, server-backed vertical slice: a primary guardian creates a child profile with **`displayName`** and **`ageYears`** only.
>
> **Authority:** [`../../AGENTS.md`](../../AGENTS.md), the [current execution plan](../CURRENT_EXECUTION_PLAN.md), and the [Cover specification](02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md).

## 1. Decision and user outcome

The primary guardian can select an authorized family, enter a child's name and age, submit one idempotent request, and see the **refreshed server roster** only after the backend confirms the change. A co-guardian does not receive the creation affordance; the backend remains the final authorization decision in every case.

This admission authorizes implementation of the narrow contract already present in the Node.js/Express and PostgreSQL foundation. It does **not** authorize a broad child-management surface.

## 2. Exact contract boundary

| Area | Admitted rule |
|---|---|
| API | `POST /v1/families/{familyId}/children` with bearer identity, `Idempotency-Key`, and exactly `{ "displayName", "ageYears" }`. A successful request returns `201 { "child": … }`. |
| Fields | `displayName` and integer `ageYears` only. No avatar, colour, device, health, location, policy, account, provider or local-only profile fact enters this request. |
| Authorization | Node.js/Express verifies the authenticated principal and primary-guardian membership. Flutter role data only determines whether to offer the action and can never grant authority. |
| Scope | The family ID comes only from the server-discovered selected family context; no manually entered or guessed family scope is accepted. |
| Idempotency | A UUID-shaped opaque key is kept for retries of unchanged sheet input. Altering the logical request creates a new key. Server replay and changed-payload conflict remain authoritative. |
| Durable outcome | PostgreSQL persists the accepted child, and the existing audit/outbox behavior records the mutation. Flutter does not write local roster state. After `201`, it reloads the roster from the server. |
| Result privacy | UI exposes no token, internal child/family ID, raw response/error body, request fingerprint or audit/outbox details. |

## 3. Required state and recovery behavior

| Outcome | User-facing handling | Data/authority rule |
|---|---|---|
| Pending | Creation submit control is disabled; navigation actions are not allowed to interleave the request. | No success is shown yet. |
| `201` then roster read succeeds | Child profile confirmation and refreshed roster. | The roster comes from a fresh server `GET`, not client insertion. |
| `201` then roster read is unavailable or malformed | Explain that saving succeeded but roster refresh is unavailable; provide the existing roster retry route. | Clear roster rather than presenting an older collection as current. |
| `400` | Keep name/age in the form and request correction. | No local success or raw server message. |
| `401` / invalid session | Clear volatile family/roster context and require sign-in again. | No persisted identity or prior family context. |
| `403` | Remove roster detail and show server-denied state. | A primary-looking discovery role never overrides the server. |
| `409` | Keep safe form input and explain that this attempt cannot be confirmed. | The caller may revise the logical request, which obtains a fresh key. |
| `429` / `503` / network / malformed response | Keep safe form input and offer retry with the same logical request. | No stale roster is represented as current. |

## 4. Explicit exclusions

This admission does **not** include child detail, profile edit/delete, guardian invitation, child sign-in, device enrollment, Android services, policy enforcement, location, health/activity, AI, providers, notifications, production rollout or default-route migration. Those each require their own source, role, privacy, operations and acceptance decision.

The isolated Foundation Gate remains a separately configured synthetic/staging composition root. This work does not claim that `foundation_gate/main.dart` is the default product route or that it has production configuration.

## 5. Implementation evidence required for this slice

- typed Flutter `POST` client and bounded JSON parsing;
- local form validation plus server-result mapping with no error-body disclosure;
- retry-stable idempotency semantics;
- controller orchestration that reloads the server roster after confirmed creation;
- primary-only accessible AR/EN, RTL/LTR form affordance and co-guardian omission;
- API/client/controller/widget tests for success, authorization denial, conflict, validation, unavailable/network and refresh failure;
- Node.js/Express backend test regression run confirming existing authorization, idempotency, audit and outbox behavior.

A successful implementation changes this capability's status, not the status of the larger Family Entry & Children Control system. The wider Cover/Compete/Polish/Lock gates and the migration/release decisions remain open.

## 6. Amendment — presentation facts reconciled (2026-10-05)

**Divergence found.** §2 of this record admitted `displayName` and `ageYears` only, and explicitly excluded avatar and colour from the request. The shipped contract had already moved past that wording: `006_family_child_presentation.sql` added durable `avatar_emoji` and `theme_color` columns with constraints, `backend/src/validation.js` requires both fields, and the typed Flutter client sends them. The record was stale, not the code.

**Reconciliation.** This amendment records what the contract is, rather than silently widening it. The admitted v1 body is:

```json
{ "displayName": "…", "ageYears": 8, "avatarEmoji": "🧒", "themeColor": "purple" }
```

**Why the risk is acceptable, stated plainly.** Both facts are non-identifying presentation choices: a single emoji and one of six fixed colour tokens, each server-validated against a closed set (`[purple, sky, amber, coral, mint, teal]`, emoji 1–32 characters containing an Extended_Pictographic). Neither reveals a location, contact, health state, device, school or any other sensitive category, and neither becomes a personal-data expansion under COPPA/GDPR-K data-minimization expectations. The data-minimization intent of the original exclusion is preserved: the request still carries no free-form profile fact beyond a display name and an age band.

**Effect on scope.** Nothing else moves. The exclusion of child detail, edit/delete, device enrollment, policy, location, AI and providers remains exactly as written in §4. A reversal of this amendment is a one-line change in `backend/src/validation.js` plus the client call site, so the owner can still close this door cheaply; the open decision is recorded in [`../OPEN_DECISIONS.md`](../OPEN_DECISIONS.md).
