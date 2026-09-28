# PHASE 1.75 — DOM-ST-02A.1 PREFLIGHT (Policy Persistence Honesty)

**Date:** 2026-09-24  
**Task:** DOM-ST-02A.1  
**DOM-ST-02A:** CLOSED  
**DOM-ST-02B:** NOT STARTED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-02A.1 PREFLIGHT
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: CONDITIONAL (Case B → smallest honesty fix)
```

---

## Traced SQLite failure path (runtime)

```text
FAT-032 / openPolicyRepository()
  → FsSessionKernel.ensureOpen()
       preferSqlite == true (non-test production)
       → SqliteLocalDatabase.openDefault() throws
       → debugPrint Memory fallback
       → _sqliteFallback = true
       → return MemoryLocalDatabase()   // ensureOpen STILL succeeds
  → ScreenTimeLocalPersistence.policyRepository(FsSessionKernel.db)
  → LocalScreenTimeKvPrefsStore on MemoryLocalDatabase
  → FAT-032 sets _policyUnavailable = false
```

`_policyUnavailable` is set only when `ensureOpen` **throws**. Memory fallback does **not** throw.

FAT-032 UI: caps/save work normally; `BannerNote` for unavailable is **not** shown.  
`EnforcementStatusBadge` = simulated enforcement only — **not** session persistence honesty.  
`FsSessionKernel.sqliteFallbackToMemory` exists but is **unread** by Screen Time Policy bind.

---

## Verdict: **Case B**

Production can continue on process-memory `kv_store` after SQLite open failure with **no clear UI/state** that restart persistence is unavailable → silent misrepresentation risk.

Intentional test Memory (`preferSqlite: false`, `sqliteFallbackToMemory == false`) is a different path and remains acceptable for FLUTTER_TEST.

---

## Smallest correction (no FsSessionKernel redesign)

1. After `ensureOpen`, if `FsSessionKernel.sqliteFallbackToMemory` → refuse Screen Time **policy** production bind (throw / fail-closed).  
2. FAT-032 catch → existing `_policyUnavailable` + BannerNote.  
3. `openPolicyRepository()` same guard (earn writers).  
4. Do **not** remove MemoryLocalDatabase; do **not** change Modes/WF/global fallback.

**PREFLIGHT COMPLETE — implement Case B honesty guard.**
