# 11 — Validation Contract (FROZEN)

**Status:** FROZEN  
**Date:** 2026-09-23  
**Purpose:** Proof bar for future engineering — not implementation now.

---

## Must-pass product scenarios (when built)

1. Shared child budget: two devices cannot each consume a full independent daily allowance.  
2. Temporary Grant increases today’s remaining; wallet balance unchanged.  
3. Grant does not open app under hard mode without ModeException.  
4. Earned Minutes do not pierce hard mode.  
5. One pending request only; second create rejected.  
6. Pending expires at min(12h, family EOD).  
7. Partner grant above ceiling rejected; Father allowed.  
8. Observer cannot decide.  
9. Mother Full toggles overflow → audit + Primary visibility.  
10. Unlimited bypasses daily cap only; still blocked by lock/permanent block/hard mode.  
11. WARNING at ≤5 minutes offers Request / Quran / Chat / SOS.  
12. EXPIRED calm UX offers Request / Quran / Chat / SOS.  
13. SOS reachable under expiry, mode, instant lock, subscription off.  
14. Self-discipline suggestion cannot credit without parent approve.  
15. UI never claims metering/OS enforce/multi-device sync/push unless proven.  
16. Daily remaining, grant remaining, wallet balances independently visible.  
17. Stale path eventually fail-closes entertainment; SOS remains.  

---

## Honesty gates

| Claim | Required proof |
|---|---|
| Metering real | Platform usage API + tests on device |
| OS enforcing | Device lab + Policy Health ENFORCING |
| Multi-device sync | Cross-device integration test on shared meter |
| Push delivered | Notification delivery proof (not toast-only) |

---

## Traceability template

`Requirement → Policy → Role → State → Screen → Event → Data → Device/Backend`

Frozen contracts 01–10 are the requirement sources until Screen Engineering begins.
