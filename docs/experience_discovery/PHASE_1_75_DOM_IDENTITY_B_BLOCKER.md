# PHASE 1.75 — HARD STOP (DOM-IDENTITY-B)

**Date:** 2026-09-25

```text
CURRENT PHASE: PHASE 1.75
TASK/Slice: DOM-IDENTITY-B (Children display roster Local KV)
STATUS: BLOCKED
WHAT WAS VERIFIED:
  - DOM-ST-02C TimeRequest/TimeGrant Local KV bind COMPLETE (focused PASS)
  - DOM-IDENTITY-A FamilyContext Local KV bind COMPLETE (focused PASS)
  - DOM-IDENTITY preflight: READY_WITH_EXPLICIT_HONESTY_GUARD; split A/B required
EXACT BLOCKER: Unclear Owner seed policy for durable children display roster
WHY IT BLOCKS:
  FAT-012 merges IdentityRuntime children (lean placeholders) with
  ChildrenListRepository display DTOs. Persisting an empty Local roster vs
  inventing demo display rows (names/location/battery) is a product honesty
  decision — must not invent fake GPS or plant prototype numerals (Rule 23).
FILES/AREAS INVOLVED:
  - app/lib/features/n02_day/children_list_repository.dart
  - app/lib/features/n02_day/children_list_screen.dart
  - docs/experience_discovery/PHASE_1_75_DOM_IDENTITY_PREFLIGHT.md
OPTIONS/IMPACT:
  A) Empty durable roster — lean merge only (IdentityRuntime IDs); no planted display
  B) Owner-approved demo seed of display DTOs (explicit, non-GPS)
  C) Defer DOM-IDENTITY-B; continue DOM-PREFS-MISC instead
DECISION REQUIRED: Choose A / B / C before DOM-IDENTITY-B implementation
PRODUCTION CODE CHANGED: YES (DOM-ST-02C + DOM-IDENTITY-A already shipped in this wake)
```
