# Family OS — Release Readiness (authoritative patch baseline)

> **Authority use:** this file is the single readiness/claim reference for current agents.  
> Scope and sequence remain in [`docs/00_MASTER_PLAN.md`](./00_MASTER_PLAN.md), and active execution remains in [`docs/CURRENT_EXECUTION_PLAN.md`](./CURRENT_EXECUTION_PLAN.md).

## 1) Current proven foundation (W1–W8)

The branch contains real server-backed vertical slices for W1→W8 (family/identity, child device onboarding, location, SOS, screen time, web filter, tasks/points, family calendar) with code on both sides:

- **Backend API/contract:** `backend/src/app.js`, `backend/src/{membership-roster.js,device-lifecycle.js,location-telemetry.js,sos-emergency.js,screen-time.js,web-filter.js,tasks.js,calendar.js}`, `backend/openapi/foundation.v1.json`
- **Flutter Foundation Gate clients/runtime:** `app/lib/foundation_gate/*api_client.dart`, `app/lib/foundation_gate/main_app_foundation_runtime.dart`
- **Journey tests/drift gates:** `backend/test/openapi-contract.test.js`, `backend/test/*.test.js`, `app/test/foundation_gate/*.dart`

## 2) Explicitly not production-complete yet

Do **not** claim the following as complete in this branch:

- Production identity/recovery UX lifecycle
- Native policy enforcement certification on real devices
- Push/SMS/call transport delivery
- Outbox consumer and external transport processing
- Real-device certification/compliance evidence
- Public production launch/release admission

## 3) Source-of-truth boundaries

- `docs/` = execution authority and operating records.
- `prototype/` = frozen UX/reference assets; route registry source is `prototype/_REGISTRY/screens.csv`.
- `family-os/` = frozen prototype/specification mirror for reference/evidence, not live execution authority.
- `docs/archive/` and historical waves = evidence only, not current execution authority.

## 4) Verification commands used for readiness claims

- Backend:
  - `npm ci --prefix backend`
  - `npm run check --prefix backend`
  - `npm test --prefix backend`
- Flutter (Foundation Gate and runtime):
  - `cd app && flutter pub get`
  - `cd app && flutter test test/foundation_gate/main_app_foundation_runtime_test.dart test/foundation_gate/family_creation_api_client_test.dart`

PostgreSQL-dependent runtime certification remains environment-gated; never claim it passed unless run on real PostgreSQL CI evidence.
