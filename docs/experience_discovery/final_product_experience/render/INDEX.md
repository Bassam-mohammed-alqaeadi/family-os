# VX-B7 Render Index

**Date:** 2026-09-26  
**Batch:** VX-B7 — Rendered Arabic/RTL & visual pass  
**Program:** Program §5 (Visual) · §6 (UX) · §13 (Arabic/RTL)

## Automated system-home render smoke

Harness: `app/test/goldens/vx_b7_system_homes_render_test.dart`

Each home is pumped at **360 + 412 dp**, **AR (RTL) + EN (LTR)**, **font scale 1.0 + 1.3**.  
PASS = mounts with **no RenderFlex / overflow** FlutterError.

**Owner TG-7 result (2026-09-26):** `+80: All tests passed!` after CHD-012 `_LevelHeroCard` Flexible fix.

| Screen ID | Widget | Role |
|---|---|---|
| SCR-FAT-010 | `DayBoardScreen` | Parent Today |
| SCR-FAT-012 | `ChildrenListScreen` | Parent Kids |
| SCR-FAT-021 | `ConversationsListScreen` | Parent Family chat |
| SCR-FAT-025 | `SettingsHubScreen` | Parent Settings |
| SCR-FAT-019 | `AlertsHubScreen` | Alerts hub |
| SCR-FAT-040 | `StudioBoardScreen` | Studio tab |
| SCR-CHD-004 | `ChildDayBoardScreen` | Child My Day |
| SCR-CHD-012 | `ChildLearnHomeScreen` | Child Learn |
| SCR-CHD-007 | `ChildChatsScreen` | Child Family chat |
| SCR-CHD-010 | `WhatIsCollectedScreen` | Child transparency |

**Count:** 10 × 2 × 2 × 2 = **80** render cases.

## Device / full-surface screenshots

Physical phone checklists and full 145-surface Vis/UX/RTL cell closure remain **PENDING-DEVICE** (D-FINAL).  
Prior batch findings (VX-B0…B6) stay CLOSED; their phone rows stay PENDING-DEVICE.

## Owner TG-7

From `app/`:

```powershell
flutter analyze
flutter test test/goldens/vx_b7_system_homes_render_test.dart
flutter test test/goldens/vx_b4_rtl_representative_test.dart
```

On overflow FAIL: paste the failing `ScreenID_width_locale_fscale` tag — Cursor applies the smallest screen-scope fix.
