# IMPLEMENTATION BEFORE/AFTER AUDIT

**Campaign:** FS-001 → FS-007 · FS-I-RECON · Phase 1.5 Hardening  
**Audit date:** 2026-09-24  
**Auditor mode:** Evidence/reporting only — production code unchanged during this audit  
**Workspace:** `D:\special projects\family`

### Evidence sources used

| Source | Path / note |
|---|---|
| FS change ledger | `docs/experience_discovery/FS_001_007_CHANGE_LEDGER.md` |
| FS closure | `docs/experience_discovery/FS_001_007_CLOSURE_REPORT.md` |
| FS master plan | `docs/experience_discovery/FS_001_007_IMPLEMENTATION_MASTER_PLAN.md` |
| Phase 1.5 ledger | `docs/experience_discovery/PHASE_1_5_CHANGE_LEDGER.md` |
| Phase 1.5 closure | `docs/experience_discovery/PHASE_1_5_CLOSURE_REPORT.md` |
| Phase 1.5 plan | `docs/experience_discovery/PHASE_1_5_MASTER_PLAN.md` |
| Ship log | `CONVERSION_LOG.md` (lines FS-A-FOUND…PHASE-1.5-HARDEN) |
| Backlog | `harness/BACKLOG.md` Lane FS + Phase 1.5 |
| Loop state | `harness/LOOP_STATE.md` — STOPPED; Phase 1.5 COMPLETE |
| Verify artifacts | `.verify/*.json` (gitignored; on-disk) + `_tier_state.json` |
| Working tree | Uncommitted `??` / `M` paths under `app/lib/core/*` |
| Current source | `fs_foundation`, `location`, `web_filter`, `app_control`, `screen_camera`, `modes`, `sos_final`, `offline_ai_safety`, design components, Stage-1 hosts |

### Git baseline (critical)

| Fact | Evidence |
|---|---|
| HEAD at audit | `4689abc` (docs: experience discovery + SOS truth pack) — **no FS / PHASE-1.5 commits** |
| Commits matching `FS-A-FOUND`…`PHASE-1.5` | **NONE** |
| Campaign implementation location | **Uncommitted working tree** (new packages mostly `??`) |
| Inference rule | BEFORE state for new packages = **did not exist** (proven by `??` + master-plan baseline). BEFORE for modified Stage-1 hosts = prior ScreenBuild/SET/UI behavior from CONVERSION_LOG + master plan §0. Do **not** invent BEFORE from imagination. |

### Status vocabulary (this audit)

- `REAL` = local domain/policy/persistence that actually runs on-device without claiming native OS success  
- `MOCK-REMOTE` = simulated remote/native plane  
- `DEGRADED` = partial / fallback honesty  
- `UNSUPPORTED` = explicitly out of product support  
- `LEGACY-MOCK-DEBT` = Stage-1 Prefs/mock leftovers still present  
- `NOT IMPLEMENTED` = capability registry honesty for missing native planes  

---

## A. Executive Summary

| Metric | Evidence-backed value |
|---|---|
| **Git commits for this campaign** | **0** |
| **New core FS lib packages** | **85** files: `fs_foundation` 9 · `location` 12 · `web_filter` 11 · `app_control` 16 · `screen_camera` 8 · `modes` 10 · `sos_final` 12 · `offline_ai_safety` 7 (all `??`) |
| **Shared design components added** | ≥13 new under `app/lib/core/design/components/` + `components.dart` **M** |
| **i18n touched** | 5 modified (`app_ar.arb`, `app_en.arb`, generated localizations) |
| **Systems touched** | FS-001…FS-007 + shared foundation + KEEP/REFINE Stage-1 hosts |
| **Cards shipped (BACKLOG/ledger)** | FS-A-FOUND → FS-007-UX · FS-I-RECON · PHASE-1.5-HARDEN |
| **Phase 1.5 FIX closed** | **11** (P15-F01, F02, F03, F04, F05, F09, F10, F11, F16, F27, F33) |
| **Schema** | Family Local Database **v1 → v10** |
| **Last green full verify** | `PHASE-1.5-HARDEN` — `.verify/PHASE-1.5-HARDEN.json` `status: passed`, analyze OK, ~1360 tests |
| **Device validation** | **REAL-DEVICE VALIDATION: NOT RUN** |

### Evidence conflicts (explicit)

| Claim | Conflicting on-disk evidence |
|---|---|
| `CONVERSION_LOG` / BACKLOG: FS-001-UX `passed` | `.verify/FS-001-UX.json` currently **`failed`** (1276 passed / 4 failed). Phase 1.5 ledger **P15-F32 DEBT**: “stale failed artifact.” |
| `CONVERSION_LOG`: FS-I-RECON `passed` | `.verify/FS-I-RECON.json` currently **`failed`** (analyze: 1 `unnecessary_import` in `child_apps_screen.dart`). Tail `.verify/_fs_i_recon_verify_tail.txt` records **passed**. Later `PHASE-1.5-HARDEN` full suite **passed**. |
| “Shipped in git” | **False** — implementation uncommitted. |

### Post-campaign capability honesty (from closure)

| Class | Examples |
|---|---|
| **REAL / IMPLEMENTED** | SQLite/Memory kernel, delivery vocabulary, location domain + geofence + SOS/Modes seams, WF lists/delivery/temp-allow, AC dispositions/protected/exception, SC policy, Modes scheduler, SOS lifecycle/readiness/break-glass/exemptions/honesty bridge, AI signal/tickets/suggest-only + parent/child UX |
| **MOCK-REMOTE** | `fs002.native_block`, `fs003.os_intercept`, `fs004.capture_pipeline`, `fs004.camera_os_plane`, `fs005.os_wake`, `fs006.remote_delivery`, `fs_a.mock_remote` |
| **NOT IMPLEMENTED** | `fs001.native_gps` |
| **UNSUPPORTED** | `fs007.cloud_classify` |
| **DEGRADED** | `fs002.taxonomy`; SQLite→Memory fallback |
| **FORBIDDEN** | `fs007.ai_as_executor` |

---

## B. FS-001 Changes

**Cards:** FS-001-DOM · FS-001-UX · FS-001-XSYS  
**Authority:** `docs/experience_discovery/location_final/` + `location_l3/` · Q-LOC-12  
**Ledger checkpoints:** FS-001-DOM / UX / XSYS in `FS_001_007_CHANGE_LEDGER.md`

### B.1 Material change table

| # | File / path | System | TYPE | Real vs Mock |
|---|---|---|---|---|
| 1 | `app/lib/core/location/geo_point.dart` | FS-001 domain | ADD | REAL |
| 2 | `app/lib/core/location/zone_geometry.dart` | FS-001 domain | ADD | REAL |
| 3 | `app/lib/core/location/safe_zone_definition.dart` | FS-001 domain | ADD | REAL |
| 4 | `app/lib/core/location/location_fix.dart` | FS-001 domain | ADD | REAL (acquisition honesty) |
| 5 | `app/lib/core/location/geofence_event.dart` | FS-001 domain | ADD | REAL |
| 6 | `app/lib/core/location/geofence_evaluator.dart` | FS-001 domain | ADD | REAL |
| 7 | `app/lib/core/location/location_store.dart` | FS-001 persistence | ADD | REAL local |
| 8 | `app/lib/core/location/location_repository.dart` | FS-001 seam | ADD | REAL interface |
| 9 | `app/lib/core/location/location.dart` | FS-001 barrel | ADD | — |
| 10 | `app/lib/core/location/sos_location_handoff.dart` | FS-001→SOS | ADD | REAL contract |
| 11 | `app/lib/core/location/sos_location_handoff_service.dart` | FS-001→SOS | ADD | REAL |
| 12 | `app/lib/core/location/modes_location_fact_feed.dart` | FS-001→Modes | ADD | REAL facts only |
| 13 | Schema v2–v3 tables in `app/lib/core/fs_foundation/local_database.dart` | Persistence | ADD | REAL local |
| 14 | `app/lib/features/n02_day/location_ux_bridge.dart` (`Stage1LocationRuntime`, `DomainSafeZonesRepository`, `SilentLocateService`) | Composition / UX bridge | ADD | REAL domain bind; GPS NOT IMPLEMENTED |
| 15 | `app/lib/core/design/components/silent_locate_sheet.dart` | Shared UX | ADD | UI; GPS honesty |
| 16 | `app/lib/core/design/components/capability_honesty_badge.dart` (also FS-A) | Shared UX | ADD | Honesty display |
| 17 | FAT-014…017 / CHD-024 hosts (e.g. `location_map_screen.dart`, `create_safe_zone_screen.dart`, …) | Location UX | MODIFY / UI REFINEMENT | KEEP/REFINE |
| 18 | Tests: `app/test/core/location/*`, `app/test/features/n02_day/fs001_ux_adapt_test.dart` | Verification | ADD | — |

### B.2 BEFORE

- Stage-1 location screens existed (SCR-FAT-014…017, CHD-024) with Prefs/mock repositories and Life360-style honesty copy (CONVERSION_LOG ScreenBuild era).
- **No** `app/lib/core/location/` package (proven: all files `??`).
- Master plan baseline: in-memory Prefs stores; **no** sqflite location trail/zones.
- **No** circle+polygon domain evaluator producing ENTER/EXIT/NO_SHOW on a Family Local DB.
- Native GPS: bare FlutterActivity — **not** a device GPS pipeline.
- SOS/Modes did not consume structured FS-001 handoff/fact tables.

### B.3 AFTER

- Domain: `SafeZoneDefinition` (circle+polygon), assignment law **Q-LOC-12=B**, `LocationFix` acquisition honesty, `GeofenceEvaluator`, local store.
- Tables: `loc_zone`, `loc_zone_geometry`, `loc_zone_assignment`, `loc_trail_sample`, `loc_geofence_event`, `loc_zone_presence`; v3 `loc_sos_evidence`, `loc_mode_fact`.
- UX: GPS **NOT IMPLEMENTED** banners + `CapabilityHonestyBadge`; Silent locate sheet/CTA; multi-select assignment; CHD-024 silent check-in banner.
- XSYS: SOS handoff attaches fixes with honesty vocabulary (**never blocks SOS fire**); Modes fact feed publishes ENTER/EXIT/NO_SHOW/presence only (**no Mode activation**).
- Capabilities: `fs001.location_domain`, `geofence_eval`, `sos_location_handoff`, `modes_fact_feed` → IMPLEMENTED; `fs001.native_gps` → **NOT IMPLEMENTED**.

### B.4 WHY

Owner Master Implementation Commission; frozen Location Final + L3; cards FS-001-DOM/UX/XSYS. Ownership: Location owns facts — SOS/Modes consume only.

### B.5 Cross-system impact

| Consumer | Effect | Isolated? |
|---|---|---|
| FS-005 Modes | Consumes `ModesLocationFactFeed` / `loc_mode_fact` | Shared after Phase 1.5 kernel |
| FS-006 SOS | Consumes handoff / `loc_sos_evidence` | Shared |
| FAT-014…017, CHD-024 | Domain bind + honesty UI | Host KEEP/REFINE |

Regression: focused location + UX adapt tests; later full suites on XSYS / HARDEN.

### B.6 Persistence

| | |
|---|---|
| Old storage | Stage-1 Prefs/mock safe-zones (feature repos) — **no** FS location tables |
| New storage | Family Local DB schema v2–v3 location tables |
| Migration | `onUpgrade` steps `<2`, `<3` in `local_database.dart` |
| Restart | Restart-capable only when SQLite session opens (Phase 1.5 F04) |
| Compatibility | Additive tables; Stage-1 Prefs paths may still exist as **LEGACY-MOCK-DEBT** where not bridged |

### B.7 Security / RBAC

- New FS-001-specific actor matrix beyond existing screen RoleGuard: **UNKNOWN — EVIDENCE NOT FOUND** in closure beyond assignment UI / mother edit patterns on Stage-1 hosts.
- SOS fire never blocked by missing GPS (XSYS contract).

### B.8 UX / visual

- **KEEP/REFINE** — badges, Silent locate CTA/sheet, assignment multi-select, check-in silent banner.
- **Not** a map SDK redesign; no new SCR id for locate.

### B.9 Verification evidence

| Artifact | Result |
|---|---|
| `.verify/FS-001-DOM.json` | passed (scoped) |
| `.verify/FS-001-UX.json` | **failed** currently (P15-F32 stale DEBT); CONVERSION_LOG claims passed |
| `.verify/FS-001-XSYS.json` | passed (full) |
| Focused tests | `geofence_evaluator_test`, `location_store_test`, `location_xsys_test`, `fs001_ux_adapt_test` |
| Device | **REAL-DEVICE VALIDATION: NOT RUN** |

---

## C. FS-002 Changes

**Cards:** FS-002-OWN · FS-002-ENF  
**Authority:** `web_filtering_l2/` + `web_filtering_l3/` · Q-WF-01 / WF-OD-08 / Q-WF-09 / Q-WF-15

### C.1 Material change table

| # | File / path | System | TYPE | Real vs Mock |
|---|---|---|---|---|
| 1 | `app/lib/core/web_filter/*` (11 files) | FS-002 | ADD | Lists/delivery/temp-allow **REAL**; native_block **MOCK-REMOTE**; taxonomy **DEGRADED** |
| 2 | Schema v4–v5 `wf_document`, `wf_temp_allow` | Persistence | ADD | REAL local |
| 3 | `app/lib/features/n04_web_filter/web_filter_runtime.dart` | Composition | ADD | Shared kernel |
| 4 | FAT-036 / unlock / interstitial hosts | UX | MODIFY / UI REFINEMENT | KEEP/REFINE + honesty |
| 5 | Tests: `web_filter_store_test`, `web_filter_enf_test`, unlock loop | Verification | ADD / MODIFY | — |

### C.2 BEFORE

- Stage-1 web filter policy / Prefs-style lists; UI-009 decision snapshot / preview.
- No authoritative family baseline + child override document on SQLite.
- No Configured→Verified delivery plane that refuses to claim native enforcement.
- Unlock path risk vs Q-WF-09 (approve must not silently write permanent allowList).

### C.3 AFTER

- `WebFilterDocument` (baseline + child override Q-WF-01).
- `WebFilterEngine` precedence WF-OD-08: blocklist → temp → allow → dict → category; source-of-deny tokens.
- Delivery: Configured→Verified (**never claims native enforced**).
- Timed temp allow store; unlock → temp allow; interstitial source-of-deny + feedback (Q-WF-15).
- Capabilities: `fs002.web_lists`, `delivery`, `timed_unlock` IMPLEMENTED; `taxonomy` DEGRADED; `native_block` MOCK-REMOTE.

### C.4 WHY

Frozen L2/L3 web filtering; cards FS-002-OWN/ENF; ownership: URL plane only (not AC packages; not Modes scheduler).

### C.5 Cross-system / persistence / security / UX

- Consumers: FAT-036, unlock flows, Modes tighten context (read-only), child interstitial.
- Persistence: Prefs/Stage-1 → `wf_document` + `wf_temp_allow`; migration v4–v5.
- RBAC: domain unlock/RBAC asserted PASS in Phase 1.5 (P15-F15); mother deep-link matrix still DEBT (F17).
- UX: list editors + honesty badges — **not** redesign.
- Verify: FS-002-OWN / ENF **passed**. Device: **REAL-DEVICE VALIDATION: NOT RUN** (no VPN/DNS).

---

## D. FS-003 Changes

**Cards:** FS-003-OWN · FS-003-UX  
**Authority:** `application_control_l2/` + `application_control_l3/` · APP-OD-09

### D.1 Material change table

| # | File / path | System | TYPE | Real vs Mock |
|---|---|---|---|---|
| 1 | `app/lib/core/app_control/*` (16 files) | FS-003 | ADD | Dispositions/protected/exception **REAL**; os_intercept **MOCK-REMOTE** |
| 2 | Schema v6 `ac_document`, `ac_exception`, `ac_lock_now`, `ac_install` | Persistence | ADD | REAL local |
| 3 | `app/lib/features/n03_screen_time/app_deny_page.dart` | Child UX | ADD | REAL domain deny UX |
| 4 | FAT-034/035 hosts (`child_apps_screen.dart`, `new_app_approval_screen.dart`, …) | UX | MODIFY / UI REFINEMENT | KEEP/REFINE |
| 5 | Phase 1.5: child actor + FAT-034 Domain bootstrap | RBAC / wiring | FIX | REAL deny |
| 6 | Tests: `app_control_own_test`, `fs003_ux_adapt_test` | Verification | ADD | — |

### D.2 BEFORE

- Prefs / Stage-1 app-access rules mixed with Screen Time axes.
- No AC-owned Allow/Block/Exempt document with protected SOS/Family OS/Chat/Quran packages.
- No timed Exception ≠ Permanent Block; no Lock Now / install deny-until-approved AC store.
- Child AppControl actor mapped toward father privilege (**P15-F16 finding**).

### D.3 AFTER

- Package dispositions; family/child docs; protected packages (APP-OD-09); timed Exception; Lock Now overlay; install tickets.
- `DomainAppAccessRulesRepository`: AC owns blocked; ST keeps limit/unlimited/countable.
- UX: protected badges; Partner tickets-only; child `AppDenyPage` (source-of-deny, Exception ≠ Minutes, SOS/Chat/Quran reachable).
- Phase 1.5: FAT-034 boots Domain AC; `AppControlActor.child()` deny.
- Capabilities: dispositions/protected/exception IMPLEMENTED; `os_intercept` MOCK-REMOTE.

### D.4 WHY

L2/L3 App Control ownership; cards OWN/UX; Phase 1.5 F05/F16.

### D.5 Security / RBAC

| | BEFORE | AFTER |
|---|---|---|
| Child on App Control | Over-privileged (mapped as father) | `AppControlActor.child()` deny |
| Mother deep-link RoleGuard | Domain throws | Router mother path matrix still **DEBT P15-F17** |

### D.6 Persistence / UX / verify

- Old: Prefs AC rules. New: schema v6 AC tables. Migration `<6`.
- UX: KEEP/REFINE + new deny page (hosted; no new SCR id).
- Verify: FS-003-OWN full / UX scoped **passed**. Device: **REAL-DEVICE VALIDATION: NOT RUN**.

---

## E. FS-004 Changes

**Cards:** FS-004-OWN · FS-004-UX  
**Authority:** `screen_camera_l2/` + `screen_camera_l3/` · P-7

### E.1 Material change table

| # | File / path | System | TYPE | Real vs Mock |
|---|---|---|---|---|
| 1 | `app/lib/core/screen_camera/*` (8 files) | FS-004 | ADD | Policy **REAL**; capture/camera_os **MOCK-REMOTE** |
| 2 | Schema v7 `sc_document` | Persistence | ADD | REAL local |
| 3 | `screen_camera_parent_panel.dart` | Shared UX | ADD | UI REFINEMENT on FAT-065 |
| 4 | `screen_camera_transparency_card.dart` | Shared UX | ADD | CHD-010 |
| 5 | FAT-065 / CHD-010 hosts | UX | MODIFY | KEEP hosts; panels co-mounted |
| 6 | Tests: `screen_camera_own_test`, `fs004_ux_adapt_test` | Verification | ADD | — |

### E.2 BEFORE

- Smart Alerts / DesiredMonitoringPrefs paths; screenshot tooling risk of a **second** policy store on FAT-065.
- No Prevent/Monitor/Protect SQLite document with Modes tighten-only semantics.
- Mic / SOS audio: out of scope (unchanged).

### E.3 AFTER

- `ScreenCameraDocument`: Prevent camera OS + capture; Monitor screenshots P-7 + package picker; Protect sensitive surfaces; baseline + child override.
- Modes may tighten only (never silent monitor). Evaluate never claims enforcement on MOCK-REMOTE planes.
- FAT-065: `ScreenCameraParentPanel` binds single SC store; Partner read-only; child preview when monitoring on.
- CHD-010: transparency card with MOCK-REMOTE plane badges.
- DesiredMonitoringPrefs (web/app/notif/location) **not** absorbed.
- Capabilities: `fs004.screen_camera_policy` IMPLEMENTED; capture + camera_os MOCK-REMOTE.

### E.4 WHY / verify

L2/L3 Screen & Camera; cards OWN/UX. Verify OWN scoped / UX full **passed**. Device: **REAL-DEVICE VALIDATION: NOT RUN**.

---

## F. FS-005 Changes

**Cards:** FS-005-OWN · FS-005-UX  
**Authority:** `modes_l2/` + `modes_l3/`

### F.1 Material change table

| # | File / path | System | TYPE | Real vs Mock |
|---|---|---|---|---|
| 1 | `app/lib/core/modes/*` (10 files) | FS-005 | ADD | Scheduler **REAL**; os_wake **MOCK-REMOTE** |
| 2 | Schema v8 `mode_document`, `mode_activation`, `mode_exception` | Persistence | ADD | REAL local |
| 3 | `mode_disclosure_card.dart` | Shared UX | ADD | CHD-004 |
| 4 | FAT-085 (`smart_modes_screen.dart`), CHD-004 (`child_day_board_screen.dart`) | UX | MODIFY / UI REFINEMENT | KEEP/REFINE |
| 5 | Tests: `modes_own_test`, `fs005_ux_adapt_test` | Verification | ADD | — |

### F.2 BEFORE

- SET-018 Prefs Smart Modes; `ScheduleWindow` as ST legacy authority risk.
- No multi-mode tighten-only overlay stack on SQLite; exams naming not remapped to study in FS-005 store.
- Location facts **not** wired across runtimes until Phase 1.5 F02.

### F.3 AFTER

- Catalog: Sleep/School/Study/Ramadan/Vacation/Family Time/Custom; exams→study; famtime→familyTime.
- Family/all or selected children (no silent expand); clock·manual·location·seasonal channels.
- Multi-mode stricter overlay (**tighten-only**; Vacation widen rejected); ModeException ≠ AC/ST.
- Consumes FS-001 facts only (activation authority stays Modes).
- UX: ownership banner; os_wake MOCK-REMOTE badge; child `ModeDisclosureCard` (no child cancel); Prefs path retained when repository injected (SET-018 tests).
- Capabilities: `fs005.modes_scheduler` IMPLEMENTED; `os_wake` MOCK-REMOTE. ScheduleWindow remains ST legacy — not Mode authority.

### F.4 WHY / verify

L2/L3 Modes; cards OWN/UX; Phase 1.5 F02 wiring. Verify OWN/UX scoped **passed**. Device: **REAL-DEVICE VALIDATION: NOT RUN**.

---

## G. FS-006 Changes

**Cards:** FS-006-LIFE · FS-006-XSYS  
**Authority:** `sos_final/` (+ sos_l2/l3) · Q-SOS-RD-02B · OD-14 · OD-16 · OD-21  
**Note:** Prior SOS-UI Stage-1 slice existed before this campaign (CONVERSION_LOG / master plan baseline). This campaign adds `core/sos_final` ownership depth.

### G.1 Material change table

| # | File / path | System | TYPE | Real vs Mock |
|---|---|---|---|---|
| 1 | `app/lib/core/sos_final/*` (12 files) | FS-006 | ADD | Lifecycle/readiness/BG/exemptions/honesty **REAL**; remote_delivery **MOCK-REMOTE** |
| 2 | Schema v9 SOS tables | Persistence | ADD | REAL local |
| 3 | Design SOS components (`sos_*_sheet/banner/card/status`, …) | Shared UX | ADD / UI REFINEMENT | KEEP shells |
| 4 | Hosts FAT-018/028 / child SOS | UX | MODIFY (KEEP/REFINE) | Lifecycle deepen; no shell redesign |
| 5 | Tests: `sos_final_life_test`, `sos_final_xsys_test` | Verification | ADD | — |

### G.2 BEFORE

- Prefs/InMemory SOS ladder/alert UI; remote delivery already MOCK-REMOTE.
- Incomplete vs Final: durable incident store, indefinite lifecycle audit, 90d ops samples, OD-21 readiness, Break-glass allowlist RBAC, OD-14 permanent exemptions audit, location honesty bridge post-fire.

### G.3 AFTER

- Durable `SosIncident` + indefinite lifecycle audit + 90d ops samples; Break-glass allowlist; OD-21 readiness; Observer cannot ack.
- `SosPermanentExemptions` audits Modes/ST/AC/locks/notifications/SC audio + never-gate fire.
- `SosLocationHonestyBridge` + `SosCrossSystemCoordinator` consume FS-001 handoff after fire (OD-16); Break-glass ≠ Find.
- `native_gps` stays NOT IMPLEMENTED; `remote_delivery` MOCK-REMOTE.
- Capabilities: lifecycle, evidence_retention, readiness, break_glass, permanent_exemptions, location_honesty_bridge IMPLEMENTED.

### G.4 WHY / security / verify

SOS Final freeze; cards LIFE/XSYS. SOS never subscription-gated (Phase 1.5 P15-F18 PASS). Verify LIFE scoped / XSYS full **passed**. Device: **REAL-DEVICE VALIDATION: NOT RUN** (no FCM/SMS/telephony).

---

## H. FS-007 Changes

**Cards:** FS-007-SIG · FS-007-UX  
**Authority:** `offline_ai_safety_l2/` + `offline_ai_safety_l3/` · AI-OD-07/08/11 · Rule 26 suggest-only

### H.1 Material change table

| # | File / path | System | TYPE | Real vs Mock |
|---|---|---|---|---|
| 1 | `app/lib/core/offline_ai_safety/*` (7 files) | FS-007 | ADD | Signal/tickets/suggest-only **REAL** (heuristic stub honesty); cloud **UNSUPPORTED**; executor **FORBIDDEN** |
| 2 | Schema v10 `ai_model_manifest`, `ai_safety_signal`, `ai_safety_ticket`, `ai_safety_suggestion`, `ai_safety_audit` | Persistence | ADD | REAL local |
| 3 | `ai_safety_ticket_review_panel.dart` | Shared UX | ADD | FAT-065 |
| 4 | `ai_safety_child_transparency_card.dart` | Shared UX | ADD | CHD-010 |
| 5 | FAT-065 / CHD-010 hosts | UX | MODIFY | KEEP; co-mounted panels |
| 6 | Tests: `fs007_sig_test`, `fs007_ux_adapt_test` | Verification | ADD | — |

### H.2 BEFORE

- Advisor suggest-only patterns elsewhere (SET-014/022); no typed on-device SafetySignal plane, signed model gate, B1 tickets, preview purge, never-SOS classifier contract on SQLite.

### H.3 AFTER

- Typed `SafetySignal`; signed model gate; B1 ticket gate; suggest-only (no auto WF/AC/Modes); preview purge on close; never fires SOS.
- Parent review: redacted preview; non-numeric certainty/severity; resolve/dismiss; Observer view-only.
- Child: on-device transparency; co-mounted with SC transparency in one ListView child.
- Classifier: heuristic stub — **not** real NN weights (ledger honesty).
- Capabilities: local_classifier / safety_tickets / suggest_only / parent_ticket_review / child_transparency IMPLEMENTED; cloud_classify UNSUPPORTED; ai_as_executor FORBIDDEN.

### H.4 WHY / verify

L2/L3 Offline AI Safety; cards SIG/UX. Verify SIG scoped / UX full **passed** (~1354). Device: **REAL-DEVICE VALIDATION: NOT RUN**.

---

## I. Shared Family-OS Infrastructure Changes

### I.1 FS-A-FOUND + Phase 1.5 kernel

| # | File / path | Subsystem | TYPE | BEFORE | AFTER | Real vs Mock |
|---|---|---|---|---|---|---|
| 1 | `app/lib/core/fs_foundation/capability_status.dart` | Honesty vocabulary | ADD | Absent | Status enum vocabulary | REAL labels |
| 2 | `app/lib/core/fs_foundation/capability_registry.dart` | Honesty registry | ADD | Absent | Seeds + `applyAllCampaignCapabilities` | REAL local |
| 3 | `app/lib/core/fs_foundation/local_database.dart` | Schema v1–v10 | ADD | No FS schema | Full statement bundles + upgrades | REAL local |
| 4 | `app/lib/core/fs_foundation/memory_local_database.dart` | In-memory DB | ADD | Absent | Test / fallback store | REAL / DEGRADED fallback |
| 5 | `app/lib/core/fs_foundation/sqlite_local_database.dart` | On-device SQLite | ADD | Unused by Stage-1 until P15 | Prefer outside tests | REAL when open |
| 6 | `app/lib/core/fs_foundation/policy_delivery.dart` | Delivery phases | ADD | Absent | Configured→Verified machine | REAL vocabulary |
| 7 | `app/lib/core/fs_foundation/mock_remote_adapter.dart` | Outbox port | ADD | Absent | Port + outbox tables | **MOCK-REMOTE** (enqueue DEBT F20) |
| 8 | `app/lib/core/fs_foundation/fs_session_kernel.dart` | Composition root | ADD (P15) | 7 Memory silos | One shared DB | REAL / DEGRADED fallback |
| 9 | `app/lib/core/fs_foundation/fs_foundation.dart` | Barrel | ADD | — | Exports | — |
| 10 | `app/lib/main.dart` | Boot | MODIFY | No kernel boot | `FsSessionKernel.ensureOpen(preferSqlite: true)` | REAL path |
| 11 | Deps: sqflite, path, path_provider (+ ffi dev) | Platform | ADD | Master plan: no sqflite in pubspec baseline | Present post FS-A | — |

### I.2 Navigation / shell

| Item | Evidence |
|---|---|
| `FamilyShell` / tabs / hub / FABs | Exist under `app/lib/app/family_shell.dart` — primarily **PRT-2** prior work, **not** claimed as FS redesign |
| FS hosts | Routed; RoleGuard + tombstones PASS (P15-F23) |
| New SCR ids for deny / SC hub | **None** (deny hosted like WebBlockPage) |

### I.3 Policy Kernel

- Campaign preferred new modules under `app/lib/core/<fs>/`.
- Exact line-level BEFORE/AFTER of every pre-existing `core/policy/*` file vs HEAD: **UNKNOWN — EVIDENCE NOT FOUND** as discrete FS commits (uncommitted tree; no per-card git show). Ledger: additive seams only; Owner commission authorizes additive FS touches.

### I.4 Offline / outbox / audit / notifications

| Item | AFTER honesty |
|---|---|
| `sync_outbox` + MockRemoteAdapter | Port exists; **not** wired to live Stage-1 event paths (**DEBT P15-F20**) → MOCK-REMOTE |
| SOS lifecycle audit / AI safety audit | Local append tables REAL |
| Remote push / FCM | MOCK-REMOTE / NOT claimed |

### I.5 Design system / localization / native

| Area | Change |
|---|---|
| Design | New shared components (honesty, silent locate, SC/AI panels, SOS sheets, enforcement badge, …). **tokens.dart not modified** (rule 21). KEEP/REFINE — not green-v1 redesign. |
| l10n | ARB EN/AR + generated localizations **M** for new honesty/locate/AI/SOS strings |
| Native Android/iOS enforcement | Unchanged for GPS/VPN/DO/Accessibility — still NOT IMPLEMENTED / MOCK-REMOTE |

### I.6 Shared components inventory (FS-era additions)

| Path | Role |
|---|---|
| `capability_honesty_badge.dart` | Capability status display |
| `enforcement_status_badge.dart` | Enforcement honesty |
| `silent_locate_sheet.dart` | Silent locate UX |
| `screen_camera_parent_panel.dart` | FAT-065 SC configure |
| `screen_camera_transparency_card.dart` | CHD-010 SC honesty |
| `mode_disclosure_card.dart` | CHD-004 Modes disclosure |
| `ai_safety_ticket_review_panel.dart` | FAT-065 AI tickets |
| `ai_safety_child_transparency_card.dart` | CHD-010 AI honesty |
| `sos_action_bar.dart`, `sos_break_glass_sheet.dart`, `sos_cancel_confirmation.dart`, `sos_delivery_status.dart`, `sos_location_status.dart`, `sos_readiness_card.dart`, `sos_status_banner.dart` | SOS UX depth |
| `remaining_minutes_card.dart`, `time_warning_banner.dart`, `trusted_contact_card.dart` | Related shared UX (present in tree; classify usage per host — do not over-claim FS-only if also ST/SOS Stage-1) |
| `components.dart` | Barrel **MODIFY** |

---

## J. Phase 1.5 Fixes

**Card:** PHASE-1.5-HARDEN  
**Authority:** `PHASE_1_5_MASTER_PLAN.md` findings register  
**FIX count closed:** 11

| ID | Finding | BEFORE | AFTER | Why | Verification |
|---|---|---|---|---|---|
| **P15-F01** | Seven separate `MemoryLocalDatabase` instances | Loc/WF/AC/SC/Modes/SOS/AI siloed — cross-system tables invisible | `FsSessionKernel` single shared DB | Composition integrity | `phase15_hardening_test` shared DB identity PASS |
| **P15-F02** | Location → Modes fact feed never wired | Facts not published across runtimes | `Stage1LocationRuntime.ensureOpen` opens Modes; evaluate always passes `ModesLocationFactFeed` | L2 Modes consume FS-001 facts | phase15 evaluate→facts PASS |
| **P15-F03** | SOS handoff used SOS-runtime DB only | Evidence not on Location DB | Same shared kernel (via F01) | OD-16 / XSYS | Shared kernel PASS |
| **P15-F04** | `SqliteLocalDatabase` unused by Stage-1 | No restart persistence | Kernel prefers SQLite outside `FLUTTER_TEST`; `main` `preferSqlite: true`; Memory fallback = DEGRADED honesty | Offline-first | Code path + migration test PASS; **device APK not run** |
| **P15-F05** | FAT-034 defaults to Prefs AC while AC SQLite exists | Domain AC unused on host | Bootstrap `Stage1AppControlRuntime.accessRules` + service when seams not injected | AC ownership | `fs003_ux_adapt_test` PASS |
| **P15-F09** | `defaultSeeds` stale vs shipped IMPLEMENTED | Seeds lagged until manual apply | Aligned seeds + `applyAllCampaignCapabilities()` at kernel open | Honesty vocabulary | Kernel open |
| **P15-F10** | `applyFs001XsysCapabilities` never called from production | XSYS caps not applied | Called from Location / `applyAll` | Honesty | Kernel open |
| **P15-F11** | Per-runtime CapabilityRegistry before shared DB | Fragmented capability table | Unified via F01 | Honesty | Via F01 |
| **P15-F16** | `AppControlUxBridge.actorFor` maps child → father | Child over-privileged | `AppControlActor.child()` deny | RBAC | Unit bridge test PASS |
| **P15-F27** | No SQLite upgrade-chain integration test | v1→v10 unproven | ffi upgrade + schema coverage in `phase15_hardening_test` | DB safety | PASS |
| **P15-F33** | Missing shared-kernel + RBAC + FAT-034 tests | Gaps | Focused hardening suite | Gate | PASS |

**Gate evidence:** `.verify/PHASE-1.5-HARDEN.json` — `status: passed`, tier `full`, analyze OK, ~1360 tests, recorded `2026-09-24T12:43:14+00:00`.  
**Device:** **REAL-DEVICE VALIDATION: NOT RUN**

---

## K. Remaining Mocks / Unsupported / Deferred

| Item | Class | Next owner |
|---|---|---|
| Native GPS / background sampling | NOT IMPLEMENTED | Stage 3 device |
| VPN/DNS/native web block | MOCK-REMOTE | Stage 3 enforcement |
| Device Admin / Accessibility app intercept | MOCK-REMOTE | Stage 3 enforcement |
| Capture pipeline / camera OS plane | MOCK-REMOTE | Stage 3 media |
| Modes OS wake | MOCK-REMOTE | Stage 3 scheduling |
| SOS FCM / SMS / telephony / national dial | MOCK-REMOTE | Stage 3 SOS delivery |
| Cloud classify / real NN weights | UNSUPPORTED | STAGE3-AI |
| AI as policy executor | FORBIDDEN | Never |
| MockRemoteAdapter live enqueue | DEBT P15-F20 / MOCK-REMOTE | Stage 3 |
| Smart Modes Prefs fallback on ensureOpen failure | DEBT P15-F06 | Later |
| Unlock / ST / time-request Prefs leftovers | DEBT P15-F07 / LEGACY-MOCK-DEBT | Non-FS leftover |
| `simulateLocalAckToVerified` production API surface | DEBT P15-F13 | Guard later |
| Router mother-level path matrix | DEBT P15-F17 | Domain still throws |
| Memory close does not clear rows | DEBT P15-F21 | Kernel reset replaces instance |
| Samsung SM-S906U / Android 16 device pass | DEBT P15-F29 | Owner device wave |
| Stale `.verify/FS-001-UX.json` failed artifact | DEBT P15-F32 | Optional prune |
| P15-QUR-004…007 | deferred_campaign | Owner re-arm only |
| Stage 3 | NOT STARTED | Owner explicit start |

---

## L. Known Limitations

1. **Entire FS + Phase 1.5 implementation is uncommitted** relative to HEAD — remote/CI cannot see it until commit.
2. **No physical-device certification** for SQLite restart, GPS honesty UI, or any native plane.
3. **Configured ≠ enforced** for WF by design; badges may show SIMULATED.
4. **Heuristic AI classifier** ≠ production model weights.
5. **Verify JSON inconsistency** for FS-001-UX and FS-I-RECON vs CONVERSION_LOG / tail files; last authoritative full green is PHASE-1.5-HARDEN.
6. **FamilyShell / PRT-2** navigation parity is prior work — not an FS visual redesign.
7. **SQLite open failure** falls back to Memory (DEGRADED) — data does not survive process kill in that mode.
8. **Mother deep-link RoleGuard** incomplete (P15-F17); domain enforcement remains the backstop.
9. **Outbox not on live event paths** — do not treat MockRemote as live sync.
10. Exact per-file git diff vs a committed pre-FS tree for every modified Stage-1 host: **partial** — use ledger + current source; where a precise prior line cannot be proven, marked UNKNOWN above.

---

## M. Real Device Readiness

### Reasonable to exercise on phone **now** (local/domain + honesty UX)

- Capability / GPS / MOCK-REMOTE honesty badges on location, WF, AC, Modes, SC, AI hosts.
- Safe-zone create/list/assignment when `Stage1LocationRuntime` opens.
- Silent locate sheet → honest NOT IMPLEMENTED / unavailable / stale outcomes (not live GPS).
- WF list editors + unlock interstitial (not real device block).
- App Control hub / protected badges / child AppDenyPage / exception request UX.
- Modes schedule UI + child ModeDisclosureCard.
- SOS fire / readiness / break-glass UI (delivery simulated).
- AI ticket review + child transparency panels.
- Restart persistence **if** `FsSessionKernel.usingSqlite == true` — **needs device confirm**.

### Still requires physical-device verification

- SQLite file survival across kill / reboot / reinstall.
- Memory fallback path when SQLite open fails.
- Any claim of GPS, VPN, OS intercept, capture, FCM, OS alarms.
- OEM permission / battery / background behavior on **Samsung SM-S906U · Android 16 · API 36**.
- Visual KEEP/REFINE + RTL on real density / font scale.

**REAL-DEVICE VALIDATION: NOT RUN**

---

## WHAT THE OWNER WILL NOTICE ON THE PHONE

Only user-visible changes supported by repository evidence (KEEP/REFINE; not redesign).

### Navigation

- Tab shell / hubs / FABs: largely **prior PRT-2** — FS campaign did not redesign chrome.  
  `BEFORE → AFTER:` same FamilyShell navigation; FS panels mount **inside** existing routes.

### Screens

- Location map/zones (FAT-014…017): `BEFORE` Stage-1 Prefs/mock map UX → `AFTER` domain-backed zones + GPS honesty badge + Silent locate CTA/sheet.  
- CHD-024: `BEFORE` live map card without FS silent check-in contract → `AFTER` silent check-in honesty banner.  
- Web filter FAT-036: `BEFORE` Stage-1 lists → `AFTER` domain lists + taxonomy/native honesty badges.  
- Apps FAT-034/035: `BEFORE` Prefs AC → `AFTER` Domain AC + protected badges + Partner tickets-only + child AppDenyPage.  
- Smart Alerts FAT-065: `BEFORE` alerts / screenshot tool as second-store risk → `AFTER` ScreenCameraParentPanel + AiSafetyTicketReviewPanel.  
- CHD-010: `BEFORE` collection transparency → `AFTER` + ScreenCameraTransparencyCard + AiSafetyChildTransparencyCard.  
- FAT-085 / CHD-004: `BEFORE` Prefs Smart Modes → `AFTER` Modes domain bind + ownership/os_wake badges + ModeDisclosureCard.

### Settings

- Modes: multi-mode tighten-only; exams→study hint; Vacation widen rejected.  
- WF unlock: timed temp allow — not permanent allowList.  
- AC Exception: timed — does not rewrite Permanent Block.  
- SC: Prevent/Monitor/Protect bound to one store on FAT-065.

### Behavior

- Geofence ENTER/EXIT/NO_SHOW evaluation on local domain (injected/simulated fixes — not live GPS).  
- Modes consume location facts when kernel shared (Phase 1.5).  
- AI tickets suggest-only — no AI execute; AI never fires SOS.  
- Child cannot act as father on App Control (P15-F16).

### Offline states

- CapabilityHonestyBadge / EnforcementStatusBadge show honest NOT IMPLEMENTED / MOCK-REMOTE / SIMULATED vocabulary.  
- WF delivery Configured ≠ native enforced.

### Safety

- SOS never subscription-gated.  
- Break-glass allowlist RBAC; Observer cannot ack.  
- Missing GPS does not block SOS fire; location attach may show not-implemented honesty.  
- OD-14 permanent exemptions audited in domain.

### Alerts

- FAT-065 hosts SC policy panel + AI safety ticket review (redacted preview; non-numeric certainty/severity).

### AI

- On-device ticket/signal plane with suggest-only UX; child transparency card; cloud classify unsupported.

### Visual refinements

- Added shared badges, sheets, and panels on existing shells — **small KEEP/REFINE**, not a frozen-prototype redesign / not green-v1 resurrection.

---

## Final status block

```
AUDIT: COMPLETE
PRODUCTION CODE: UNCHANGED DURING THIS AUDIT
DEVICE TESTING: NOT RUN
ARTIFACT: docs/experience_discovery/IMPLEMENTATION_BEFORE_AFTER_AUDIT.md
```

*Authority chain: Policy Register → Constitution → FS L2/L3 freezes → FS_001_007_* + PHASE_1_5_* ledgers/closures → working tree + `.verify` evidence.*
