# FINAL VISUAL · UX · JOURNEY MATRIX

**Date:** 2026-09-25 · **Type:** DOCS-ONLY pre-audit baseline · **Machine-readable companion:** `FINAL_VISUAL_UX_JOURNEY_MATRIX.json`
**Populated from:** `app/lib/app/router.dart` (route params), `app/lib/app/family_shell.dart` + `shell_config.dart` (tabs/hubs), `family-os/_REGISTRY/screens.csv` (purpose/journey/tab), `FRONTEND_COMPLETION_MATRIX.md` (system, native/remote dependency, current status), repository singletons in each screen (`widget.repository ?? stage1…`), and the static findings in `FINAL_VISUAL_UX_JOURNEY_FINDINGS.md`.
**Progress (2026-09-25):** VX-B0 baseline **PASSED** (Owner-run; `.verify/VX-B0-BASELINE.json`). VX-B1 **PASSED** (Owner-run; `.verify/VX-B1-TRUST.json`) — VX-B1 findings G-01, G-07, G-09, C-01, C-03, C-04, C-05 are **CLOSED (FIXED, PASSED 2026-09-25)** on rows SHR-003, FAT-041, FAT-079, FAT-077, FAT-058, FAT-017, FAT-036 and all RoleGuard landings; their phone checks stay PENDING-DEVICE. VX-B2 code done (G-03, G-04, G-05, G-06, S-06) — **FIXED-PENDING-GATE** until the Owner reports the VX-B2 gate. Cells stay PR/PD until the rendered and device passes.
**Rule:** nothing is marked PASS in this baseline. Cells that need a rendered look are **PR** (PENDING-RENDER); cells that need a phone are **PD** (PENDING-DEVICE). Static failures are **F:** + finding ID.

## 1. Legend

| Code | Meaning |
|---|---|
| PR | PENDING-RENDER |
| PD | PENDING-DEVICE (physical phone check required) |
| F:G-04 | FAIL (static) — see finding FVX-G-04 |
| NA | NOT APPLICABLE |
| BN / BR | BLOCKED-NATIVE / BLOCKED-REMOTE (honest closed state still verified) |
| OD | OWNER-DECISION pending |
| FC | Current status FRONTEND COMPLETE (per `FRONTEND_COMPLETION_MATRIX.md`) |
| OOS | Out of scope (FAT-039 tombstone, FAT-077) |
| Ctx ✓route | router forwards `childId`/id query param |
| Ctx ✗drop | per-child screen but router drops `childId` (FVX-G-04) |
| Ctx resolver | reads active child/family from identity/resolver |
| Hub:X | reachable from the tab hub strip of tab X (today/kids/family/studio/settings · myday/learn/cfam/me) |
| Tab | tab root |
| Unbound | production default is an empty in-memory store never bound at boot |
| St | states: L loading · E empty · 1 one · M many · Er error · Off offline · Stl stale · P pending · S success · U unavailable · NC native-closed · RC remote-closed |

**Columns (every screen):** Screen · Role · Journeys · Purpose · Entry · Exit · Data source · Control surface — Primary / Secondary · States · Context · RBAC · Native · Remote · Visual · UX · RTL · Device · Status · Findings · Batch · Evidence · Final.
**Cells marked "(in-form)" or "flow"** for context mean the screen picks the child inside a form or carries state from the previous step; this is to be confirmed in the render pass (not verified by route params).
**Evidence baseline:** 122 `*_screen_test.dart` files exist under `app/test/features/`; each screen's existing test is the regression anchor. Evidence cells such as "welcome test" are short forms of `app/test/features/<area>/<name>_screen_test.dart`; names written in full (e.g. `login_screen_test`) were seen in the repo, the short forms are confirmed at the VX-B1 baseline. New VX evidence is recorded per batch (`.verify/VX-*.json`). All **Final** cells are `PENDING` until the batch gate passes.

---

## 2. Screen matrix (by system group)

### 2.1 ADM:أ Onboarding & identity (JRN-FAT-01/02/03, JRN-CHD-01, JRN-MOT-01)

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-SHR-001 | Any | FAT-01 | Welcome slides + start | App start (initial route) | SHR-007 / SHR-002 / SHR-003 | ARB static | Start / login link | NA list; S | none | Any | — | — | PR | PR | PR | PD cold start | FC | — | VX-B7 | welcome test | PENDING |
| SCR-SHR-002 | Any | FAT-01 | Create account (email+password, no OTP) | SHR-001 | FAT-001 | Identity runtime (local) | Create / login link | Er, S | none | Any | — | Account backend | PR | PR | PR | PD keyboard | FC | — | VX-B7 | create_account test | PENDING |
| SCR-SHR-003 | Any | FAT-01; MOT-01 | Login + recovery | SHR-001/007 | FAT-010 / FAT-009 | Identity/session kernel (local) — credentials ignored | Login / fingerprint, forgot, invite link | Er, S | none | Any | Biometric NC | Auth backend | F:C-02 | F:C-01 | F:C-02 | PD keyboard, touch | FC | G-01, C-01, C-02 | VX-B1, VX-B6 | login_screen_test | PENDING |
| SCR-SHR-007 | Any | FAT-01 | Neutral device mode (parent / my child) | SHR-001 | SHR-003 / CHD-001 | RoleController / device mode prefs | Parent / Child | S | none | Any | — | — | PR | PR | PR | — | FC | — | VX-B7 | device_mode test | PENDING |
| SCR-SHR-008 | Parent | FAT-01 | Switch user on device | Settings "other" shortcut | Role home | Unbound `stage1DeviceUserSwitchRepository` | Switch / password | E, S | none | Parent | — | — | PR | PR | PR | PD role switch | FC | Local reality (§12) | VX-B6 | device_user_switch test | PENDING |
| SCR-FAT-001 | Parent | FAT-01 | Create family | SHR-002 | FAT-002 | Identity FamilyContextStore (SQLite) | Create | Er, S | family | Owner | — | — | PR | PR | PR | PD keyboard | FC | G-05 (downstream) | VX-B2 | create_family test | PENDING |
| SCR-FAT-002 | Parent | FAT-02; FAT-03 | Setup wizard (deferrable steps) | FAT-001 | FAT-003 / FAT-007 / FAT-010 | Local wizard + identity | Next / skip | S | family | Owner | — | — | PR | PR | F:G-11 | — | FC | G-11 | VX-B4 | setup_wizard test | PENDING |
| SCR-FAT-003 | Parent | FAT-02 | Add child (name, age, photo) | FAT-002, FAT-012 | FAT-004 | `stage1ChildDeviceManagementRepository` + roster | Continue / character, colour | Er, S | family | Parent | — | — | PR | F:S-04 | F:G-15 | PD keyboard | FC | S-04 | VX-B6 | add_child_screen_test | PENDING |
| SCR-FAT-004 | Parent | FAT-02 | Link QR (expiring code) | FAT-003 | FAT-005 / FAT-006 | Child device management (local) | Show code / refresh | P, S, Er(expired) | childId | Parent | Camera on child NC | — | PR | PR | F:G-11 | PD | FC | G-11 | VX-B4 | link_qr test | PENDING |
| SCR-FAT-005 | Parent | FAT-02 | Permissions explainer | FAT-004 | FAT-006 | ARB static | Continue | NA | none | Parent | OS permission NC | — | PR | PR | PR | — | FC | — | VX-B7 | permissions_explainer test | PENDING |
| SCR-FAT-006 | Parent | FAT-02 | Link success (first value) | FAT-005 | FAT-010 | Roster + decorative map | Go to Today | S, NC | childId | Parent | GPS NC | — | F:G-12 | PR | F:G-12 | PD small screen | FC | G-12 | VX-B4 | link_success_screen_test | PENDING |
| SCR-FAT-007 | Parent | FAT-03 | Trial mode (labelled demo) | FAT-002 | FAT-010 | LOCAL_DEMO data | Explore / exit | S | none | Parent | — | — | PR | PR | F:G-11 | — | FC | G-11 | VX-B4 | trial_mode test | PENDING |
| SCR-FAT-030 | Parent | FAT-01 | Parent second key (unlock parent mode) | CHD-011 request | Back | `stage1ChildModeLockService` | Allow 10 min / deny | P, S | childId | Father | — | Push to father RC | PR | PR | PR | PD | FC | — | VX-B7 | parent_second_key test | PENDING |
| SCR-CHD-001 | Child | CHD-01 | Child welcome | SHR-007 | CHD-002 | ARB static | Start | NA | none | Child | — | — | PR | PR | PR | — | FC | — | VX-B7 | child_welcome test | PENDING |
| SCR-CHD-002 | Child | CHD-01 | Scan link QR | CHD-001 | CHD-003 | Child device management | Scan / manual | P, Er, NC | none | Child | Camera NC | — | F:G-13 | PR | PR | PD camera | FC | G-13 | VX-B4 | child_qr_scan test | PENDING |
| SCR-CHD-003 | Child | CHD-01; CHD-05 | Transparency consent | CHD-002 | CHD-004 | Local consent | Agree | S | resolver | Child | — | — | PR | PR | PR | — | FC | — | VX-B7 | transparency_consent test | PENDING |
| SCR-CHD-011 | Child | CHD-01 | Child-mode lock + secret entry | Hub:me | FAT-030 request | `stage1ChildModeLockService` | Long-press / password | P, U(24 h lock) | resolver | Child | — | Father device approval RC | PR | PR | PR | PD long-press | FC | — | VX-B7 | child_mode_lock test | PENDING |

### 2.2 ADM:ب Family & members · ADM:ج Devices · ADM:ح Settings/support

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-008 | Parent | FAT-04 | Invite mother + level | Hub:settings, FAT-027 | FAT-027 | `stage1AdultInviteRepository` (identity local) | Send invite / level | Er, S, RC | family | Father | — | Email/invite delivery RC | PR | PR | PR | — | FC | G-02 copy | VX-B3 | invite_mother_screen_test | PENDING |
| SCR-FAT-009 | Mother | MOT-01 | Accept mother invite | Login invite link; **Settings shortcut (wrong)** | FAT-010 | Identity invite token | Accept | Er(invalid), S | inviteTokenId ✓route | Invitee | — | Backend join RC | PR | F:S-09 | PR | — | FC | S-09 | VX-B5 | accept_mother_invite_screen_test | PENDING |
| SCR-FAT-027 | Parent | FAT-04 | Family members, roles, alternate guardian | Hub:settings | FAT-008 / FAT-031 | Identity adults + local children | Invite / change level / remove | E, M, Er | family | Owner (invite) | — | — | PR | PR | PR | — | FC | N-01 no action | VX-B7 | family_members_screen_test | PENDING |
| SCR-FAT-031 | Parent | FAT-04 | Mother permission level (3 levels) | FAT-027 | FAT-027 | Identity mother level | Choose level | S | memberId ✓route | Father | — | — | PR | PR | F:G-17 | — | FC | G-17 (SOS go) | VX-B4 | mother_permission_level_screen_test | PENDING |
| SCR-FAT-025 | Parent | FAT-13; FAT-14 | Settings home + device health | Tab settings | FAT-026, hubs, shortcuts | Device health seam (LOCAL_DEMO) + identity | Open item / shortcuts | E, M, NC | family | Parent | Heartbeat NC | — | PR | F:S-09 | F:G-11 | — | FC | S-09, G-11 | VX-B5 | settings_hub_screen_test | PENDING |
| SCR-FAT-026 | Parent | FAT-13; FAT-14 | Device detail + fix permissions | FAT-025 list, FAT-013 (wrong id), Hub:settings (no id) | Back / OS settings (simulated) | `stage1DeviceHealthSeam` (FakeDeviceHealthSeam.demo) | Fix permission / SOS | E(not found), NC | deviceId ✓route | Parent | OS settings NC | — | PR | F:S-06 | PR | PD | FC | S-06, G-08 | VX-B2, VX-B4 | device_health_detail_screen_test | PENDING |
| SCR-FAT-061 | Parent | FAT-30 | Language + help + support | Hub:settings | Back | Local prefs (locale not applied) | Language / help / support | S | none | Parent | — | Support channel RC | PR | F:S-07 | OD-01 | — | FC | S-07 | VX-B3 | language_help_screen_test | PENDING |

### 2.3 ADM:ز Day board · ADM:د Billing · ADM:هـ Notifications · ADM:و Privacy

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-010 | Parent | FAT-05; MOT-02 | Today board — card per child | Tab today (parent home) | FAT-013, pending inbox, quick actions | `RosterDayBoardProjectionRepository` (roster + EDU results + athkar; famStage1 default) | Pending card / quick actions (Quran, Tasks, Lock, Map) | E, 1, M, P | ✗ quick actions drop child; family pinned | Parent | GPS/battery NC (demo) | — | PR | F:S-03 | F:G-15 | PD back | FC | S-03, G-05, G-17 | VX-B5, VX-B2 | day_board_screen_test | PENDING |
| SCR-FAT-011 | Parent | FAT-05 | Advisor suggestions (3 taps) | Hub:today | Approve → rule | `stage1RulesEngineRuleRepository` (unbound) + Advisor mock | Approve / reject | E, M, RC | resolver | Parent | — | Advisor Gateway RC | PR | PR | PR | — | FC | — | VX-B7 | advisor_suggestions test | PENDING |
| SCR-FAT-056 | Parent | FAT-26 | Plans (3 + annual; SOS never gated) | Hub:settings | FAT-057 | `stage1EntitlementService` | Choose plan | RC | family | Father-only / owner | — | Billing RC | PR | PR | F:G-15 | — | FC | — | VX-B7 | plans test | PENDING |
| SCR-FAT-057 | Parent | FAT-26 | Manage subscription | FAT-056 | Back | Entitlement (local) | Upgrade / restore | RC | family | Father-only | — | Billing RC | PR | PR | PR | — | FC | — | VX-B7 | manage_subscription test | PENDING |
| SCR-FAT-058 | Parent | FAT-27 | Notification prefs (SOS never muted) | Hub:settings | Back | PrefsMisc notification (local KV) | Toggles / schedule | S, Er | family | Parent | — | FCM delivery RC | PR | F:G-09 | PR | PD persist | FC | G-09 | VX-B1 | notification_prefs test | PENDING |
| SCR-FAT-059 | Parent | FAT-28 | Privacy & data + forget | Hub:settings | FAT-060 | `stage1PrivacyCollectionSyncBus` + lifecycle | Toggles / export / forget | S, RC | ✗ 'demo-child' | Owner-only | — | AI Gateway RC | PR | F:G-03 | PR | PD persist | FC | G-03 | VX-B2 | privacy_data test | PENDING |
| SCR-FAT-060 | Parent | FAT-28 | Audit log (append-only) | FAT-059, Hub:settings | Back | `stage1AuditLogRepository` (local) | Filter / read | E, M | family | Owner-only | — | — | PR | F:G-06 | PR | — | FC | G-06 (SOS actor 'demo-child') | VX-B2 | audit_log test | PENDING |

### 2.4 SEC:د Location & safe zones · SEC:هـ SOS

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-012 | Parent | FAT-06; MOT-03 | Children list (colour status) | Tab kids | FAT-013, FAT-003 | `ChildrenListLocalRepository` (SQLite; LOCAL_DEMO seed) + identity | Open child / add | E, 1, M | family (identity) | Parent | Telemetry NC (demo) | — | F:C-07 | F:S-04 | F:G-11/G-15 | PD | FC | S-04, C-07, S-08 | VX-B6 | children_list_screen_test | PENDING |
| SCR-FAT-013 | Parent | FAT-06; MOT-03 | Child profile — everything about one child | FAT-010, FAT-012 | Per-child tools (FAT-014…085), FAT-026 | Unbound `stage1ChildProfileRepository` → roster fallback + management | Tools grid / edit, remove device | E, S, NC | childId ✓route | Parent | GPS NC | — | PR | F:S-06 | F:G-11 | PD | FC | G-04 (downstream), S-06 | VX-B2 | child_profile_screen_test | PENDING |
| SCR-FAT-014 | Parent | FAT-07; MOT-06 | Location map (live + battery) | FAT-013, Hub:kids (no child), FAT-010 quick action (no child) | FAT-015 / FAT-016 | Unbound `stage1LocationMapRepository`; FamilyId pinned | Locate / history / SOS | E, NC | childId ✓route (hub/dash lose it) | Parent | GPS NC | — | F:G-12 | PR | F:G-12 | PD small screen | FC | G-08, G-12, G-05 | VX-B4 | location_map_screen_test | PENDING |
| SCR-FAT-015 | Parent | FAT-07 | Location history | FAT-014 | Back | Unbound `stage1LocationHistoryRepository`; FamilyId pinned | Filter day | E, NC | childId ✓route | Parent | GPS NC | — | PR | PR | PR | — | FC | G-05 | VX-B2 | location_history test | PENDING |
| SCR-FAT-016 | Parent | FAT-08 | Safe zones list | FAT-013, Hub:kids | FAT-017 | DomainSafeZonesRepository(`fam_stage1`) | Add / edit zone | E, 1, M | childId ✓route; family pinned | Parent | Geofence NC | — | PR | PR | PR | — | FC | G-05, G-08 | VX-B2 | safe_zones_screen_test | PENDING |
| SCR-FAT-017 | Parent | FAT-08 | Create safe zone (map + radius + alerts) | FAT-016, Hub:kids | FAT-016 | Domain safe zones (`fam_stage1`) | Save / radius, alerts | Er, S, NC | childId ✓route | Parent | Geofence NC | — | F:G-12/G-10 | F:S-05 | F:G-12 | PD keyboard | FC | S-05, G-09, G-10, G-12 | VX-B6, VX-B1 | create_safe_zone_screen_test | PENDING |
| SCR-FAT-018 | Parent | FAT-09; MOT-05 | SOS alert (breaks mute) | SOS fire events (~15 screens), **Settings shortcut (no alert)** | FAT-023 call / resolve | SOS final service / alert repo (local) | Call / acknowledge | P, S, RC, E(no alert) | alertId, childId ✓route | Parent | Telephony NC | FCM/SMS RC | F:G-12/G-10 | F:C-08 | F:G-12 | PD | FC | G-06, S-09, C-08 | VX-B2, VX-B5 | sos_alert_screen_test | PENDING |
| SCR-FAT-028 | Parent | FAT-08; FAT-09 | Emergency setup (contacts + national number) | Hub:settings | Back | `stage1SosSettingsStore` (rebound by runtime) | Add contact / ladder | E, M, S | family | Parent | Telephony NC | SMS RC | PR | PR | PR | PD persist | FC | — | VX-B7 | emergency_setup_screen_test | PENDING |
| SCR-CHD-005 | Child | CHD-03 | SOS button (always works) | Child SOS FAB | CHD-006 | SOS fire service | Hold to send | P, S, RC | actor 'self' | Child | Telephony NC | FCM/SMS RC | F:G-13 | PR | PR | PD hold gesture | FC | G-06, G-13 | VX-B2 | child_sos_button test | PENDING |
| SCR-CHD-006 | Child | CHD-03 | SOS in progress | CHD-005 | CHD-004 | SOS final service | Cancel / call | P, RC | alertId, childId ✓route | Child | Telephony/GPS NC | FCM RC | PR | PR | PR | PD | FC | G-10 | VX-B4 | child_sos_in_progress_screen_test | PENDING |
| SCR-CHD-024 | Child | CHD-11 | "I arrived" + my location | Hub:cfam | Back | Child arrival local repository (journal) | I arrived / reply | S, NC, RC | resolver | Child | GPS NC | FCM RC | PR | PR | F:G-02 | PD | FC | G-02 | VX-B3 | child_arrival_screen_test | PENDING |
| SCR-FAT-077 | Parent | FAT-39 | Road safety — **OOS** | Deep link only | Back | Road safety screen (no hub) | — | NA | — | Parent | Motion NC | — | NA | NA | NA | NA | OOS | C-05 | VX-B1 (D11: redirect → FAT-075) | vx_b1_role_guard_landing_test | CLOSED (PASSED 2026-09-25) · PD |

### 2.5 SEC:أ Screen time · SEC:ب Apps · SEC:ج Web filter · SEC:ح Anti-tamper · SEC:ط Instant lock · SEC:ل Modes

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-032 | Parent | FAT-15 | Child screen time (limit, schedules, sleep, per-app, education free) | FAT-013 tools | Back | ScreenTime local KV + `stage1PolicySyncBus` | Save limits / grant remaining | S, Er, NC | childId ✓route | Parent | OS enforce NC | — | PR | PR | F:G-15 | PD persist, role switch | FC | G-15 | VX-B3 | child_screen_time_screen_test; ce_b3_control_spine_test | PENDING |
| SCR-FAT-033 | Parent | FAT-15; MOT-07 | Extra-time requests inbox | FAT-013 tools, FAT-010 pending fallback | Back | Stage-1 time request runtime (local) | Approve / deny / reward | E, M, S | ✗drop (inbox lists all) | Parent (participant+) | — | Push RC | PR | PR | F:G-11 | PD loop | FC | G-10 (SnackBar), S-03 (not on dashboard) | VX-B5 | request_inbox test | PENDING |
| SCR-FAT-034 | Parent | FAT-16 | Child apps (allow/block, categories) | FAT-013 tools | FAT-035 | `stage1ChildAppsRepository` (local AC) | Allow / block | E, M, NC | childId ✓route | Parent | OS intercept NC | — | F:G-13 | PR | F:G-11 | PD | FC | G-02 (badge), G-13, G-17 | VX-B3, VX-B4 | child_apps_screen_test | PENDING |
| SCR-FAT-035 | Parent | FAT-16 | New app approval (one card decision) | FAT-034 (hub excluded on kids; listed elsewhere) | Back | App control local | Approve / deny | P, S | childId, appId ✓route | Parent | OS intercept NC | — | PR | PR | PR | — | FC | G-02 badge, G-03, G-17 | VX-B2 | new_app_approval_screen_test | PENDING |
| SCR-FAT-036 | Parent | FAT-17 | Web filter (29 categories, safe search) | FAT-013 tools | Back | Web filter local prefs | Toggle categories / exceptions | S, Er, NC | ✗drop → 'demo-child' | Parent | VPN/DNS NC | — | PR | F:G-04 | F:G-02 | PD persist | FC | G-03, G-04, G-09, G-10, G-02 | VX-B2, VX-B1 | web_filter_screen_test | PENDING |
| SCR-FAT-037 | Parent | FAT-18 | Instant lock (full / internet / timer) | FAT-013 tools, FAT-010 quick action | Back | Device lock prefs + `stage1AntiTamperAlertBus` | Lock / unlock / timer | S, NC | ✗drop → 'demo-child' | Parent | Device Admin NC | — | PR | F:G-04 | F:G-02 | PD persist, role switch | FC | G-03, G-04, G-02 | VX-B2 | instant_lock_screen_test | PENDING |
| SCR-FAT-038 | Parent | FAT-19 | Tamper alerts (dialogue signal, not trial) | FAT-013 tools | Back | `stage1TamperAlertsRepository` (local) | Read / acknowledge | E, M | childId ✓route | Parent | OS signals NC | — | PR | PR | PR | — | FC | — | VX-B7 | tamper_alerts test | PENDING |
| SCR-FAT-085 | Parent | FAT-44 | Smart modes (Ramadan/exams/holiday) with preview | Hub:kids (no child) | Back | Modes runtime + `stage1SmartModeActivationBus` | Preview / apply | S, NC | ✗drop | Parent | OS wake NC | — | PR | F:G-04 | PR | PD role switch | FC | G-04, G-08, G-02 badge | VX-B2 | smart_modes_screen_test | PENDING |
| SCR-CHD-004 | Child | CHD-02 | My day (time, points — no punishment board) | Tab myday (child home) | CHD-020 / CHD-022 / CHD-027 | Smart mode + policy sync bus (child 'child_demo') | Request time / tasks | S, NC | ✗ 'child_demo' | Child | GPS NC | — | PR | F:G-03 | F:G-15 | PD role switch | FC | G-03 | VX-B2 | child_day_board test | PENDING |
| SCR-CHD-020 | Child | CHD-06 | Request extra time (polite reason) | CHD-004, CHD-021 | CHD-004 | `stage1ChildTimeRequestRepository` (local) | Send request | P, S, RC | childId ✓route | Child | — | Push RC | PR | PR | F:G-02 | PD loop | FC | G-02 | VX-B3 | child_time_request_screen_test | PENDING |
| SCR-CHD-021 | Child | CHD-06 | Time is up — gently (chat/Quran/SOS stay open) | ST expiry event | CHD-020 / CHD-008 / CHD-025 | ScreenTime local ('demo-child') | Ask for more / open chat | S | ✗ 'demo-child' | Child | OS lock NC | — | PR | F:G-03 | F:G-11 | PD | FC | G-03, G-04, G-11 | VX-B2 | time_expiry test | PENDING |

### 2.6 SEC:و Smart content monitoring · SEC:ز Platform · SEC:ي Reports

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-065 | Parent | FAT-31 | Smart alerts (amber, behaviour not child) | FAT-013 tools | FAT-066 | `stage1SmartAlertsRepository` ('demo-child') | Open alert | E, M, NC, RC | ✗drop | Parent | MediaProjection NC | Advisor RC | PR | F:G-02 | F:G-02 | — | FC | G-02, G-03, G-04 | VX-B2, VX-B3 | smart_alerts_screen_test | PENDING |
| SCR-FAT-066 | Parent | FAT-31 | Alert detail + dialogue step | FAT-065 | Back | `stage1SmartAlertDetailRepository` | Suggested dialogue | S, RC | ✗drop | Parent | Capture NC | Advisor RC | PR | PR | F:G-02 | — | FC | G-02, G-04 | VX-B3 | smart_alert_detail_screen_test | PENDING |
| SCR-FAT-067 | Parent | FAT-32 | Smart supervision settings (contact watch list) | FAT-013 tools | Back | `stage1DesiredMonitoringSyncBus` ('child_1') | Toggles | S, NC | ✗drop | Parent | Capture NC | — | PR | F:G-04 | PR | PD persist | FC | G-03, G-04 | VX-B2 | smart_supervision test | PENDING |
| SCR-FAT-068 | Parent | FAT-32 | Platform monitoring (Android full / iOS reports) | FAT-067 / FAT-013 (noHub) | Back | Desired monitoring sync bus | Toggles | S, NC | resolver | Parent | Platform NC | — | PR | PR | PR | — | FC | — | VX-B7 | platform_monitoring test; ce_b5_mock_hardening_test | PENDING |
| SCR-FAT-069 | Parent | FAT-33 | Child usage report (30-day retention) | FAT-013 tools | FAT-081 | `stage1ChildUsageReportRepository` | Forget / export | E, 1, RC | ✗drop | Parent | — | Email/PDF RC | PR | F:G-04 | F:G-15 | — | FC | G-04, G-02 | VX-B2 | child_usage_report_screen_test | PENDING |
| SCR-FAT-081 | Parent | FAT-33 | Anonymous peer comparison | FAT-069 (noHub) | Back | `stage1PeerCompareRepository` (local cohort mock) | Read | S, RC | resolver | Parent | — | Email/PDF RC | PR | PR | PR | — | FC | G-02 | VX-B3 | peer_compare_screen_test | PENDING |
| SCR-FAT-073 | Parent | FAT-36 | Weekly report + one recommendation | Hub:today | Approve suggestion | Weekly report local (empty-first) | Apply suggestion / email | E, S, RC | resolver | Parent | — | Email/PDF + Gateway RC | PR | PR | F:G-02 | — | FC | G-02 | VX-B3 | weekly_report_screen_test; ce_b2_reports_empty_first_test | PENDING |

### 2.7 COM:أ Chat · COM:ب Calls · COM:ج Media · COM:د Safe circle · COM:ز Location-in-comms

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-021 | Parent | FAT-11; MOT-04 | Conversations list (pinned family) | Tab family | FAT-022 | **Unbound** `stage1ConversationsListRepository` | Open thread (none available) | E only | family | Parent (never plan-gated) | — | Multi-device RC | PR | F:S-01 | F:G-02 | PD | FC | S-01, G-02 | VX-B6 | conversations_list_screen_test; ce_b0_chat_delivery_honesty_test | OD |
| SCR-FAT-022 | Parent | FAT-11; MOT-04 | Conversation (edit 15 min, delete for all) | FAT-021 | FAT-023 | **Unbound** `stage1ConversationRepository` + ChatAvailability | Send / edit / delete | E, Er(send throws) | chatWith ✓route | Parent | — | Relay RC | PR | F:S-01 | F:G-02 | PD keyboard | FC | S-01, G-06, G-10 | VX-B6 | conversation_screen_test | OD |
| SCR-FAT-023 | Parent | FAT-12; MOT-04 | Active call (voice/video) | FAT-022, FAT-018 | Back | **Unbound** `stage1ActiveCallRepository` | End / mute | E, NC | callId ✓route | Parent | LiveKit NC | — | PR | PR | PR | PD | FC | G-06 (callId as childId), G-10 | VX-B2, VX-B4 | active_call test | PENDING |
| SCR-FAT-024 | Parent | FAT-12 | Call history | Hub:family | FAT-023 | **Unbound** `stage1CallHistoryRepository` | Call back | E, NC | family | Parent | Telephony NC | — | PR | PR | PR | — | FC | G-10 | VX-B4 | call_history test | PENDING |
| SCR-CHD-007 | Child | CHD-04 | My chats (family) | Tab cfam | CHD-008 | **Unbound** `stage1ChildChatsRepository` | Open thread | E only | resolver | Child (never time-locked) | — | Relay RC | PR | F:S-01 | F:G-02 | PD | FC | S-01, G-02, G-10 | VX-B6 | child_chats_screen_test | OD |
| SCR-CHD-008 | Child | CHD-04 | Conversation (never locks) | CHD-007, CHD-021 | CHD-009 | Child conversation (in-memory) | Send | E, Er | chatWith ✓route | Child | — | Relay RC | PR | F:S-01 | F:G-02 | PD keyboard | FC | S-01, G-10 | VX-B6 | child_conversation_screen_test | OD |
| SCR-CHD-009 | Child | CHD-04 | Call parents (always works) | CHD-008 | Back | Child active call (unbound) | End | NC | callId ✓route | Child | LiveKit NC | — | PR | PR | PR | PD | FC | G-10 | VX-B4 | child_active_call test | PENDING |
| SCR-CHD-036 | Child | CHD-17 | Call play (games during call) | CHD-031 / CHD-009 | Back | `stage1ChildCallPlayRepository` | Pick game | NC | resolver | Child | LiveKit NC | — | PR | PR | PR | — | FC | — | VX-B7 | child_call_play_screen_test | PENDING |
| SCR-CHD-023 | Child | CHD-11 | Share media (photo/file/voice) | Hub:cfam | Back | `stage1ChildMediaShareRepository` (local catalog) | Share / type | S, NC, RC | resolver | Child | Camera/mic/files NC | Chat RC | PR | PR | F:G-02 | PD | FC | G-02 | VX-B3 | child_media_share_screen_test | PENDING |
| SCR-CHD-037 | Child | CHD-17 | Stickers & backgrounds | Hub:cfam | Back | `stage1ChildStickersBackgroundsRepository` (local) | Apply | S, RC | resolver | Child | — | Chat apply RC | PR | PR | PR | — | FC | — | VX-B7 | child_stickers_backgrounds_screen_test | PENDING |
| SCR-FAT-070 | Parent | FAT-34 | Outer circle (approved relatives/friends) | FAT-013 / Hub:family (noHub) | FAT-071 | `stage1OuterCircleRepository` (local) | Add / block | E, M | family | Parent | — | — | F:G-13 | PR | PR | — | FC | G-13 | VX-B4 | outer_circle_screen_test | PENDING |
| SCR-FAT-071 | Parent | FAT-34; CHD-13 | Friend request approval (one card) | FAT-070 / child request | Back | `stage1FriendApprovalRepository` → outer circle | Approve / decline | P, S | resolver | Parent | — | — | PR | F:S-03 (not on dashboard) | PR | PD loop | FC | S-03 | VX-B5 | friend_approval_screen_test | PENDING |
| SCR-CHD-030 | Child | CHD-13 | My friends (approval required) | Hub:cfam (noHub) → CHD-007 | Back | `stage1ChildFriendsRepository` (outer circle projection) | Request friend | E, M, P | resolver | Child | Telephony NC | Chat RC | F:G-13 | PR | F:G-02 | — | FC | G-02, G-13 | VX-B3 | child_friends_screen_test | PENDING |

### 2.8 COM:هـ Calendar · COM:و Tasks

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-052 | Parent | FAT-24; MOT-08 | Family calendar (Hijri + Gregorian, prayer times) | Hub:family | FAT-053 | `stage1FamilyCalendarRepository` (local) | Add event / filter | E, M | family | Parent | — | — | PR | PR | PR (dates) | — | FC | G-15 | VX-B3 | family_calendar test | PENDING |
| SCR-FAT-053 | Parent | FAT-24 | Add event | FAT-052, Hub:family | FAT-052 | `stage1AddEventRepository` | Save | Er, S | family | Parent | — | — | PR | PR | PR | PD keyboard | FC | — | VX-B7 | add_event test | PENDING |
| SCR-FAT-054 | Parent | FAT-25; MOT-08 | Family tasks | Hub:family, FAT-010 quick action | FAT-055 | `stage1FamilyTasksRepository` (local persistence) | Confirm done / add | E, M, P | family | Parent | — | — | PR | PR | PR | PD persist | FC | G-17 (dash go) | VX-B5 | family_tasks test; ce_b1_family_tasks_local_test | PENDING |
| SCR-FAT-055 | Parent | FAT-25 | Create task with reward (minutes) | FAT-054, Hub:family | FAT-054 | Create task repository → family tasks | Save / assign, reward | Er, S | family | Parent | — | — | PR | PR | PR | PD keyboard | FC | — | VX-B7 | create_task test | PENDING |
| SCR-FAT-082 | Parent | FAT-42 | Smart chore distributor (suggest → approve) | Hub:family | FAT-054 | `stage1SmartChoreDistributorRepository` | Approve plan | S, RC | family | Parent | — | — | PR | PR | PR | — | FC | — | VX-B7 | smart_chore_distributor_screen_test | PENDING |
| SCR-CHD-022 | Child | CHD-12 | My tasks (done → confirm → reward) | Hub:myday | Back | `stage1ChildTasksRepository` (family-bound) | Mark done | E, M, P | resolver | Child | — | — | PR | PR | PR | PD loop | FC | — | VX-B7 | child_tasks_screen_test | PENDING |

### 2.9 EDU Studio (EDU:ط) · Materials (EDU:أ) · Assignments/Assessments (EDU:ب/ج) · Focus (EDU:ح)

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-040 | Parent | FAT-21 | Studio board (today + create) | Tab studio | FAT-041, FAT-043 | `stage1StudioBoardRepository` | Create / open | E, M | family | Parent | — | Advisor RC | PR | PR | F:G-11 | — | FC | G-11 | VX-B4 | studio_board test | PENDING |
| SCR-FAT-041 | Parent | FAT-21 | Add from any source | FAT-040, Hub:studio | FAT-042 / FAT-043 | Screen-local sheet + SOS | Pick source / subject | S, NC, RC | family | Parent | Camera/voice NC | Generate RC | PR | F:C-03 | F:G-11 | — | FC | C-03, G-11 | VX-B1 | add_from_source test | PENDING |
| SCR-FAT-042 | Parent | FAT-21 | Camera capture (book page) | FAT-041, Hub:studio | FAT-043 | Staged local | Capture | NC | none | Parent | Camera NC | — | F:G-13 | PR | PR | PD camera | FC | G-13, G-08 | VX-B4 | studio_camera_capture test | PENDING |
| SCR-FAT-043 | Parent | FAT-21 | Generation outputs (1 source → 9 outputs) | FAT-041/042 | FAT-044 | `stage1GenerationOutputsRepository` | Open output | P, RC | flow | Parent | — | Advisor RC | PR | PR | F:G-02 | — | FC | G-02 | VX-B3 | generation_outputs_screen_test | PENDING |
| SCR-FAT-044 | Parent | FAT-21 | Preview & approve (90-second rule) | FAT-043 | FAT-045 | `stage1PreviewApproveRepository` | Approve / edit | S, RC | flow | Parent | — | Advisor RC | PR | PR | F:G-02 | — | FC | G-02 | VX-B3 | preview_approve_screen_test | PENDING |
| SCR-FAT-045 | Parent | FAT-21 | Assign + reward (minutes) + due | FAT-044 | FAT-040 | Attribution reward repo | Assign | S | childId (in-form) | Parent | — | — | PR | PR | PR | — | FC | — | VX-B7 | attribution_reward test | PENDING |
| SCR-FAT-046 | Parent | FAT-22 | Community library | Hub:studio | Import | Community library (local) | Import / publish | E, M | family | Parent | — | — | PR | PR | PR (dates) | — | FC | G-15 | VX-B7 | community_library test | PENDING |
| SCR-FAT-047 | Parent | FAT-23 | Learning path | Hub:studio | Back | `stage1LearningPathRepository` | Order lessons | E, M | family | Parent | — | — | PR | PR | PR | — | FC | — | VX-B7 | learning_path test | PENDING |
| SCR-FAT-048 | Parent | FAT-23 | Materials & lessons | Hub:studio | FAT-049 | `stage1MaterialsLessonsRepository` | Add material | E, M, RC | family | Parent | — | Licensed materials RC | PR | PR | F:G-11 | — | FC | G-11 | VX-B4 | materials_lessons_screen_test | PENDING |
| SCR-FAT-049 | Parent | FAT-23 | Create assignment / quiz | FAT-048, Hub:studio | FAT-050 | `stage1CreateAssignmentRepository` (EDU local) | Save | Er, S | childId (in-form) | Parent | — | — | PR | PR | PR | PD keyboard | FC | — | VX-B7 | create_assignment test; dom_edu_local_a test | PENDING |
| SCR-FAT-050 | Parent | FAT-23 | Results follow-up | Hub:studio, FAT-010 pending | Back | Learning results (EDU local) | Review | E, M | family | Parent | — | — | PR | PR | PR | — | FC | — | VX-B7 | results_followup test; dom_edu_local_b test | PENDING |
| SCR-FAT-051 | Parent | FAT-23 | Focus report (weekly) | FAT-013 tools | Back | `stage1FocusReportRepository` | Read | E, 1 | ✗drop | Parent | — | — | PR | F:G-04 | PR | — | FC | G-04 | VX-B2 | focus_report test | PENDING |
| SCR-FAT-084 | Parent | FAT-43 | Staged project (milestones) | Hub:studio | Back | Staged project local | Add stage / reward | E, M | childId (in-form) | Parent | — | — | PR | PR | PR | — | FC | — | VX-B7 | staged_project_screen_test | PENDING |
| SCR-CHD-012 | Child | CHD-07 | Learn home (subjects, streak) | Tab learn | CHD-013…019 | `stage1ChildLearnHomeRepository` ('child_a') | Open subject | E, M, RC | ✗ 'child_a' | Child | — | Materials RC | PR | F:G-03 | F:G-11 | — | FC | G-03, G-11 | VX-B2 | child_learn_home_screen_test | PENDING |
| SCR-CHD-013 | Child | CHD-07 | Lesson | CHD-012 | Back | `stage1ChildLessonRepository` | Next | E, RC | resolver | Child | — | Materials RC | PR | PR | PR | — | FC | — | VX-B7 | child_lesson_screen_test | PENDING |
| SCR-CHD-014 | Child | CHD-07 | My assignment / flashcards | CHD-012 | CHD-016 | `stage1ChildFlashcardsRepository` (parent-assigned) | Flip / submit | E, M, RC | resolver | Child | — | Advisor RC | F:G-13 | PR | F:G-02 | — | FC | G-02, G-13 | VX-B3 | child_flashcards_screen_test | PENDING |
| SCR-CHD-015 | Child | CHD-07 | Quiz | CHD-012 | CHD-016 | `stage1ChildQuizRepository` + results ('child_a') | Answer / submit | S | ✗ 'child_a' | Child | — | — | F:G-13 | F:G-03 | PR | — | FC | G-03, G-13 | VX-B2 | child_quiz_screen_test | PENDING |
| SCR-CHD-016 | Child | CHD-07 | My result (mistakes never punished) | CHD-015 | CHD-012 | Learning result (local) | Continue | S, RC | resolver | Child | — | Parent notify RC | PR | F:C-06 | F:G-02 | — | FC | C-06, G-02 | VX-B3 | child_result_screen_test | PENDING |
| SCR-CHD-017 | Child | CHD-08 | Smart tutor (Socratic, no answers) | CHD-012 | Back | `stage1ChildTutorRepository` | Ask | S, RC | resolver | Child | — | Tutor RC | PR | PR | F:G-02 | — | FC | G-02 | VX-B3 | child_tutor_screen_test | PENDING |
| SCR-CHD-018 | Child | CHD-09 | Focus mode (timer, education time free) | Hub:learn | CHD-035 | `stage1ChildFocusRepository` | Start / stop | S, NC | resolver | Child | OS wake NC | — | PR | PR | PR | PD timer | FC | — | VX-B7 | child_focus_screen_test | PENDING |
| SCR-CHD-035 | Child | CHD-17 | Focus sounds | Hub:learn, CHD-018 | Back | Focus sounds local repository | Play sound | S | resolver | Child | Audio playback | — | PR | PR | PR | PD audio | FC | — | VX-B7 | child_focus_sounds_screen_test | PENDING |

### 2.10 EDU:ز Quran · EDU:هـ Adaptive · EDU:و Rewards · EDU:د Tutor/Stories

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-072 | Parent | FAT-35 | Quran memorization follow-up | FAT-013 tools, FAT-010 quick action | Back | Quran progress repo via QuranLocalBridge ('child_a') | Set ward / whisper | E, 1, RC | ✗drop → 'child_a' | Parent | — | Licensed audio RC | F:G-13 | F:G-04 | F:G-02 | PD loop | FC | G-03, G-04, G-02, G-13 | VX-B2, VX-B3 | quran_progress_screen_test; ce_b4_quran_local_test | PENDING |
| SCR-CHD-025 | Child | CHD-14 | My ward — memorize & recite (licensed only) | Hub:learn | CHD-026 | `stage1ChildQuranWardRepository` ('child_a') | Mark recited | S, RC | ✗ 'child_a' | Child (never time-locked) | — | Licensed RC | F:G-13 | F:G-03 | PR | PD loop | FC | G-03, G-13 | VX-B2 | child_quran_ward_screen_test; ce_b4_quran_local_test | PENDING |
| SCR-CHD-026 | Child | CHD-14 | Memorization progress (surah map) | CHD-025 | Back | `stage1ChildMemorizationRepository` | Review due | E, M | resolver | Child | — | Licensed RC | PR | PR | PR | — | FC | — | VX-B7 | child_memorization_screen_test | PENDING |
| SCR-CHD-027 | Child | CHD-14 | Daily athkar (gentle) | Hub:myday; **father via FAT-010 pending (wrong)** | Back | Child athkar repository | Mark read | S | resolver | Child | — | — | PR | F:S-03 | PR | — | FC | S-03 | VX-B5 | child_athkar test | PENDING |
| SCR-CHD-032 | Child | CHD-18 | Smart tilawah (gentle correction) | Hub:learn | Back | `stage1ChildSmartTilawahRepository` | Start recitation | NC, RC | resolver | Child | Mic NC | Licensed + Advisor RC | PR | PR | F:G-02 | PD mic | FC | G-02 | VX-B3 | child_smart_tilawah_screen_test | PENDING |
| SCR-CHD-028 | Child | CHD-15 | My smart plan | Hub:learn | CHD-029 | Smart plan local | Open step | E, M | resolver | Child | — | — | PR | PR | PR | — | FC | — | VX-B7 | child_smart_plan_screen_test | PENDING |
| SCR-CHD-029 | Child | CHD-15 | Daily review (spaced, 5 min) | CHD-028, Hub:learn | Back | `stage1ChildDailyReviewRepository` | Start | E, S | resolver | Child | — | — | PR | PR | PR | — | FC | — | VX-B7 | child_daily_review_screen_test | PENDING |
| SCR-CHD-019 | Child | CHD-10 | My minutes & badges (redeem for time) | Hub:me | Back | `stage1ChildWalletRepository` (Minutes) | Redeem | E, S | resolver | Child | — | — | PR | PR | F:G-11 | PD loop | FC | G-11 | VX-B4 | child_wallet_screen_test | PENDING |
| SCR-CHD-033 | Child | CHD-17 | Interactive stories | Hub:learn | Back | `stage1ChildInteractiveStoriesRepository` | Choose path | S, RC | resolver | Child | — | Tutor RC | PR | PR | PR | — | FC | — | VX-B7 | child_interactive_stories_screen_test | PENDING |
| SCR-CHD-034 | Child | CHD-17 | Family challenges (friendly, no humiliating rank) | Hub:me | Back | `stage1ChildFamilyChallengesRepository` | Join | E, M | resolver | Child | — | — | PR | PR (G-8) | F:G-12 | — | FC | G-12 | VX-B4 | child_family_challenges_screen_test | PENDING |
| SCR-CHD-031 | Child | CHD-16 | Coming for you 🎁 (catalog) | Hub:me | Live fun screens | Local catalog | Open | S, RC | resolver | Child | LiveKit NC | Tutor RC | PR | PR | PR | — | FC | — | VX-B7 | child_coming_gifts_screen_test | PENDING |

### 2.11 AIC Advisor / Insights / Agent

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-FAT-019 | Parent | FAT-10 | Alerts hub (grouped by urgency) | Hub:today | FAT-020 | **Unbound** `stage1AlertsHubRepository` | Open alert | E only | family | Parent | — | — | PR | F:S-02 | F:G-11 | — | FC | S-02, G-11 | VX-B5 | alerts_hub test | PENDING |
| SCR-FAT-020 | Parent | FAT-10 | Alert detail (excerpt, not archive) | FAT-019 (noHub) | Back | **Unbound** `stage1AlertDetailRepository` | Dialogue step | E(not found) | alertId, kind ✓route | Parent | — | — | PR | F:S-02 | PR | — | FC | S-02, G-10 | VX-B5 | alert_detail test | PENDING |
| SCR-FAT-029 | Parent | FAT-10 | Brain control (level per child + scope) | Hub:settings | Back | Local stage flags | Level / scope | S, RC | resolver | Father-only | — | Gateway RC | PR | PR | PR | — | FC | — | VX-B7 | brain_control test | PENDING |
| SCR-FAT-062 | Parent | FAT-29 | Family patterns | Hub:today | FAT-063 | Insights mock (local) | Read | E, RC | family | Parent | — | Insights RC | PR | PR | PR | — | FC | — | VX-B7 | family_patterns test | PENDING |
| SCR-FAT-063 | Parent | FAT-29 | Individual timeline | FAT-062 (noHub) | Back | `stage1IndividualTimelineRepository` | Filter | E, M, RC | resolver | Parent | — | Knowledge RC | PR | PR | PR | — | FC | — | VX-B7 | individual_timeline test | PENDING |
| SCR-FAT-064 | Parent | FAT-29 | Knowledge maps | FAT-062 (noHub) | Back | Knowledge mock | Read | E, RC | resolver | Parent | — | Knowledge RC | PR | PR | PR | — | FC | — | VX-B7 | knowledge_maps test | PENDING |
| SCR-FAT-074 | Parent | FAT-37 | Family advisor hub (✨ FAB) | AI FAB (all parent screens) | FAT-083 | AdvisorRepository mock | Ask / suggestions | S, RC | family | Parent | — | Assistant RC | PR | PR | F:G-11 | — | FC | G-11 | VX-B4 | family_advisor_hub_screen_test | PENDING |
| SCR-FAT-083 | Parent | FAT-37 | Advisor voice chat | FAT-074 (noHub) | Back | Advisor mock | Talk | NC, RC | family | Parent | Mic NC | Assistant RC | PR | PR | PR | PD mic | FC | — | VX-B7 | advisor_voice_screen_test | PENDING |
| SCR-FAT-076 | Mother | MOT-09 | Mother AI feed (by level) | Hub:today | Back | `stage1MotherAiFeedRepository` | Read | E, M, RC | family | Mother level | — | Assistant RC | F:G-13 | PR | PR | — | FC | G-13 | VX-B4 | mother_ai_feed_screen_test | PENDING |
| SCR-FAT-079 | Parent | FAT-41 | My advisor — delegation rules | Hub:today | FAT-080 | `stage1RulesEngineRuleRepository` (unbound) | Add rule | E, M | family | Parent | — | Agent RC | PR | F:C-04 | F:C-04 | — | FC | C-04 | VX-B1 | my_advisor test | PENDING |
| SCR-FAT-080 | Parent | FAT-41 | What the assistant did (permanent log, 10-min undo) | FAT-079 (noHub) | Back | `stage1AgentActionLogRepository` | Undo | E, M, RC | family | Parent | — | Agent RC | PR | PR | PR | — | FC | — | VX-B7 | agent_action_log_screen_test | PENDING |
| SCR-FAT-075 | Parent | FAT-38 | Coming features ✨ (honest catalog) | Hub:settings | Live screens | Local catalog | Open live screen | S | none | Parent | VPN/DNS NC | Gateways RC | PR | PR | PR | — | FC | G-08 label | VX-B4 | coming_soon test | PENDING |
| SCR-FAT-078 | Parent | FAT-40 | Home router filter guide | Hub:settings | Back | `stage1HomeRouterFilterRepository` | Check readiness | S, NC | family | Parent (level ≥ partner) | DNS NC | — | PR | F:G-02 | F:G-02 | — | FC | G-02 (Q-CEX keep layout) | VX-B3 | home_router_filter_screen_test | PENDING |
| SCR-FAT-086 | Parent | FAT-45 | Family moments (Friday recap, pride card) | Hub:today | Back | `stage1FamilyMomentsRepository` | Add / share | E, M, RC | family | Parent | — | Chat share RC | PR | PR | F:G-02 | — | FC | G-02 | VX-B3 | family_moments_screen_test | PENDING |

### 2.12 Privacy (child side) & shared templates

| Screen | Role | Journeys | Purpose | Entry | Exit | Data source | Control — Primary / Secondary | St | Ctx | RBAC | Native | Remote | Vis | UX | RTL | Dev | Status | Findings | Batch | Evidence | Final |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| SCR-CHD-010 | Child | CHD-05 | What is collected about me | Tab me | Back | Privacy collection ('demo-child') | Read | S | ✗ 'demo-child' | Child | — | — | PR | F:G-03 | PR (dates) | — | FC | G-03 | VX-B2 | what_is_collected test | PENDING |
| SCR-SHR-005 | Any | SHR-01 | Network error template | Event (error) | Retry | `AppErrorState` | Retry | Er | NA | Any | — | — | PR | PR | PR | — | FC | N-16 | VX-B7 | network_error_template_screen_test | PENDING |
| SCR-SHR-006 | Any | SHR-01 | Empty state template | Event (empty) | CTA | `AppEmptyState` | CTA | E | NA | Any | — | — | PR | PR | PR | — | FC | N-16 | VX-B7 | empty_state_template_screen_test | PENDING |
| SCR-FAT-039 | — | FAT-20 | School mode — **deleted (ADR-034)** | Tombstone → `/scr-fat-085` | FAT-085 | — | — | NA | — | — | — | — | NA | NA | NA | NA | OOS | — | — | router_routes_test | NA |

### 2.13 Non-catalog live surfaces (`sys3_routes.dart` + dev)

| Surface | Purpose | Entry | Data source | RBAC | Vis | UX | RTL | Findings | Batch | Final |
|---|---|---|---|---|---|---|---|---|---|---|
| session-restore | Restore session at boot | boot | FsSessionKernel | Any | PR | PR | PR | — | VX-B7 | PENDING |
| session-expired | Expired session | kernel event | FsSessionKernel | Any | PR | PR | PR | — | VX-B7 | PENDING |
| logout | Sign out | Settings | Identity | Any | PR | PR | PR | destructive confirm check | VX-B7 | PENDING |
| recovery | Account recovery | SHR-003 | Identity | Any | PR | PR | PR | — | VX-B7 | PENDING |
| deactivate | Deactivate account | Settings | Identity | Owner | PR | PR | PR | destructive confirm check | VX-B7 | PENDING |
| family-select | Choose family | boot / settings | FamilyContextStore | Parent | PR | PR | PR | G-05 downstream | VX-B2 | PENDING |
| remove-adult | Remove adult member | FAT-027 | Identity | Owner | PR | PR | PR | destructive confirm check | VX-B7 | PENDING |
| ownership-transfer | Transfer ownership | FAT-027 | Identity | Owner | PR | PR | PR | — | VX-B7 | PENDING |
| leave-family | Leave family | Settings | Identity | Non-owner adult | PR | PR | PR | — | VX-B7 | PENDING |
| invite-status | Invite status | FAT-008 | Adult invite repo | Father | PR | PR | PR | — | VX-B7 | PENDING |
| adult-sessions | Adult sessions | Settings | Session kernel | Parent | PR | PR | F:G-11 | G-11 | VX-B4 | PENDING |
| child-sessions | Child sessions | FAT-013 | Session kernel | Parent | PR | PR | F:G-11 | G-11 | VX-B4 | PENDING |
| remote-end | End child session | child-sessions | Session kernel | Parent | PR | PR | PR | "remote" wording is correct here (human) | VX-B7 | PENDING |
| revoke-confirm | Revoke device | child-sessions | Session kernel | Parent | PR | PR | PR | destructive confirm check | VX-B7 | PENDING |
| /gallery (dev) | Design token gallery | **RoleGuard blocked landing** | tokens | dev | NA | F:G-07 | NA | G-07 | VX-B1 | PENDING |

**Row count check:** 128 live catalog screens + FAT-077 (OOS, routed) + FAT-039 (tombstone) = 130 catalog rows; + 14 sys3 + 1 dev = 145 surfaces.

---

## 3. Journey matrix (all 73)

Columns: Journey · Screens · Entry → Result chain · Context preserved? · Back · Dead end / misleading success · Loop partner · Findings · Batch · Result.

| Journey | Screens | Chain summary | Context | Back | Dead end / false success | Loop | Findings | Batch | Result |
|---|---|---|---|---|---|---|---|---|---|
| JRN-FAT-01 | SHR-001, 002, 003, FAT-001, SHR-007, 008, FAT-030 | welcome → account → family → mode | family ✓ | PR | Login ignores credentials; fingerprint false success | — | G-01, C-01, C-02 | B1, B6 | PENDING |
| JRN-FAT-02 | FAT-002…006 | wizard → add child → QR → permissions → success | ✗ name lost | PR | child shown as ID | CHD-01 | S-04 | B6 | PENDING |
| JRN-FAT-03 | FAT-002, 007 | wizard → trial | — | PR | — | — | G-11 | B4 | PENDING |
| JRN-FAT-04 | FAT-008, 027, 031 | invite → members → level | memberId ✓ | PR | honesty jargon | MOT-01 | G-02 | B3 | PENDING |
| JRN-FAT-05 | FAT-010, 011 | today → suggestions | ✗ family pinned | ✗ go | pending lacks time/app/friend | — | S-03, G-05, G-17 | B5, B2 | PENDING |
| JRN-FAT-06 | FAT-012, 013 | kids → profile | childId ✓ | PR | new child as ID | — | S-04 | B6 | PENDING |
| JRN-FAT-07 | FAT-014, 015 | map → history | ✓ from profile; ✗ from hub/dashboard | PR | — (NC honest) | — | G-08, G-12 | B4 | PENDING |
| JRN-FAT-08 | FAT-016, 017, 028 | zones → create → emergency | family pinned | PR | hint saved as name; server-error copy | — | S-05, G-09 | B6, B1 | PENDING |
| JRN-FAT-09 | FAT-018, 028 | SOS alert ← event | actor ambiguous | PR | shortcut opens with no alert | CHD-03 | G-06, S-09 | B2, B5 | PENDING |
| JRN-FAT-10 | FAT-019, 020, 029 | alerts → detail → brain | — | PR | hub never fed | — | S-02 | B5 | PENDING |
| JRN-FAT-11 | FAT-021, 022 | chats → thread | — | PR | nothing to open; send throws | CHD-04 | S-01 | B6 (OD-09) | OD |
| JRN-FAT-12 | FAT-023, 024 | call → history | callId used as SOS actor | PR | — (NC honest) | CHD-04 | G-06, G-10 | B2, B4 | PENDING |
| JRN-FAT-13 | FAT-025, 026 | settings → device | ✗ wrong device id from profile | PR | device not found | — | S-06, S-09 | B2, B5 | PENDING |
| JRN-FAT-14 | FAT-025, 026 | device health fix | same | PR | OS settings simulated (honest) | — | S-06 | B2 | PENDING |
| JRN-FAT-15 | FAT-032, 033 | limits → requests | ✓ 032; inbox all | PR | not surfaced on Today | CHD-06 | S-03 | B5 | PENDING |
| JRN-FAT-16 | FAT-034, 035 | apps → approve | ✓ | ✗ SOS go | badge jargon | — | G-02, G-17 | B3, B4 | PENDING |
| JRN-FAT-17 | FAT-036 | web filter | ✗ drop | PR | edits default child | — | G-04, G-03 | B2 | PENDING |
| JRN-FAT-18 | FAT-037 | instant lock | ✗ drop | PR | edits default child | CHD-06 | G-04, G-03 | B2 | PENDING |
| JRN-FAT-19 | FAT-038 | tamper alerts | ✓ | PR | not in alerts hub | — | S-02 | B5 | PENDING |
| JRN-FAT-20 | FAT-039 (tombstone) | → FAT-085 | — | — | — | — | — | — | NA |
| JRN-FAT-21 | FAT-040…045 | studio → source → outputs → approve → assign | flow | PR | PDF subject fake | CHD-07 | C-03, G-02 | B1, B3 | PENDING |
| JRN-FAT-22 | FAT-046 | community library | — | PR | — | — | — | B7 | PENDING |
| JRN-FAT-23 | FAT-047…051 | path → materials → assignment → results → focus | ✗ 051 drop | PR | — | CHD-07 | G-04 | B2 | PENDING |
| JRN-FAT-24 | FAT-052, 053 | calendar → add | family | PR | — | MOT-08 | G-15 | B3 | PENDING |
| JRN-FAT-25 | FAT-054, 055 | tasks → create | family | ✗ from Today (go) | — | CHD-12 | G-17 | B5 | PENDING |
| JRN-FAT-26 | FAT-056, 057 | plans → manage | — | PR | — (RC honest) | — | — | B7 | PENDING |
| JRN-FAT-27 | FAT-058 | notifications | — | PR | server-error copy | — | G-09 | B1 | PENDING |
| JRN-FAT-28 | FAT-059, 060 | privacy → audit | ✗ 'demo-child' | PR | SOS actor 'demo-child' in log | CHD-05 | G-03, G-06 | B2 | PENDING |
| JRN-FAT-29 | FAT-062, 063, 064 | patterns → timeline → maps | — | PR | — (RC honest) | — | — | B7 | PENDING |
| JRN-FAT-30 | FAT-061 | language & help | — | PR | English toggle does nothing | — | S-07 | B3 (OD-01) | OD |
| JRN-FAT-31 | FAT-065, 066 | smart alerts → detail | ✗ drop | PR | jargon | — | G-04, G-02 | B2, B3 | PENDING |
| JRN-FAT-32 | FAT-067, 068 | supervision → platforms | ✗ 067 drop ('child_1') | PR | — | — | G-04, G-03 | B2 | PENDING |
| JRN-FAT-33 | FAT-069, 081 | usage → peers | ✗ 069 drop | PR | — | — | G-04 | B2 | PENDING |
| JRN-FAT-34 | FAT-070, 071 | circle → approve | resolver | PR | friend request not on Today | CHD-13 | S-03 | B5 | PENDING |
| JRN-FAT-35 | FAT-072 | Quran follow-up | ✗ drop ('child_a') | ✗ from Today (go) | — | CHD-14 | G-03, G-04 | B2 | PENDING |
| JRN-FAT-36 | FAT-073 | weekly report | — | PR | jargon | — | G-02 | B3 | PENDING |
| JRN-FAT-37 | FAT-074, 083 | advisor → voice | — | PR | — | — | — | B7 | PENDING |
| JRN-FAT-38 | FAT-075 | coming features | — | PR | — | — | G-08 | B4 | PENDING |
| JRN-FAT-39 | FAT-077 (OOS) | road safety | — | — | URL now redirects to FAT-075 Coming soon (D11) | — | C-05 | B1 | CLOSED (PASSED 2026-09-25) · PD |
| JRN-FAT-40 | FAT-078 | home router guide | — | PR | CTA "Native" | — | G-02 | B3 | PENDING |
| JRN-FAT-41 | FAT-079, 080 | delegation → action log | — | PR | own rules now show localized title + consequent | — | C-04 | B1 | CLOSED (PASSED 2026-09-25) · PD |
| JRN-FAT-42 | FAT-082 | chore distributor | — | PR | — | FAT-25 | — | B7 | PENDING |
| JRN-FAT-43 | FAT-084 | staged project | — | PR | — | — | — | B7 | PENDING |
| JRN-FAT-44 | FAT-085 | smart modes | ✗ drop | PR | — | CHD-02 | G-04 | B2 | PENDING |
| JRN-FAT-45 | FAT-086 | family moments | — | PR | jargon | — | G-02 | B3 | PENDING |
| JRN-MOT-01 | SHR-003, FAT-009 | login → accept invite | token ✓ | PR | father sees accept shortcut | FAT-04 | S-09 | B5 | PENDING |
| JRN-MOT-02 | FAT-010 | today (mother) | family pinned | ✗ go | as FAT-05 | — | S-03 | B5 | PENDING |
| JRN-MOT-03 | FAT-012, 013 | kids → profile | ✓ | PR | as FAT-06 | — | S-04 | B6 | PENDING |
| JRN-MOT-04 | FAT-021, 022, 023 | chat → call | — | PR | chat empty | CHD-04 | S-01 | B6 | OD |
| JRN-MOT-05 | FAT-018 | SOS alert | actor | PR | — | CHD-03 | G-06 | B2 | PENDING |
| JRN-MOT-06 | FAT-014 | map | as FAT-07 | PR | — | — | G-08 | B4 | PENDING |
| JRN-MOT-07 | FAT-033 | time requests (level) | inbox all | PR | not on Today | CHD-06 | S-03 | B5 | PENDING |
| JRN-MOT-08 | FAT-052, 054 | calendar, tasks | family | PR | — | — | — | B7 | PENDING |
| JRN-MOT-09 | FAT-076 | mother AI feed | — | PR | — | — | G-13 | B4 | PENDING |
| JRN-CHD-01 | CHD-001, 002, 003, 011 | welcome → scan → consent | — | PR | — (camera NC honest) | FAT-02 | G-13 | B4 | PENDING |
| JRN-CHD-02 | CHD-004 | my day | ✗ 'child_demo' | PR | father changes not reflected | FAT-44/15 | G-03 | B2 | PENDING |
| JRN-CHD-03 | CHD-005, 006 | SOS | actor 'self' | PR | — | FAT-09 | G-06 | B2 | PENDING |
| JRN-CHD-04 | CHD-007, 008, 009 | chats → thread → call | — | PR | chat empty | FAT-11 | S-01 | B6 | OD |
| JRN-CHD-05 | CHD-003, 010 | consent → what is collected | ✗ 'demo-child' | PR | — | FAT-28 | G-03 | B2 | PENDING |
| JRN-CHD-06 | CHD-020, 021 | request time ← expiry | ✓ 020; ✗ 021 | PR | jargon | FAT-15 | G-03, G-02 | B2, B3 | PENDING |
| JRN-CHD-07 | CHD-012…016 | learn → lesson → quiz → result | ✗ 'child_a' | PR | hard-coded praise topic | FAT-21/23 | G-03, C-06 | B2, B3 | PENDING |
| JRN-CHD-08 | CHD-017 | tutor | — | PR | jargon | — | G-02 | B3 | PENDING |
| JRN-CHD-09 | CHD-018 | focus | — | PR | — | FAT-23 | — | B7 | PENDING |
| JRN-CHD-10 | CHD-019 | minutes & badges | — | PR | — | FAT-25 | G-11 | B4 | PENDING |
| JRN-CHD-11 | CHD-023, 024 | share media, I arrived | — | PR | jargon | FAT-07 | G-02 | B3 | PENDING |
| JRN-CHD-12 | CHD-022 | my tasks | resolver | PR | — | FAT-25 | — | B7 | PENDING |
| JRN-CHD-13 | CHD-030 | friends | resolver | PR | jargon | FAT-34 | G-02 | B3 | PENDING |
| JRN-CHD-14 | CHD-025, 026, 027 | ward → progress → athkar | ✗ 'child_a' | PR | — | FAT-35 | G-03 | B2 | PENDING |
| JRN-CHD-15 | CHD-028, 029 | plan → review | — | PR | — | — | — | B7 | PENDING |
| JRN-CHD-16 | CHD-031 | coming gifts | — | PR | — | — | — | B7 | PENDING |
| JRN-CHD-17 | CHD-033…037 | stories, challenges, sounds, call play, stickers | — | PR | — | — | G-12 | B4 | PENDING |
| JRN-CHD-18 | CHD-032 | smart tilawah | — | PR | jargon | FAT-35 | G-02 | B3 | PENDING |
| JRN-SHR-01 | SHR-005, 006 | error / empty templates | — | NA | — | — | — | B7 | PENDING |

Count: FAT 45 + MOT 9 + CHD 18 + SHR 1 = **73**.

---

## 4. Father ↔ child loop register (L6 priority)

| Loop | Parent side | Child side | Shared authority | Static verdict | Blocking finding |
|---|---|---|---|---|---|
| Time request | FAT-033 | CHD-020 / CHD-021 | Stage-1 time request runtime | FAIL (child 021 reads 'demo-child'; not on Today) | G-03, S-03 |
| Screen-time limit | FAT-032 | CHD-004 | ScreenTime local + policy sync bus | FAIL (CHD-004 reads 'child_demo') | G-03 |
| Instant lock | FAT-037 | CHD-021 / CHD-004 | Device lock prefs | FAIL (route drops child) | G-04 |
| Smart modes | FAT-085 | CHD-004 | Smart mode activation bus | FAIL (route drops child; 'child_demo') | G-03, G-04 |
| Quran ward | FAT-072 | CHD-025 | QuranLocalBridge | PASS-candidate only if single child 'child_a' matches roster — FAIL for real roster | G-03 |
| Tasks & reward | FAT-054/055 | CHD-022 | Family tasks local | PENDING-RENDER (CE-B1 evidence) | — |
| Friend approval | FAT-071 | CHD-030 | Outer circle | PENDING (not on Today) | S-03 |
| Learning assignment/result | FAT-049/050 | CHD-014/015/016 | EDU local | FAIL (child side 'child_a') | G-03 |
| SOS | CHD-005/006 | FAT-018 | SOS final service | FAIL (actor 'self') | G-06 |
| Family chat | FAT-021/022 | CHD-007/008 | none bound | FAIL / OD-09 | S-01 |

---

## 5. Control completeness by system (42)

Properties: **Cf** Configure · **Op** Operate · **Ad** Adjust · **Ex** Exceptions · **Sc** Scope · **Rb** RBAC · **St** State · **Rv** Review · **Rc** Recovery · **Cq** Consequence clarity. Values: P-cand = PASS candidate (static OK, render pending) · F = fail (finding) · BN/BR · NA · OD.

| System | Surfaces | Cf | Op | Ad | Ex | Sc | Rb | St | Rv | Rc | Cq | Key findings |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ADM:أ Onboarding | SHR-001/002/003/007, FAT-001/002/030, CHD-001/002/003/011 | P-cand | F (login) | NA | NA | P-cand | P-cand | P-cand | NA | P-cand | F (fingerprint) | G-01, C-01, C-02 |
| ADM:ب Family & members | FAT-003, 008, 009, 027, 031 | F (name lost) | P-cand | P-cand | NA | P-cand | P-cand | F (ID shown) | P-cand (audit) | P-cand | F | S-04 |
| ADM:ج Devices | FAT-025, 026 | NA | BN | NA | NA | F (wrong id) | P-cand | P-cand (demo banner) | NA | BN | P-cand | S-06 |
| ADM:ح Settings/support | FAT-061, shortcuts | F (EN no-op) | — | — | NA | NA | P-cand | F | NA | NA | F | S-07, S-09 |
| ADM:د Billing | FAT-056, 057 | BR | BR | BR | NA | P-cand | P-cand | P-cand | NA | BR | P-cand | — |
| ADM:ز Day board | FAT-010 | NA | F (pending incomplete) | NA | NA | F (family pinned) | P-cand | F (last sync null) | NA | NA | P-cand | S-03, G-05 |
| ADM:هـ Notifications | FAT-058 | P-cand | P-cand | P-cand | P-cand (SOS never muted) | P-cand | P-cand | P-cand | NA | F (server copy) | P-cand | G-09 |
| ADM:و Privacy | FAT-059, 060, CHD-010 | P-cand | P-cand | P-cand | NA | F (demo-child) | P-cand (owner-only) | P-cand | P-cand (append-only) | P-cand (forget) | P-cand | G-03, G-06 |
| AIC:أ Monitoring engine | FAT-019, 020, 029 | P-cand | F (hub unfed) | P-cand | NA | P-cand | P-cand | F | F | NA | P-cand | S-02 |
| AIC:ب Patterns | FAT-062 | BR | BR | NA | NA | P-cand | P-cand | P-cand | NA | NA | P-cand | — |
| AIC:ج Knowledge | FAT-063, 064 | BR | BR | NA | NA | P-cand | P-cand | P-cand | NA | NA | P-cand | — |
| AIC:د Advisor/reports | FAT-043/044/065/066/073/086, CHD-014/016/017/032 | P-cand | BR | P-cand | NA | F (drop) | P-cand | P-cand | P-cand | NA | F (jargon) | G-02, G-04 |
| AIC:هـ Interactive assistant | FAT-074, 076, 083 | NA | BR | NA | NA | P-cand | P-cand | P-cand | NA | NA | P-cand | — |
| AIC:و Delegated agent | FAT-079, 080 | F (rule label) | BR | P-cand | NA | P-cand | P-cand | P-cand | P-cand | P-cand (undo) | F | C-04 |
| COM:أ Chat | FAT-021/022, CHD-007/008 | NA | F | NA | NA | P-cand | P-cand (never gated) | F (empty) | NA | NA | P-cand | S-01 (OD-09) |
| COM:ب Calls | FAT-023/024, CHD-009/036 | NA | BN | NA | NA | F (actor) | P-cand | P-cand | BN | NA | P-cand | G-06 |
| COM:ج Media | CHD-023, 037 | P-cand | BN | P-cand | NA | P-cand | P-cand | P-cand | NA | NA | F (jargon) | G-02 |
| COM:د Safe circle | FAT-070, 071, CHD-030 | P-cand | P-cand | P-cand | P-cand (strangers locked) | P-cand | P-cand | P-cand | P-cand | P-cand | P-cand | S-03 (dashboard) |
| COM:ز Location-in-comms | CHD-024 | NA | P-cand | NA | NA | P-cand | P-cand | P-cand | NA | NA | F (FCM wording) | G-02 |
| COM:هـ Calendar | FAT-052, 053 | P-cand | P-cand | P-cand | NA | P-cand | P-cand | P-cand | NA | P-cand | P-cand | G-15 |
| COM:و Tasks | FAT-054, 055, 082, CHD-022 | P-cand | P-cand | P-cand | NA | P-cand | P-cand | P-cand | P-cand | P-cand | P-cand | G-17 |
| EDU:أ Materials | FAT-048, CHD-012, 013 | P-cand | BR | P-cand | NA | F ('child_a') | P-cand | P-cand | NA | NA | P-cand | G-03 |
| EDU:ب Assignments | FAT-049, 050, CHD-014 | P-cand | P-cand | P-cand | NA | F | P-cand | P-cand | P-cand | NA | P-cand | G-03 |
| EDU:ج Assessments | CHD-015, 016 | NA | P-cand | NA | NA | F | P-cand | P-cand | P-cand | NA | F (fixed topic) | G-03, C-06 |
| EDU:ح Focus | FAT-051, CHD-018, 035 | P-cand | BN | P-cand | NA | F (051 drop) | P-cand | P-cand | P-cand | NA | P-cand | G-04 |
| EDU:د Tutor | CHD-017, 033 | NA | BR | NA | NA | P-cand | P-cand | P-cand | P-cand (logged to father) | NA | F (jargon) | G-02 |
| EDU:ز Quran | FAT-072, CHD-025/026/027/032 | P-cand | P-cand | P-cand | P-cand (never time-locked) | F ('child_a') | P-cand | P-cand | P-cand | NA | F (jargon) | G-03, G-04, G-02 |
| EDU:ط Studio | FAT-040…047, 084 | P-cand | P-cand | P-cand | NA | P-cand | P-cand | P-cand | P-cand | P-cand | F (PDF sheet) | C-03 |
| EDU:هـ Adaptive | CHD-028, 029 | NA | P-cand | NA | NA | P-cand | P-cand | P-cand | NA | NA | P-cand | — |
| EDU:و Rewards (Minutes) | FAT-045, 055, CHD-019, 034 | P-cand | P-cand | P-cand | NA | P-cand | P-cand | P-cand | P-cand | NA | P-cand | — |
| SEC:أ Screen time | FAT-032, 033, 085, CHD-004, 020, 021 | P-cand | P-cand | P-cand | P-cand (extra time) | F (child ids) | P-cand | P-cand | P-cand | P-cand | F (jargon) | G-03, G-04, S-03 |
| SEC:ب Apps | FAT-034, 035 | P-cand | BN | P-cand | P-cand | P-cand | P-cand | P-cand | NA | P-cand | F (badge) | G-02 |
| SEC:ج Web filter | FAT-036, 078 | P-cand | BN | P-cand | P-cand | F (drop) | P-cand | P-cand | NA | F (server copy) | F (jargon) | G-04, G-09, G-02 |
| SEC:ح Anti-tamper | FAT-038 | NA | BN | NA | NA | P-cand | P-cand | P-cand | F (not in hub) | NA | P-cand | S-02 |
| SEC:د Location | FAT-013…017 | F (hint as name) | BN | P-cand | NA | F (family pinned; hub no child) | P-cand | P-cand | BN | P-cand | F (server copy) | S-05, G-05, G-08 |
| SEC:ز Platforms | FAT-068 | P-cand | BN | P-cand | NA | P-cand | P-cand | P-cand | NA | NA | P-cand | — |
| SEC:ط Instant lock | FAT-037 | P-cand | BN | P-cand | NA | F (drop) | P-cand | P-cand | NA | P-cand | F (jargon) | G-04, G-02 |
| SEC:ك Road safety | FAT-077 | OD | — | — | — | — | — | — | — | — | — | C-05 (OOS) |
| SEC:ل Modes (School) | FAT-039 → 085 | see SEC:أ | | | | | | | | | | tombstone NA |
| SEC:هـ SOS | FAT-018, 028, CHD-005, 006 | P-cand | P-cand (local fire) | P-cand | P-cand | F (actor) | P-cand | P-cand | P-cand | P-cand | P-cand | G-06, S-09 |
| SEC:و Smart content | FAT-065, 066, 067 | P-cand | BN | P-cand | NA | F (drop / 'child_1') | P-cand | P-cand | P-cand | NA | F (jargon) | G-03, G-04, G-02 |
| SEC:ي Reports | FAT-069, 073, 081 | NA | P-cand | NA | NA | F (069 drop) | P-cand | P-cand | P-cand | NA | F (jargon) | G-04, G-02 |

Count: 42 rows (SEC:ل shown for completeness via its tombstone and mode successor).
