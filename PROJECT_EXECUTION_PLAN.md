# FAMILY OS — PROJECT EXECUTION PLAN

**Authority:** Authoritative human-readable execution roadmap for Guardian Eye Pro / Family OS.  
**Owner changes:** Require explicit `CHANGE PHASE` before treating the roadmap as changed.  
**Last governance install:** 2026-09-24

---

## CURRENT POSITION

We began with a complete web prototype containing:

* 42 systems
* 240 services
* 73 journeys
* 130 screens

Cursor converted that prototype into Flutter primarily as a **UI/mock/simulation implementation**.

The current objective is NOT to throw away that prototype.

The approved strategy is:

**Web Prototype**  
→ **Flutter Prototype**  
→ **Real Local Flutter Runtime**  
→ **Complete policies / domains / missing UI**  
→ **Native platform capabilities**  
→ **Backend / Sync**  
→ **Production certification**

---

## CURRENT STATE (authoritative)

| Marker | Status |
|--------|--------|
| `PHASE 1.5 COMPLETE` | Yes (FS-001 → FS-007 reconciliation evidenced) |
| `PHASE 1.75 COMPLETE` | Yes — residual LOCAL debt closed; see `docs/experience_discovery/PHASE_1_75_LANE_ACCEPTANCE.md` |
| `PHASE 2 COMPLETE` | Yes (analysis 2026-09-25) — see `docs/experience_discovery/PHASE_2_ACCEPTANCE.md` |
| `FS-008 → FS-010 ANALYSIS CONTINUES` | **No** — FS-008/009/010 analysis accepted; OPEN items listed in acceptance |
| `PHASE 3` | **COMPLETE** (2026-09-25) — nine maps + gap register; see `docs/experience_discovery/PHASE_3_ACCEPTANCE.md` |
| `PHASE 4` | **COMPLETE** (2026-09-25) — Master Implementation Plan; see `docs/experience_discovery/PHASE_4_ACCEPTANCE.md` |
| `FRONTEND COMPLETION GATE` | **COMPLETE** (2026-09-25) — superseded by Full Frontend Closure |
| `FULL FRONTEND CLOSURE` | **COMPLETE** (2026-09-25) — 128/130 FRONTEND COMPLETE; 0 POLICY · 0 DEFERRED · 2 OOS; Native/Backend still closed |
| `CONTROL & EXPERIENCE LOCAL CAMPAIGN (CE-B0→B5)` | **COMPLETE** (2026-09-25) — Final Re-Audit + Final Frontend Gate PASSED; STOP (recorded here retroactively; see `docs/experience_discovery/final_product_experience/FINAL_RE_AUDIT.md`) |
| `FINAL VISUAL · UX · JOURNEY VERIFICATION` | **AUTHORIZED** (Owner D12, 2026-09-25) — VX-B0…B7 **PASSED**. UX verification pack **UNLOCKED** after LDR-EXIT → execute → **D-FINAL** |
| `LOCAL DATA REALITY (LDR)` | **COMPLETE** (Owner EXIT, 2026-09-26; B0…B8; `test/ldr/` +27; verify --full +80). Docs: `docs/experience_discovery/final_product_experience/local_data_reality/` |
| `GLOBAL IMPLEMENTATION PLAN NOT YET AUTHORIZED` | **No** — Phase 4 Master Plan complete; Frontend Completion Gate authorizes Local/UI deepen only |
| `FULL CODEGEN NOT YET AUTHORIZED` | **Partial** — Frontend + Local experience codegen authorized; Native/Backend codegen still closed |
| `BACKEND INTEGRATION NOT YET AUTHORIZED` | Yes |
| `NATIVE WAVE NOT YET AUTHORIZED` | Yes |

Do not mark any of these as complete unless later evidence proves it.

---

## PHASE 1 — COMPLETE SYSTEM DESIGN

Continue analytical/design work across:

`FS-001 → FS-010`

For every system establish:

* requirements
* policies
* domain ownership
* data ownership
* events
* contracts
* cross-system dependencies
* UX surfaces
* RBAC
* offline behavior
* native requirements
* backend requirements
* testing requirements

**NO** broad production implementation before the design gates justify it.

---

## PHASE 1.5 — UX + IMPLEMENTATION RECONCILIATION

This phase has already been performed for:

`FS-001 → FS-007`

Evidence includes:

* `docs/experience_discovery/FAMILY_OS_SCREEN_BEFORE_AFTER_UX_AUDIT.md`
* `FS_001_007_IMPLEMENTATION_GAP_MATRIX.md`
* `FS_001_007_RECONCILIATION_REPORT.md`

Current findings include under-bound Stage-1 repositories, duplicate authority risks, verification conflicts, and unimplemented native/remote capability planes.

---

## PHASE 1.75 — REAL FLUTTER RUNTIME CONVERSION

**STATUS: COMPLETE** (residual LOCAL debt closed 2026-09-25).  
Next phase is **not started** until Owner authorizes.

### Objective

Convert the existing Flutter simulation into a **real local Flutter application/runtime**, without redesigning or discarding the existing product experience.

This means progressively replacing simulation-only foundations with real:

* Flutter state management
* Riverpod state
* Domain services
* repositories
* SQLite persistence
* Outbox
* Local Event Bus
* policy evaluation
* audit records
* restart-safe state
* offline behavior
* local cross-system contracts

### Goal

**Real Local Application**

### Not the goal (yet)

**Full Native/Backend Production System**

---

## CRITICAL DISTINCTION

The following are **NOT** the same thing:

`UI implemented`  
≠ `Domain implemented`  
≠ `SQLite persisted`  
≠ `Offline resilient`  
≠ `Native OS enforced`  
≠ `Backend synchronized`

Never report one as another.

Capability states must remain honest:

* REAL LOCAL
* LOCAL ONLY
* MOCK-REMOTE
* NOT IMPLEMENTED
* NOT CONFIGURED
* UNSUPPORTED
* REMOTE UNIMPLEMENTED

---

## FS-001 → FS-007 POLICY

Use the reconciled FS-001 → FS-007 implementation as the **first proving ground** for the Real Flutter Runtime.

* Do **NOT** treat them as evidence that the whole product is complete.
* Do **NOT** freeze the project only around FS-001 → FS-007.
* Continue analytical work on `FS-008 → FS-010` and the broader 42-system product inventory.

---

## DO NOT DO THESE PREMATURELY

Until the relevant design/dependency gates are complete:

* Do not implement all 42 systems blindly.
* Do not convert every PlaceholderScreen just to increase completion percentages.
* Do not invent policies for systems not yet analyzed.
* Do not introduce new duplicate repositories.
* Do not create a second authority beside the approved domain owner.
* Do not replace architecture simply because the current code is imperfect.
* Do not begin full Backend integration prematurely.
* Do not claim native enforcement when the native plane is absent.
* Do not claim cloud functionality when transport/cloud implementation is absent.
* Do not redesign frozen KEEP/REFINE screens merely to simplify implementation.

---

## GLOBAL ROADMAP AFTER PHASE 1.75

After Real Local Flutter Runtime conversion progresses sufficiently:

## PHASE 2

**STATUS: COMPLETE** (Owner `CHANGE PHASE` 2026-09-25; analysis accepted same day).  
**Mode completed:** Analysis / design / L2–L3 / inventory reconciliation only.  
**Not authorized still:** production codegen · NAT · REM · Phase 3+ until Owner `CHANGE PHASE`.

FS-008 One-Way Audio · FS-009 PDF Activity Reports · FS-010 Ephemeral Family Chat (durable; ephemeral transport) — packs under `docs/experience_discovery/fs008_*` / `fs009_*` / `fs010_*`. Acceptance: `PHASE_2_ACCEPTANCE.md`.

### PHASE 3

**STATUS: COMPLETE** (Owner `CHANGE PHASE` 2026-09-25; accepted same day).  
**Mode completed:** Read-only global reconciliation maps.  
**Not authorized still:** production codegen · NAT · REM · Phase 4+ until Owner `CHANGE PHASE`.

Global reconciliation delivered:

* System Map
* Domain/Policy Ownership Map
* Data Ownership Map
* Event/Contract Map
* Screen Map
* Journey Integrity Map
* Native Capability Map
* Backend Capability Map
* Full Dependency Graph
* Gap Register

Evidence: `docs/experience_discovery/phase3_reconciliation/` + `PHASE_3_ACCEPTANCE.md` + `.verify/PHASE-3-COMPLETE.json`.

### PHASE 4

**STATUS: COMPLETE** (Owner `CHANGE PHASE` 2026-09-25; accepted same day).  
**Mode completed:** Planning / architecture-to-execution reconciliation — Master Implementation Plan.  
**Not authorized still:** production codegen · NAT waves · REM/backend · Phase 5+ until Owner `CHANGE PHASE`.

Create the real dependency-first implementation graph.

Do **NOT** implement strictly by FS number.

Evidence: `docs/experience_discovery/phase4_master_plan/` + `PHASE_4_ACCEPTANCE.md` + `.verify/PHASE-4-COMPLETE.json`.

### FRONTEND COMPLETION GATE (PRE-NATIVE / PRE-BACKEND)

**STATUS: COMPLETE** (2026-09-25).  
Evidence: `docs/experience_discovery/FRONTEND_COMPLETION_MATRIX.md` · `.verify/FRONTEND_COMPLETION_GATE_COMPLETE.json`.  
**Exit met.** Do **not** auto-enter Phase 5 Native — await Owner.  

**Objective:** Complete Frontend + Local Product Experience across 42/240/73/130 before Native or Backend waves.

**Authorized:** UI reachability · state management · domain/local bind · SQLite where already owned · seeded coherent fixtures · loading/empty/error/offline/stale · role/RBAC · AR/EN RTL · capability honesty · focused tests · real-device UI checks.

**Forbidden:** Native planes (GPS, VPN/DNS, Accessibility, Device Admin, MediaProjection, mic, OS wake/enforcement) · Backend/Remote (Render, Firestore prod sync, FCM, SMS, cloud AI, remote chat delivery) · fake capability claims.

**Evidence:** `docs/experience_discovery/FRONTEND_COMPLETION_PREFLIGHT.md` · `FRONTEND_COMPLETION_MATRIX.md`.

**Exit:** `FRONTEND COMPLETION = COMPLETE` with evidence — then wait for Owner before Native wave. Do **not** auto-enter Phase 5 Native.

### FULL FRONTEND CLOSURE (POST GATE)

**STATUS: COMPLETE** (2026-09-25).  
Evidence: `docs/experience_discovery/FRONTEND_COMPLETION_MATRIX.md` · `.verify/FULL_FRONTEND_CLOSURE_COMPLETE.json`.  
**128 / 130 FRONTEND COMPLETE** — Residual: **0 POLICY · 0 DEFERRED · 2 OOS** only.  
Honesty closures without inventing AUD*/REP*/CHAT* Owner law. Native/Backend remain **CLOSED**.  
Await Owner `CHANGE PHASE` before Phase 5 Native or Backend.

### FINAL VISUAL · UX · JOURNEY VERIFICATION (POST CE-B0→B5)

**STATUS: AUTHORIZED** (Owner decision D12, 2026-09-25). VX-B0…B7 **PASSED** (2026-09-26; Owner TG-7). OD-13 + OD-14 CLOSED. **LDR-EXIT PASSED** (2026-09-26). UX verification pack **UNLOCKED** under `user_experience_verification/` → then **D-FINAL**.
**Rules:**
* KEEP + REFINE — no redesign, no architecture rewrite, no new capability class.
* Staged batches VX-B0 → VX-B7 (+ optional VX-B8 mock tidy, Owner D8) → **[LDR intervenes]** → Final Device Pass → Final Product Re-Audit → Final Frontend Certification → **STOP**.
* Every batch ends at an **Owner-run test gate**: Owner runs `flutter analyze` / `flutter test` / `verify_ship` manually and reports results; Cursor does not run them.
* Native, Backend, FCM, AI Gateway, chat relay, Render, Firestore remain **NOT AUTHORIZED**. `core/policy/` and `.cursor/rules/` unchanged (OD-06 = NO CHANGE). `tokens.dart` changes only for the contrast value(s) authorized by Owner decision D3 (rule 21 exception, VX-B4).
* No new batches (VX-B8+) after certification without a new Owner `CHANGE PHASE`.

### LOCAL DATA REALITY (LDR) — POST VX / PRE D-FINAL

**STATUS: COMPLETE** (Owner LDR-EXIT PASSED, 2026-09-26; B0…B8; `test/ldr/` +27; verify --full +80).  
**Scope:** Bind every locally supportable screen/domain to `family_os_fs.db` / `kv_store` / FS domain tables; seed coherent REAL_LOCAL family data; eliminate production mock/unbound defaults for local product state; keep Native/Remote capabilities **empty/honest** (no fabricated GPS, AI, calls, FCM, billing). Schema, binds, repositories, and defaults may change for long-term correctness (smallest coherent change; document in Decisions log).  
**Program:** `docs/experience_discovery/final_product_experience/local_data_reality/LOCAL_DATA_REALITY_*.md`.  
**Batches:** LDR-B0…B8 + EXIT **done** → resume UX verification → D-FINAL.  
**Out of bounds:** Phase 5 Native, Backend, AI Gateway, FCM, redesign.

### PHASE 5

**STATUS: NOT STARTED** — Native / Backend waves remain closed until Owner authorizes after Frontend Completion.

Agentic implementation waves (future):

1. Shared Foundation
2. Local Domains
3. UX integration
4. Cross-system seams
5. Native Android planes
6. Mock transport
7. Real backend
8. Certification

### PHASE 6

Real-device certification, including:

* offline
* restart/recovery
* permissions
* RBAC
* security
* native enforcement
* transport
* device-specific validation

---

## PROGRESS PERCENTAGES ARE NOT EXECUTION AUTHORITY

Do **NOT** optimize for:

* number of green screens
* number of converted services
* percentage of placeholders removed
* test count alone

A feature is considered genuinely implemented only when its required layers are evidenced.

---

## MANDATORY DEVIATION CHECK

Before beginning **ANY** requested implementation, refactor, redesign, migration, or architecture change:

1. Read `PROJECT_EXECUTION_PLAN.md`.
2. Identify the CURRENT PHASE.
3. Identify the requested task's phase.
4. Check dependencies and gates.
5. Check for conflicts with approved architecture/policy.
6. State whether the task is:
   * **ALIGNED**
   * **PREMATURE**
   * **BLOCKED**
   * **CONFLICTING**

If it is PREMATURE, BLOCKED, or CONFLICTING:

**DO NOT silently continue.**

Explicitly tell the Owner:

> "This request is outside the current approved execution phase."

Then explain the exact missing gate.

If the Owner explicitly changes the roadmap, update the governance files **BEFORE** proceeding.

---

## OWNER AUTHORITY

The Product Owner / Executive Director may deliberately change the roadmap.

However, such a change must be **explicit**.

Never infer a phase change from a casual request.

A request such as:

* "let's quickly build this"
* "skip the analysis"
* "do this screen first"
* "connect backend now"
* "rewrite this architecture"

does **NOT** automatically change the approved project phase.

Ask the Owner to explicitly state:

`CHANGE PHASE`

before treating the roadmap as changed.

---

## REQUIRED PROGRESS REPORT FORMAT

At the beginning of significant Agent tasks, report:

```
CURRENT PHASE:
TASK PHASE:
STATUS: ALIGNED / PREMATURE / BLOCKED / CONFLICTING
REQUIRED GATE:
WILL MODIFY PRODUCTION CODE: YES/NO
```
