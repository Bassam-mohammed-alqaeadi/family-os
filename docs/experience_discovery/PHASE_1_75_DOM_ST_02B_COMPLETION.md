# PHASE 1.75 — DOM-ST-02B COMPLETION

**Date:** 2026-09-25  
**Task:** DOM-ST-02B — ScheduleWindow Production Binding  
**Broad codegen:** NOT ARMED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-02B
STATUS: ALIGNED
```

---

## Result

### `PASS`

---

## Authority

`MemorySchedulePrefsStore` (FAT-032 production default)  
→ `LocalScreenTimeKvPrefsStore(namespace: st_schedule)` via `PrefsScheduleWindowRepository` + `FsSessionKernel`

---

## Production path

```text
FAT-032 ChildScreenTimeScreen (repository == null)
  → FsSessionKernel.ensureOpen()
  → refuse if sqliteFallbackToMemory
  → ScreenTimeLocalPersistence.scheduleRepository(FsSessionKernel.db)
  → PrefsScheduleWindowRepository(
       LocalScreenTimeKvPrefsStore(ns=st_schedule))
  → kv_store SQLite
       key: schedule_windows:{childId}
```

Also: `ScreenTimeLocalPersistence.openScheduleRepository()` — same honesty guard as policy.

Explicit `repository:` inject remains the test seam.

JSON / kinds / defaults / validation **unchanged**. No schema bump. No Memory→SQLite data migration.

---

## Persistence

| Proof | Suite |
|-------|--------|
| openScheduleRepository write→close→reopen (sleep/prayer/study + defaults) | `dom_st02b_schedule_bind_restart_proof_test` |
| Healthy SQLite restart-safe | `dom_st02b_persistence_honesty_test` |
| Foundation reopen (DOM-ST-01) | `screen_time_local_persistence_restart_proof_test` |

---

## Failure behavior

| Session | ScheduleWindow bind |
|---------|---------------------|
| Healthy SQLite | Bind Local KV — restart-safe |
| `sqliteFallbackToMemory` | **Refuse** — `StateError`; FAT-032 `_policyUnavailable` + BannerNote; save disabled; **no** `stage1SchedulePrefsStore` fallback |
| Intentional test Memory (`preferSqlite: false`) | Allowed |
| Explicit inject | Unchanged |

`FsSessionKernel` / `MemoryLocalDatabase` **unchanged** globally.

---

## Legacy

| Symbol | Reachability |
|--------|----------------|
| `stage1SchedulePrefsStore` / `MemorySchedulePrefsStore` | **LEGACY / RETAINED** — not FAT-032 production |
| Explicit `repository:` / `InMemoryScheduleWindowRepository` | **TEST-ONLY** |
| `PrefsScheduleWindowRepository` | **PRODUCTION** adapter on Local KV |

---

## Modes boundary

- `ScheduleWindowQuery` / `timeContextFromSchedules` — **untouched**
- `ModesEngine` / `ModesService` / `mode_*` — **untouched**
- ScheduleWindow remains ST-owned; Modes remains independent

---

## Blast radius

**Changed:**  
`screen_time_local_persistence.dart` (`openScheduleRepository`)  
`child_screen_time_screen.dart` (Local KV bootstrap for schedules + fail-closed)  
`dom_st02b_*` tests · this completion doc · harness log

**Not changed:** TimeRequest, TimeGrant, PolicySyncBus durability, child mirror, TimeEngine, Modes, AC, WF, SOS, routes, UI redesign.

---

## Verification

| Check | Result |
|-------|--------|
| `dom_st02b_schedule_bind_restart_proof_test` | **PASS** |
| `dom_st02b_persistence_honesty_test` | **PASS** |
| `schedule_window_test` | **PASS** |
| FAT-032 widget tests | **PASS** |
| Analyzer (touched files) | **No issues found** |
| `verify_ship.py verify --scoped` | **passed** (`.verify/DOM-ST-02B.json`) |

---

## Scope

```text
DOM-ST-02B COMPLETE
DOM-ST-02C NOT STARTED
PHASE 1.75 BROAD CODEGEN NOT ARMED
```

**HARD STOP** — do not migrate TimeRequest/TimeGrant; do not start DOM-ST-02C.
