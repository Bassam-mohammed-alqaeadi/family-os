# 03 — Screen and Navigation Inventory (Family OS)

**Primary:** `app/lib/app/router.dart`, `app/lib/features/**/*_screen.dart`  
**Supporting:** `family-os/_REGISTRY/screens.csv`  
**Date:** 2026-09-23  

---

## Counts

| Metric | Value | Evidence |
|---|---|---|
| Registry SCR rows | ~130 (header + rows in CSV) | `family-os/_REGISTRY/screens.csv` |
| Constitution target | Exactly 129 active; no OTP/green-v1/two-app/role-picker | constitution rule 3 |
| `generatedScreenIds` entries | 130 | `router.dart` |
| Feature `*_screen.dart` files | 131 | Glob |
| `PlacehِolderScreen` route builders | **43** | `router.dart` |
| `ComingSoonScreen` | SCR-FAT-075 | `router.dart` |
| Tombstone example | SCR-FAT-039 school mode removed; redirect toward FAT-085 | GAP_LOG SET-018; CSV note |

---

## Navigation architecture (FACT)

- **Router:** generated go_router (`// GENERATED — do not edit by hand. Run: dart run tool/gen_routes.dart`).  
- **Initial:** welcome / onboarding path (CONVERSION_LOG: initialLocation `/scr-shr-001`).  
- **Role gating:** `roleGuardRedirect` in `app/lib/app/role_guard.dart`.  
  - Father-only: FAT-029, FAT-031, FAT-056, FAT-057.  
  - Owner-only vs child: FAT-059, FAT-060.  
- **Shell:** `FamilyShellHost` in `app/lib/app/family_shell.dart` — bottom tabs + hub + AI/SOS FABs; **StatefulShellRoute deferred** (PRT-2.1 comment).  
- **Gallery:** `/gallery` used as RoleGuard safe landing.  
- **Role switching:** `RoleController` / `CurrentRole` InheritedNotifier — **in-app role switch**, not multi-user OS accounts.

---

## Screen groups by feature folder

| Folder | Role focus | Notes |
|---|---|---|
| `shared_onboarding/` | Shared | Welcome, account, login, device mode, user switch |
| `shared_templates/` | Shared | Network error / empty templates (SHR-005/006 hosts) |
| `n01_linking/` | Father + child + mother invite | Pairing wizard spine |
| `n02_day/` | All | Day board, location, chat/call, alerts, social |
| `n03_screen_time/` | Father/mother/child | Caps, apps, expiry, requests |
| `n04_web_filter/` | Father/child | Filter + block + home router filter |
| `n05_lock/` | Father/mother/child | Instant lock, tamper, child mode lock, second key |
| `n06_notifications/` | Parents | Prefs |
| `n07_privacy/` | Father (+ mother read), child transparency | Privacy, audit, what-is-collected |
| `n07_advisor/` | Father (+ mother limited) | Brain, suggestions, patterns, moments, voice, etc. |
| `n08_platform/` | Father | Smart supervision, platform monitoring, smart alerts |
| `n09_smart_modes/` | Father | Modes host FAT-085 |
| `n10_emergency/` | All | SOS + emergency setup |
| `n11_billing/` | Father owner | Plans + manage |
| `n12_devices/` | Father (+ mother members) | Settings hub, health, members, mother level |
| `n13_coming_soon/` | Father | FAT-075 |
| `n14_studio/` | Father | Education studio spine |
| `n15_calendar/` | Family | Calendar |
| `n16_tasks/` | Family | Tasks + chore AI |
| `n17_child_learn/` | Child | Learn suite |
| `education/` | Cross | Approved packs, assignments, source library (repos) |

---

## Critical wiring finding (FACT → status G)

Many Wave-2/3 screens exist as Dart widgets **but are not referenced by `router.dart`**.

Spot-check:

- `router.dart` builds `PlaceholderScreen` for `SCR-CHD-012` … `SCR-CHD-020` (learn/time-request titles).  
- Files exist: e.g. `n17_child_learn/child_quiz_screen.dart`, `child_learn_home_screen.dart`, etc.  
- Grep: `KnowledgeMapsScreen` / `ChildLearnHomeScreen` / `ChildQuizScreen` — **no matches in `router.dart`**.  
- `SCR-FAT-064` (knowledge maps) still `PlaceholderScreen` while `knowledge_maps_screen.dart` / repository exist under `n07_advisor/`.

**Inference:** conversion produced screen files + tests ahead of (or parallel to) route generator wiring — architects must not assume a screen file implies a live route.

---

## Registry vs code

| Situation | Example | Status |
|---|---|---|
| Registry + wired real screen | SCR-FAT-010 DayBoardScreen | B/A |
| Registry + PlaceholderScreen | Many CHD-012+, FAT-064 | F/G |
| Registry tombstone | SCR-FAT-039 | Redirected / unrouted |
| Screen file without router import | Child learn suite | G |
| Coming soon honesty host | SCR-FAT-075 | C |

Full per-ID matrix is large; treat `router.dart` builders as authoritative for “what opens,” and feature folders as “what code exists.”

---

## Shell tabs (supporting)

`shell_config.dart` + `FamilyShellHost` define parent/child tab chrome. Exact tab→route map: see `app/lib/app/shell_config.dart` and `family_shell_test.dart`.

---

## FACT / INFERENCE / UNKNOWN

- **FACT:** 43 PlaceholderScreen builders in router.  
- **FACT:** 131 feature screen dart files.  
- **INFERENCE:** Placeholders will be replaced as harness cards ship.  
- **UNKNOWN:** Exact count of screen files that are fully wired vs orphaned without opening every route builder (partial audit done).
