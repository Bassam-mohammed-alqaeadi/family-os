# PHASE 1.75 — SLICE 02-A COMPLETION (AUTH-FS002-UNLOCK)

**Date:** 2026-09-24  
**Task:** AUTH-FS002-UNLOCK  
**Broad codegen:** NOT ARMED  
**DOM-ST:** NOT STARTED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: AUTH-FS002-UNLOCK
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: YES (complete)
```

---

## Result

### `PASS_WITH_EXPLICIT_DEBT`

Production timed-allow authority for Web Filter unlock now goes through FS-002 Domain SQLite (`LocalWebFilterTempAllowStore` / `wf_temp_allow`). Request inbox Prefs remain LEGACY (no unlock-request table). InMemory temp-allow constructor default retained for tests only — production screen no longer uses it.

```text
SLICE 02-A CLOSED: YES (with explicit debt)
DOM-ST: NOT STARTED
PHASE 1.75 BROAD CODEGEN: NOT ARMED
```

---

## Authority

| Concern | OLD (pre-slice) | NEW (post-slice) |
|---------|-----------------|------------------|
| Timed temp allow | `WebUnlockService` default `InMemoryWebFilterTempAllowStore()` on FAT-036 bootstrap | `Stage1WebFilterRuntime.tempAllows` → `LocalWebFilterTempAllowStore` → SQLite `wf_temp_allow` |
| Unlock request queue | `PrefsWebUnlockRequestRepository(stage1WebUnlockPrefsStore)` | **Unchanged** — LEGACY Prefs (no Domain table this slice) |
| Policy lists | Domain SQLite (prior) | Unchanged |

**Single production authority for temporary allow:** Domain SQLite only.  
No silent Prefs/InMemory fallback when Domain bootstrap fails — screen fail-closes unlock UI (`_unlockUnavailable`).

---

## Production reachability

| Path | Reachable as production authority? |
|------|--------------------------------------|
| `WebFilterScreen` → `Stage1WebFilterRuntime.tempAllows` | **YES** — default production path |
| `WebUnlockService(... tempAllows omitted ...)` InMemory default | **NO for FAT-036 production** — only if caller omits `tempAllows` (tests / explicit inject) |
| Prefs unlock **request** store | **YES** for inbox queue only — not timed-allow authority |
| Prefs as timed-allow store | **NO** — never was; InMemory was the gap |

Old Prefs path does **not** remain a dual timed-allow authority.

---

## Persistence

Evidence: `app/test/core/web_filter/wf_temp_allow_restart_proof_test.dart`

Invariant proven on real SQLite file:

1. `SqliteLocalDatabase.openAt(path)` → `LocalWebFilterTempAllowStore.save(...)`
2. `db.close()`
3. Reopen same path → `activeHosts` still contains host while `now < expiresAt`
4. After `expiresAt` → `activeHosts` empty; row status → `expired`

---

## Restart + expiry

| Check | Result |
|-------|--------|
| write → close → reopen → read active | **PASS** (restart proof test) |
| expired after persisted timestamp | **PASS** (same test + existing `web_filter_enf_test` temp-allow expiry) |
| Focused unlock suite | **PASS** — 15/15 (`wf_temp_allow_restart_proof`, `web_unlock_service`, `web_unlock_loop`, `web_filter_screen`) |
| Domain store/ENF suite | **PASS** — 15/15 |
| `dart analyze` touched files | **PASS** — no issues |
| `verify_ship.py verify` | **PASS** — analyze OK; tests OK (~217s). Evidence: `.verify/AUTH-FS002-UNLOCK.json` |

---

## Legacy

| Symbol | Classification | Reason |
|--------|----------------|--------|
| `PrefsWebUnlockRequestRepository` / `stage1WebUnlockPrefsStore` | **LEGACY / RETAINED** | Unlock request inbox — no SQLite table; still production queue |
| `InMemoryWebFilterTempAllowStore` | **TEST-ONLY** (constructor default) | Explicit inject / omitted `tempAllows`; not FAT-036 production |
| `MemoryWebFilterPrefsStore` / `stage1WebFilterPrefsStore` | **OTHER / RETAINED** | Unrelated policy Prefs symbol; not timed-allow authority; not deleted this slice |
| Prefs implementation source files | **RETAINED** | Not deleted (slice rule) |

---

## Blast radius

**Inspected:** `web_filter_screen.dart`, `web_filter_runtime.dart`, `web_unlock_service.dart`, `web_filter_temp_allow_store.dart`, unlock tests, ENF/store tests, consumers (`WebUnlockInbox`, `WebBlockPage`).

**Could still be affected:** Any future caller that constructs `WebUnlockService` without `tempAllows:` still gets InMemory (document as inject contract). Request inbox still process-RAM Prefs (false restart for *requests*, not temp allows). Native VPN/DNS unchanged (MOCK-REMOTE).

**Not touched:** DOM-ST, Modes, Identity, Event Bus, Router, Backend, Screen Time Prefs.

---

## Scope

Confirmed:

- `SLICE 02-A ONLY`
- `DOM-ST NOT STARTED`
- `PHASE 1.75 BROAD CODEGEN NOT ARMED`

**HARD STOP** — next execution requires separate Owner authorization (DOM-ST or later).

---

## Changed files

- `app/lib/features/n04_web_filter/web_filter_screen.dart` — Domain tempAllows bind; fail-closed unlock
- `app/test/core/web_filter/wf_temp_allow_restart_proof_test.dart` — SQLite restart+expiry proof
- `docs/experience_discovery/PHASE_1_75_SLICE_02A_PREFLIGHT.md`
- `docs/experience_discovery/PHASE_1_75_SLICE_02A_COMPLETION.md` (this file)
