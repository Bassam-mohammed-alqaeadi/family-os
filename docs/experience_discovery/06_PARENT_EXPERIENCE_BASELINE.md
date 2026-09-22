# 06 — Parent (Father / Primary Parent) Experience Baseline (Family OS)

**Role in code:** `AppRole.father` (default in `main.dart`)  
**Date:** 2026-09-23  

Scope: what the father can **actually** do in the current app — not the blueprint ideal.

---

## Capabilities that work in-app (stronger)

| Intent | Screens | System logic | Child effect (in-app) | Real device | Status |
|---|---|---|---|---|---|
| Browse day board | FAT-010 | DayBoardProjectionRepository phases | N/A | N/A | B |
| Configure schedules/caps | FAT-032 | ScheduleWindow + ScreenTimePolicy repos → TimeEngine | PolicySyncBus mirror on child screens | None | A→H |
| Approve/deny time request | FAT-033 inbox | TimeRequestService | Child decision seam toast/state | None | A→H |
| Configure web categories + preview | FAT-036 | WebFilterEvaluator | Same verdict on WebBlockPage | None | A→H |
| Approve web unlock | FAT-036 inbox | WebUnlockService | Allow-list update in-process | None | A→H |
| Instant lock / anti-tamper prefs | FAT-037 | DeviceLockService / AntiTamperRepository | Notify bus / exempt chat-quran-sos | None | A→H |
| Smart modes | FAT-085 | SmartMode prefs + activation bus | Child day board status tint | None | A→H |
| Notification prefs | FAT-058 | NotificationPrefs; SOS never muted | Simulated delivery rules | No FCM | A→H |
| Privacy scopes / forget-wipe | FAT-059 | PrivacyCollection + FamilyDataLifecycle | CHD-010 mirror bus | None | B |
| Audit log view | FAT-060 | Append-only repo | N/A | None | B |
| Brain control / AI stages | FAT-029 | AiStageFlags (server-flag mock) | Coming-soon when flag off | No AI | F |
| Approve advisor → rules | FAT-079 | AiSuggestion + RulesEngineRuleRepository | Rules stored in memory | None | B/F |
| Billing view | FAT-056/057 | MockEntitlement; RoleGuard father-only | SOS/chat ungated by design | No store | F |
| Mother permission level | FAT-031 | MotherPermissionLevelRepository | Gates unlock approve | None | B |
| Invite mother | FAT-008 | Mock invite form | Accept screen sets mother role | No email | F |
| Pair child (QR) | FAT-004…006 | Mock QR TTL | Child scan fake permission | No pairing server | F |
| Device health repair | FAT-025/026 | FakeDeviceHealthSeam | N/A | No OS settings | F |
| SOS receive / emergency setup | FAT-018 / FAT-028 | Sos ladder; MockSosFire | Child SOS UI | No SMS/GPS | B/F |
| Education studio | FAT-040…051 | InMemory studio repos; PolicyEngine on reward | Partial; EDU gaps open | None | B/G |
| Location / geofence UI | FAT-014…017 | InMemory repos | None real | No GPS | C/F |
| Chat / call UI | FAT-021…024 | InMemory / mock store | Same-process only | No LiveKit | C/F |

---

## What father cannot do today (real world)

- Enforce screen time or web filter on a physical child phone.  
- Receive real push SOS or location pings.  
- Persist family data across reinstalls/devices.  
- Authenticate against a real account service.  
- Manage real App Store / Play Billing subscriptions.  
- Rely on Device Owner / VPN / Accessibility enforcement (absent).

---

## Recovery / error / empty (FACT)

- Shared templates SHR-005/006 and components `AppErrorState` / `AppEmptyState` used on several spines (e.g. create family UI-001, day board UI-004).  
- SettingsPersistToggle provides loading/error/revert for some toggles (UI-008).  
- Offline often simulated via repository phases / sync status enums — not true network.

---

## Father-only gates (FACT)

From `role_guard.dart`:

- Brain control FAT-029  
- Mother permission level FAT-031  
- Billing FAT-056 / FAT-057  

Privacy FAT-059 / audit FAT-060: owner-only vs **child** (mother may open per comments).

---

## Journey sketch (typical)

`Welcome → Device mode (guardian) → Create account/login (mock) → Create family → Wizard → Add child → QR → … → Day board → Settings spines`

All steps are **UI navigation + mock repositories** unless listed as policy-connected above.
