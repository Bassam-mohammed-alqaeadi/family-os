# 07 — FS-002 Test & Validation Audit

---

## 1. Test inventory (found)

| Test path | Focus | Proves |
|---|---|---|
| `app/test/core/policy/web_filter_policy_test.dart` | Policy model/JSON/presets | Domain object |
| `app/test/core/policy/web_unlock_service_test.dart` | Request/approve/deny/Observer deny/father wins/prefs restart | Unlock loop AuthZ |
| `app/test/features/n04_web_filter/web_filter_screen_test.dart` | FAT-036 UI | Screen behaviors |
| `app/test/features/n04_web_filter/web_block_page_test.dart` | Block page + preview parity | Shared verdict |
| `app/test/features/n04_web_filter/ui_009_preview_parity_test.dart` | UI-009 AC | Father preview == child verdict; stale refresh |
| `app/test/features/n04_web_filter/web_unlock_loop_test.dart` | End-to-end unlock UI loop | P12-ish in-process |
| `app/test/features/n04_web_filter/home_router_filter_screen_test.dart` | FAT-078 | Mock screen |

Router registration covered indirectly via `router_routes_test.dart`.

---

## 2. What tests do **not** prove

| Gap | Status |
|---|---|
| VPN/DNS/Device Owner blocks real Chrome traffic | **No tests** |
| Multi-device sync of policy | **No tests** |
| Safe-search / private browse | **No tests** (features missing) |
| 29-category catalog | **No tests** |
| Mother Full can edit FAT-036 | **Would fail if asserted** — `_canEdit` father-only |
| FCM unlock notify | **No tests** |
| Drift/schema persistence | **No tests** (deferred) |
| Router actually changes DNS | **No tests** (mock) |

---

## 3. Validation vs GAP_LOG “CLOSED”

SET-004/005/006 + UI-009 closures are **consistent with Flutter test evidence**.  
They are **not** validation of platform enforcement.

---

## 4. Classification

| Layer | Reality |
|---|---|
| Unit/widget (in-app) | **Strong** |
| Integration (OS) | **Missing** |
| Contract/API | **Missing** |
| Honesty of “filtered device” claims | **Unvalidated** — risk |
