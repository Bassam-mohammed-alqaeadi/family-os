# PHASE 1.75 — DOM-ST-02C PREFLIGHT (TimeRequest / TimeGrant Production Binding)

**Date:** 2026-09-25  
**Task:** DOM-ST-02C  
**Status:** AUTHORIZED (Phase 1.75 autonomous loop)  
**Broad codegen:** NOT ARMED  

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-02C PREFLIGHT
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: YES (after this preflight)
```

---

## 1. Current production path

```text
FAT-033 RequestInboxScreen (service == null)
  → TimeRequestService(
       PrefsTimeRequestRepository(stage1TimeRequestPrefsStore),
       stage1TimeRequestDecisionBus)
  → MemoryTimeRequestPrefsStore (process RAM)
       keys: time_requests · time_grants

CHD-020 / stage1TimeRequestService
  → same Memory Prefs store + decision bus

CHD-004 ChildDayBoardScreen
  → PrefsTimeRequestRepository(stage1TimeRequestPrefsStore)

FAT-032 ChildScreenTimeScreen
  → TimeRequestService(PrefsTimeRequestRepository(stage1TimeRequestPrefsStore))
  → activeGrantRemaining only (display)
```

### Foundation already available (DOM-ST-01)

```text
ScreenTimeLocalPersistence.timeRequestRepository(db)
  → PrefsTimeRequestRepository(
       LocalScreenTimeKvPrefsStore(ns=st_time))
  → kv_store
```

Restart proofs already exist for TimeRequest + TimeGrant (+ expiry).  
**No** `openTimeRequestRepository()` yet (honesty gate missing).

---

## 2. Ownership

**Screen Time Final** owns TimeRequest / TimeGrant (G-A Temporary Grant).  
Not Modes. Not WalletLedger. Not AC.

Request + Grant share one Prefs store (`time_requests` / `time_grants`) — **must migrate as one slice** (do not split 02C into Request-only + Grant-only).

---

## 3. Serialization (preserve exactly)

| Item | Value |
|------|--------|
| Namespace | `st_time` |
| Keys | `time_requests`, `time_grants` |
| Shape | Existing `TimeRequest.toJson` / `TimeGrant.toJson` |
| Schema DDL | None — kv_store v10 |
| Memory→SQLite migration | None (RAM-only prior) |

---

## 4. Consumers / blast radius

| Site | Action in 02C |
|------|----------------|
| FAT-033 default service | Bind Local KV |
| CHD-020 `stage1TimeRequestService` | Bind Local KV (shared) |
| `ServiceChildTimeRequestRepository` default repo | Same Local KV (no dual) |
| CHD-004 day board | Bind Local KV |
| FAT-032 grant remaining | Bind Local KV |
| `TimeRequestDecisionBus` | **Unchanged** (process notify; not durable) |
| `TemporaryGrantQuery` / `TimeEngine` / `ScreenTimePolicyQuery` | **Unchanged** (pure / object inputs) |
| `PolicySyncBus` | **Out of scope** |
| Policy / ScheduleWindow | **Do not modify** unless proven dependency |

---

## 5. Dual-authority risk

All production writers/readers currently share `stage1TimeRequestPrefsStore`.  
After bind they must all share `FsSessionKernel.db` + `st_time`.  
Leaving any production host on Memory while others use SQLite = **second authority** → forbidden.

---

## 6. Failure / honesty

Mirror 02A.1 / 02B:

`openTimeRequestRepository()` refuses `sqliteFallbackToMemory`.  
No silent `stage1TimeRequestPrefsStore` production fallback.  
Hosts: fail-closed / inject seam for tests.  
Do not redesign `FsSessionKernel`.

---

## 7. Proposed binding (smallest)

1. Add `ScreenTimeLocalPersistence.openTimeRequestRepository()`.  
2. Add thin `Stage1TimeRequestRuntime.ensureOpen()` (ModesRuntime-shaped) holding one `TimeRequestService` on Local KV + shared decision bus.  
3. Production defaults (FAT-033 / CHD-004 / CHD-020 / FAT-032) → runtime / open repo.  
4. Explicit service/repository inject remains TEST seam.  
5. Keep `MemoryTimeRequestPrefsStore` / `stage1TimeRequestPrefsStore` LEGACY/RETAINED.

---

## 8. Slice split decision

**Keep as single DOM-ST-02C** — Request + Grant are one store and one loop.

---

## 9. Tests required (focused)

- `openTimeRequestRepository` write→close→reopen (request + grant + expiry)  
- Honesty refuse `sqliteFallbackToMemory`  
- Existing `time_request_service_test` + key widget inject paths  
- Analyzer on touched files  

No full suite during iteration.

---

## 10. Verdict

### `READY_WITH_EXPLICIT_HONESTY_GUARD`

Not blocked by authority or architecture. Foundation present. Honesty guard required.
