# 10 — SOS Competitive Lessons

**Rule:** COMPETITOR FACT ≠ Family OS behavior. Apply only through Owner decisions.

Sources: Qustodio Help (Panic Button); FamiSafe SOS docs; Bark Watch support; Google Android Emergency SOS / ELS help.

---

## Useful patterns to adopt (aligned with OD-*)

| Lesson | From | Family OS application |
|---|---|---|
| Accidental activation protection | FamiSafe cancel window; Android hold/countdown; Qustodio confirm | Keep **3s hold** + explicit child cancel confirm (OD-06) |
| Trusted contacts distinct from 911 | Bark; Qustodio disclaimer | Auto-call/escalate = family/trusted only (OD-07, OD-15) |
| Location updates while active | Qustodio Panic Mode | Location stream with honesty states (OD-16) |
| Cancel notifies guardians | Qustodio deactivation notice | False-alarm notifies parents (OD-06) |
| Offline / degraded honesty | Android Emp. SOS limits (airplane, battery saver) | OD-17 + readiness classifications |
| ELS only on OS emergency call | Android ELS | Do **not** claim ELS; emergency dial excluded (OD-08) |

---

## Limitations / risks observed

| COMPETITOR FACT | Risk if copied blindly |
|---|---|
| FamiSafe parent can **disable** child SOS | Violates OD-14 / P-4 — **AVOID** |
| Qustodio Panic largely Android-focused | Design cross-platform readiness honesty |
| Bark 911 is separate multi-step | Good — keep emergency services out of auto ladder |
| Android Emp. SOS can call emergency services | Out of scope for Family OS SOS pack |
| Email/SMS link location pages | OK as fallback pattern; require confirmation semantics (OD-09) |

---

## Patterns Family OS intentionally avoids

1. **Parent kill-switch that disables child SOS** (FamiSafe-style).  
2. **Auto-dispatch to police/ambulance** as product SOS.  
3. **Hardcoded local emergency numbers**.  
4. **Audio/video silent recording** as default SOS (Android can record; we exclude audio).  
5. **Fake “delivered” without receipts**.  
6. **Static child UI claiming parents saw alert** without delivery data (current Stage-1 smell).  
7. **Merging notification success with incident closed**.

---

## Reliability lessons

- Treat SMS/email as **best-effort** with honest labels.  
- Multi-channel > single push.  
- Idempotent incident ids under retry.  
- Last-known location better than blank — but label STALE.  
- Watch/hardware SOS (Bark) shows value of break-glass / always-reachable entry — OD-13.
