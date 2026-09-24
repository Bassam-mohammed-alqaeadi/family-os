# 04 — FAT-034 Child Apps Engineering

**Screen:** SCR-FAT-034  
**Widget:** `ChildAppsScreen`  
**Disposition:** WIRING FIX (conceptual → TimeEngine) + EXTEND  

---

## Purpose
Author **separate rule axes** per app/category that feed TimeEngine conceptually.

## Axes (never merge)

| Axis | Values |
|---|---|
| Access | allow · block |
| Limit | none · per-day Minutes |
| Countable | on · off (S-1; edu/Quran forced off) |
| Unlimited | on · off (ST-OD-010; bypasses daily cap only) |

## Clarifications (on-screen help)
- Unlimited ≠ non-countable  
- Unlimited ≠ permanent unblock  
- Wallet never opens permanent blocks  
- Instant Lock still higher precedence  
- Web Filter is separate  

## Roles
Primary + Mother Full: edit. Partner/Observer: read. Father-only: unlock father-permanent-block if distinct from mother edits (ADR-035).

## Hierarchy
Filters (category) · app rows (`AppRuleCard`) · legend of axes · new install → FAT-035  

## Primary action
Save rule set (conceptual persist to policy store).  

## Policy I/O
Out: `permanentlyBlocked` · per-app limit · countable · unlimited · category defaults → TimeEngine inputs (future wiring).  

## States / honesty
loading · empty · ready · saving · error. Show SIMULATED enforcement until OS agents.  

## Events
`app_rule.updated` · `app_rule.blocked` · `app_unlimited.toggled`

## A11y / RTL
Each axis its own control with semantics; not color-only block/allow.
