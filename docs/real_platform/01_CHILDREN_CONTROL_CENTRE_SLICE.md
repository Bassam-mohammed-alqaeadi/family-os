# Children Control Centre — Real + Refined Vertical Slice

> **Status:** Active Phase-0 design and migration contract.
>
> **Screen:** `SCR-FAT-012` — Children list / parent Kids control centre.
>
> **Purpose:** Replace the current mock-first roster presentation with a truthful, role-aware and polished control centre. This contract is an implementation gate, not a promise that an unavailable device or remote state already works.

## 1. User jobs

| Member | Job | Required truthful outcome |
|---|---|---|
| Father/owner | Understand each child’s current setup, device and policy state; act or repair quickly. | Only real child/device/policy states are shown; privileged actions are authorized and audited. |
| Mother observer | Understand what applies and why, without accidental authority. | Read-only state and a clear request path where a request is allowed. |
| Mother partner | Review and approve the limited requests assigned to her. | The UI explains the exact allowed action; server/native authorization remains decisive. |
| Mother full | Manage permitted child rules in her family/child scope. | Controls show scope, status and recovery; no billing or delegation-owner authority. |
| Child | Understand rules applying to them and request a change. | Child has a separate transparency/request surface, never the parent control centre. |

## 2. Current-state audit

The existing screen already has loading, empty, error, retry, roster rows, add-child, a shared-policy sheet and local-provenance honesty. It is not yet a real control centre because it has process-global fallbacks, static role branching and can synthesize a roster entry from a device-management record (`id` as name, fixed emoji, age zero and excellent health). That synthetic projection must not survive migration.

## 3. Truth model

Every displayed child card must distinguish these independent facts:

```text
Child profile: known / setup incomplete / unavailable
Device link: none / pairing / linked / offline / repair required / unsupported
Policy lifecycle: none / configured / published / delivered / applied / verified / stale
Data origin: remote-authoritative / local-only / cached / unavailable
Freshness: observed time or explicitly unavailable
```

A card may not manufacture a display name, age, location, battery, health or policy success. Unknown information becomes a translated setup/repair/unavailable state, never a plausible value.

## 4. Visual and interaction hierarchy

```text
Family context header
  ├─ source/freshness and number of children
  ├─ quick actions: add child, link device, review requests
  └─ setup/repair attention card only when required

Child control cards
  ├─ verified child identity or explicit setup-required state
  ├─ device/capability state
  ├─ primary policy/status summary
  ├─ one important action or repair path
  └─ open child profile/control centre

Shared rules
  ├─ scope: who is included
  ├─ impact summary
  ├─ configured/published/delivered/applied/verified truth
  └─ edit/request/read-only treatment from RoleGate

Advanced / activity
  └─ change history, explanations and repair details by progressive disclosure
```

The screen must use design tokens and reusable controls; it must not add new unexplained inline visual conventions. It requires phone/tablet/landscape layouts, AR/EN, RTL/LTR, dynamic type and semantic labels.

## 5. Runtime migration contract

1. `SCR-FAT-012` obtains family/member/role context from `AppScope` runtime sources, not a normal-route global fallback.
2. A typed roster source owns roster/profile data. A device source owns device truth. A policy source owns delivery truth. The screen composes them; it does not invent missing state.
3. `PanelProfile`, `PermissionMatrix` and `RoleGate` determine presentation disposition. Backend/native mutation checks remain authoritative.
4. Empty/setup/unavailable/repair are first-class screen states.
5. Cached or local-only data is visibly labelled; it never impersonates remote authority.

## 6. Acceptance gates

- No fixed child identity, age, health, location, battery or successful policy status reaches the normal route.
- No `stage1*`/`InMemory*` normal-route fallback remains after the screen migration is complete.
- Observer, partner, full and father dispositions have focused widget coverage.
- Child never receives this parent control surface through route or in-screen fallback.
- Add/delete/link/edit actions show capability, scope and failure/recovery truth.
- Shared policy status never advances beyond evidence received from the responsible source.
- Widget tests cover loading, empty/setup, remote/local/cached/unavailable, denied/request-only, repair and error/retry states.
- Golden/device checks cover Arabic and English at phone/tablet and enlarged text before declaring visual completion.
