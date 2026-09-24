# 02 — FS-005 Current Repo Evidence

**Mode:** Evidence-only map of symbols, screens, docs, and prototypes.  
**Master:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Policy Register (supreme text — Modes)

Source: `handoff/04_POLICY_REGISTER_EN.md` §3 (M-A/B/C/D) + §2 priority ladder.

| Ruling | Binding gist | Code impact named |
|---|---|---|
| M-A | 6 ready + custom; six-property structure | `FamilyMode` entity |
| Mode structure | identity · scheduling · scope · allowed apps (still time-governed) · exceptions · grace | Model fields; #4 through TimeEngine |
| M-B | Conflict → stricter wins + father notified | `ModeConflictResolver` + notification |
| M-C | Child top card + app-grid tint | `activeMode` stream |
| M-D | Grace 2 default (0–5); **manual always instant** | `mode.grace`; skip on manual |
| Lock above modes | Instant lock overrides active mode | Same ladder as §2 |

---

## 2. Flutter domain / policy spine

| Path | Role | Class |
|---|---|---|
| `app/lib/core/policy/smart_modes.dart` | `BuiltInModeId`, `ModeGrace`, `ModeConflictResolver`, `GrantOnModeStart` / `GrantConflictPolicy` | **IMPLEMENTED** (pure domain) |
| `app/lib/core/policy/smart_mode_prefs.dart` | `SmartModeRow`, `SmartModePrefs` (per-child rows; single active) | **PARTIAL** / prefs model |
| `app/lib/core/policy/smart_mode_prefs_repository.dart` | Rule-25 seam; in-memory `stage1SmartModePrefsStore` | **MOCK/SIMULATION** |
| `app/lib/core/policy/smart_mode_activation.dart` | Activation snapshot (`modeId`, `active`, `expiresAt`) | **PARTIAL** |
| `app/lib/core/policy/smart_mode_activation_bus.dart` | Same-session parent→child publish; lean offline queue | **PARTIAL** |
| `app/lib/core/policy/time_engine.dart` | P3: `modeActive` → `deniedMode` unless allow/exception | **IMPLEMENTED** (flag algebra) |
| `app/lib/core/policy/schedule_window.dart` | `ScheduleKind` sleep/prayer/study | **IMPLEMENTED** (ST schedules) |
| `app/lib/core/policy/schedule_window_query.dart` | Maps active windows → `BuiltInModeId` + sets `modeActive` | **IMPLEMENTED** — **competing producer** |
| `app/lib/core/policy/policy_sync_bus.dart` | `PolicySyncKind.schedule` for `ScheduleWindow` only — **not** smart-mode activation | **PARTIAL** (ST path) |
| `app/lib/core/policy/screen_time_policy_query.dart` | Passes through mode flags on `TimeContext` | **PARTIAL** |
| `app/lib/core/policy/app_access_rules.dart` | Passes through mode flags; does not author mode allow-lists | **PARTIAL** |

---

## 3. Feature UI / routes

| Screen / ID | Path / route | Evidence |
|---|---|---|
| SCR-FAT-085 Smart Modes | `features/n09_smart_modes/smart_modes_screen.dart` · `/scr-fat-085` | Toggles all `BuiltInModeId`; school start/end pickers; honesty banner; publishes activation bus |
| SCR-FAT-039 School Mode | Registry tombstone; router redirects `/scr-fat-039` → `/scr-fat-085` | ADR-034 / SET-018 closed |
| SCR-CHD-004 Child Day Board | `child_day_board_screen.dart` | Listens `SmartModeActivationBus`; tint + active mode label; soft toasts |
| SCR-FAT-032 Child Screen Time | schedules sleep/prayer/study | **Separate** schedule UI that can set `modeActive` via query |

Router: `app/lib/app/router.dart` — `SmartModesScreen()` at `/scr-fat-085`; `tombstoneSchoolRedirectTarget = '/scr-fat-085'`.

**RoleGuard on FAT-085:** **not found** in screen or route builder — AuthZ open (**Q-MODE-02**).

---

## 4. Tests

| Test | Covers |
|---|---|
| `app/test/core/policy/smart_modes_test.dart` | M-A catalog length; M-B intersect; M-D grace; GrantOnModeStart required |
| `app/test/features/n09_smart_modes/smart_modes_screen_test.dart` | FAT-085 widget |
| `app/test/features/n02_day/child_day_board_screen_test.dart` | Activation bus → label; offline keep; JSON round-trip |
| `app/test/core/policy/schedule_window_test.dart` | Sleep window → `modeActive` / `deniedMode` |
| `app/test/core/policy/time_engine_test.dart` | Mode deny / exception paths |

---

## 5. Prototype evidence (frozen HTML)

Source: `prototype/family_os_app.html` / `family-os/family_os_app.html` — `S.familyModes`.

| Field | Prototype behavior |
|---|---|
| `list[]` | Modes with `id`, `name`, `icon`, `sched` (string), `kids[]`, `allowedApps[]`, `exceptions[]`, `grace`, `strict` |
| Catalog | sleep, school, study, ramadan, vacation, **famtime** (not `exams`) |
| `activeId` / `graceLeft` | Single active; grace UX on child |
| `setFamilyMode(id)` | Toggle activate/deactivate; reflects named kids |
| `saveCustomMode` / “أنشئ وضعًا مخصصًا” | Custom builder toast — **not complete** |
| Child grace button | Child can clear `graceLeft` unilaterally — flagged historically as GAP-A-CHILD-015 |

---

## 6. Schema / contracts

| Asset | Finding |
|---|---|
| `family-os/_CONTRACTS/schema.sql` | **No** `FamilyMode` / mode schedule tables |
| Present | `device_mode` enum (PARENT / CHILD_LOCKED / CHILD_PREVIEW); `mode_unlock_attempt` (device unlock attempts — **not** lifestyle modes) |
| Registry `screens.csv` | FAT-085 = smart modes; FAT-039 tombstone still lists S-SEC-058/059/060 services historically |

---

## 7. GAP_LOG closures (evidence of Stage-1 intent)

| Gap | Closure |
|---|---|
| SET-018 | School services hosted on FAT-085, not tombstone FAT-039 |
| SET-019 | CHD-004 follows `SmartModeActivationBus` |
| SET-001 | Sleep/prayer/study ControlFit on FAT-032 via `ScheduleWindow*` |

---

## 8. Sibling discovery / L2 references to FS-005

Named as schedule owner / tighten-only consumer in:

- `web_filtering_l2/` (WF-OD-10/13)
- `application_control_l2/` (APP-OD-10/11)
- `screen_camera_l2/` (SC-SF-10)
- Screen Time packs (`n09_smart_modes`, P3 precedence)
- Cross maps in FS-002/003/004 discovery

**No prior `modes_discovery/` folder** before this pack.

---

## 9. What is simulated vs real (summary)

| Claim often heard | Evidence truth |
|---|---|
| “Smart modes enforce on child device” | UI tint + TimeEngine **flags** when callers supply them; **no OS Focus / MDM** |
| “School auto-activates by location (S-SEC-059)” | Hosted-on-FAT-085 **copy only**; no geofence wire |
| “School schedule runs” | Times stored; activation is **manual toggle**; `expiresAt` derived for display |
| “Allowed apps per mode” | Register + prototype lists; Flutter mode prefs **do not store** allow-lists |
| “Modes sync family-wide” | Per-`childId` prefs + in-process bus; no FCM / Drift |
