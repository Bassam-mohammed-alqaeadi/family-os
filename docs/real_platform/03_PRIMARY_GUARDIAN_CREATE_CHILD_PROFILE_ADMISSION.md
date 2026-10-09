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
| API | `POST /v1/families/{familyId}/children` with bearer identity, `Idempotency-Key`, and exactly `{ "displayName", "ageYears", "avatarEmoji", "themeColor" }`. A successful request returns `201 { "child": … }`. The presentation fields were reconciled in §6; this table now states the contract as shipped. |
| Fields | `displayName`, integer `ageYears`, and the two server-validated presentation facts `avatarEmoji` and `themeColor` (§6). No device, health, location, policy, account, provider or free-form local-only profile fact enters this request. |
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
| `400` | Keep the entered name, age and presentation choices in the form and request correction. | No local success or raw server message. |
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

## 7. Amendment — the presentation facts are contract, not display (2026-10-06)

**Second divergence found, wider than the first.** §6 reconciled this record against the shipped contract, but other documents kept describing the capability as *name-and-age only*, and one of them described the presentation facts as *local display-only*. Both statements are false against the code, and each was verified before being corrected:

| Where | It said | The code says |
|---|---|---|
| This record §2 | `{ "displayName", "ageYears" }` only | `validation.js` requires all four fields and rejects unknown ones (`onlyKnownFields`) |
| [`02`](02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md) §3 | "narrow `POST /children` foundation for **name and age**" | same |
| [`../OPEN_DECISIONS.md`](../OPEN_DECISIONS.md) decision area | "the exact **name-and-age-only** contract … are in `03`" | same, and it contradicted the D5 entry in the same file |
| [`04`](04_FAMILY_ENTRY_AUTO_POLISH.md) | keep emoji/theme "**as local display-only** until backend contract admits them" | the backend admitted them in `006_family_child_presentation.sql`, and **both clients already send them** |

**Why "local display-only" was wrong in both directions.** The facts are not local — `children_roster_api_client.dart` validates them against the closed sets and writes them into the request body, and PostgreSQL stores them under `CHECK` constraints. They are not display-only — they are the persisted identity of the child's card in the roster, which the server returns on every read.

**The one real gap this amendment does identify.** The presentation facts are fully wired everywhere except the real client's form. The prototype screen `features/n01_linking/add_child_screen.dart` has a complete picker — five emoji (`kAddChildCharacters`) and six colours (`_colorIndex`) — and sends the chosen values. The real client's form in `foundation_gate/children_control_centre.dart` passes the constants `'🧒'` and `'purple'` instead. So a guardian using the real path gets a valid, server-persisted profile, but cannot choose how it looks.

This is a **UI gap, not a contract gap**: no server, schema, validation or client-transport change is required to close it, which is why it is recorded here rather than opened as a new capability.

**Closed on 2026-10-06** on commit `b5e27f4`. Closing it also surfaced a second half of the same gap that this record had not described: the roster card never rendered the stored facts either, so a guardian who chose an avatar and a colour would have seen neither. Both halves were closed together, because closing only the form would have produced a promise the roster did not keep. Two defects were fixed in passing: the idempotency key did not cover the presentation choices, so a post-failure change of avatar would have been sent under a key the server had already answered; and the form's own hint still promised "a name and age" only.

**Evidence.** Flutter CI `37488369544` and Foundation Gate CI `37488369382` are both green on `f0e9f20`: `flutter analyze --fatal-infos` clean, and the enforcement steps are `skipped`, which happens only when no gate failed. Three tests were added, bringing this file's widget coverage to eleven: the card renders the stored facts, the form offers exactly the closed sets, and a chosen avatar and colour reach the server while changing one is a distinct logical request.

**Effect on the M0 lock.** Gate 5 of [`05`](05_M0_LOCK_RECORD.md) certified that "the admission boundary is reconciled, including presentation facts", and cited §6. That was true for this record and **only** for this record: the reconciliation left `02`, `OPEN_DECISIONS` and `04` carrying the older wording, and this amendment is what closes them. The lock itself is unaffected — no gate's evidence depended on the wording of those three documents — but the scope of gate 5 is recorded honestly here rather than left implied.
