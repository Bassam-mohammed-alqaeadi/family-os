# PHASE 1.75 — SLICE 02-A PREFLIGHT (AUTH-FS002-UNLOCK)

**Date:** 2026-09-24  
**Slice:** 02-A only  
**DOM-ST:** NOT STARTED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: AUTH-FS002-UNLOCK PREFLIGHT
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: YES (after this preflight)
```

---

## Current flow

| Layer | Production today | Target |
|-------|------------------|--------|
| Policy lists (FAT-036) | `Stage1WebFilterRuntime.policyRepository` → SQLite `wf_document` | Keep |
| Unlock **requests** (inbox) | `PrefsWebUnlockRequestRepository(stage1WebUnlockPrefsStore)` — RAM Map | Keep Prefs this slice (no `wf_unlock_request` table) — **LEGACY request queue** |
| Timed **temp allow** on approve | `WebUnlockService` default `InMemoryWebFilterTempAllowStore()` | `LocalWebFilterTempAllowStore` via runtime (`wf_temp_allow` SQLite) |
| Native VPN/DNS | MOCK-REMOTE | Out of scope |

**Authority conflict resolved without Owner OD:** Lawful timed-allow owner is already FS-002 Domain (`LocalWebFilterTempAllowStore` / Q-WF-09). Production screen simply failed to wire it — under-bind, not ownership ambiguity.

---

## Consumers / producers

| Actor | Role |
|-------|------|
| `WebFilterScreen` | Creates default `WebUnlockService` (Prefs + InMemory temp) |
| `WebUnlockInbox` / `WebBlockPage` | Consume injected `WebUnlockService` |
| `WebUnlockService.approve` | Producer of `WebFilterTempAllow` |
| `WebUnlockService.activeTemporaryHosts` | Reader of temp allows for evaluator |
| Tests | Explicit `WebUnlockService(...)` inject |

---

## Bootstrap / persistence

- `Stage1WebFilterRuntime.ensureOpen()` already constructs `LocalWebFilterTempAllowStore(db)`.
- Screen never passes `tempAllows:` → defaults to **InMemory** (process-only).
- Prefs request store remains process RAM (false “restart” only if Map shared).

---

## Proceed

Wire production `WebUnlockService` to `Stage1WebFilterRuntime.tempAllows` after `ensureOpen`.  
No Prefs/InMemory temp-allow fallback on failure.  
Do not delete Prefs request repository.  
Do not invent unlock-request SQLite schema.

**PREFLIGHT COMPLETE — migrate.**
