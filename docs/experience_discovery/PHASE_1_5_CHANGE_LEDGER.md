# Phase 1.5 — Change Ledger

**Plan:** [`PHASE_1_5_MASTER_PLAN.md`](PHASE_1_5_MASTER_PLAN.md)  
**Campaign:** Platform Hardening after FS-001…FS-007  
**Started:** 2026-09-24  

Status vocabulary: `IMPLEMENTED` · `MOCK-REMOTE` · `DEGRADED` · `UNSUPPORTED` · `NOT IMPLEMENTED`

---

## CHECKPOINT-P15-H1 (shared session kernel)

| Date | IDs closed | Change |
|---|---|---|
| 2026-09-24 | P15-F01, F03, F04, F09, F10, F11 | Added `FsSessionKernel` — single shared `FamilyLocalDatabase` for all Stage-1 FS runtimes. Prefer SQLite outside tests (`main.dart` boots `preferSqlite: true`); Memory under `FLUTTER_TEST` env; Memory fallback on SQLite failure = honest DEGRADED. |

### Impact

| Consumer | Risk | Verification | Result |
|---|---|---|---|
| Stage1Location / WF / AC / SC / Modes / SOS / AI runtimes | Cross-table visibility | `phase15_hardening_test` shared DB identity | PASS |
| Widget tests using injected DBs | Low — inject path unchanged | fs001/fs003 UX tests | PASS |
| Production restart | SQLite path now used from `main` | Code path + migration test | PASS (device APK not run) |

---

## CHECKPOINT-P15-H2 (Location → Modes facts)

| Date | IDs closed | Change |
|---|---|---|
| 2026-09-24 | P15-F02 | `Stage1LocationRuntime.ensureOpen` opens Modes on same kernel; `evaluateFixAcrossZones` always passes `ModesLocationFactFeed`; calls `applyFs001XsysCapabilities`. |

### Impact

| Consumer | Risk | Verification | Result |
|---|---|---|---|
| ModesEngine fact consumers | Facts now visible on shared `loc_mode_fact` | phase15 evaluate→facts test | PASS |
| SOS handoff | Same DB as Location | Shared kernel | PASS |

---

## CHECKPOINT-P15-H3 (capability honesty seeds)

| Date | IDs closed | Change |
|---|---|---|
| 2026-09-24 | P15-F09, F10 | `defaultSeeds` aligned to post-campaign IMPLEMENTED / MOCK-REMOTE / UNSUPPORTED. Added `applyAllCampaignCapabilities()` invoked from kernel open. |

---

## CHECKPOINT-P15-H4 (RBAC + FAT-034)

| Date | IDs closed | Change |
|---|---|---|
| 2026-09-24 | P15-F16, F05 | `AppControlActor.child()` + bridge maps child → deny. FAT-034 bootstraps `Stage1AppControlRuntime.accessRules` + service when seams not injected. |

### Impact

| Consumer | Risk | Verification | Result |
|---|---|---|---|
| Child role on FAT-034 | Was over-privileged as father | unit bridge test | PASS |
| Injected test repos | Skip bootstrap when both seams set | fs003_ux_adapt_test | PASS |

---

## CHECKPOINT-P15-H5 (DB migration proof)

| Date | IDs closed | Change |
|---|---|---|
| 2026-09-24 | P15-F27, F33 | `phase15_hardening_test`: schema table coverage + SQLite ffi v1→v10 upgrade + shared kernel + child RBAC. |

---

## DEBT carried (not fixed this phase)

| ID | Note |
|---|---|
| P15-F06 | Smart Modes Prefs fallback on ensureOpen failure |
| P15-F07 | Unlock / ST / time-request Prefs leftovers |
| P15-F13 | `simulateLocalAckToVerified` production API surface |
| P15-F17 | Router mother-level path matrix (domain still enforces) |
| P15-F20 | MockRemoteAdapter enqueue not on live event paths |
| P15-F21 | Memory close does not clear rows (kernel replaces instance) |
| P15-F29 | Samsung SM-S906U / Android 16 device pass — **not executed** |
| P15-F32 | Stale `.verify/FS-001-UX.json` failed artifact |
| P15-F34 | Native planes Stage 3 |

---

## OUT-OF-SCOPE / BLOCKED

| ID | Note |
|---|---|
| P15-F30 | Performance invent metrics |
| P15-F35 | P15-QUR resume / Stage 3 |
| P15-F36 | BLOCKED product questions — **none** |
