# 04 — Architecture and Service Map (Family OS)

**Date:** 2026-09-23  
**Stack evidence:** `app/pubspec.yaml`, `app/lib/main.dart`, `app/lib/app/`, `app/lib/core/`

---

## Top-level architecture (FACT)

```
┌─────────────────────────────────────────────────────────┐
│ FamilyOsApp (MaterialApp.router, AR locale, Role scope) │
│  └─ FamilyShellHost (tabs/hub/FABs chrome)              │
│      └─ GoRouter (generated flat routes + RoleGuard)    │
│           └─ Feature screens                            │
│                └─ Repository interfaces                 │
│                     └─ InMemory / Prefs(Memory) impls   │
│                          └─ core/policy engines & buses │
└─────────────────────────────────────────────────────────┘
         ▲
         │  NO network client, NO Firebase, NO Drift
         │
family-os/_CONTRACTS/schema.sql  (design-time Postgres contract)
```

**Composition root:** `main.dart` constructs `RoleController` + `createAppRouter`. Feature screens typically construct or inject repositories in constructors/tests (not a global DI container like Riverpod).

---

## State management (FACT)

| Expected in some docs | Actual in code |
|---|---|
| Riverpod | **NOT in pubspec** |
| Freezed models | **Not required by pubspec**; models are hand-written immutable classes |
| ChangeNotifier / InheritedWidget | **USED** widely |

Evidence: `RoleController`, policy services extending `ChangeNotifier`, `MotherPermissionLevelRepository extends ChangeNotifier`.

---

## Major runtime services (selected)

| Service | Class / path | Status | Notes |
|---|---|---|---|
| Router | `createAppRouter` / `router.dart` | A | Generated |
| RoleGuard | `role_guard.dart` | A | Path redirects |
| PolicyEngine | `policy_engine.dart` | A | Pure minutes rules |
| TimeEngine | `time_engine.dart` | A | Cap/wallet/schedule decisions |
| PolicySyncBus | `policy_sync_bus.dart` | F/A in-process | Parent→child mirror |
| WebUnlockService | `web_unlock_service.dart` | A in-process | Approve/deny + bus |
| DeviceLockService | `device_lock_service.dart` | A in-process | Lock supersession |
| ChildModeLockService | `n05_lock/child_mode_lock_service.dart` | B/F | In-app lock UX |
| NotificationDelivery | `notification_delivery.dart` | A rules / H push | Simulated |
| MockSosFireService | `sos_fire.dart` | F | No telecom |
| MockEntitlementService | `entitlement_service.dart` | F | Billing mock |
| FamilyDataLifecycleService | `family_data_lifecycle.dart` | B | Forget≠wipe mock |
| AdvisorRepository | `advisor_repository.dart` | F | Mock suggestions |
| AuditLogRepository | `n07_privacy/audit_log_repository.dart` | A mock | Append-only API |
| DayBoardProjectionRepository | `day_board_projection.dart` | B/F | State phases |
| FakeDeviceHealthSeam | `n12_devices/device_health_seam.dart` | F | Repair round-trip fake |
| FakeCameraPermissionSeam | used by child QR | F | UI-003 |

---

## Repository pattern (Rule 25 intent vs reality)

**Intent (constitution):** Widgets → providers → repository interfaces; mock today, API tomorrow; zero UI change on swap.

**Reality (FACT):**

- Abstract repositories + `InMemory*` / `Prefs*` implementations are widespread (~98 repository files).  
- `Prefs*` backends take a `*PrefsStore` with **memory map** default — comments say SharedPreferences adapter-ready.  
- **No** `api/` implementations found in this discovery.  
- Root `API_CONTRACT.md` table is essentially empty (header only).  
- Swapping mock→API would require adding packages + implementations; UI often constructs concrete repos today → **partial seam compliance** (status **B**).

---

## Design system

- Tokens: `core/design/tokens.dart` (constitution: do not modify without owner).  
- Components: `core/design/components/` (`PrimaryBtn`, `AppEmptyState`, `AppErrorState`, `SettingsPersistToggle`, etc.).  
- i18n: ARB → `core/i18n/app_localizations*.dart` (Arabic default).

---

## Native / platform layer

| Platform | Finding | Status |
|---|---|---|
| Android | `MainActivity.kt` extends `FlutterActivity` only | H for DO/VPN/Usage |
| iOS | Standard Flutter scaffold (not deeply audited here) | UNKNOWN depth |
| Permissions | Explainer UI + fake seams | F |

---

## Test & verification architecture

- Widget/unit tests under `app/test/` (~170 files).  
- Harness ship gate: `python .cursor/hooks/verify_ship.py verify`.  
- Tests prove **render, buttons, mock loop closure** — not physical device enforcement.

---

## Backend relationship

```
Feature UI ──► Repository interface ──► InMemory/Prefs(Memory)
                      │
                      ✕ no HTTP
                      ✕ no Firestore
                      │
schema.sql (docs) ─► future Postgres (D/E only today)
```

---

## FACT / INFERENCE

- **FACT:** Minimal dependency set; mock-first declared.  
- **FACT:** Policy logic is extensive and tested.  
- **INFERENCE:** Architecture is intentionally staged for backend-readiness.  
- **UNKNOWN:** Whether a sibling backend repo exists outside this tree.
