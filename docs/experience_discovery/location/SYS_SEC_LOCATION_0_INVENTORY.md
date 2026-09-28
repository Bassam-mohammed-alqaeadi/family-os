# SYS-SEC-LOCATION-0 — Location pack inventory (Owner)

**Date:** 2026-09-27  
**Screens:** SCR-FAT-014 (map) · SCR-FAT-015 (history) · SCR-FAT-016 (zones) · SCR-FAT-017 (create)  
**Routes:** `/scr-fat-014`…`017` · `n02_day` feature screens  
**Method:** Compare → Cover → Compete → Polish · Super-App bar vs Life360 / Find My (Local only)  
**Status:** **INVENTORY COMPLETE** · **LOCATION-1 Cover COMPLETE** · **LOCATION-1B COMPLETE** (Owner scoped verify EXIT:0, 2026-09-28)  
**Native / Backend:** NOT AUTHORIZED (GPS honesty only · UI-complete now / wire later)

**LOCATION-1B shipped:** no-show deadline time on FAT-017 → Domain `noShowDeadlineMinutes` → FAT-016 display; FAT-013 deepened (network chip · live map · location history · assigned zones count). Evidence: `.verify/SYS-SEC-LOCATION-1B.json` (local).

**Prior card parked:** `SYS-SEC-EMERGENCY-COMPETE` code-ready; Owner verify still owed when convenient.

---

## 1. Plain picture

Location is the family’s **where-are-they desk** — calm presence, not a fake live GPS product while Native is closed.

| Who | Job |
|-----|-----|
| Father (Primary) | Watch map, tune zones/alerts, history, Silent Locate request, export/archive later |
| Mother Full | Edit zones (when Identity binds Full) |
| Mother Partner / Observer | Read / limited initiate per L2 — must not silently look like Full |
| Child | Lean empty on parent desks; CHD-024 check-in is separate |

Emotional job: **presence without theater**. Father leaves knowing zones and alerts are real Local controls — and that Stage-1 does not claim Apple Maps–grade tracking.

---

## 1b. Father control completeness (phase law)

| Need | Meaning on Location |
|------|---------------------|
| Full control | Map desk, zone library, create/edit, alert granularity, history, Silent Locate honesty |
| Flexible / mood | Standard vs Elevated watch intensity (Local state) — without inventing sample intervals |
| Real enforcement | Toggles persist and affect Domain / mailbox; no decorative-only switches |
| Retention | Father need not bolt to Life360 for “serious” Local geofence + history desk |

---

## 2. Competitor Gap Analysis (strict codebase audit)

Owner checklist vs **current Flutter** (evidence paths below). Verdicts: **PRESENT** · **THIN** · **MISSING**.

### 2.1 Live Map Desk — SCR-FAT-014

| Super-App expect | Codebase verdict | Evidence |
|------------------|------------------|----------|
| Child **avatar** on pin list / map | **PRESENT** | `CircleAvatar` + `pin.emoji` in `_PinRow` / map pins — [`location_map_screen.dart`](../../../app/lib/features/n02_day/location_map_screen.dart) |
| **Current place** text | **PRESENT** | `LocationMapPin.locationLabel` in title via `locationMapPinTitle` — model [`location_map_repository.dart`](../../../app/lib/features/n02_day/location_map_repository.dart) |
| **Battery** percentage / label | **PRESENT** | `batteryLabel` (+ `batteryWarn`) in pin subtitle ARB `locationMapPinSubtitle` |
| **Network** status | **MISSING** | No field on `LocationMapPin`; no Wi‑Fi / cellular / offline chip in FAT-014 UI |
| **Silent Locate** control | **PRESENT (button, not toggle)** | `PrimaryBtn` key `location_map_silent_locate` → `SilentLocateSheet` with `CapabilityStatus.notImplemented` honesty |

**FAT-014 summary:** Avatar + place + battery + Silent Locate CTA are in. Network status is absent. Map positions remain **decorative fractions** (GPS NAT CLOSED honesty banners present).

### 2.2 Zone Library — SCR-FAT-016

| Super-App expect | Codebase verdict | Evidence |
|------------------|------------------|----------|
| Distinct toggle **Arrive (Enter)** | **MISSING on library** | Single `Switch` bound to `SafeZone.alertsEnabled` via `setAlertsEnabled` |
| Distinct toggle **Leave (Exit)** | **MISSING on library** | Same collapsed switch |
| Distinct toggle **No-Show** | **MISSING on library** | Same collapsed switch |

**Note:** Domain / create path already model `alertEnter` / `alertExit` / `alertNoShow` on FAT-017 save. Library UX **collapses** them to one boolean (`alertsEnabled`). Super-App bar requires three visible, persistable controls on **016**, not only at create time.

### 2.3 Zone Creation — SCR-FAT-017

| Super-App expect | Codebase verdict | Evidence |
|------------------|------------------|----------|
| **Roster assignment** (per-child select) | **THIN (code present · production route empty)** | `FilterChip` multi-select when `assignableChildren.isNotEmpty`. Constructor defaults `assignableChildren = const []`. Router builds `CreateSafeZoneScreen(childId: …)` only — **no roster injection** → assign section **never mounts** in normal navigation. |
| **Geofence radius** control | **PRESENT** | `Slider` key `create_safe_zone_radius`, 50–500 m, step 25 |

Also on 017 (not in Owner checklist but relevant): three alert switches Arrive / Departure / No-Show **do** exist on create (`_AlertsCard`) — asymmetry with 016.

### 2.4 History & Retention — SCR-FAT-015

| Super-App expect | Codebase verdict | Evidence |
|------------------|------------------|----------|
| **Export / archive stub** Primary-only | **MISSING** | No export/archive keys, CTAs, or Primary gate in [`location_history_screen.dart`](../../../app/lib/features/n02_day/location_history_screen.dart) |
| **90-day retention** honesty copy | **PRESENT** | Key `location_history_retention`; ARB EN: “History is kept for 90 days, then deleted automatically — mandatory prune policy.” |

### 2.5 Scoreboard (Owner glance)

| Item | Status |
|------|--------|
| FAT-014 avatar | PRESENT |
| FAT-014 place text | PRESENT |
| FAT-014 battery | PRESENT |
| FAT-014 network status | MISSING |
| FAT-014 Silent Locate | PRESENT (CTA button + honesty sheet) |
| FAT-016 Arrive / Leave / No-Show distinct toggles | MISSING (one master switch) |
| FAT-017 roster assignment | THIN (UI exists; router feeds empty list) |
| FAT-017 radius slider | PRESENT |
| FAT-015 Primary export/archive stub | MISSING |
| FAT-015 90-day retention copy | PRESENT |

---

## 3. Cohesion map

```
FAT-014 Live map ──► FAT-015 History
       │                 │
       ├── Silent Locate (honesty sheet)
       ├── FAT-016 Zone library ──► FAT-017 Create/Edit
       │         │
       │         └── alert granularity (Cover target)
       ▼
Local geofence samples ──► mailbox kinds arrive / leaveZone (today: hook only)
       │
       └── SOS handoff (ungated) · Device Health permission honesty (link later)
```

| Seam | Current |
|------|---------|
| Notifications | `arrive` / `leaveZone` remain **hook** in `family_alert_catalog` — no live producer |
| Identity | Router does not pass live `MotherLevel` / roster into 016/017 → mother defaults Partner → read-only; assign chips hidden |
| GPS | Honesty banners + `CapabilityStatus.notImplemented` — correct for Stage-1 |
| Policy | Child lean empty on parent desks; SOS never gated |

---

## 4. Native-closed / never fake

| Claim | Status |
|-------|--------|
| Live map SDK / true lat-lng | Closed — decorative canvas |
| Background OS geofence | Closed |
| Silent Locate success | Closed — sheet returns notImplemented |
| Network / battery from device sensors | Closed — labels from Local/Domain projection only when seeded |
| FCM arrive/leave push | Closed — in-app mailbox wire is Local Cover |

---

## 5. LOCATION Cover order — CLOSED

| Card | Scope | Status |
|------|--------|--------|
| LOCATION-1 | FAT-016 three toggles · FAT-017 roster · FAT-014 network · FAT-015 export stubs · mailbox arrive/leave · MotherLevel | Cover shipped |
| LOCATION-1B | No-show deadline time · FAT-013 map+history desk · zones count | **Owner EXIT:0 2026-09-28** |

Compete/Polish (Standard/Elevated mood, edit/archive zone library polish) only when Owner orients — not auto-started.

---

## 6. Evidence sources

- Screens: `app/lib/features/n02_day/location_map_screen.dart` · `location_history_screen.dart` · `safe_zones_screen.dart` · `create_safe_zone_screen.dart` · `child_profile_screen.dart`  
- Models: `location_map_repository.dart` · `safe_zones_repository.dart` · `safe_zone_definition.dart`  
- Router: `app/lib/app/router.dart` (`/scr-fat-014`…`017`)  
- Domain: `app/lib/core/location/` (schema v12 `no_show_deadline_minutes`)  
- Law packs: `docs/experience_discovery/location_final/` · `location_l3/`  
- Mailbox: `docs/experience_discovery/notifications/SYS_SEC_NOTIF_0_INVENTORY.md`  
- Scope: `.verify/scope_map.json` → `SYS-SEC-LOCATION-1` · `SYS-SEC-LOCATION-1B`

---

## 7. Gate

**LOCATION Cover CLOSED** for Local UI (1 + 1B). Native GPS / schedule worker remain closed until Phase 5.  
Visual Polish / Compete only on Owner orientation — no silent phase advance.