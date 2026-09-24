# 03 — FS-002 Code and Data Map

**Mode:** Discovery map of symbols, stores, routes, contracts.

---

## 1. Feature module

| Path | Symbols / role | Status |
|---|---|---|
| `app/lib/features/n04_web_filter/web_filter_screen.dart` | `WebFilterScreen`, `stage1WebFilterPrefsStore`, preview fixture URL | Parent FAT-036 UI |
| `app/lib/features/n04_web_filter/web_block_page.dart` | `WebBlockPage`, `webFilterHumanReason`, `defaultWebUnlockRequest` | Child-facing block + unlock CTA |
| `app/lib/features/n04_web_filter/web_unlock_inbox.dart` | Parent pending unlock list Approve/Deny | SET-006 UI |
| `app/lib/features/n04_web_filter/home_router_filter_screen.dart` | FAT-078 UI | Mock-driven |
| `app/lib/features/n04_web_filter/home_router_filter_repository.dart` | `InMemoryHomeRouterFilterRepository` | Mock |
| `app/lib/features/n04_web_filter/home_router_filter_models.dart` | Snapshot flags (`dnsActive`, `protected`, …) | Mock model |

---

## 2. Policy core

| Path | Symbols | Behavior |
|---|---|---|
| `app/lib/core/policy/web_filter_policy.dart` | `WebFilterLevel`, `WebFilterCategories`, `WebFilterPolicy` | level · 6 categories · allowList · policyVersion · updatedAt · JSON |
| `app/lib/core/policy/web_filter_evaluator.dart` | `WebFilterDecision`, `WebFilterAllow`/`Deny`, `WebFilterDecisionSnapshot`, `WebFilterEvaluator` | allowList → classify → deny/allow |
| `app/lib/core/policy/web_filter_policy_repository.dart` | `WebFilterPolicyRepository`, `Prefs*`, `InMemory*`, `MemoryWebFilterPrefsStore` | Rule 25 seam; Drift deferred |
| `app/lib/core/policy/web_unlock_request.dart` | Request model/status | Pending/approved/denied |
| `app/lib/core/policy/web_unlock_request_repository.dart` | Prefs/InMemory request store | |
| `app/lib/core/policy/web_unlock_service.dart` | `WebUnlockService`, `WebUnlockDecisionBus`, `AuditAppend`, stage1 singletons | request/approve/deny → mutate allowList |

**Decision order (code):** allow-listed host → category match if enabled → else allow. Level `open` does **not** skip explicit category blocks (commented edge case).

---

## 3. Routes

| Route | Screen | File |
|---|---|---|
| `/scr-fat-036` | `WebFilterScreen` | `app/lib/app/router.dart` |
| `/scr-fat-078` | Home router filter | `router.dart` |

No dedicated `/scr-chd-*` web-block route identified as primary; `WebBlockPage` is a widget (preview sheet + tests).

---

## 4. Related entry points (not owners)

| Path | Relation |
|---|---|
| `child_profile_screen.dart` | Tool row `web_filter` → navigate FAT-036 |
| `children_list_*` ARB | “Shared web filter” copy |
| `platform_capability_table.dart` | `MonitoringFeature.webFilter` claimed levels |
| `smart_supervision_*` / monitoring prefs | Desired `webFilter` feature bit (honesty UI) |
| `n02_day/request_inbox_*` | Time/web unlock **inbox patterns** adjacent; web unlock primary host is FAT-036 inbox |

---

## 5. Data stores (CURRENT)

| Store | Durability | Notes |
|---|---|---|
| `MemoryWebFilterPrefsStore` / JSON string map | Process (+ shared map in tests) | Not proven SharedPreferences production wiring |
| `MemoryWebUnlockPrefsStore` | Same | |
| `stage1WebUnlockAudit` | In-memory list | Not Drift `audit_log` |
| `stage1WebUnlockDecisionBus` | In-process ChangeNotifier | Not FCM |
| Home router snapshot | InMemory seed | Fake `deviceCount` / `dnsActive` |

**SQLite / Drift / schema.sql:** no `web_filter_policy` / `web_unlock_request` tables implemented.  
**Proposed (gap specs only):** WFP + WFR DDL in `docs/project-plan/08-gap-closure-specs.md` — **Referenced, not implemented**.

---

## 6. Backend / cloud

| Layer | Finding |
|---|---|
| Firebase / Firestore | Absent from `app/pubspec.yaml` |
| HTTP web-filter APIs | Not found in app |
| Render / external filter intel | Not found |

---

## 7. i18n

ARB keys under `webFilter*`, `webBlock*`, `webUnlock*`, `homeRouterFilter*` in `app_en.arb` / `app_ar.arb` — UI strings exist for Stage-1 surfaces.

---

## 8. Fake vs real behavior (callouts)

| Appearance | Reality |
|---|---|
| “Preview what child sees” | Same evaluator + `WebBlockPage(isPreview: true)` |
| Category block of `adult.example` | Fixture map / keyword heuristic |
| Unlock approve | Mutates in-app allowList; toast + bus |
| Router “protection check” | Increments counter / returns same snapshot |
| Android “full” web filter capability | Table fixture only — no OS code |
