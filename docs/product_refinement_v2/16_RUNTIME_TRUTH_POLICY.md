# Runtime Truth Policy — No Fake or Hard-Coded Product Behaviour

> **Status:** Active product and engineering policy
> **Decision:** PRV2-020
> **Applies to:** Every Family OS pillar, client, backend, Native adapter, integration, test, support tool, and release claim.

## 1. Product promise

Family OS must be real, not a beautiful simulation.

A user-facing value is considered real only when the underlying state, authorization, delivery, capability, persistence, and recovery behavior exist and can be evidenced. A screen is not allowed to display success merely because a local button was pressed.

## 2. What is prohibited in production behaviour

The following must not power production user outcomes:

- Hard-coded family members, children, contacts, messages, events, tasks, lessons, reports, locations, balances, device-health states, permissions, or results.
- Fake success toast, checkmark, confirmation, delivery/read receipt, call state, location freshness, AI response, camera analysis, scoring result, or safety state.
- Static role/permission checks that are not validated against the authorized runtime family context.
- Static “AI insight,” report, chart, streak, achievement, device status, or subscription entitlement presented as current user data.
- Client-only policy mutations shown as effective on another device without an authoritative delivery/effective-state receipt.
- A hidden mock fallback that silently replaces an unavailable production service.

## 3. What remains allowed

| Allowed use | Required condition |
|---|---|
| Design tokens, layouts, localized copy, icons, static help content | These are presentation/content assets, not dynamic family/product outcomes. |
| Test fixtures and mocks | Isolated to tests, development/audit routes, or explicit demo mode; never the production default. |
| Local cache/offline state | Clearly identify source, freshness, pending sync/delivery status, and recovery path. |
| Empty/onboarding examples | Marked as examples or starter content; never impersonate a real family state. |
| Local-first functionality | May be real for the current device if persistence/recovery truth is clear; it must not claim cross-device or remote effect. |
| Feature flags | Obtained from an authorized runtime configuration source and visibly safe when unavailable. |

## 4. Runtime source hierarchy

```text
Authoritative Render service / authorized Native adapter
  → versioned local cache with source + freshness metadata
  → explicit offline/local-only state
  → empty/setup/recovery state
```

The UI must reveal which state is active when that distinction affects user trust.

## 5. Definition of a real feature

A feature can be called real only when it has:

1. Authenticated family/role/child/device scope.
2. Durable authoritative state.
3. A real mutation/action path with validation and authorization.
4. Truthful delivery/effective-state lifecycle when another device/service is involved.
5. Restart/reconnect/offline/failure/recovery behavior.
6. Activity/audit and notification relationships where relevant.
7. Automated tests and real-device/integration proof appropriate to the claim.
8. Support/diagnostic path and data/retention visibility where sensitive data is involved.

## 6. Migration rule for current local/mock-first source

Existing local repositories, mock screens, and fixtures are useful evidence and may remain during development. Each production-bound surface must later receive one of these outcomes:

- **Replace:** bind it to a real runtime repository/service.
- **Retain local:** keep it as an honestly local/offline feature with clear scope.
- **Demo only:** isolate it behind a development/demo flag and remove it from normal production routes.
- **Retire:** replace it with a real product path or remove it from the product promise.

No current mock may silently become a production data source.

## 7. Verification gate

Before a product slice changes from UI-complete to feature-complete, reviewers verify:

- No fixture or hard-coded user outcome appears on the normal production path.
- Every status label maps to a real persisted/runtime state.
- Runtime source/freshness is visible where necessary.
- Success, failure, queue, retry, unsupported, permission and recovery states are all exercised.
- Analytics/observability does not substitute for a source of truth.
