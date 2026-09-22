# 12 — SOS Decisions Requiring Owner Approval

**Status:** OPEN — do not silently decide in implementation.  
**Channel:** answer here or in `QUESTIONS.md` with date.

---

## Decisions

### Q-SOS-001 — Mother Observer powers on active SOS
**Why:** FAT-018 currently lets Observer resolve/escalate (tested). Web unlock forbids Observer.  
**Question:** Is Observer **receive-only**, or full action parity with Partner/Full for SOS?  
**Answer:** _(pending)_

### Q-SOS-002 — ACK vs RESOLVE
**Why:** Schema has ACKNOWLEDGED; app conflates into resolve.  
**Question:** Keep distinct ACK then RESOLVE, or collapse to single close?  
**Answer:** _(pending)_

### Q-SOS-003 — Child cancel after ACTIVE
**Why:** UF-08 ambiguous; CHD-006 confirm-safe calls `resolve()`.  
**Question:** May child close ACTIVE without parent ACK? If yes, what notification do parents get (false alarm vs resolved)?  
**Answer:** _(pending)_

### Q-SOS-004 — Auto-call medium
**Why:** S-SEC-028 auto-call after ~5s; today snackbar.  
**Question:** Cellular dialer, in-app VoIP, or parent-manual only for v1?  
**Answer:** _(pending)_

### Q-SOS-005 — National emergency auto-dial
**Why:** P-5 / S-SEC-030 escalate to national number. Competitors often **do not** auto-call 911.  
**Question:** Auto-dial national after ladder, parent-initiated only, or deep-link dialer confirm?  
**Answer:** _(pending)_

### Q-SOS-006 — Audio broadcast in v1
**Why:** P-4 text includes audio; GAP-A-SEC-008 notes undisclosed/unbuilt audio.  
**Question:** Ship location-only first, or require mic audio for v1 SOS?  
**Answer:** _(pending)_

### Q-SOS-007 — Backup contact channels
**Why:** `SosBackupContact` has no phone/email.  
**Question:** SMS, email, in-app only, or all? Verification required?  
**Answer:** _(pending)_

### Q-SOS-008 — Evidence Pack
**Why:** Not present; Android records video; P-4 mentions audio.  
**Question:** In scope for SOS v1? Retention? Who can view (Father only / Full / Partner)?  
**Answer:** _(pending)_

### Q-SOS-009 — Panic Quiet Mode / Break-glass
**Why:** Requested in discovery checklist; not found in product.  
**Question:** Define and include, or explicitly out of SOS v1?  
**Answer:** _(pending)_

### Q-SOS-010 — Who edits FAT-028
**Why:** Screen has no MotherLevel / RoleGuard lean.  
**Question:** Father only, Father+Full, or any mother? Can child ever open?  
**Answer:** _(pending)_

### Q-SOS-011 — False-alarm cooldown
**Why:** Accidental triggers / storm control.  
**Question:** Cooldown after cancel? Still allow immediate re-fire in true emergency?  
**Answer:** _(pending)_

### Q-SOS-012 — Region national number model
**Why:** Family OS Arabic-first; national numbers vary.  
**Question:** Father-configured string, locale default (e.g. 911/997/112), or both?  
**Answer:** _(pending)_

---

## How to resolve

1. Owner answers under each item with date.  
2. Orchestrator updates this file + optionally mirrors critical ones into `QUESTIONS.md` if they block a harness card.  
3. ScreenBuild / GapClose must not guess.
