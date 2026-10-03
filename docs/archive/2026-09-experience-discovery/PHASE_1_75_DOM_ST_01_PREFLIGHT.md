# PHASE 1.75 — DOM-ST-01 PREFLIGHT (Storage Foundation)

**Date:** 2026-09-24  
**Task:** DOM-ST-01 — Storage Foundation  
**Mode:** Design-before-code  
**DOM-ST-02 / DOM-ST-03:** NOT STARTED  
**Production host binds:** FORBIDDEN this slice

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-01 PREFLIGHT
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: YES (foundation only, after this preflight)
```

---

## Options

### Option A — `kv_store` namespaces (preserve Prefs JSON shapes)

Reuse existing `Prefs*Repository` classes with a `FamilyLocalDatabase`-backed string store writing into schema v10 `kv_store` under namespaces:

| Namespace | Prefs key(s) preserved |
|-----------|------------------------|
| `st_policy` | `screen_time_policy:{childId}` |
| `st_schedule` | `schedule_windows:{childId}` |
| `st_time` | `time_requests` · `time_grants` (same Prefs store shape) |

| Factor | Assessment |
|--------|------------|
| Schema safety | **Highest** — `kv_store` already exists; **no version bump** |
| Type/integrity | JSON validated by existing `fromJson` / policy factories on read |
| Restart persistence | Proven via STOR-01 pattern on same table |
| Query requirements | Match today's Prefs (load-by-key / load-all lists) — no SQL joins required |
| Migration complexity | **Lowest** — no DDL; no Prefs→SQLite data migrate (RAM-only today) |
| Compatibility with foundation | Native fit |
| Repository complexity | Thin `LocalScreenTimeKvPrefsStore` + existing Prefs repos |
| Future audit/outbox | Service layer can still emit; not blocked |
| Preserve shapes | **Exact** Prefs JSON |
| Blast radius | New files under `core/screen_time/`; hosts untouched |
| Reversibility | Delete namespaces / stop wiring |

### Option B — Dedicated `st_*` tables (D-1 / D-1b / D-2 / D-3 style)

Bump `FamilyLocalSchema` **10 → 11**; add tables for policy, schedule_window, time_request, time_grant (and possibly app_wallet).

| Factor | Assessment |
|--------|------------|
| Schema safety | Additive OK, but **new migration surface** on every install/upgrade |
| Type/integrity | Stronger column-level constraints |
| Restart | Equal if implemented correctly |
| Query | Better for future SQL filters; **not required** by current repos |
| Migration complexity | Higher — DDL + MemoryLocalDatabase table registry + onUpgrade |
| Compatibility | Fits FS Domain pattern (wf_/mode_) but heavier than needed now |
| Repository complexity | New Local*Store row mappers; duplicate Prefs path logic |
| Future audit | Slightly cleaner row IDs |
| Preserve shapes | Must map JSON ↔ columns carefully |
| Blast radius | Touches `local_database.dart`, `sqlite_local_database.dart`, `memory_local_database.dart` |
| Reversibility | Harder once v11 ships |

---

## Decision

### **Option A — `kv_store` namespaced Screen Time records**

**Justification:** Current ST repositories are already Prefs/JSON-blob shaped. Query needs match key/list load. `kv_store` already ships in schema v10 (STOR-01 proven). Smallest safe foundation: durable backing for existing contracts **without** inventing `st_*` product schema or a Stage1 singleton authority.

Dedicated tables remain a **future** optimization (DOM-ST later / D-1…D-3) if SQL query needs appear — not required for DOM-ST-01.

---

## Compatibility note

Existing Memory Prefs stores are **process-RAM only** (SharedPreferences never wired). **No Prefs→SQLite data migration** is required or invented.

---

## Implement plan (this slice)

1. `LocalScreenTimeKvPrefsStore` + namespace constants  
2. Factory helpers composing `PrefsScreenTimePolicyRepository` / `PrefsScheduleWindowRepository` / `PrefsTimeRequestRepository` on that store  
3. Real-SQLite restart proofs for Policy, ScheduleWindow, Request, Grant (+ expiry after reopen)  
4. **No** FAT-032 / FAT-033 / CHD-020 / TimeEngine production binds  
5. Memory Prefs symbols **RETAINED** (hosts still use them until DOM-ST-02)

**PREFLIGHT COMPLETE — implement Option A.**
