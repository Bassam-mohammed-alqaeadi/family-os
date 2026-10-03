# PHASE 1.75 — DOM-ST-02A PREFLIGHT (Policy Production Binding)

**Date:** 2026-09-24  
**Task:** DOM-ST-02A  
**DOM-ST-01:** CLOSED  
**DOM-ST-02B / 02C:** NOT STARTED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-02A PREFLIGHT
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: YES (policy bind only)
```

---

## Current production policy path

```text
FAT-032 ChildScreenTimeScreen
  null policyRepository → PrefsScreenTimePolicyRepository(stage1PolicyPrefsStore)
    → MemoryScreenTimePolicyPrefsStore (process RAM)
```

### Producers (write ScreenTimePolicy)

| Producer | Today |
|----------|--------|
| FAT-032 save / overflow toggle | Memory Prefs |
| `WalletLedger.earn` via Attribution / Quran / Child wallet | Memory Prefs (`stage1PolicyPrefsStore`) |

### Consumers (read)

| Consumer | Today |
|----------|--------|
| FAT-032 load / RemainingMinutesCard | Memory Prefs |
| `PolicyChildWalletRepository` | Memory Prefs |
| `ScreenTimePolicyQuery` / TimeEngine | In-memory policy object (no store) |
| PolicySyncBus policy events | Emitted from FAT-032 after save (unchanged; not durable) |

### Foundation already available

`ScreenTimeLocalPersistence.policyRepository(db)` → `LocalScreenTimeKvPrefsStore` → `kv_store`  
`FsSessionKernel.ensureOpen()` — shared lawful DB lifecycle (no new Stage1ScreenTimeRuntime).

---

## Ownership

**No conflict.** Screen Time Final owns policy. Modes / ScheduleWindow / TimeRequest / AC axes out of slice.

---

## Compatibility

Memory Prefs was process-RAM only → **no data migration**. Fresh SQLite/kv starts empty (defaults on first load).

---

## Bootstrap plan

1. FAT-032: async `FsSessionKernel.ensureOpen()` → `ScreenTimeLocalPersistence.policyRepository(FsSessionKernel.db)` when `policyRepository` null.  
2. Fail-closed on open failure — **no** `stage1PolicyPrefsStore` fallback.  
3. ScheduleWindow / TimeRequest remain Memory Prefs.  
4. Earn writers default to same `openPolicyRepository()` so dual authority cannot form.  
5. Explicit inject remains test seam.

**Architecture:** Not `BLOCKED_BY_ARCHITECTURE` — FsSessionKernel is sufficient composition root.

**PREFLIGHT COMPLETE — bind.**
