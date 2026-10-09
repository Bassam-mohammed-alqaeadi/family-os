# PHASE 1.75 — DOM-ST-02A.1 COMPLETION

**Date:** 2026-09-24  
**Task:** DOM-ST-02A.1 — Screen Time Policy Persistence Honesty Hardening  
**Broad codegen:** NOT ARMED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-02A.1
STATUS: ALIGNED
```

---

## Actual SQLite failure path

```text
FsSessionKernel.ensureOpen(preferSqlite: true)
  → SqliteLocalDatabase.openDefault() throws
  → debugPrint + MemoryLocalDatabase
  → sqliteFallbackToMemory = true
  → ensureOpen completes successfully (does not throw)
```

**Before 02A.1:** FAT-032 / `openPolicyRepository` bound Local KV to that Memory session and set `_policyUnavailable = false` → looked healthy, not restart-safe.

---

## Production behavior (after fix)

| Session | Policy bind |
|---------|-------------|
| SQLite healthy (`usingSqlite`, no fallback) | Bind Local KV — restart-safe |
| SQLite→Memory fallback (`sqliteFallbackToMemory`) | **Refuse** — `StateError`; FAT-032 `_policyUnavailable` + BannerNote; save disabled |
| Intentional test Memory (`preferSqlite: false`, flag false) | Still allowed (FLUTTER_TEST / inject) |
| Explicit `policyRepository:` inject | Unchanged |

`FsSessionKernel` / `MemoryLocalDatabase` **unchanged** globally.

---

## Persistence honesty verdict

### `PASS`

Case B was real; smallest ST-policy guard closes the silent misrepresentation. Degraded Memory session remains for other FS domains via kernel (out of scope); Screen Time **Policy** no longer treats it as production-ok.

---

## Production changes

| File | Reason |
|------|--------|
| `screen_time_local_persistence.dart` | `openPolicyRepository` throws on `sqliteFallbackToMemory` |
| `child_screen_time_screen.dart` | Same check in `_bootstrapPolicy` → existing fail-closed UI |

---

## Test evidence

| Suite | Result |
|-------|--------|
| `dom_st02a1_persistence_honesty_test` — refuse fallback | **PASS** |
| Intentional test Memory still opens | **PASS** |
| Healthy SQLite restart-safe | **PASS** |
| `dom_st02a_policy_bind_restart_proof` | **PASS** |
| FAT-032 widget tests | **PASS** |
| Analyzer touched files | **PASS** |

---

## Scope confirmation

```text
DOM-ST-02A.1 ONLY
DOM-ST-02A CLOSED
DOM-ST-02B NOT STARTED
PHASE 1.75 BROAD CODEGEN NOT ARMED
```

**HARD STOP** — do not start ScheduleWindow migration.
