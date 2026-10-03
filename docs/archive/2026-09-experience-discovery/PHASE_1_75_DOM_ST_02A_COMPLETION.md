# PHASE 1.75 — DOM-ST-02A COMPLETION

**Date:** 2026-09-24  
**Task:** DOM-ST-02A — Screen Time Policy Production Binding  
**Broad codegen:** NOT ARMED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-02A
STATUS: ALIGNED
```

---

## Result

### `PASS`

---

## Authority

`MemoryScreenTimePolicyPrefsStore` (FAT-032 / earn defaults)  
→ `LocalScreenTimeKvPrefsStore` (`st_policy` / `kv_store`) via `PrefsScreenTimePolicyRepository` + `FsSessionKernel`

---

## Production path

```text
FAT-032 ChildScreenTimeScreen (policyRepository == null)
  → FsSessionKernel.ensureOpen()
  → ScreenTimeLocalPersistence.policyRepository(FsSessionKernel.db)
  → PrefsScreenTimePolicyRepository(LocalScreenTimeKvPrefsStore ns=st_policy)
  → kv_store SQLite
```

Earn writers (wallet / attribution / Quran) default to `openPolicyRepository()` — same authority.

ScheduleWindow + TimeRequest remain Memory Prefs (DOM-ST-02B/C).

---

## Persistence

| Proof | Result |
|-------|--------|
| `dom_st02a_policy_bind_restart_proof_test` open→write→close→reopen | **PASS** |
| DOM-ST-01 policy restart suite | **PASS** |
| FAT-032 widget tests (inject + default) | **PASS** |
| `screen_time_policy_test` / `time_engine_test` | **PASS** (with suite) |

No Prefs→SQLite data migration (prior Memory Prefs was process-RAM only).

---

## Consumers now on SQLite-backed policy

- FAT-032 production load/save/overflow  
- `PolicyChildWalletRepository` (default)  
- Attribution / Quran `WalletLedger` defaults  

TimeEngine / ScreenTimePolicyQuery: unchanged (consume policy objects).

---

## Legacy

| Symbol | Status |
|--------|--------|
| `stage1PolicyPrefsStore` / `MemoryScreenTimePolicyPrefsStore` | **LEGACY / RETAINED** — not FAT-032 production; kept for explicit Memory-Map widget tests |
| Explicit `policyRepository:` inject | **TEST-ONLY** seam |

No Memory Prefs silent production fallback.

---

## Failure behavior

`ensureOpen` / Local KV bootstrap failure → `_policyUnavailable`, BannerNote, caps/save disabled. No Prefs fallback.

---

## Regression

FAT-032 UI structure unchanged (banner only on fail). Schedule/Modes/AC/WF untouched.

---

## Blast radius

Touched: `child_screen_time_screen.dart`, `screen_time_local_persistence.dart`, wallet/attribution/quran earn defaults, DOM-ST-02A tests/docs.  
Residual: FsSessionKernel may use in-process MemoryLocalDatabase when SQLite open fails (existing DEGRADED session honesty) — still Local KV path, not Prefs.

---

## Verification

- Analyzer on touched files: clean (after null-assert fix)  
- Focused flutter tests: PASS  
- Ship evidence: **PASS** — `.verify/DOM-ST-02A.json`

---

## Scope

```text
DOM-ST-02A COMPLETE
DOM-ST-02B NOT STARTED
DOM-ST-02C NOT STARTED
PHASE 1.75 BROAD CODEGEN NOT ARMED
```

**HARD STOP.**
