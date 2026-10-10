# Next work: Slice 0 — coherence fixes before Slice 2 (approved 2026-10-10)

Status: NOT STARTED. Written so any agent can resume. Read `RESUME.md`, `01_SAFETY_PHASE_PLAN.md`, then `02_PLATFORM_COHERENCE_MAP.md` (§3 conflicts, §5 slice impacts) first.

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
