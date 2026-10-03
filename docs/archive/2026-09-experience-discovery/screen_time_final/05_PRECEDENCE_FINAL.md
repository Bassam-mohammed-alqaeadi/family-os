# 05 — Precedence Final (FROZEN)

**Status:** FROZEN  
**Date:** 2026-09-23  

---

## Frozen ladder

Evaluate top-down. First decisive deny wins. Allows still subject to lower remaining-time rules.

```
P0  Safety Exempt Surfaces
    chat | quran | sos  → always reachable for those surfaces
    SOS is OUTSIDE the entertainment ladder

P1  Instant Device Lock
    → deny entertainment / non-exempt surfaces
    Father unlock supersedes mother lock (ADR-035)

P2  Permanent App Block
    → deny; Minutes / grants / unlimited NEVER open

P3  Active Schedule / Smart Mode
    if not allowed AND no ModeException → deny
    Temporary Grant does NOT pierce this (ST-OD-005)
    Earned Minutes do NOT pierce this (ST-ADD-002)
    overlapping modes → stricter wins (M-B)

P4  Daily Entertainment Cap  (child-level shared budget — ST-OD-001)
    Note: discovery name said "Device Daily"; freeze clarifies CHILD-LEVEL budget.
    if countable used ≥ cap:
      if Temporary Grant remaining > 0 → may continue under grant (still P0–P3)
      else if Unlimited flag for this app → may continue (ST-OD-010; still P0–P3)
      else if wallet may open past cap (Ruling B) && app wallet > 0 → may continue
      else → denyCap

P5  Per-App / Category Daily Limit
    same pattern scoped to app/category

P6  Allow
    consumption order (future): Daily → Temporary Grant → Earned Wallet
```

---

## Clarifications (FROZEN)

| Topic | Rule |
|---|---|
| Web Filter | Independent gate — not on this ladder |
| Wallet vs permanent block | Never opens (Ruling A) |
| Wallet vs instant lock | Never defeats |
| Wallet vs hard schedule/mode | Never defeats |
| Temporary Grant vs hard schedule/mode | Never defeats |
| Unlimited | Bypasses **P4 cap only** — not P1/P2/P3 |
| SOS | Always available (expiry, restriction, mode, lock, subscription) |
| Chat / Quran | Constitutional exemptions (Rule 11 / C-1 / S-1) |

---

## Correction of discovery misreadings

Any implication that **SOS becomes unavailable during active mode** is **WRONG** and void.

At P3, only **non-exempt entertainment** (and non-excepted apps) are denied. SOS never enters that deny set.
