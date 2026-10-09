# PHASE 1.75 — DOM-ST-02C COMPLETION

**Date:** 2026-09-25  
**Task:** DOM-ST-02C — TimeRequest / TimeGrant Production Binding  
**Broad codegen:** NOT ARMED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-02C
STATUS: ALIGNED
```

---

## Result

### `PASS`

---

## Authority

`MemoryTimeRequestPrefsStore` (FAT-033 / CHD-020 / CHD-004 / FAT-032)  
→ `LocalScreenTimeKvPrefsStore(namespace: st_time)` via `PrefsTimeRequestRepository` + `Stage1TimeRequestRuntime` / `FsSessionKernel`

---

## Production path

```text
Stage1TimeRequestRuntime.ensureOpen()
  → ScreenTimeLocalPersistence.openTimeRequestRepository()
  → refuse if sqliteFallbackToMemory
  → PrefsTimeRequestRepository(LocalScreenTimeKvPrefsStore ns=st_time)
  → kv_store keys: time_requests · time_grants

FAT-033 / CHD-004 / CHD-020 / FAT-032 defaults → Stage1TimeRequestRuntime
```

Decision bus remains process-memory notify (not claimed durable).

---

## Persistence

| Proof | Result |
|-------|--------|
| openTimeRequestRepository write→close→reopen (request + grant + expiry) | **PASS** |
| Honesty refuse Memory fallback | **PASS** |
| Stage1TimeRequestRuntime shared authority | **PASS** |
| DOM-ST-01 foundation reopen | retained |

---

## Failure behavior

`sqliteFallbackToMemory` → refuse bind; hosts fail-closed (no `stage1TimeRequestPrefsStore` fallback). Kernel unchanged.

---

## Legacy

| Symbol | Status |
|--------|--------|
| `stage1TimeRequestPrefsStore` / Memory store | **LEGACY / RETAINED** |
| `stage1TimeRequestService` (Memory) | **LEGACY** — production uses Runtime |
| Explicit service/repository inject | **TEST-ONLY** |

---

## Modes / ST boundary

Policy + ScheduleWindow bindings untouched except FAT-032 TimeRequest bootstrap alongside existing Local KV open. TimeEngine / TemporaryGrantQuery / ScheduleWindowQuery / Modes **untouched**.

---

## Blast radius

Changed: `screen_time_local_persistence.dart`, `stage1_time_request_runtime.dart` (new), request inbox, day board, FAT-032, CHD-020 binder, `dom_st02c_*` tests.

Not changed: PolicySyncBus durability, Wallet earn, Modes, AC, WF, Native, Backend.

---

## Verification

Focused: `dom_st02c_time_request_bind_test`, `time_request_service_test`, `ui_006_request_inbox_test`, FAT-032 + CHD-020 widget tests — **All passed**. Analyzer on touched files — **clean**.

---

## Scope

```text
DOM-ST-02C COMPLETE
DOM-ST lane (policy/schedule/request) COMPLETE for production Prefs→Local KV
NEXT Phase 1.75 candidate: DOM-IDENTITY (local roster) or DOM-PREFS-MISC
PHASE 1.75 BROAD CODEGEN NOT ARMED
```
