# 07 — FS-003 Test and Validation Audit

**Mode:** Evidence of what tests prove — and what they cannot prove.  
**Master:** [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md)

---

## 1. Tests that touch app control

| Test file | Coverage |
|---|---|
| `app/test/features/n03_screen_time/child_apps_screen_test.dart` | Empty/one/many; allow/block; pending→035; RoleGuard lean; observer hint |
| `app/test/features/n03_screen_time/new_app_approval_screen_test.dart` | Approve/deny; observer; access-rules persist |
| `app/test/core/policy/app_access_rules_query_test.dart` | Rule → TimeContext → TimeEngine (blocked / unlimited / grant) |
| `app/test/core/policy/time_engine_test.dart` | Full precedence ladder including `deniedBlocked` |
| `app/test/core/policy/screen_time_policy_test.dart` | Policy → TimeEngine (adjacent) |
| `app/test/core/policy/policy_sync_bus_test.dart` | Offline queue / idempotent apply — **screen time only** |
| `app/test/core/policy/time_request_service_test.dart` | Minutes request lifecycle (adjacent) |
| `app/test/features/n03_screen_time/child_time_request_screen_test.dart` | CHD-020 UI (adjacent) |
| `app/test/features/n03_screen_time/ui_011_time_expiry_test.dart` | CHD-021 + AppAccess (adjacent) |
| `app/test/app/router_routes_test.dart` | Route resolves to `ChildAppsScreen` |

---

## 2. What tests prove (CURRENT)

- FAT-034/035 **render** and **in-app** allow/block/approve loops against mock repositories.  
- AuthZ lean/observer variants at widget level.  
- `AppAccessRuleQuery` algebra is consistent with `TimeEngine` when called.  
- Screen-time sync bus simulates offline delivery (**not** app rules).

---

## 3. What tests do **not** prove

| Claim | Test status |
|---|---|
| FAT-034 block → child device denial | **No integration test** (impossible without enforcement layer) |
| PackageManager inventory accuracy | **None** |
| UsageStats / Accessibility / Device Owner | **None** |
| App rules on `PolicySyncBus` | **None** (bus tests exclude app rules) |
| Unified Web Filter ∩ App Control evaluator | **None** |
| Launch interception | **None** |
| Uninstall / force-stop resistance | **None** |

---

## 4. Validation honesty

Stage-1 “green tests” for FAT-034/035 validate **UI + mock persistence + policy algebra**, not **OS application control**.

`EnforcementStatusBadge` is the product honesty surface for simulated enforcement.

---

## 5. GAP_LOG / QUESTIONS

| Source | Finding |
|---|---|
| `GAP_LOG.md` | **No matches** for FAT-034 / FAT-035 / app-control enforcement gaps |
| `QUESTIONS.md` | **No open FS-003 questions** recorded at discovery time |
| Experience gaps | `docs/experience_discovery/screen_time/17_SCREEN_TIME_EXPERIENCE_GAPS.md` — ST-GAP class items for FAT-034 ↔ TimeEngine disconnect (docs may lag code: query exists but feature wiring still missing) |

---

## 6. Verdict

**Test reality:** Strong Flutter coverage for Stage-1 app-control **screens and algebra**.  
**Zero** OS / child-device enforcement proof.
