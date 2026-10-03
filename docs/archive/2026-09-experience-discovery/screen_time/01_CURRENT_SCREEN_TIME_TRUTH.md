# 01 — Current Screen Time Truth

**System:** Screen Time + Minutes Economy (System #2)  
**Mode:** Discovery only — repository code is source of truth for CURRENT behavior  
**Date:** 2026-09-23  
**Labels:** `CURRENT FACT` · `PARTIAL` · `UI ONLY` · `MOCK/STUB` · `DISCONNECTED` · `NOT FOUND` · `POLICY LAW` (Register/Constitution — may exceed code)

Classification legend (capability maturity):

| Code | Meaning |
|---|---|
| **A** | Implemented and connected in-process |
| **B** | Partial |
| **C** | UI only |
| **D** | Backend contract only |
| **E** | Model only |
| **F** | Mock / stub |
| **G** | Disconnected (parallel surfaces) |
| **H** | Not found |

---

## Executive verdict (`CURRENT FACT`)

Family OS Stage-1 has a **real in-process policy spine** for daily entertainment caps, schedule windows, `TimeEngine` precedence, `PolicySyncBus` parent→child mirror, parent time-request inbox, instant lock, smart-mode activation flags, and time-expiry exemptions (chat / Quran / SOS).

It does **not** have:

- OS metering or app blocking (Android Usage Access / Device Owner / iOS Family Controls)
- `WalletLedger.consume` / spend
- CHD-020 → FAT-033 closed loop (child request UI is a parallel mock)
- Time-grant → wallet deposit
- FAT-034 app inventory wired into `ScreenTimePolicy` / `TimeEngine`
- CHD-019 wallet UI wired into `WalletLedger`
- Postgres economy tables in `schema.sql`
- Push / multi-device sync beyond in-process buses

**Maturity:** Strong **policy simulation** · Weak **device enforcement** · Broken **child↔parent request loop** · Split **Minutes surfaces**.

---

## Capability matrix

| Capability | Class | Evidence |
|---|---|---|
| Daily entertainment cap | **A** (prefs) | `ScreenTimePolicy.dailyCapMinutes`; FAT-032 save → `PolicySyncBus` |
| Remaining minutes mirror | **A** | `ChildPolicyMirror.remainingMinutes` = `cap − used`; CHD-004 + `ChildScreenTimeMirror` |
| `usedMinutesToday` metering | **F** | Comment: “Mock daily usage (SET-002 Stage-1; real metering later)” |
| Schedule windows (sleep/prayer/study) | **A** (prefs) | `ScheduleWindow` + `ScheduleWindowRepository`; FAT-032 |
| Per-app daily limits | **F** / **G** | `ChildAppEntry.limitMins` in mock inventory only — not in `ScreenTimePolicy` |
| Allowed / unlimited / blocked apps | **B** / **G** | Domain: `permanentlyBlocked`, mode lists, edu non-countable. FAT-034 mock statuses not feeding `TimeEngine` |
| Wallet overflow switch | **A** | `allowWalletOverflow` + SET-024 / Ruling B in `TimeEngine` |
| Instant lock | **A** in-app | `DeviceLockService` + FAT-037; OS lock **H** |
| Smart modes × access | **B** | `TimeContext.modeActive` / `appAllowedInMode`; FAT-085 activation bus; OS Focus **H** |
| Web filter × screen time | **G** (separate) | Unlock grants URLs, not entertainment minutes |
| Time expiry UI | **A** | CHD-021 + `TimeExpirySurface`; exempt `chat`/`quran`/`sos` |
| Parent time-request decide | **A** service | `TimeRequestService` + FAT-033 |
| Child time-request submit | **F** / **G** | `ChildTimeRequestRepository.submit` local status only — does **not** call `createRequest` |
| Grant → Minutes deposit | **B** / gap | Approve writes `TimeGrant` row; **no** `WalletLedger.earn` |
| Usage report | **F** | FAT-069 fixture repository |
| New app approval | **F** | FAT-035 mock |
| Anti-tamper list | **B** | FAT-038 UI; honesty badges; no OS sensors |
| OS enforcement | **H** | No UsageStats / FamilyControls integration |
| FCM / cross-device sync | **H** | `PolicySyncBus` same-isolate only |
| Audit append on time decide | **B** | `decidedBy` labels stored; no `AuditAppend` in `TimeRequestService` |

---

## Core policy spine (connected)

| Symbol | Path | Role |
|---|---|---|
| `Minutes` | `app/lib/core/domain/minutes.dart` | Non-negative currency VO |
| `ScreenTimePolicy` / `AppWallet` | `app/lib/core/policy/screen_time_policy.dart` | Cap + per-app wallets |
| `ScreenTimePolicyRepository` | `…/screen_time_policy_repository.dart` | Prefs + InMemory |
| `ScheduleWindow*` | `…/schedule_window.dart` (+ repo/query) | Sleep / prayer / study |
| `TimeEngine` | `…/time_engine.dart` | Precedence ladder |
| `TimeExpirySurface` | `…/time_expiry_surface.dart` | Exempt surfaces |
| `PolicySyncBus` | `…/policy_sync_bus.dart` | Parent→child mirror |
| `WalletLedger` | `…/wallet_ledger.dart` | earn / deposit / balance — **no consume** |
| `PolicyEngine` | `…/policy_engine.dart` | `rewardForAssignee` / `depositOnApproval` |
| `TimeRequestService` | `…/time_request_service.dart` | create / approve / reject / offline queue |
| `DeviceLockService` | `…/device_lock_service.dart` | Instant lock |
| `SmartModes*` | `…/smart_modes.dart` (+ prefs / activation) | Mode flags |

---

## Screens & routes (`CURRENT FACT`)

| Screen ID | Route | Widget | Repo / service | Class |
|---|---|---|---|---|
| SCR-FAT-032 | `/scr-fat-032` | `ChildScreenTimeScreen` | Prefs policy + schedules + sync bus | **A** |
| SCR-FAT-033 | `/scr-fat-033` | `RequestInboxScreen` | `TimeRequestService` | **A** |
| SCR-FAT-034 | `/scr-fat-034` | `ChildAppsScreen` | `ChildAppsRepository` mock | **F**/**G** |
| SCR-FAT-035 | `/scr-fat-035` | `NewAppApprovalScreen` | local mock | **F** |
| SCR-FAT-036 | `/scr-fat-036` | Web filter screens | web filter policy | related **A** separate |
| SCR-FAT-037 | `/scr-fat-037` | `InstantLockScreen` | `DeviceLockService` | **A** in-app |
| SCR-FAT-038 | `/scr-fat-038` | Anti-tamper | honesty UI | **B** |
| SCR-FAT-069 | `/scr-fat-069` | `ChildUsageReportScreen` | fixture repo | **F** |
| SCR-FAT-085 | `/scr-fat-085` | `SmartModesScreen` | activation bus | **A** flags |
| SCR-CHD-004 | day board | `ChildDayBoardScreen` | `PolicySyncBus` remaining | **A** |
| SCR-CHD-019 | `/scr-chd-019` | `ChildWalletScreen` | fixture ≠ ledger | **F**/**G** |
| SCR-CHD-020 | `/scr-chd-020` | `ChildTimeRequestScreen` | local snapshot | **F**/**G** |
| SCR-CHD-021 | `/scr-chd-021` | `TimeExpiryScreen` | `TimeExpirySurface` | **A** |
| (P12 host) | n/a | `ChildScreenTimeMirror` | sync bus | **A** test host |

FAT-039 school mode is a **tombstone** → redirects to FAT-085 (ADR-034).

---

## Current user journeys (as coded)

### Father / Primary

| Intent | What happens today | Class |
|---|---|---|
| View remaining | FAT-032 shows cap/used; child mirror via sync | **A** (mock used) |
| Configure daily cap | FAT-032 edit → save policy → publish sync | **A** |
| Configure schedules | FAT-032 schedule section → prefs + sync kind `schedule` | **A** |
| App/category limits | FAT-034 shows mock limits — **not** saved into `ScreenTimePolicy` | **G** |
| Allow/unlimited apps | Mock statuses on FAT-034 | **F** |
| Add/remove time | Cap edit + overflow toggle; no live “bonus time” control separate from grant | **B** |
| Approve/deny requests | FAT-033 → `TimeRequestService` | **A** (grant not deposited) |
| Inspect usage | FAT-069 fixture charts | **F** |
| Override / lock | FAT-037 instant lock | **A** in-app |
| Understand conflicts | Soft sync status pending/delivered/offlineQueued | **B** |
| Offline recover | Sync bus queue + time-decision offline queue | **F** Stage-1 |

**FAT-032 edit gate:** `_canEdit` returns true only for `AppRole.father` — Mother FULL cannot edit schedules/caps in current UI (`PARTIAL` vs Register FULL edit law).

### Mother

| Level | Screen-time decide (FAT-033) | Instant lock | Edit FAT-032 | Anti-tamper |
|---|---|---|---|---|
| Observer | `canDecide == false` | No | No | Invisible (ADR-035-b) |
| Partner | Approve/reject; grant ≤ ceiling (default 30) | No | No | Invisible |
| Full | Same ceiling on grant; Register allows rule edit | Yes (`DeviceLockActor`) | **UI says no** (gap) | Invisible |

Evidence: `TimeRequestActor.canDecide` / `canGrantMinutes`; FAT-032 `_canEdit`; ADR-035 / ADR-039.

### Child

| Intent | Today | Class |
|---|---|---|
| Remaining time | CHD-004 binds `PolicySyncBus` | **A** |
| Active schedule | Mirror schedules + sleep notice flag | **B** |
| Restricted / expired | CHD-021 when entertainment denied | **A** UI |
| Warning before expiry | Register S-3 = 5 min — **no dedicated warning pipeline found** | **H** / law only |
| Request more time | CHD-020 local pending — **not** in FAT-033 inbox | **G** |
| Granted / denied feedback | `TimeRequestDecisionBus` exists for service path; CHD-020 does not use it | **B**/**G** |
| Wallet / earned | CHD-019 fixture minutes | **G** |
| Usable at expiry | chat, Quran, SOS CTAs | **A** |
| SOS | Always reachable per exemption lists | **A** policy |

---

## Tests (proof surface)

**n03:** `child_screen_time_screen_test`, `child_time_mirror_test`, `child_apps_screen_test`, `new_app_approval_screen_test`, `child_time_request_screen_test`, `child_usage_report_screen_test`, `ui_011_time_expiry_test`

**policy:** `minutes_test`, `policy_engine_economy_test`, `time_engine_test`, `screen_time_policy_test`, `schedule_window_test`, `policy_sync_bus_test`, `smart_modes_test`, `device_lock_service_test`

**adjacent:** `ui_006_request_inbox_test`, `ui_005_child_day_board_test`, instant lock / smart modes / child wallet / attribution earn tests

---

## Schema / backend

| Item | Status |
|---|---|
| `schema.sql` wallet / cap / grant tables | **H** |
| `perm_key` `USAGE_STATS`, `SCREEN_TIME_IOS` | present (permissions enum only) |
| Gap-closure proposed D-1/D-2/D-3 | **D** in `docs/project-plan/08-gap-closure-specs.md` |

---

## Honesty summary

| Claim a parent might believe | Current truth |
|---|---|
| “Daily limit is enforced on the phone” | **False** — Flutter policy only |
| “Remaining time is measured from usage” | **False** — `usedMinutesToday` is stored mock |
| “Child request appears in my inbox” | **False** for CHD-020 path |
| “Approved minutes go to the wallet” | **False** — `TimeGrant` only |
| “App list rules drive access” | **False** — FAT-034 disconnected |
| “Chat/Quran/SOS stay open at expiry” | **True** in policy + CHD-021 |
| “Minutes are the only currency” | **True** in core domain; some registry titles still say “نقاط” (ADR-036 legacy) |

See also: [02_MINUTES_ECONOMY_CURRENT_TRUTH.md](02_MINUTES_ECONOMY_CURRENT_TRUTH.md), [20_SCREEN_TIME_MASTER_TRUTH.md](20_SCREEN_TIME_MASTER_TRUTH.md).
