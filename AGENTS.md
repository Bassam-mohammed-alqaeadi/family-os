# AGENTS.md — Family OS root execution guard

Read **`PROJECT_EXECUTION_PLAN.md`** before significant work. Do not duplicate the roadmap here.

## Hard guards

1. **Read the plan first** — identify CURRENT PHASE and whether the request belongs there.
2. **Never silently change phase** — Owner must say `CHANGE PHASE`; then update `PROJECT_EXECUTION_PLAN.md` before proceeding.
3. **Detect and report scope drift** — PREMATURE / BLOCKED / CONFLICTING → warn Owner; do not quietly continue.
4. **KEEP + REFINE UX law** — do not redesign frozen surfaces to simplify code.
5. **Single source of truth** — never create a second authority beside the approved domain owner.
6. **Honest capability states** — distinguish UI / domain / SQLite / offline / native / remote; never convert mocks into fake production claims.
7. **Gate Backend and native** — do not start Backend/native work before its approved gate.
8. **Conflict with roadmap** — warn the Owner before editing.
9. **Owner runs verify** — Bassam runs analyze / tests / `verify_ship` and pastes results; agent decides from the paste. Do **not** run the suite as the normal path (see `.cursor/rules/owner-runs-verify.mdc`).
10. **Platform cohesion** — every system pack must prove ties to the mailbox, identity, policy, and closed loops; no isolated screens (see `.cursor/rules/platform-cohesion-partner.mdc`).
11. **Four-phase system polish** — Compare → Cover → Compete → Polish. Prototype is an incomplete baseline, not the UX ceiling.
12. **Partnership stance** — agent acts as senior engineer + strategist + UX psychologist + craft designer + power-user advocate; challenge weak ideas; protect Policy.
13. **Father control completeness** — each system’s Cover phase must leave Primary with full, flexible, real controls (mood-aligned intensity within Policy); retention = “settings desk complete enough that father will not abandon the platform” (see `.cursor/rules/platform-cohesion-partner.mdc`).
14. **Owner orients · Partner owns** — Owner ideas are orientation, not micromanagement. Agent executes full UX impact without confirmation theater; halt only on Policy ambiguity (QUESTIONS.md).
15. **UI-complete now · Backend wire later** — ship full screens/settings desks now; Local persist + honesty. Backend/Native later only wires existing controls — **zero** screen redesign or IA rearrange (Rule 25).

## Progress report (significant tasks)

```
CURRENT PHASE:
TASK PHASE:
STATUS: ALIGNED / PREMATURE / BLOCKED / CONFLICTING
REQUIRED GATE:
WILL MODIFY PRODUCTION CODE: YES/NO
```

## Current markers (see plan for detail)

* PHASE 1.5 COMPLETE  
* PHASE 1.75 COMPLETE  
* PHASE 2 COMPLETE (analysis — FS-008/009/010)  
* PHASE 3 COMPLETE (global reconciliation — docs only)  
* PHASE 4 COMPLETE (Master Implementation Plan — docs only)  
* FRONTEND COMPLETION GATE — **COMPLETE** (2026-09-25)  
* FULL FRONTEND CLOSURE — **COMPLETE** (2026-09-25; 128/130; Policy=0 · Deferred=0 · OOS=2)  
* CONTROL & EXPERIENCE LOCAL CAMPAIGN (CE-B0→B5) — **COMPLETE** (2026-09-25; Final Re-Audit + Final Frontend Gate PASSED; STOP)  
* FINAL VISUAL · UX · JOURNEY VERIFICATION — **AUTHORIZED** (2026-09-25; VX-B0→B7 PASSED) — UX verification pack **UNLOCKED** after LDR-EXIT; next: execute `user_experience_verification/` → **D-FINAL**  
* LOCAL DATA REALITY (LDR) — **COMPLETE** (2026-09-26; Owner EXIT; B0…B8; `test/ldr/` +27; verify --full +80) — see `docs/experience_discovery/final_product_experience/local_data_reality/`  
* SYS-SEC NOTIFICATIONS CORE — **COMPLETE** (2026-09-27; Owner scoped verify)  
* SYS-SEC LOCATION COVER (LOCATION-1 + LOCATION-1B) — **COMPLETE** (2026-09-28; Owner scoped verify EXIT:0 for LOCATION-1B; no-show deadline + FAT-013 location desk; Native GPS still closed)  
* SYS-SEC EMERGENCY — Cover/Compete code ready; Owner verify for EMERGENCY-COMPETE still owed when convenient  
* PHASE 5 NATIVE — NOT STARTED / NOT AUTHORIZED  
* BACKEND — NOT YET AUTHORIZED  
* NATIVE WAVES — NOT YET AUTHORIZED

## Authority anti-conflict (do not invent a second roadmap)

1. **Policy Register** (`handoff/04_POLICY_REGISTER_EN.md`) wins product law.  
2. **`PROJECT_EXECUTION_PLAN.md`** wins phase / gate / authorization.  
3. **`AGENTS.md` markers** mirror the plan — update both together when Owner ships a campaign exit.  
4. **`harness/LOOP_STATE.md`** is the live tick pointer only — never a second phase authority.  
5. **`.cursor/rules/*`** enforce workflow; they must not contradict items 1–4. On clash: stop and align docs before coding.  
6. **`verify_ship` card** = newest `CONVERSION_LOG.md` line (env `VERIFY_CARD` is ignored). Append the log line before Owner runs verify so the correct card is scoped.