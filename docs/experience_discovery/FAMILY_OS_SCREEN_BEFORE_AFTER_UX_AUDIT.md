# FAMILY OS — SCREEN-BY-SCREEN BEFORE/AFTER UX AUDIT

**Campaign:** FS-001 → FS-007 · FS-I-RECON · Phase 1.5  
**Audit date:** 2026-09-24  
**Type:** Evidence/reporting only — production code **not** modified by this audit  

### Evidence sources

| Source | Use |
|---|---|
| `docs/experience_discovery/FS_001_007_CHANGE_LEDGER.md` | KEEP/REFINE hosts + capability honesty |
| `docs/experience_discovery/FS_001_007_CLOSURE_REPORT.md` | Visual KEEP confirmation |
| `docs/experience_discovery/PHASE_1_5_*` | Composition / RBAC / no redesign |
| `docs/experience_discovery/IMPLEMENTATION_BEFORE_AFTER_AUDIT.md` | Engineering baseline |
| `app/lib/app/router.dart` | Exact routes |
| Current host screens + shared components | Visible elements / Keys / ARB |
| `.verify/*.json` + focused `*ux_adapt*` / domain tests | Verification |
| Git | **No FS commits** — BEFORE for new panels = absent; BEFORE for hosts = Stage-1 ScreenBuild/SET behavior from CONVERSION_LOG + master-plan baseline |

### Accuracy rules applied

- Do **not** invent BEFORE UI. If a prior widget tree cannot be proven line-by-line from git (uncommitted campaign), BEFORE is stated from **ledger + Stage-1 ScreenBuild existence + absence of FS widgets**.
- Unchanged screens are listed only under **§ Explicitly unchanged / no material UI** — not as modified.
- `FamilyShell` / tab chrome = **PRT-2**, not FS campaign UI.
- Device: **REAL-DEVICE VALIDATION: NOT RUN** everywhere unless proven otherwise (never proven).

### Visual classification vocabulary

`NO CHANGE` · `LIGHT REFINEMENT` · `STRUCTURAL UI CHANGE` · `NEW SCREEN` · `REDESIGN`

**Strict rule:** spacing/order/grouping alone ≠ redesign. Campaign law = KEEP + REFINE.

---

## Indexed routes (materially touched)

| Screen ID | Route | File | Role | System |
|---|---|---|---|---|
| SCR-FAT-014 | `/scr-fat-014` | `location_map_screen.dart` | Parent | FS-001 |
| SCR-FAT-015 | `/scr-fat-015` | `location_history_screen.dart` | Parent | FS-001 |
| SCR-FAT-016 | `/scr-fat-016` | `safe_zones_screen.dart` | Parent | FS-001 |
| SCR-FAT-017 | `/scr-fat-017` | `create_safe_zone_screen.dart` | Parent | FS-001 |
| SCR-CHD-024 | `/scr-chd-024` | `child_arrival_screen.dart` | Child | FS-001 |
| SCR-FAT-036 | `/scr-fat-036` | `web_filter_screen.dart` | Parent | FS-002 |
| *(hosted)* | *(no GoRoute)* | `web_block_page.dart` | Shared interstitial | FS-002 |
| SCR-FAT-034 | `/scr-fat-034` | `child_apps_screen.dart` | Parent | FS-003 |
| SCR-FAT-035 | `/scr-fat-035` | `new_app_approval_screen.dart` | Parent | FS-003 |
| *(hosted)* | *(no SCR id)* | `app_deny_page.dart` | Child interstitial | FS-003 |
| SCR-FAT-065 | `/scr-fat-065` | `smart_alerts_screen.dart` | Parent | FS-004 + FS-007 |
| SCR-CHD-010 | `/scr-chd-010` | `what_is_collected_screen.dart` | Child | FS-004 + FS-007 |
| SCR-FAT-085 | `/scr-fat-085` | `smart_modes_screen.dart` | Parent | FS-005 |
| SCR-CHD-004 | `/scr-chd-004` | `child_day_board_screen.dart` | Child | FS-005 |
| SCR-FAT-018 | `/scr-fat-018` | `sos_alert_screen.dart` | Parent | FS-006 |
| SCR-FAT-028 | `/scr-fat-028` | `emergency_setup_screen.dart` | Parent | FS-006 |
| SCR-CHD-006 | `/scr-chd-006` | `child_sos_in_progress_screen.dart` | Child | FS-006 |

---

# PART 1 — CHANGED SCREENS (full records)

---

## 1. SCR-FAT-014 — Location Map

### 1. Screen identity

| Field | Value |
|---|---|
| Name | Where are my kids? (`locationMapTitle`) |
| Route | `/scr-fat-014` |
| System | FS-001 Location |
| Existing / new | **Existing** Stage-1 host |
| Role | Parent |

### 2. BEFORE

Stage-1 map host (ScreenBuild SCR-FAT-014): AppBar + SOS; Life360-style honesty banner; decorative map canvas; child pins; day-thread card; Safe zones CTA; Prefs/mock location data. **No** GPS NOT IMPLEMENTED strip; **no** `CapabilityHonestyBadge`; **no** Silent locate CTA/sheet; **no** `Stage1LocationRuntime` domain bridge.

### 3. AFTER

Same shell sections **plus**:

- Banner `locationGpsNotImplementedBanner`
- `CapabilityHonestyBadge(notImplemented)` for GPS
- Primary CTA `locationMapSilentLocateCta` → `SilentLocateSheet` (`silentLocateTitle` / Confirm / Done + result strings including `silentLocateResultGpsNotImplemented`)
- Runtime may open `Stage1LocationRuntime` for locate request honesty

### 4. Element-by-element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| GPS honesty banner | Absent | `locationGpsNotImplementedBanner` | Added |
| CapabilityHonestyBadge | Absent | NOT IMPLEMENTED badge | Added |
| Silent locate CTA | Absent | `locationMapSilentLocateCta` | Added |
| SilentLocateSheet | Absent | Sheet with Request locate / Done | Added |
| Map canvas / pins / day thread | Present | Present | Unchanged structure |
| Safe zones CTA | Present | Present | Unchanged |
| SOS AppBar | Present | Present | Unchanged |
| Navigation route | `/scr-fat-014` | Same | Unchanged |

### 5. Policy alignment

- Location Final / L3 honesty: never claim live GPS (`native_gps` NOT IMPLEMENTED).
- Silent locate: quiet parent request; child sees no interactive prompt (ARB `silentLocateBody`).
- SOS remains reachable (P-4).

### 6. UX assessment

| Lens | Verdict | Why |
|---|---|---|
| Discoverability | **IMPROVED** | Silent locate is an explicit CTA on the map host |
| Cognitive load | **MORE COMPLEX** | Extra honesty strip + badge + CTA (additive) |
| Steps | Equal for map browse; **+1 sheet** for locate | Locate was not a flow before |
| Hierarchy | Primary map still dominates; honesty above canvas | Supported by widget order |
| Control placement | Silent locate near Safe zones CTA | Evidence in screen build |
| Error recovery | **IMPROVED** | Explicit GPS NOT IMPLEMENTED / stale / unavailable results |
| Consistency | Family-OS banners + tokens | KEEP language |

### 7. Visual class

`LIGHT REFINEMENT`

### 8. Mock / real honesty

`NOT IMPLEMENTED` (device GPS) · map decorative · domain locate request `REAL LOCAL` honesty path when injected · **never** live tracking

### 9. Cross-system

None for display. Locate may attach domain fixes later used by FS-006 handoff / FS-005 facts — **does not** activate Modes.

### 10. Verification

- Focused: `fs001_ux_adapt_test.dart`, location map tests  
- `.verify/FS-001-UX.json` currently **failed** (stale DEBT P15-F32); CONVERSION_LOG claims passed  
- **REAL-DEVICE VALIDATION: NOT RUN**

---

## 2. SCR-FAT-015 — Location History

### Identity

`LocationHistoryScreen` · `/scr-fat-015` · FS-001 · Existing · Parent

### BEFORE → AFTER

BEFORE: Stage-1 day-thread + frequent places + Life360 honesty + SOS.  
AFTER: Same + `locationGpsNotImplementedBanner`. **No** Silent locate, **no** CapabilityHonestyBadge, **no** domain repository bind on this host (source evidence).

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| GPS NOT IMPLEMENTED banner | Absent | Present | Added |
| Thread / frequent places / retention | Present | Present | Unchanged |

### Policy / UX / visual / honesty

- Policy: GPS honesty vocabulary.  
- UX: Discoverability **UNCHANGED**; load **slightly MORE COMPLEX** (one banner).  
- Visual: `LIGHT REFINEMENT` (minimal).  
- Honesty: `NOT IMPLEMENTED` GPS.  
- Verify: covered under FS-001-UX suite / history widget tests. **REAL-DEVICE VALIDATION: NOT RUN**

---

## 3. SCR-FAT-016 — Safe Zones list

### Identity

`SafeZonesScreen` · `/scr-fat-016` · FS-001 · Existing · Parent

### BEFORE → AFTER

BEFORE: Family zone list, alert switches, add/draw CTAs, honesty/read-only banners, default Stage-1 in-memory repo.  
AFTER: Same + GPS NOT IMPLEMENTED banner. Default repo evidence still `stage1SafeZonesRepository` on this host — **Domain bind is on FAT-017**, not proven on FAT-016 list host.

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| GPS banner | Absent | Present | Added |
| Zone switches / add / draw | Present | Present | Unchanged |

### Classification

`LIGHT REFINEMENT` (minimal) · Honesty `NOT IMPLEMENTED` GPS · list persistence may remain **LEGACY-MOCK-DEBT** on this host until DomainSafeZones is injected.  
**REAL-DEVICE VALIDATION: NOT RUN**

---

## 4. SCR-FAT-017 — Create Safe Zone

### Identity

`CreateSafeZoneScreen` · `/scr-fat-017` · FS-001 · Existing · Parent

### BEFORE

Draw map + radius slider; name; arrival/departure/no-show switches; save; Life360 honesty; Partner read-only. Assignment law incomplete vs Q-LOC-12 (ledger: multi-select required).

### AFTER

Same draw/save chrome **plus**:

- GPS banner + `CapabilityHonestyBadge(notImplemented)`
- Section `createSafeZoneAssignHeading` + child `FilterChip`s (`create_safe_zone_child_$id`) + hint requiring ≥1 child
- Optional `DomainSafeZonesRepository` persist when injected / Stage-1 bridge

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| GPS badge / banner | Absent / incomplete | Present | Added |
| Assign-to-children chips | Absent / not Q-LOC-12 | Required multi-select | Added / Changed |
| Arrival/Departure/No-show switches | Present | Present | Unchanged |
| Save CTA | Present | Present (domain-capable) | Changed (backend of save) |
| Draw map / radius | Present | Present | Unchanged |

### Policy

Q-LOC-12 assignment = select children (no silent expand-all). Geometry honesty. Partner read-only preserved.

### UX

| Lens | Verdict |
|---|---|
| Discoverability | **IMPROVED** (assignment explicit) |
| Cognitive load | **MORE COMPLEX** (required chips + honesty) |
| Steps | **+assignment step** before valid save |
| Hierarchy | Draw still primary; assign before save | 

### Visual / honesty / verify

`LIGHT REFINEMENT` · GPS `NOT IMPLEMENTED` · domain save `REAL LOCAL` when bridged · `fs001_ux_adapt_test` · **REAL-DEVICE VALIDATION: NOT RUN**

---

## 5. SCR-CHD-024 — Child Arrival (“أنا وصلت”)

### Identity

`ChildArrivalScreen` · `/scr-chd-024` · FS-001 · Existing · Child

### BEFORE

Headline; zones grid one-tap check-in; **live location card** (`child_arrival_live`); SOS; parent lean.

### AFTER (ledger FS-001-UX)

Live map card treatment → **silent check-in honesty banner** (`childArrivalSilentBanner` on `child_arrival_live` key). Zones grid + SOS retained. **No** CapabilityHonestyBadge / SilentLocate sheet on this child host.

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| Live map / live status card | Interactive live-map style card | Silent check-in honesty banner | Changed |
| Zone check-in CTAs | Present | Present | Unchanged |
| SOS | Present | Present | Unchanged |

### Policy / UX / visual

Silent child location honesty (no fake live tracking). UX: Discoverability **UNCHANGED**; cognitive load **UNCHANGED/slightly clearer** honesty. Visual: `LIGHT REFINEMENT`. Honesty: `NOT IMPLEMENTED` live GPS.  
**REAL-DEVICE VALIDATION: NOT RUN**

---

## 6. SCR-FAT-036 — Web Filter

### Identity

`WebFilterScreen` · `/scr-fat-036` · FS-002 · Existing · Parent

### BEFORE

Stage-1/UI-009: filter level segmented control; category switches; allow/block/dict editors; preview → block page; unlock inbox; save. Prefs/Stage-1 policy. Limited native/taxonomy honesty.

### AFTER

Same editors **plus** honesty box with:

- `CapabilityHonestyBadge` ×2 (mockRemote + degraded)
- Copy: `webFilterNativeBlockHonesty`, `webFilterTaxonomyTbdHonesty`, `webFilterDeliveryHonesty`
- Precedence note `webFilterPrecedenceNote` (block → temp → allow → dict → category)
- Domain / `Stage1WebFilterRuntime` bind for lists + delivery Configured→Verified

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| Native/taxonomy/delivery honesty badges | Absent / weaker | Two badges + three honesty strings | Added |
| Level / categories / lists | Present | Present (domain-backed) | Changed (binding) |
| Preview CTA | Present | Present → WebBlockPage | Unchanged entry |
| Unlock inbox | Present (SET-006) | Present (temp-allow law) | Changed (policy effect) |
| Save | Present | Present → Configured delivery | Changed |

### Policy

WF-OD-08 precedence; Q-WF-01 baseline/override; Q-WF-09 unlock ≠ silent allowList; delivery honesty Configured≠native enforced.

### UX

| Lens | Verdict |
|---|---|
| Discoverability | **IMPROVED** (explicit native/delivery honesty) |
| Cognitive load | **MORE COMPLEX** (honesty stack on already dense screen) |
| Steps | Equal for edit; unlock still approve/deny |
| Consistency | KEEP list editors |

### Visual / honesty / verify

`LIGHT REFINEMENT` · Lists `REAL LOCAL` · native block `MOCK-REMOTE` · taxonomy `DEGRADED` · `.verify/FS-002-*` passed · **REAL-DEVICE VALIDATION: NOT RUN**

---

## 7. WebBlockPage (hosted interstitial)

### Identity

`WebBlockPage` · **no dedicated GoRoute** · FS-002 · Existing interstitial · Shared (preview/child)

### BEFORE → AFTER

BEFORE: Block title/reason + unlock CTA (UI-009).  
AFTER: Adds/emphasizes **source-of-deny** (`web_block_source_of_deny`) + feedback path; unlock creates **timed temp allow**, not permanent allowList.

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| Source-of-deny line | Weak / generic | Explicit owning system deny | Added/Changed |
| Unlock CTA | Present | Present → temp allow | Changed (effect) |
| Feedback | Present / evolving | Present | Changed |

### Visual

`LIGHT REFINEMENT` (not NEW SCR). Honesty: domain verdict `REAL LOCAL`; device block `MOCK-REMOTE`.  
**REAL-DEVICE VALIDATION: NOT RUN**

---

## 8. SCR-FAT-034 — Child Apps (App Control hub)

### Identity

`ChildAppsScreen` · `/scr-fat-034` · FS-003 · Existing · Parent

### BEFORE

Stage-1 app inventory: categories; per-app switches; control sheet Allow/Block/Unlimited mixed with ST; pending installs; SOS. Prefs AC rules. Partner/observer hints. **No** Domain AC bootstrap; **no** protected package badges; **no** AppDeny preview; **no** os_intercept honesty badge. Child actor over-privilege fixed only in Phase 1.5 (domain).

### AFTER

- Tip + `CapabilityHonestyBadge(mockRemote)` + `childAppsOsInterceptHonesty`
- Partner tickets-only / observer hints retained/refined
- Protected badge `childAppsProtectedBadge` on SOS/Family OS/Chat/Quran packages; cannot block toast
- Preview → **`AppDenyPage`**
- `Stage1AppControlRuntime` / `AppControlService` bootstrap (Phase 1.5 F05)
- ST axes remain ST; AC owns Allow/Block/Exempt

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| OS intercept honesty badge | Absent | Present MOCK-REMOTE | Added |
| Protected badge on apps | Absent | Present | Added |
| AppDeny preview path | Absent | Opens AppDenyPage | Added |
| App list / switches / sheet | Present | Present (AC dispositions) | Changed (binding) |
| Partner tickets-only | Hint evolving | Explicit Partner tickets-only | Changed |
| Unlimited control | Mixed ST | ST remains ST; AC block separate | Changed (ownership) |

### Policy

APP-OD-09 protected packages; Partner tickets-only; Permanent Block ≠ Exception; os_intercept MOCK-REMOTE; Phase 1.5 child deny.

### UX

| Lens | Verdict |
|---|---|
| Discoverability | **IMPROVED** (protected + honesty) |
| Cognitive load | **MORE COMPLEX** (extra honesty + protected rules) |
| Hierarchy | Inventory still primary |
| Consistency | KEEP hub |

### Visual / honesty / verify

`LIGHT REFINEMENT` · dispositions `REAL LOCAL` · intercept `MOCK-REMOTE` · `fs003_ux_adapt_test` · FS-003 verify passed · **REAL-DEVICE VALIDATION: NOT RUN**

---

## 9. SCR-FAT-035 — New App Approval

### Identity

`NewAppApprovalScreen` · `/scr-fat-035` · FS-003 · Existing · Parent

### BEFORE → AFTER

BEFORE: Approve/deny install ticket UI (Stage-1).  
AFTER: Same CTAs + `CapabilityHonestyBadge` + `newAppApprovalChildScopedHonesty` (child-scoped install). Domain AC install store when bridged.

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| Honesty badge / child-scoped copy | Absent | Present | Added |
| Approve / Deny | Present | Present | Unchanged entry; Changed binding |

### Visual

`LIGHT REFINEMENT` · install tickets `REAL LOCAL` · OS intercept still `MOCK-REMOTE` · **REAL-DEVICE VALIDATION: NOT RUN**

---

## 10. AppDenyPage — NEW hosted child interstitial

### Identity

`AppDenyPage` · **no SCR id** (hosted like WebBlockPage) · FS-003 · **New surface** · Child

### BEFORE

No dedicated FS-003 deny interstitial with source-of-deny + Exception≠Minutes + protected reachability CTAs. Child blocked experience was incomplete vs L3.

### AFTER (new)

- Title `appDenyTitle`
- Reason variants: blocked / Lock Now / pending / generic
- Disclosure `appDenyDisclosure`
- Pending banner
- CTA `appDenyExceptionCta` + note `appDenyExceptionNotMinutes`
- Reachability: Chat / Quran / SOS CTAs
- Keys under `AppDenyPageKeys`

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| Entire page | Absent | Full interstitial | Added |
| Exception CTA | Absent | Temporary access request | Added |
| Chat / Quran / SOS | Absent on deny | Present (never locked) | Added |

### Policy

Source-of-deny; Exception ≠ Minutes / ≠ permanent unblock; SOS/Chat/Quran reachable (constitution / APP-OD-09).

### UX

| Lens | Verdict |
|---|---|
| Discoverability | **IMPROVED** (clear why + what to do) |
| Cognitive load | New surface — clearer than silent fail |
| Steps | +exception request flow |
| Consistency | Mirrors WebBlockPage pattern |

### Visual / honesty / verify

`NEW SCREEN` (hosted interstitial; **not** a registry SCR redesign) · deny domain `REAL LOCAL` · OS intercept `MOCK-REMOTE` · `fs003_ux_adapt_test` · **REAL-DEVICE VALIDATION: NOT RUN**

---

## 11. SCR-FAT-065 — Smart Alerts (FS-004 + FS-007 host)

### Identity

`SmartAlertsScreen` · `/scr-fat-065` · FS-004 + FS-007 · Existing · Parent

### BEFORE

Alerts inventory; watch keywords/emotions/images; **tools switches including screenshot tool** as a second monitoring store risk; detect card; settings CTA; SOS. No SC Prevent/Monitor/Protect panel; no AI safety ticket review panel.

### AFTER

- Banner `fs004SmartAlertsPolicyOwned` (SC owns screenshot policy; this screen = entry/notify)
- Tools list: **screenshot tool switch hidden when `_scDoc != null`** (`if (!(t.id == 'screenshot' && _scDoc != null))`)
- **New** `ScreenCameraParentPanel`: switches Prevent camera OS / Prevent capture / Monitor screenshots / Protect surfaces + honesty badges (MOCK-REMOTE planes) + mic out-of-scope note
- **New** FS-007 entry text `fs007SmartAlertsEntry` + `AiSafetyTicketReviewPanel` (resolve / dismiss FP / suggest WF; suggest-only; Observer view-only when `canReview` false)
- Alerts list / detect card retained

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| Screenshot tool switch | Present as tool | Hidden when SC panel bound | Removed/Moved (policy ownership) |
| ScreenCameraParentPanel | Absent | Four policy switches + badges | Added |
| AiSafetyTicketReviewPanel | Absent | Ticket list + resolve/dismiss/suggest | Added |
| Policy-owned banner | Absent | Present | Added |
| Alerts inventory | Present | Present | Unchanged |
| Detect card | Present | Present | Unchanged |

### Policy

FS-004 single P-7 store; Modes tighten-only never silent monitor; mic OOS; FS-007 suggest-only / never executor / never SOS; Partner read-only on configure.

### UX

| Lens | Verdict |
|---|---|
| Discoverability | **IMPROVED** for SC + AI (panels on host) |
| Cognitive load | **MORE COMPLEX** — densest FS host (alerts + SC + AI) |
| Steps | SC toggles local; AI review adds resolve/suggest steps |
| Hierarchy | Risk of **overload** (see Final Verdict §6) |
| Consistency | Additive panels on KEEP shell |

### Visual / honesty / verify

`LIGHT REFINEMENT` with **additive structural panels** (not shell redesign) · SC policy `REAL LOCAL` · camera/capture `MOCK-REMOTE` · AI tickets `REAL LOCAL` (heuristic) · cloud `UNSUPPORTED` · `.verify/FS-004-UX` + `FS-007-UX` passed · **REAL-DEVICE VALIDATION: NOT RUN**

**Cross-system:** FS-004 + FS-007 share host; AI suggest may target WF — human approve still required; AI does not own Modes/AC.

---

## 12. SCR-CHD-010 — What is collected

### Identity

`WhatIsCollectedScreen` · `/scr-chd-010` · FS-004 + FS-007 · Existing · Child

### BEFORE

SET-012-era collection scopes + honesty note. No SC/AI FS transparency cards.

### AFTER

Same scopes **plus** co-mounted stack:

- `AiSafetyChildTransparencyCard`
- `ScreenCameraTransparencyCard` (camera/capture planes shown MOCK-REMOTE)

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| Collection scopes | Present | Present | Unchanged |
| AI transparency card | Absent | Present | Added |
| SC transparency card | Absent | Present | Added |

### Policy

Child transparency W-C01/W-C02; on-device honesty; never claim capture/OS camera enforcement.

### UX / visual / verify

Discoverability **IMPROVED**; load **MORE COMPLEX** (two cards). Visual `LIGHT REFINEMENT`. Honesty: transparency `REAL LOCAL` copy; planes `MOCK-REMOTE`.  
**REAL-DEVICE VALIDATION: NOT RUN**

---

## 13. SCR-FAT-085 — Smart Modes

### Identity

`SmartModesScreen` · `/scr-fat-085` · FS-005 · Existing · Parent

### BEFORE

SET-018 Prefs Smart Modes: mode tiles + switches; school schedule card; host honesty banner. Prefs authority; ScheduleWindow risk as second authority.

### AFTER (when `_usingModes`)

- Ownership banner `fs005ModesOwnershipBanner`
- OS wake row + `CapabilityHonestyBadge(mockRemote)` (`fs005OsWakeHonestyHint`)
- Exams tile + hint `fs005ExamsMapsToStudyHint`
- Bind `Stage1ModesRuntime` / `ModesService` (multi-mode activate + school clock → FS-005 store)
- Prefs path retained when repository injected (tests)

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| Ownership banner | Absent | Present | Added |
| OS wake honesty badge | Absent | Present MOCK-REMOTE | Added |
| Exams→Study hint | Absent / unclear | Present under exams | Added |
| Mode switches | Present | Present (domain when Modes) | Changed binding |
| School schedule card | Present | Present | Unchanged structure |

### Policy

Modes own lifestyle schedule; ST minutes separate; ScheduleWindow ≠ Mode authority; tighten-only; Vacation widen rejected; os_wake MOCK-REMOTE.

### UX / visual / verify

Discoverability **IMPROVED** (ownership clear). Load **MORE COMPLEX** (extra banners). Visual `LIGHT REFINEMENT`. Scheduler `REAL LOCAL`; wake `MOCK-REMOTE`. `fs005_ux_adapt_test` · **REAL-DEVICE VALIDATION: NOT RUN**

**Cross-system:** Consumes FS-001 location facts when kernel shared (Phase 1.5) — **does not** mean Location owns Mode activation.

---

## 14. SCR-CHD-004 — Child Day Board

### Identity

`ChildDayBoardScreen` · `/scr-chd-004` · FS-005 · Existing · Child

### BEFORE

Remaining minutes; time warning; request/Quran/chat/SOS; status/idle. Mode stream existed (SET-019) without FS-005 `ModeDisclosureCard`.

### AFTER

When Modes evaluation injected: **`ModeDisclosureCard`** — idle text or active mode name(s); multi-mode stricter copy; reachability line; **no child cancel**.

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| ModeDisclosureCard | Absent | Present when Modes eval set | Added |
| Minutes / warning / SOS | Present | Present | Unchanged |

### Policy

MODE-OD-10: child disclosure only — no admin/cancel. Multi-mode stricter overlay honesty.

### UX / visual / verify

Discoverability **IMPROVED**; load slightly **MORE COMPLEX**. Visual `LIGHT REFINEMENT`. Modes eval `REAL LOCAL` when injected.  
**REAL-DEVICE VALIDATION: NOT RUN**

---

## 15. SCR-FAT-018 — SOS Alert board

### Identity

`SosAlertScreen` · `/scr-fat-018` · FS-006 · Existing · Parent

### BEFORE

Stage-1 / SOS-UI coral board: map, recipients, resolve/escalate, P-4. Remote delivery already MOCK-REMOTE.

### AFTER (KEEP / component polish — ledger: no full rebind)

Shared components wired: `SosStatusBanner`, `SosLocationStatus`, `SosDeliveryStatus`, `SosActionBar` (incl. break-glass → `showSosBreakGlassSheet`). Location honesty bridge may surface NOT IMPLEMENTED GPS. **No** CapabilityHonestyBadge on this host (evidence).

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| Status / location / delivery widgets | Inline / earlier SOS-UI | Shared Sos* components | Changed (componentization) |
| Break-glass sheet | Present (SOS-UI) | `showSosBreakGlassSheet` shared | Changed (shared design) |
| Shell / coral board | Present | Present | Unchanged (KEEP) |

### Policy

OD-14 never gate fire; OD-16 location attach honesty; Break-glass ≠ Find; Observer cannot ack; remote_delivery MOCK-REMOTE.

### UX / visual / verify

Discoverability **UNCHANGED** for primary SOS actions; honesty of location/delivery **IMPROVED**. Visual `LIGHT REFINEMENT` (not redesign). Lifecycle `REAL LOCAL`; delivery `MOCK-REMOTE`; GPS `NOT IMPLEMENTED`.  
**REAL-DEVICE VALIDATION: NOT RUN**

---

## 16. SCR-FAT-028 — Emergency Setup

### Identity

`EmergencySetupScreen` · `/scr-fat-028` · FS-006 · Existing · Parent

### BEFORE

Ladder parents immovable; backups; quiet/mute rules (SET-020/021).

### AFTER

Adds/emphasizes **`SosReadinessCard`** (`sosReadinessTitle` / body — Push/SMS/calling NOT_CONFIGURED honesty) + `TrustedContactCard` pattern. Ladder switches retained. No CapabilityHonestyBadge.

### Element diff

| Element | BEFORE | AFTER | Change Type |
|---|---|---|---|
| SosReadinessCard | Absent / weaker | Present | Added |
| Parent rung switches | Present (locked on) | Present | Unchanged |
| Backup contacts | Present | TrustedContactCard polish | Changed |

### Visual / honesty / verify

`LIGHT REFINEMENT` · readiness honesty `REAL LOCAL` copy · remote planes `MOCK-REMOTE` / NOT_CONFIGURED · **REAL-DEVICE VALIDATION: NOT RUN**

---

## 17. SCR-CHD-006 — Child SOS in progress

### Identity

`ChildSosInProgressScreen` · `/scr-chd-006` · FS-006 · Existing · Child

### BEFORE → AFTER

BEFORE: Coral in-progress; cancel; call.  
AFTER: Uses `SosLocationStatus` + `SosDeliveryStatus` + cancel confirmation sheet; P-4 banners. CHD-005 hold button: **NO MATERIAL FS UI CHANGE** (KEEP).

### Visual

`LIGHT REFINEMENT` · **REAL-DEVICE VALIDATION: NOT RUN**

---

# PART 2 — Explicitly unchanged / no material FS UI

| Screen / surface | Route | Note |
|---|---|---|
| FamilyShell / tabs / hub / AI+SOS FABs | shell host | **PRT-2 only** — `NO MATERIAL UI CHANGE` from FS campaign |
| SCR-CHD-005 Child SOS button | `/scr-chd-005` | KEEP Stage-1 SOS UI — `NO MATERIAL UI CHANGE` |
| Child profile location metric card | profile route | Link to FAT-014 only — `NO MATERIAL UI CHANGE` |
| SCR-FAT-032 Child Screen Time | `/scr-fat-032` | `EnforcementStatusBadge` is **pre-FS ST honesty**, not FS-001…007 ADAPT host |
| Day Board FAT-010 / Children list / etc. | various | Not FS KEEP hosts for this campaign — do not list as modified |
| Home Router Filter FAT-078 | `/scr-fat-078` | Not in FS-001…007 KEEP host list for this ADAPT wave — `NO MATERIAL UI CHANGE` claimed by FS ledger |

---

# PART 3 — SETTINGS / BUTTON INVENTORY

### New buttons

| Screen | Button | Purpose |
|---|---|---|
| FAT-014 | Silent locate (`locationMapSilentLocateCta`) | Open silent locate sheet |
| SilentLocateSheet | Request locate / Done | Request quiet fix / dismiss |
| AppDenyPage | Ask for temporary access | Exception request (≠ Minutes) |
| AppDenyPage | Family Chat / Quran / SOS | Reachability while denied |
| FAT-065 | AI Resolve / Dismiss FP / Suggest WF | Ticket review actions |
| FAT-065 | SC Prevent/Monitor/Protect switches | FS-004 policy (switch controls) |

### Removed buttons

| Screen | Button | Why |
|---|---|---|
| FAT-065 | Screenshot **tool** switch (when SC bound) | Policy ownership moved to FS-004 panel — avoid second store |

### Moved buttons

| Before location | After location | Reason |
|---|---|---|
| FAT-065 tools → Screenshot switch | FAT-065 → ScreenCameraParentPanel Monitor switch | Single P-7 store (FS-004) |

### New settings

| Screen | Setting | Effect |
|---|---|---|
| FAT-017 | Assign to children chips | Q-LOC-12 required assignment |
| FAT-065 SC panel | Prevent camera OS | Policy flag (plane MOCK-REMOTE) |
| FAT-065 SC panel | Prevent capture | Policy flag (MOCK-REMOTE) |
| FAT-065 SC panel | Monitor screenshots | P-7 monitoring policy |
| FAT-065 SC panel | Protect sensitive surfaces | Protect policy |
| FAT-085 | Modes domain toggles (when Modes) | Lifestyle activation (tighten-only) |

### Removed settings

| Screen | Setting | Reason |
|---|---|---|
| FAT-065 | Duplicate screenshot tool toggle | Absorbed by FS-004 |

### Changed defaults

| Before | After | Authority |
|---|---|---|
| Unlock approve → risk of permanent allowList | Unlock → timed temp allow | Q-WF-09 |
| Exams as separate mental mode | Exams maps to Study | FS-005 catalog |
| Child AC actor ≈ father | Child deny | Phase 1.5 P15-F16 |
| FAT-034 Prefs AC default | Domain AC bootstrap | Phase 1.5 P15-F05 |
| GPS implied live (Stage-1 decorative map) | Explicit NOT IMPLEMENTED | FS-001 honesty |

### New cards

| Screen | Card | Purpose |
|---|---|---|
| FAT-065 | ScreenCameraParentPanel | Prevent/Monitor/Protect |
| FAT-065 | AiSafetyTicketReviewPanel | Suggest-only ticket review |
| CHD-010 | AiSafetyChildTransparencyCard | On-device AI honesty |
| CHD-010 | ScreenCameraTransparencyCard | SC plane honesty |
| CHD-004 | ModeDisclosureCard | Active mode disclosure |
| FAT-028 | SosReadinessCard | Capability readiness honesty |

### Removed cards

| Screen | Card | Reason |
|---|---|---|
| CHD-024 | Live-map style presentation on `child_arrival_live` | Replaced by silent check-in honesty banner (ledger) |

### New dialogs/sheets

| Trigger | Before | After |
|---|---|---|
| FAT-014 Silent locate CTA | N/A | `SilentLocateSheet` with honest GPS outcomes |
| FAT-034 AppDeny preview | N/A / weak | Full `AppDenyPage` |
| FAT-018 Break-glass | Earlier SOS-UI sheet | Shared `showSosBreakGlassSheet` |
| CHD-006 Cancel | Confirm | `showSosCancelConfirmation` (shared polish) |

---

# PART 4 — WHAT WILL I ACTUALLY SEE ON MY PHONE?

**Assumption:** current uncommitted build installed. **REAL-DEVICE VALIDATION: NOT RUN** — this is a repository-backed expectation walkthrough.

## Launch

**BEFORE → AFTER:** App still boots welcome / shell (PRT-2). FS adds `FsSessionKernel.ensureOpen(preferSqlite: true)` under the hood — **no new splash UI**. If SQLite fails, Memory fallback is logged (DEGRADED) — **not a visible redesign**.

## Parent Dashboard

**BEFORE → AFTER:** Day board / hub chrome **unchanged by FS** (PRT-2). No new dashboard cards from FS-001…007 on FAT-010 proven in this audit.

## Location

**BEFORE → AFTER (FAT-014):** Map look similar → now shows **GPS NOT IMPLEMENTED** banner + honesty badge + **Silent locate** button → sheet saying device GPS cannot claim live locate.  
**FAT-017:** Same draw UI → must **assign children** before save.  
**FAT-015/016:** Mostly same lists → extra GPS honesty banner.  
**CHD-024:** Live-map feel → **silent check-in** honesty banner.

## Web Filtering

**BEFORE → AFTER (FAT-036):** Same level/categories/lists → top honesty that **device block is mock-remote**, taxonomy provisional, delivery Configured→Verified. Preview/unlock still there; unlock is **temporary**, not permanent allow.

## App Control

**BEFORE → AFTER (FAT-034):** Same inventory → **Protected** badges; cannot block SOS/Chat/Quran/Family OS; OS intercept honesty; preview opens **AppDenyPage**. Partner stays tickets-oriented.  
**AppDenyPage (new):** Child sees why blocked + **Ask for temporary access** (not Minutes) + Chat/Quran/SOS.

## Screen / Camera

**BEFORE → AFTER (FAT-065):** Screenshot lived as a tool switch → now a **Screen & Camera panel** with Prevent camera / capture / Monitor screenshots / Protect + MOCK-REMOTE badges; mic note out of scope. Banner says Smart Alerts is entry only.

## Modes

**BEFORE → AFTER (FAT-085):** Same mode tiles → ownership banner (Modes ≠ Screen Time), **OS wake MOCK-REMOTE** badge, exams→study hint.  
**CHD-004:** May show **Mode disclosure** card (active mode / stricter stack) — child cannot cancel.

## SOS

**BEFORE → AFTER:** Shell same coral SOS → clearer **status / location / delivery** widgets; readiness card on setup says push/SMS/calling not configured; break-glass sheet shared. **Still no real FCM/SMS.** GPS attach may say not implemented — **SOS still fires**.

## AI Safety

**BEFORE → AFTER (FAT-065):** New **ticket review** panel — redacted preview, resolve/dismiss, suggest web filter only; banner that AI is not executor.  
**CHD-010:** New transparency cards for on-device AI + screen/camera monitoring honesty.

## Settings

**BEFORE → AFTER:** No new top-level Settings SCR from FS. Policy settings appear **inside** FAT-036 / 034 / 065 / 085 hosts. DesiredMonitoringPrefs (FAT-067/068) **not** absorbed by FS-004.

---

# PART 5 — FINAL UX VERDICT

### 1. Screens that became materially easier

| Screen | Evidence | Impact |
|---|---|---|
| AppDenyPage | Explicit reason + Exception≠Minutes + SOS/Chat/Quran | Child understands block + safe exits |
| FAT-014 Silent locate | Dedicated CTA + honest outcomes | Parent finds locate without guessing |
| FAT-017 assignment | Required child chips | Prevents silent “applies to all” ambiguity |
| FAT-065 SC ownership banner + panel | Ends second screenshot store | Clearer who owns monitoring |
| CHD-004 ModeDisclosure | Names active mode(s) | Child sees lifestyle limits honestly |

### 2. Screens that became more complex

| Screen | Evidence | Impact |
|---|---|---|
| FAT-065 | Alerts + SC panel + AI ticket panel | Highest density — risk of scroll fatigue |
| FAT-036 | Extra honesty stack on already dense editors | More reading before editing |
| FAT-034 | Protected + honesty + deny preview | More rules visible on inventory |
| FAT-085 | Ownership + wake badges + exams hint | Extra banners above mode list |
| CHD-010 | Two new transparency cards | Longer transparency scroll |

### 3. Essentially unchanged (chrome)

FamilyShell; CHD-005; parent Day Board FAT-010; most non-KEEP catalog screens; FAT-015/016 beyond one GPS banner.

### 4. Light refinement only

FAT-014, 015, 016, 017, 034, 035, 036, 085, CHD-004, CHD-010, CHD-024, FAT-018, FAT-028, CHD-006 — all classified `LIGHT REFINEMENT` or minimal.

### 5. Structural UI changes

| Screen | Evidence |
|---|---|
| FAT-065 | Additive SC + AI panels; screenshot tool removed when SC bound — **structural composition change inside KEEP shell** (still not redesign) |
| AppDenyPage | **NEW SCREEN** (hosted interstitial) |
| CHD-024 | Live card → silent banner reshape |

**No `REDESIGN` of frozen shells** per closure KEEP/REFINE confirmation.

### 6. Overloaded UI?

| Screen | Evidence | Impact |
|---|---|---|
| FAT-065 | Three concerns (alerts inventory, SC policy, AI tickets) on one scroll | **Yes — overload risk**; discoverability up, cognitive load up |

### 7. Hard-to-discover policy controls?

| Screen | Evidence | Impact |
|---|---|---|
| FS-004 policy | On FAT-065, not a dedicated SCR hub | Parent must open Smart Alerts to configure Prevent/Monitor/Protect — **discoverability depends on hub labeling** |
| Domain AC | FAT-034 honesty helps; Partner tickets-only is hint-based | Mother Full vs Partner difference still easy to miss if hint scrolled past |

### 8. Duplicated controls?

| Screen | Evidence | Impact |
|---|---|---|
| FAT-065 screenshot | Tool switch **removed** when SC panel present | Duplicate **removed by design** |
| Modes vs ScheduleWindow | Ownership banner states ScheduleWindow is not Mode authority | Duplicate authority **warned**, Prefs path may still exist (DEBT) |

### 9. Dead-end routes or buttons?

| Screen | Evidence | Impact |
|---|---|---|
| Silent locate | CTA works but result often GPS NOT IMPLEMENTED | Not a dead button — **honest non-capability** |
| SC Prevent camera/capture switches | Toggle policy locally; plane MOCK-REMOTE | Not dead — **non-enforcing** settings (honesty badges) |
| AI Suggest WF | Creates suggestion, not auto-apply | Not dead — suggest-only by law |

### 10. UI claiming more than implementation?

| Screen | Evidence | Impact |
|---|---|---|
| FAT-014 map | Decorative map + explicit NOT IMPLEMENTED banner | **Mitigated** if banner visible; risk if user ignores banner |
| FAT-036 | Native block honesty strings + badges | **Mitigated** |
| FAT-065 SC switches | Badges MOCK-REMOTE on camera/capture | **Mitigated** — still possible user reads switches as “enforced” |
| FAT-028 readiness | Body says Push/SMS/calling NOT_CONFIGURED | **Honest** |
| AI panel | Suggest-only + no-executor note | **Honest**; classifier is heuristic stub — do not read as production ML |

---

## Verification rollup

| Area | Evidence |
|---|---|
| Focused UX tests | `fs001_ux_adapt_test`, `fs003_ux_adapt_test`, `fs004_ux_adapt_test`, `fs005_ux_adapt_test`, `fs007_ux_adapt_test` |
| Domain tests | location / web_filter / app_control / screen_camera / modes / sos_final / offline_ai_safety / phase15 |
| Last full green | `.verify/PHASE-1.5-HARDEN.json` passed (~1360) |
| Stale / conflict | `.verify/FS-001-UX.json` failed; `.verify/FS-I-RECON.json` analyze failed vs CONVERSION_LOG |
| Device | **REAL-DEVICE VALIDATION: NOT RUN** |

---

## Final status block

```
SCREEN UX AUDIT: COMPLETE
PRODUCTION CODE CHANGED BY THIS AUDIT: NO
REAL-DEVICE TESTING: NOT RUN
ARTIFACT: docs/experience_discovery/FAMILY_OS_SCREEN_BEFORE_AFTER_UX_AUDIT.md
```

*Campaign visual law retained: KEEP + REFINE — no frozen-prototype redesign; no green-v1 resurrection.*
