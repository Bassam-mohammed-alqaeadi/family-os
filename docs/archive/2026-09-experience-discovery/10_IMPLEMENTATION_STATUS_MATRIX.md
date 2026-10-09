# 10 — Implementation Status Matrix (Family OS)

**Date:** 2026-09-23  
**Legend:** A connected in-process · B partial · C UI only · D backend-only contract · E model only · F mock/stub · G disconnected · H not found  

Columns: UI · Logic · DB · Backend · Sync/Offline · Permissions · Parent · Co-Parent · Child · Notifications · Audit · Dependencies · Gaps · Evidence  

---

## Matrix (major features)

| Feature | Status | UI | Logic | DB | Backend | Sync | Perms | Parent | Co-Parent | Child | Notif | Audit | Deps | Known gaps | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| App shell / routing | B | A | A | H | H | H | A RoleGuard | A | B | B | H | — | go_router | StatefulShell deferred; 43 placeholders | `router.dart`, `family_shell.dart` |
| Onboarding / auth | F | A | F | H | H | H | F | F | F | F | H | F | — | No real auth | `shared_onboarding/*` |
| Family create / members | F/B | A | F | E | D | H | B | B | B | — | H | B | schema member | No server member | `n01_linking`, `family_members_*` |
| QR pairing | F | A | F | E | D | H | F fake cam | F | — | F | H | F | pairing_token | No enrollment | `link_qr_*`, `child_qr_*` |
| Day board | B | A | B | H | H | F | — | B | B | B | F | F | projection repo | Mock seed optional | `day_board_*`, `register_mock_family.dart` |
| Screen time / minutes | A→H | A | A | H | H | F bus | H OS | A | B approve | A mirror | F | B | PolicyEngine | No OS block | `screen_time_*`, `time_engine.dart` |
| Time requests | A→H | A/G | A | H | H | F | — | A | B | A/G | F | B | TimeRequestService | CHD route may placeholder | `request_inbox_*`, `time_request_*` |
| Web filter | A→H | A | A | H | H | F | H VPN | A | B | A block UI | F | B | evaluator | No real filter | `web_filter_*`, `web_unlock_*` |
| Instant lock / tamper | A→H | A | A | H | H | F | H MDM | A | B | B | F | B | DeviceLockService | Honesty: no Device Admin | `n05_lock`, `device_lock_*` |
| Child mode lock | B/F | A | B | H | H | H | H | B second key | — | B | F | B | ChildModeLockService | Not kiosk | `child_mode_lock_*` |
| Notifications prefs | A→H | A | A | H | H | H | H FCM | A | B | — | F sim | B | NotificationDelivery | No push | `n06_notifications` |
| Privacy / transparency | B | A | B | E | D | F bus | — | A | B | B | H | A mock | collection scopes | No real collectors | `n07_privacy`, `privacy_*` |
| Audit log | B | A | A append | E | D | H | — | A | B | blocked | H | A | R10 API | Memory only | `audit_log_repository.dart` |
| Advisor / AI | F | A | F | E | D | H | — | F | F read | F tutor mocks | F | F | Rule 26 | No gateway | `advisor_*`, `ai_stage_*` |
| Platform honesty | B | A | B | H | H | F | F table | B | — | — | H | B | capability table | No OS probes | `n08_platform` |
| Smart modes | A→H | A | A | H | H | F | H | A | B? | A tint | F | B | activation bus | No Focus Mode | `n09_smart_modes` |
| SOS / emergency | B/F | A | B | E | D | H | H | B | B receive | B fire | F | B | MockSosFire | No telecom/GPS | `n10_emergency`, `sos_*` |
| Billing | F | A | F | E | D | H | — | F owner | blocked | — | H | B | MockEntitlement | No IAP | `n11_billing` |
| Device health | F | A | F | E | D | H | F seam | F | — | — | H | F | FakeDeviceHealthSeam | No OS perms | `n12_devices` |
| Mother levels | B | A | A gates | E | D | H | — | A set | B act | — | H | B | MotherLevel | Soft elsewhere | `mother_permission_*`, `mother_level.dart` |
| Education studio | B/G | A/G | B | H | H | F partial | — | B | F | G routes | F | B | education repos | P15-EDU-006/007 | `n14_studio`, `education/` |
| Child learn | G/F | A files | F | H | H | H | — | — | — | G routes | H | F | n17 repos | Router placeholders | `n17_child_learn`, `router.dart` |
| Calendar | F | A | F | H | H | H | — | F | F | F? | H | F | InMemory | No sync | `n15_calendar` |
| Tasks / chores | F/B | A | F | H | H | H | — | F | F | F | H | F | InMemory | No real assign sync | `n16_tasks` |
| Location / geofence | C/F | A | F | E | D | H | H GPS | C | C | C | H | F | InMemory | No maps SDK | `location_*`, `safe_zones_*` |
| Chat | C/F | A | F | E | D | H | — | C | C | C | H | F | chat_mock_store | No realtime | `conversation_*` |
| Calls | C/F | A | F | E | D | H | — | C | C | C | H | F | InMemory | No LiveKit dep | `active_call_*` |
| Coming soon | C | A | — | — | — | — | — | C | — | — | — | — | — | Honesty only | `coming_soon_screen.dart` |
| Postgres schema | D/E | — | — | E | D | — | E enums | — | — | — | — | E | — | Unimplemented | `family-os/_CONTRACTS/schema.sql` |
| Firebase | H | — | — | — | H | H | H | — | — | — | H | — | — | Absent | pubspec |
| Device Owner / VPN | H | — | — | — | — | — | H | — | — | H | — | — | — | Bare MainActivity | `MainActivity.kt` |

---

## How to read “A→H”

Means: **logic and UI are connected inside the Flutter process**, but **OS/backend/device columns are H**. Do not ship messaging that implies real parental control without those layers.
