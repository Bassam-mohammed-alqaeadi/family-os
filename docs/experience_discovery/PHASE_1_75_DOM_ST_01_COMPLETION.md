# PHASE 1.75 — DOM-ST-01 COMPLETION

**Date:** 2026-09-24  
**Task:** DOM-ST-01 — Screen Time Local Storage Foundation  
**Broad codegen:** NOT ARMED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-01
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: YES (foundation only)
```

---

## 1. Storage decision

### **Option A — `kv_store` namespaced records**

Selected in `PHASE_1_75_DOM_ST_01_PREFLIGHT.md`.

**Reasoning:** Existing ST repositories are Prefs/JSON-blob shaped; `kv_store` already exists in schema **v10**; no DDL/version bump; preserves exact Prefs JSON; smallest blast radius vs dedicated `st_*` tables (Option B deferred).

---

## 2. Schema changes

| Item | Change |
|------|--------|
| `FamilyLocalSchema.currentVersion` | **Unchanged (10)** |
| New tables | **None** |
| Migration / onUpgrade | **None** |
| Fresh DB | Existing `kv_store` CREATE remains in `createStatements` |

---

## 3. Ownership

Persisted under ST namespaces only:

| Entity | Namespace | Keys |
|--------|-----------|------|
| ScreenTimePolicy | `st_policy` | `screen_time_policy:{childId}` |
| ScheduleWindow set | `st_schedule` | `schedule_windows:{childId}` |
| TimeRequest list | `st_time` | `time_requests` |
| TimeGrant list | `st_time` | `time_grants` |

**Not written:** `mode_*`, `ac_*`, AppAccess Limit/Unlimited Prefs, WF, SOS.

---

## 4. Repository path

```text
(Caller supplies open FamilyLocalDatabase)
    → ScreenTimeLocalPersistence.*Repository(db)
    → Prefs*Repository(LocalScreenTimeKvPrefsStore)
    → kv_store (SQLite)
```

No new Stage-1 process-global singleton authority.  
**Production hosts (FAT-032 / FAT-033 / CHD-020 / TimeEngine) not rebound** — still Memory Prefs until DOM-ST-02.

---

## 5. Restart evidence

Suite: `app/test/core/screen_time/screen_time_local_persistence_restart_proof_test.dart`  
+ `screen_time_local_persistence_test.dart`

| Entity | Result |
|--------|--------|
| Policy write→close→reopen | **PASS** |
| ScheduleWindow write→close→reopen | **PASS** |
| TimeRequest pending/decided | **PASS** |
| TimeGrant + expiry after reopen | **PASS** (`isActiveAt` mid=true, after expiry=false) |
| Closed DB fail (no Prefs fallback) | **PASS** (`StateError`) |

Analyzer on touched files: **No issues found.**

---

## 6. Failure behavior

`LocalScreenTimeKvPrefsStore` requires an **open** `FamilyLocalDatabase`.  
Closed / missing DB → operation throws (`StateError` on Memory; SQLite errors otherwise).  
**No silent Memory Prefs production fallback** in this foundation.

---

## 7. Legacy status

| Symbol | Status |
|--------|--------|
| `MemoryScreenTimePolicyPrefsStore` / `stage1PolicyPrefsStore` | **RETAINED** — still production on FAT-032 until DOM-ST-02 |
| `MemorySchedulePrefsStore` / `stage1SchedulePrefsStore` | **RETAINED** — same |
| `MemoryTimeRequestPrefsStore` / `stage1TimeRequestPrefsStore` | **RETAINED** — same |
| Prefs*Repository classes | **RETAINED** — reused by Local KV adapter |
| InMemory* repositories | **TEST-ONLY** |

Not deleted this slice.

---

## 8. Blast radius

**Added:**
- `app/lib/core/screen_time/screen_time_local_persistence.dart`
- `app/test/core/screen_time/*`
- docs preflight + this completion

**Inspected / protected:** Modes `mode_*`, AC, WF, FAT-032/033/CHD-020 hosts (untouched), ScheduleWindowQuery semantics (untouched), AppAccess ST axes Prefs (untouched).

**Compatibility:** Prior Memory Prefs was process-RAM only → **no Prefs→SQLite data migration** invented.

---

## 9. Verification

| Check | Result |
|-------|--------|
| `dart analyze` (touched) | PASS |
| `flutter test test/core/screen_time/` | PASS (6 tests) |
| Ship gate | **PASS** — `.verify/DOM-ST-01.json` (analyze OK; tests OK) |

---

## 10. Scope

```text
DOM-ST-01 COMPLETE
DOM-ST-02 NOT STARTED
DOM-ST-03 NOT STARTED
PHASE 1.75 BROAD CODEGEN NOT ARMED
```

**HARD STOP** — do not bind production hosts; await DOM-ST-02 authorization.
