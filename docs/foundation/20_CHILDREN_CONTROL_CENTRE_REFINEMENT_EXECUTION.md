# Children Control Centre — refinement execution

> **Status:** Bounded Foundation refinement record — retained technical evidence, 2026-10-04.
> **Authority at time of record:** [`19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md`](19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md), [`../real_platform/01_CHILDREN_CONTROL_CENTRE_SLICE.md`](../real_platform/01_CHILDREN_CONTROL_CENTRE_SLICE.md), and [`../product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md`](../product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md).
> **Boundary of this evidence:** This record refines the narrow read-only roster proof. The current Global Super-App plan retains it as a base but selects and completes whole systems under [`../CURRENT_EXECUTION_PLAN.md`](../CURRENT_EXECUTION_PLAN.md).

## 1. Why this comes before owner emulator evidence

The authenticated roster adapter is necessary technical groundwork, but a working GET request does not make `SCR-FAT-012` a finished control centre. Before the Owner treats the connected flow as accepted, the screen must satisfy the product requirement for a familiar, coherent, role-aware and truthful experience.

The Owner’s direction requires the design/refinement work to happen with the vertical slice, not as an afterthought once backend connection has already been declared complete.

## 2. Audit result

### Strengths retained

- The existing `ChildrenListScreen` already has loading, empty, error/retry, Arabic-first localization, shared Family OS design tokens, role-gate concepts and an explicit distinction between local/demo provenance and runtime sources.
- The newer runtime card path avoids inventing a display profile when the roster only knows a child identifier; it shows a setup/repair state instead.
- The isolated Foundation Gate already has a typed HTTPS roster client, strict payload validation, server-authoritative denial, volatile session data and no mutation path.

### Gaps that prevent declaring the screen refined

- The normal route still has mock/local repository seams and family/role fallbacks that cannot become a remote-authoritative product path.
- Its visual hierarchy was built around an older local roster and shared-policy desk; it does not yet compose the approved remote profile-roster truth into the full, familiar Children Control Centre hierarchy.
- Device/policy presentation belongs to independent sources. The present roster endpoint deliberately has none of those facts, so a connected screen cannot display the legacy device/policy summary as if it were current.
- The isolated connected view was a secure functional shell, not yet the reusable, refined control-centre composition required by the product bar.

## 3. Required implementation order

### A. Preserve the truth boundary

- Keep the existing typed `GET /v1/families/{familyId}/children` adapter, strict UUID/path validation, transient token flow, `401` sign-out, server `403`, `503`/rate-limit and network mapping.
- Do not add a POST/PUT/PATCH/DELETE, an idempotency key, cache, telemetry, default-app import, device/policy data or a new API read.
- Do not run owner emulator acceptance while the experience remains a technical shell.

### B. Build the reusable refined surface

Create an isolated `ChildrenControlCentre` presentation module that receives only typed display state. It must:

1. use the shared Family OS tokens and familiar mobile control-centre hierarchy;
2. show a family-context header, a concise source/current-session statement, role-appropriate read-only context and an explicit profile-only boundary;
3. make child cards readable and actionable only where an authorized action actually exists—there is no fake add/edit control in this slice;
4. supply first-class loading, populated, empty/setup, access-denied, unavailable, network, retry, family-switch and sign-out states;
5. use Arabic/English copy, Directionality, semantic labels, dynamic type-safe layout and phone/tablet responsive composition; and
6. expose a stable component API that later `SCR-FAT-012` migration can reuse without importing local mock data.

### C. Connect only after the visual state contract exists

The isolated controller supplies selected family, server-returned role display context and parsed roster models to the refined surface. The API is not called by a widget. The role is never used as authorization; the server outcome controls whether the parent surface may appear.

### D. Prove the experience

Automated coverage must include:

- primary guardian roster and co-guardian read-only context;
- child/unrelated server denial with no parent card/list;
- loading, empty, `401`, `403`, `429`/`503`, invalid response, network, retry, family switch and sign-out;
- Arabic/RTL and English/LTR, compact phone, tablet width and enlarged text;
- no mutation affordance, no hard-coded device/policy/location/health state, no token/ID/raw-body rendering; and
- isolation from the default mock-first application and persistence domains.

## 4. Experience hierarchy for this slice

```text
Family context
  ├─ active family name
  ├─ server roster / current-session source truth
  ├─ guardian context (display only)
  └─ profile-only boundary

Children
  ├─ source-driven loading
  ├─ readable child profile cards
  ├─ empty/setup state
  └─ no unavailable-device or policy fiction

Recovery
  ├─ denied: no parent control surface
  ├─ unavailable/network: retry or switch family
  └─ session invalid: clear and sign in again
```

This follows familiar control-centre/list patterns under Jacob’s Law, but uses Family OS language, tokens, family context and truth boundaries rather than copying another product.

## 5. Acceptance and next operation

The refinement is complete only after code review, isolated Foundation Gate CI and full Flutter CI demonstrate the state/role/visual gates above. Only then is the next external operation allowed: Owner-only synthetic Android-emulator verification using the protected local configuration.

The operator records only the status labels already listed in plan 19. A successful emulator run proves this narrow read-only experience only; it does not authorize the default app migration or the next family capability.
