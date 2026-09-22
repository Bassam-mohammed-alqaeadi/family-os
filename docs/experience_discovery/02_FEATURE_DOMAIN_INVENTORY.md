# 02 — Feature Domain Inventory (Family OS)

**Source of truth:** `app/lib/features/`, `app/lib/core/policy/`, `family-os/_REGISTRY/screens.csv`  
**Date:** 2026-09-23  

Status codes: A–H (see `15_MASTER_DISCOVERY_SUMMARY.md`).  
**A = connected in Flutter process only**, unless noted.

---

## Domaِِin catalog

### D01 — Shared onboarding & identity UI
- **Folders:** `features/shared_onboarding/`
- **Screens:** welcome, create account, login, device mode, device user switch
- **Services:** mock navigation; `DeviceUserSwitchRepository`
- **Status:** **F/B** — UI flows work; **no real auth/account persistence**
- **Evidence:** `welcome_screen.dart`, `login_screen.dart`, `device_mode_screen.dart`, `app/lib/main.dart` (default role father)

### D02 — Family linking & pairing
- **Folders:** `features/n01_linking/`
- **Screens:** create family, wizard, add child, QR, permissions explainer, link success, trial, invite/accept mother, child welcome/QR/transparency
- **Status:** **C/F** — mock QR TTL, fake camera permission seam; no real pairing token exchange
- **Evidence:** `link_qr_screen.dart`, `child_qr_scan_screen.dart`, `onboarding_progress_repository.dart`

### D03 — Day board & family hub
- **Folders:** `features/n02_day/`
- **Screens:** day board, children list/profile, alerts, location/safe zones, chat/call UIs, request inbox, many Wave-3 child social screens
- **Status:** **B/F** — projection repository + empty/loading/error states; location/chat/call = in-memory; some routes may be wired screens vs placeholders (see doc 03)
- **Evidence:** `day_board_projection.dart`, `mock/register_mock_family.dart`

### D04 — Screen time & minutes economy
- **Folders:** `features/n03_screen_time/`, `core/policy/screen_time_*`, `time_engine.dart`, `wallet_ledger.dart`, `policy_engine.dart`
- **Status:** **A (in-process)** / **H (OS enforcement)**
- **Evidence:** `PrefsScreenTimePolicyRepository`, `PolicySyncBus`, `ChildScreenTimeMirror` tests

### D05 — Web filter
- **Folders:** `features/n04_web_filter/`, `core/policy/web_*`
- **Status:** **A (evaluate + mock unlock loop)** / **H (real DNS/VPN/filter)**
- **Evidence:** `WebFilterEvaluator`, `WebUnlockService`, `home_router_filter_*` (mock)

### D06 — Lock & anti-tamper
- **Folders:** `features/n05_lock/`, `core/policy/device_lock_*`, `anti_tamper_*`
- **Status:** **A (in-app state)** / **H (Device Admin / MDM)**
- **Evidence:** `DeviceLockService`, `ChildModeLockService`, honesty banner for no Device Admin delete

### D07 — Notifications prefs
- **Folders:** `features/n06_notifications/`, `core/policy/notification_*`
- **Status:** **A (prefs + delivery rules)** / **H (FCM/OS notifications)**
- **Evidence:** `NotificationDelivery.shouldDeliver`, SOS pierce tests

### D08 — Privacy, audit, transparency
- **Folders:** `features/n07_privacy/`, `core/policy/privacy_*`, `family_data_lifecycle.dart`
- **Status:** **A (mock append-only audit + collection scopes)** / **D/E (schema audit_log table unused at runtime)**
- **Evidence:** `AuditLogRepository` (load+append only), `WhatIsCollectedScreen`

### D09 — Advisor / AI
- **Folders:** `features/n07_advisor/`, `core/policy/advisor_repository.dart`, `ai_*`
- **Status:** **F** — MockAdvisor; stages are flags; no inference
- **Evidence:** `AiStageFlagsRepository`, `BrainControlScreen`, Rule 26 comments

### D10 — Platform monitoring & smart alerts
- **Folders:** `features/n08_platform/`
- **Status:** **B** — capability honesty table + desired prefs; smart alerts mostly mock lists
- **Evidence:** `PlatformCapabilityTable`, `CapabilityHonestyTile`

### D11 — Smart modes
- **Folders:** `features/n09_smart_modes/`, `core/policy/smart_mode_*`
- **Status:** **A (prefs + activation bus → child day board tint)** / **H (device focus mode)**
- **Evidence:** `SmartModeActivationBus`, SET-019

### D12 — Emergency / SOS
- **Folders:** `features/n10_emergency/`, `core/policy/sos_*`
- **Status:** **B/F** — UI + ladder + MockSosFire; no real SMS/call/location stream
- **Evidence:** `SosLadderRepository`, `MockSosFireService`

### D13 — Billing
- **Folders:** `features/n11_billing/`, `core/policy/entitlement_*`
- **Status:** **F** — MockEntitlement; father-only RoleGuard; safety ungated by design tests
- **Evidence:** `PlansScreen`, `ui_007_paywall_boundary_test.dart`

### D14 — Devices, members, mother level, settings hub
- **Folders:** `features/n12_devices/`
- **Status:** **B/F** — FakeDeviceHealthSeam; mother level repo ChangeNotifier
- **Evidence:** `mother_permission_level_repository.dart`, `device_health_seam.dart`

### D15 — Coming soon catalog
- **Folders:** `features/n13_coming_soon/`
- **Status:** **C** — honesty “no fake dates”
- **Evidence:** `ComingSoonScreen`, UI-013

### D16 — Education studio (parent)
- **Folders:** `features/n14_studio/`, `features/education/`
- **Status:** **B/G** — many screens+repos; some routes still placeholders; P15 education loops partially open
- **Evidence:** `GAP_LOG.md` P15-EDU-006/007 OPEN; `preview_approve_*`, `approved_pack_*`

### D17 — Calendar & tasks
- **Folders:** `features/n15_calendar/`, `features/n16_tasks/`
- **Status:** **F/B** — InMemory create/list; chore distributor mock
- **Evidence:** `family_calendar_repository.dart`, `smart_chore_distributor_repository.dart`

### D18 — Child learn
- **Folders:** `features/n17_child_learn/`
- **Status:** **G/F** — many `*_screen.dart` exist; **router still PlaceholderScreen for SCR-CHD-012+** (spot-checked)
- **Evidence:** `router.dart` CHD-012… vs `child_learn_home_screen.dart` etc. **not imported in router**

---

## Cross-cutting services (core)

| Service area | Path | Status |
|---|---|---|
| PolicyEngine (minutes) | `core/policy/policy_engine.dart` | A pure logic |
| TimeEngine | `core/policy/time_engine.dart` | A pure logic |
| RoleGuard | `app/role_guard.dart` | A route gating |
| MotherLevel / WebUnlockActor | `core/domain/mother_level.dart` | A approve rules |
| Chat mock store | `core/policy/chat_mock_store.dart` | F |
| Platform capability table | `core/policy/platform_capability_table.dart` | E/F fixture |

---

## Domain → role relevance

| Domain | Father | Mother | Child |
|---|---|---|---|
| Onboarding | Primary | Invite accept | Pairing path |
| Day board | Primary | Shared (level-dependent UNKNOWN depth) | Own day board |
| Screen time | Configure | Approve if partner/full | Mirror / request |
| Web filter | Configure | Approve unlock if allowed | Block page / request |
| SOS | Receive / setup | Always receive | Fire |
| Billing | Owner only | Blocked | N/A |
| Brain control | Father only | Blocked | Blocked |
| Education | Studio | Limited / UNKNOWN | Learn (routes often placeholder) |
