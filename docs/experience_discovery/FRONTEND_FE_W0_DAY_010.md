# FE-W0-DAY-010 — Bind FAT-010 to Identity Local roster

**Date:** 2026-09-25  
**Gate:** Frontend Completion (PRE-NATIVE / PRE-BACKEND)  
**Screen:** `SCR-FAT-010`  
**Status:** **COMPLETE**

```
CURRENT PHASE: FRONTEND COMPLETION GATE
TASK PHASE: FE-W0-DAY-010
STATUS: ALIGNED
REQUIRED GATE: Focused day_board_screen_test
WILL MODIFY PRODUCTION CODE: YES (shipped)
```

## Problem

Today (FAT-010) used Register §10 person names (`خالد` / `نورة` / `سعد`, ids `child_k*`).  
Kids (FAT-012) used Identity Local roster (`demo-child` / `child_b`).  
Profile taps from the day board omitted `childId`.

## Change

| Item | Action |
|------|--------|
| `RosterDayBoardProjectionRepository` | New — loads from `ChildrenListRepository` |
| `stage1DayBoardProjectionRepository` | Switched off Register §10 → roster bind |
| Quran / wallet axes | Honest unbound `—` (not planted %) |
| Pending | Learning results only — no planted Khaled request |
| `_goChild` / pulse | Pass `?childId=` to FAT-013 |
| Pulse touch target | 38 → 48 dp |

## Honesty

Roster location/battery/time-left remain `LOCAL_DEMO_SEEDED` presentation strings (Identity-B contract) — not GPS / OS battery.

## Verification

```text
flutter test test/features/n02_day/day_board_screen_test.dart
→ 14 passed · EXIT=0
```

Evidence: `.verify/FE-W0-DAY-010.json`

## Next

`FE-W0-FAT-012-HONESTY` — surface `LOCAL_DEMO_SEEDED` provenance on Kids roster (FAT-012) so demo location/battery never read as live telemetry.
