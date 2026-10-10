# Next work: Slice 0 — coherence fixes before Slice 2 (approved 2026-10-10)

Status: **EXECUTED 2026-10-10** on `arena/dee7af80-family-os` (stacked on `main` after PR #33). Every item in Scope 1–4 is implemented; backend `npm run check`/`npm test` and repo harness gates run in this change, and Flutter `analyze`/`test` run in CI (no Flutter/Dart toolchain in this environment). The execution record and the earlier-real-path finding are below.

Branch from `main` after PR #33 merges (or stack on `feat/safety-s1-honest-build`). Suggested branch `feat/safety-s0-coherence`.

## Scope
1. **Create family real.** `app/lib/features/n01_linking/create_family_screen.dart` defaults to `mockCreateFamilySuccess` (saves nothing). Wire it to `POST /v1/families` via `app/lib/foundation_gate/family_creation_api_client.dart` with the authenticated session; persist the server family id that add-child needs; honest loading/error/offline states; Arabic RTL. Mock stays in tests only. The owner reports create-family and add-child worked for real earlier — find out which path did that, do not break it, and document the finding.
2. **Device revoke/lost/retire** on child profile (and `/sys3-revoke-confirm`) must call the server revocation route (add the Dart client method + contract check if missing); show success only after the server confirms.
3. **Docs alignment.** `docs/CURRENT_EXECUTION_PLAN.md` and the docs still naming "Family Entry": active phase is SAFETY (owner decision 2026-10-10: all safety systems first, then two-phone test, then education). Mark `product_refinement_v2` lines calling FCM/realtime/native "unauthorized" as superseded by the owner's safety-phase approval. Record owner (Taha) approval of the fifth "on the phone" column in `AGENTS.md` §1.1. Record written Google Maps billing approval per doc 17 (owner 2026-10-10: Google Maps now; subscribe when the free quota runs out).
4. **Plan updates.** Fold coherence-map §5 into `01_SAFETY_PHASE_PLAN.md`: slice 4 needs an SOS "delivered" state migration + child push registration; slice 7 "edit place" = archive + recreate; slice 12 needs a child time-request device route. Add slice 0 checks to `PHONE_CHECKS.md` (create family on phone → exists on server; revoke device → child location rejected).

## Out of scope (logged)
- Role-system unification (phone father/mother/child vs server primary/co-guardian/child) — plan as its own slice.
- Child-profile deletion — owner decision pending (slice 3 depends on it; alternative: delete data only on revocation or guardian request).

## Gates
AGENTS.md Surface Wiring + Environment gates; full backend + Flutter tests and analyze; contract drift tests; real PostgreSQL CI.

## Owner-side risks
- Render free Postgres created 2026-09-29 → deleted ~2026-10-29. Upgrade or recreate + migrate before then.
- Rotate the Render DB password (it was shared in chat on 2026-10-10) and update `DATABASE_URL` on Render.

## Execution record (2026-10-10)

**Finding — which path did real create-family/add-child earlier (scope 1):**
- The earlier **real create-family** work ran through the backend verification tool
  `backend/scripts/verify-staging-children-roster.mjs` →
  `backend/src/children-roster-staging-verifier.js` (`createFamily()` at ~L137): it called
  `POST /v1/families` for real, then memberships/accepts/children, with idempotent replays,
  and kept honest by re-reading server state — never claiming success without the server's
  response. **Slice 0 does not touch it**; its fixtures stay as they are.
- The app-side **real add-child** path was already wired: `AddChildScreen._continue` →
  `AppScope` → `appRuntime.childProfiles.create(familyId: …)` (server
  `POST /v1/families/{familyId}/children`) with success navigation `?source=server`. It needs
  `identity.value.isRemoteAuthoritative` and a **server-issued family id** — which the old
  mock create-family (C1) could never produce. Slice 0 gives it one: create-family now runs
  `POST /v1/families` through `FamilyCreationApiClient` inside `MainAppFoundationRuntime`,
  re-discovers families, selects the created family, and only then navigates to SCR-FAT-002.
- The old default seam `mockCreateFamilySuccess` (instant "success", no persistence) is
  removed from `lib/` and lives in `app/test/features/n01_linking/create_family_mocks.dart`
  only; tests inject it explicitly.

**What shipped:**
- Create family real: `MainAppFoundationRuntime.createFamily` + `RemoteFamilyCreationSource`
  (`app/lib/core/runtime/family_creation_source.dart` port), honest loading/error/offline
  states (SHR-005 + toast `settingsPersistError` when no session), idempotency key reused per
  name across retries. No new ARB keys (CI byte-matches gen-l10n).
- Device revoke real: `FamilyDeviceApiClient.revokeDevice`
  (`POST /v1/families/{f}/children/{c}/devices/{d}/revocation`, contract `revokeFamilyChildDevice`
  already in `openapi/foundation.v1.json`), `MainAppFoundationRuntime.revokeDevice` +
  `RemoteDeviceRevocationSource` (`app/lib/core/runtime/family_device_revocation.dart`).
  Child-profile close (revoked/lost/decommissioned) and `/sys3-revoke-confirm` are
  **server-first**: success only after the server confirms; a refusal is an honest failure and
  never closes the local mirror. Reason codes: `lost | stolen | replaced | no_longer_used | other`.
- Docs: AGENTS.md §1.1 records the owner (Taha) approval of the fifth "on the phone" column;
  `product_refinement_v2` "unauthorized" lines (README, 49, 69, 82, 89) marked superseded by the
  safety-phase approval; Google Maps billing approval recorded in doc 17; "Family Entry" active
  naming in `OPEN_DECISIONS.md`/`EXECUTIVE_OPERATING_MODEL.md` marked superseded by SAFETY;
  coherence-map §5 folded into `01_SAFETY_PHASE_PLAN.md` (ش٤/ش٧/ش١٢); slice-0 phone checks (ف٠)
  added to `PHONE_CHECKS.md`.
- Tests: create-family real path (success/refusal/retry-idempotency/no-session) and device
  revocation (child profile + confirm screen, server-confirm and server-refusal) added; the
  pre-existing sys3 residual-closure flows keep their Stage-1 shape and stay green.
