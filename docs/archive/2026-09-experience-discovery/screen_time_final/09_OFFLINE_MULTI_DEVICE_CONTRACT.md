# 09 — Offline / Multi-Device Contract (FROZEN)

**Status:** FROZEN  
**Date:** 2026-09-23  

---

## Multi-device (ST-OD-001)

| Layer | Scope |
|---|---|
| Daily entertainment allowance + countable used | **Child-level shared** |
| Temporary Grant remaining | **Child-level** (child-wide grant) |
| Earned wallets | **Child-level** per-app |
| Instant lock / local enforcement / permission health | **Device-level** |
| Optional schedule overlays | Device-specific allowed **without** new full daily allowance |

**Forbidden:** each device silently getting a full independent daily entertainment budget.

---

## Timezone (ST-OD-008)

- Family/home timezone owned by Primary Parent.  
- Day rollover, request end-of-day timeout, grant day boundary → family TZ.  
- Child device TZ must not silently redefine the day.  
- Travel TZ: only via explicit auditable Primary action (detail later — not invented).

---

## Offline / stale (ST-OD-009 + G-1)

| Step | Behavior |
|---|---|
| 1 | Continue with **last known policy** |
| 2 | **Bounded grace** (duration not permanently numeric-frozen yet) |
| 3 | **Fail closed** for entertainment |
| Exempt | **SOS** always |
| Chat / Quran | Constitutional exemptions |

Honesty: show last synced; never claim cross-device sync until proven.

---

## Conflict / replay (principles frozen; mechanisms engineering)

- Father wins mother lock conflicts (ADR-035).  
- Request approve on non-pending is invalid.  
- Credits/grants require idempotency at implementation.  
- Simultaneous mother+father policy edits: Primary sovereignty; Mother Full edits audited and visible — exact CRDT deferred (not invented).

---

## Request offline

Parent decisions may queue offline; on flush re-validate ceiling and pendingness; expired requests (ST-OD-007) must not revive into grants.
