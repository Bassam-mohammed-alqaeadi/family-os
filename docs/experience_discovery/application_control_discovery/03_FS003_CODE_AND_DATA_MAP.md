# 03 — FS-003 Code and Data Map

**Mode:** Evidence map only — no redesign.  
**Master:** [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md)

---

## 1. Flutter feature surfaces

| Path | Role |
|---|---|
| `app/lib/features/n03_screen_time/child_apps_screen.dart` | SCR-FAT-034 UI + `_AppControlSheet` allow/block/unlimited |
| `app/lib/features/n03_screen_time/new_app_approval_screen.dart` | SCR-FAT-035 approve/deny pending install |
| `app/lib/features/n03_screen_time/child_apps_models.dart` | `ChildAppEntry`, `ChildAppStatus`, `toAccessRule` / `applyAccessRule` |
| `app/lib/features/n03_screen_time/child_apps_repository.dart` | `ChildAppsRepository` seam; `InMemoryChildAppsRepository` persists axes |
| `app/lib/features/n03_screen_time/child_apps_mock.dart` | Fixture inventory (`minecraft`, `roblox`, `snapchat` pending, …) |
| `app/lib/app/router.dart` | Routes `SCR-FAT-034`, `SCR-FAT-035` |

---

## 2. Policy core

| Path | Role |
|---|---|
| `app/lib/core/policy/app_access_rules.dart` | `AppAccessRule` (blocked, limitMinutes, countable, unlimited); `AppAccessRuleSet`; `AppAccessRuleQuery.applyRule` → `TimeContext` |
| `app/lib/core/policy/app_access_rules_repository.dart` | Prefs/in-memory repo; key `app_access_rules:{childId}`; `AppAccessRuleMapper` |
| `app/lib/core/policy/time_engine.dart` | Precedence ladder → `AppAccess` enum |
| `app/lib/core/policy/screen_time_policy.dart` | Caps, wallets, countable defaults |
| `app/lib/core/policy/screen_time_policy_query.dart` | Builds `TimeContext` from policy + wallet (**no** `AppAccessRule` merge) |
| `app/lib/core/policy/temporary_grant_query.dart` | Temporary **minutes** grant remaining/expiry |
| `app/lib/core/policy/time_request.dart` / `time_request_service.dart` | Minutes request lifecycle (adjacent) |
| `app/lib/core/policy/policy_sync_bus.dart` | Syncs **ScreenTimePolicy + ScheduleWindow only** |
| `app/lib/core/policy/anti_tamper_*.dart` | Anti-tamper flags (UI/prefs — adjacent) |

### Critical wiring gap

`AppAccessRuleQuery` is imported **only in unit tests** (`app/test/core/policy/app_access_rules_query_test.dart`).  
Feature screens / day-board paths **do not** call it at runtime.

---

## 3. Domain model sketch (CURRENT)

```
ChildAppEntry (UI inventory row)
  id: String slug          ← not Android packageName
  status: allowed|free|blocked|pending
  limitMins, unlimited, instantLocked (display; toggle unwired)
       │
       ▼ toAccessRule()
AppAccessRule
  appId, blocked, limitMinutes, countable, unlimited
       │
       ▼ AppAccessRulesRepository.save (parent prefs)
       │
       ✗ NOT published on PolicySyncBus
       ✗ NOT applied via AppAccessRuleQuery in features
```

---

## 4. Android native

| Path | Evidence |
|---|---|
| `app/android/app/src/main/kotlin/com/familyos/family_os/MainActivity.kt` | Bare `FlutterActivity()` only |
| `app/android/app/src/main/AndroidManifest.xml` | Launcher activity; no services/receivers/privileged permissions for app control |
| Other Kotlin/Java under `app/android` | **None** beyond MainActivity + standard Flutter manifests |

---

## 5. Schema / contracts

| Artifact | Finding |
|---|---|
| `family-os/_CONTRACTS/schema.sql` | `perm_key` includes `ACCESSIBILITY`, `USAGE_STATS`; **no** `app_rule`, `installed_app`, or package-policy tables |
| `API_CONTRACT.md` | **No** app-control section found |
| `family-os/_REGISTRY/screens.csv` | FAT-034: S-SEC-008/009/012/013; FAT-035: S-SEC-010/011 |

---

## 6. Prototype (frozen)

| Path | Role |
|---|---|
| `family-os/family_os_app.html` | `canUseApp`, `openAppControlSheet`, `setAppStatus`, `setAppLimit`, unlock helpers |
| `family-os/31A_SYSTEM_AUDIT_LOG.md` | Confirms prototype control functions present |
| `family-os/18_PLATFORM_GATES.md` / `prototype/18_PLATFORM_GATES.md` | Documents UsageStats / Device Owner / Accessibility as **strategic** gates — not code |

---

## 7. Providers / state

| Mechanism | Scope |
|---|---|
| `InMemoryChildAppsRepository` extends `ChangeNotifier` | Live FAT-034 list updates in-process |
| `stage1AppAccessRulesStore` | Shared memory prefs store for Stage-1 |
| `CurrentRole` / `MotherLevel` widget params | In-screen AuthZ (see doc 06) |
| Riverpod / dedicated app-control providers | **Not** found as a separate FS-003 provider layer |

---

## 8. Notifications / audit / events

| Mechanism | App-control usage |
|---|---|
| Pending CTA on FAT-034 | In-app navigation to FAT-035 |
| Push / FCM for new install | **Missing** |
| `AuditAppend` on app allow/block | **Not verified** as first-class on FAT-034 mutations |
| `app_rule.*` events named in eng doc | Engineering aspiration (`04_FAT_034_ENGINEERING.md`) — not proven as emitted bus events |

---

## 9. Key absolute paths (index)

**Features**

- `D:\special projects\family\app\lib\features\n03_screen_time\child_apps_screen.dart`
- `D:\special projects\family\app\lib\features\n03_screen_time\new_app_approval_screen.dart`
- `D:\special projects\family\app\lib\features\n03_screen_time\child_apps_repository.dart`
- `D:\special projects\family\app\lib\features\n03_screen_time\child_apps_mock.dart`

**Policy**

- `D:\special projects\family\app\lib\core\policy\app_access_rules.dart`
- `D:\special projects\family\app\lib\core\policy\app_access_rules_repository.dart`
- `D:\special projects\family\app\lib\core\policy\time_engine.dart`
- `D:\special projects\family\app\lib\core\policy\policy_sync_bus.dart`

**Android**

- `D:\special projects\family\app\android\app\src\main\kotlin\com\familyos\family_os\MainActivity.kt`
- `D:\special projects\family\app\android\app\src\main\AndroidManifest.xml`

**Registry / contracts**

- `D:\special projects\family\family-os\_REGISTRY\screens.csv`
- `D:\special projects\family\family-os\_CONTRACTS\schema.sql`

**Adjacent discovery**

- `docs/experience_discovery/screen_time/01_CURRENT_SCREEN_TIME_TRUTH.md`
- `docs/experience_discovery/screen_time_screen_engineering/04_FAT_034_ENGINEERING.md`
- `docs/experience_discovery/web_filtering_l2/09_FS002_CROSS_SYSTEM_BOUNDARIES.md`
