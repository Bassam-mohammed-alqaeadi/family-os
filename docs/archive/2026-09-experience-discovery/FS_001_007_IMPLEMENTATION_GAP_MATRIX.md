# FS-001 → FS-007 Implementation Gap Matrix

**Gate:** Post–Phase 1.5 UX Audit · Implementation Reconciliation  
**Date:** 2026-09-24  
**Mode:** READ-ONLY evidence (no production code modified by this gate)  
**UX baseline (authoritative):** [`FAMILY_OS_SCREEN_BEFORE_AFTER_UX_AUDIT.md`](FAMILY_OS_SCREEN_BEFORE_AFTER_UX_AUDIT.md)  
**Engineering baseline:** [`IMPLEMENTATION_BEFORE_AFTER_AUDIT.md`](IMPLEMENTATION_BEFORE_AFTER_AUDIT.md) · [`FS_001_007_CHANGE_LEDGER.md`](FS_001_007_CHANGE_LEDGER.md) · [`FS_001_007_CLOSURE_REPORT.md`](FS_001_007_CLOSURE_REPORT.md)  
**Blueprint:** `docs/family_os_blueprint/` — **MISSING in workspace** (same finding as FS discovery packs; treated UNKNOWN, not invented)

### Vocabulary (this matrix)

`VERIFIED_PRESENT` · `PARTIAL` · `MISSING` · `MISLEADING` · `WRONG_OWNERSHIP` · `DUPLICATED_AUTHORITY` · `MOCK_ONLY` · `LOCAL_ONLY` · `REMOTE_UNIMPLEMENTED` · `NOT_IMPLEMENTED` · `UNVERIFIED`

A row may combine states by capability (e.g. UI honesty `VERIFIED_PRESENT` + native plane `MOCK_ONLY`).

### Git / verify posture (applies to all rows)

| Fact | Evidence |
|---|---|
| Campaign commits | **0** FS / PHASE-1.5 commits on HEAD (IMPLEMENTATION_BEFORE_AFTER_AUDIT + working-tree `??`/`M`) |
| Last full green | `.verify/PHASE-1.5-HARDEN.json` → `status: passed` (~1360 tests) |
| Stale / conflict | `.verify/FS-001-UX.json` → `failed` (1276/4); `.verify/FS-I-RECON.json` → `failed` (analyze `unnecessary_import`); CONVERSION_LOG claims both `passed` |
| Device | **REAL-DEVICE VALIDATION: NOT RUN** |

### Safe-to-proceed without backend (column shorthand)

| Code | Meaning |
|---|---|
| **Y** | Local domain / honesty UX can deepen without Stage-3 API |
| **Y*** | Local OK; do not claim native/remote success |
| **N** | Requires device/OS/native or transport plane |

---

## Gap matrix (audited surfaces)

| Screen | System | Required | Present | Partial/Missing | Actual Binding | Capability State | Policy Owner | Test Evidence | Verification | Device Required | Backend Required | Implementation Risk |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **SCR-FAT-014** Location Map `/scr-fat-014` | FS-001 | GPS honesty; Silent locate CTA/sheet; decorative map KEEP; SOS reachable | GPS banner + `CapabilityHonestyBadge` + `SilentLocateSheet` via `Stage1LocationRuntime` **VERIFIED_PRESENT** in `location_map_screen.dart` | Live GPS **NOT_IMPLEMENTED**; map decorative | `Stage1LocationRuntime.store` + `SilentLocateService`; route in `router.dart` | Local locate honesty `LOCAL_ONLY`; `fs001.native_gps` `NOT_IMPLEMENTED` | FS-001 Location | `fs001_ux_adapt_test.dart`; map widget tests | `.verify/FS-001-UX.json` **failed** (stale P15-F32) vs CONVERSION_LOG passed; HARDEN passed | Native GPS later (N for live track) | No for honesty | **Medium** — banner mitigates map over-claim; ignore-banner = `MISLEADING` risk |
| **SCR-FAT-015** Location History `/scr-fat-015` | FS-001 | GPS honesty; day-thread KEEP | `locationGpsNotImplementedBanner` **VERIFIED_PRESENT** | No Silent locate; **no** CapabilityHonestyBadge; **no** Domain location store bind on host (**PARTIAL**) | Stage-1 history / Prefs-era path (audit) | GPS `NOT_IMPLEMENTED`; trail domain exists in core but **not proven on this host** | FS-001 (facts); host under-bound | History tests / FS-001-UX suite | Same FS-001-UX conflict | N for live trail GPS | No for banner | **Medium** — LEGACY host bind gap |
| **SCR-FAT-016** Safe Zones list `/scr-fat-016` | FS-001 | Zone list + GPS honesty; domain zones preferred | GPS banner **VERIFIED_PRESENT** | Default `_repo = stage1SafeZonesRepository` — DomainSafeZones **not** default (**PARTIAL** / LEGACY-MOCK-DEBT) | Injected `SafeZonesRepository?` else Stage-1 in-memory | List `LOCAL_ONLY` Stage-1; domain zones `PARTIAL` | FS-001 owns zones; host still Stage-1 default | FS-001-UX / safe-zones tests | FS-001-UX conflict | No | No for list UI | **High** — dual store risk if Domain + Stage-1 diverge |
| **SCR-FAT-017** Create Safe Zone `/scr-fat-017` | FS-001 | Q-LOC-12 multi-select; GPS honesty; geometry save | Banner + badge + assign chips **VERIFIED_PRESENT**; optional `DomainSafeZonesRepository` | Default `_repo = stage1SafeZonesRepository`; domain only when `domainRepository` set (**PARTIAL**) | Stage-1 repo default; domain optional | Geometry domain `VERIFIED_PRESENT` in core; host save path `PARTIAL` | FS-001; Q-LOC-12 | `fs001_ux_adapt_test` | FS-001-UX conflict | No for local geometry | No | **Medium** — assignment UI real; persistence path dual |
| **SCR-CHD-024** Child Arrival `/scr-chd-024` | FS-001 | Silent check-in honesty (no fake live map); zone CTAs; SOS | `BannerNote` + `childArrivalSilentBanner` on `ChildArrivalKeys.liveCard` **VERIFIED_PRESENT** (code) | Live GPS still `NOT_IMPLEMENTED`; no CapabilityHonestyBadge on child host | Stage-1 arrival repo / zones grid | Honesty reshape `VERIFIED_PRESENT`; GPS `NOT_IMPLEMENTED` | FS-001 silent child law | CHD-024 ScreenBuild + FS-001-UX | FS-001-UX conflict | N for real check-in GPS | No for honesty banner | **Low–Medium** — UX class inconsistency: audit §11 = LIGHT; Part 5 §5 lists as structural reshape |
| **SCR-FAT-036** Web Filter `/scr-fat-036` | FS-002 | Lists/categories; delivery honesty; native/taxonomy honesty; unlock ≠ permanent allow | Honesty badges + strings + `Stage1WebFilterRuntime` bind **VERIFIED_PRESENT** | Native block plane **MOCK_ONLY**; taxonomy **PARTIAL**/DEGRADED | `Stage1WebFilterRuntime.policyRepository` + delivery | Lists/delivery/temp-allow `VERIFIED_PRESENT`/`LOCAL_ONLY`; `fs002.native_block` `MOCK_ONLY`/`REMOTE_UNIMPLEMENTED` | FS-002 | `web_filter_*` + unlock loop tests | `.verify/FS-002-*` claimed passed; HARDEN passed | N for VPN/DNS | No for lists | **Medium** — UI honest; control non-enforcing at OS |
| **WebBlockPage** (hosted, **no GoRoute**) | FS-002 | Source-of-deny; unlock → temp allow; feedback | Interstitial pattern **VERIFIED_PRESENT** (feature host; not in router as SCR) | Native block still mock | Domain verdict → temp allow via unlock service | Verdict `LOCAL_ONLY`; device block `MOCK_ONLY` | FS-002 | Unlock / interstitial tests | Under FS-002-ENF / HARDEN | N for OS block | No for interstitial UX | **Low** — hosting ≠ missing route for SCR registry |
| **SCR-FAT-034** Child Apps `/scr-fat-034` | FS-003 | AC dispositions; protected packages; OS honesty; AppDeny preview; Partner tickets-only | Badge + protected + `Stage1AppControlRuntime` bootstrap + `AppDenyPage` preview **VERIFIED_PRESENT** (P15-F05) | `fs003.os_intercept` **MOCK_ONLY** | Domain AC accessRules + service | Dispositions `VERIFIED_PRESENT`/`LOCAL_ONLY`; intercept `MOCK_ONLY` | FS-003; ST keeps Limit/Unlimited | `fs003_ux_adapt_test` | FS-003 verify claimed passed; HARDEN passed | N for Device Admin / Accessibility | No for dispositions | **Medium** — honest UI, non-enforcing OS |
| **SCR-FAT-035** New App Approval `/scr-fat-035` | FS-003 | Child-scoped install; approve/deny | Honesty badge + child-scoped copy **VERIFIED_PRESENT** | OS install intercept mock | Domain AC install when bridged | Install tickets `LOCAL_ONLY`; intercept `MOCK_ONLY` | FS-003 | fs003 UX tests | FS-003 / HARDEN | N for OS package install gate | No | **Low–Medium** |
| **AppDenyPage** (hosted, **no SCR id**) | FS-003 | Source-of-deny; Exception≠Minutes; Chat/Quran/SOS reachable | Full page + keys **VERIFIED_PRESENT** (`app_deny_page.dart`) | Not a registry SCR (by design); OS still mock | Opened from FAT-034 preview / deny path | Deny domain `LOCAL_ONLY`; intercept `MOCK_ONLY` | FS-003 | `fs003_ux_adapt_test` | FS-003 / HARDEN | N for real deny-at-OS | No for interstitial | **Low** — classified `NEW SCREEN` hosted |
| **SCR-FAT-065** Smart Alerts `/scr-fat-065` | FS-004 + FS-007 | SC Prevent/Monitor/Protect single store; hide screenshot tool when SC bound; AI ticket review suggest-only; overload risk acknowledged | `fs004SmartAlertsPolicyOwned` + `ScreenCameraParentPanel` + `AiSafetyTicketReviewPanel` + screenshot tool gated **VERIFIED_PRESENT** (`smart_alerts_screen.dart`) | Capture/camera OS `MOCK_ONLY`; cloud classify `NOT_IMPLEMENTED`/`UNSUPPORTED`; **classification conflict** LIGHT vs structural (see Report) | SC service + AI safety service when injected / Stage-1 runtime | Policy `LOCAL_ONLY`/`VERIFIED_PRESENT`; planes `MOCK_ONLY`; AI heuristic `LOCAL_ONLY`; cloud `UNSUPPORTED` | FS-004 owns SC; FS-007 owns tickets; Smart Alerts = entry/notify only | `fs004_ux_adapt_test`, `fs007_ux_adapt_test` | `.verify/FS-004-UX` + `FS-007-UX` **passed**; HARDEN passed | N for MediaProjection / camera kill | No for policy+tickets; cloud later | **High** — density/`MISLEADING` if switches read as enforced; discoverability of SC on alerts hub |
| **SCR-CHD-010** What is collected `/scr-chd-010` | FS-004 + FS-007 | Child transparency W-C01/W-C02 for SC + AI | `AiSafetyChildTransparencyCard` + `ScreenCameraTransparencyCard` co-mounted **VERIFIED_PRESENT** | Planes remain mock | Transparency cards bind eval / copy | Transparency copy `VERIFIED_PRESENT`; enforcement `MOCK_ONLY` | FS-004 / FS-007 honesty; SET-012 scopes retained | FS-004/007 UX tests | FS-004/007 / HARDEN | No | No | **Low** |
| **SCR-FAT-085** Smart Modes `/scr-fat-085` | FS-005 | Modes scheduler authority; ownership banner; os_wake honesty; exams→study | When `_usingModes`: ownership banner + wake badge + `Stage1ModesRuntime` **VERIFIED_PRESENT** | Prefs path if `repository` injected or Modes `ensureOpen` fails (`_usingModes=false`) → **PARTIAL** / **DUPLICATED_AUTHORITY** vs Prefs + ScheduleWindow residual | ModesService **or** `PrefsSmartModePrefsRepository` | Scheduler `LOCAL_ONLY` when Modes; `fs005.os_wake` `MOCK_ONLY`; Prefs fallback LEGACY | FS-005 Modes; ST ScheduleWindow ≠ Mode authority (banner) | `fs005_ux_adapt_test`; SET-018 Prefs tests still valid | FS-005 / HARDEN | N for OS wake / Focus | No for local Modes | **High** — dual authority Prefs vs Modes (P15-F06 DEBT) |
| **SCR-CHD-004** Child Day Board `/scr-chd-004` | FS-005 | ModeDisclosureCard; no child cancel; minutes/SOS KEEP | `ModeDisclosureCard` when Modes eval injected **VERIFIED_PRESENT** | Absent when Modes not injected (**PARTIAL**) | Optional Modes evaluation | Disclosure `LOCAL_ONLY` conditional | FS-005 MODE-OD-10 | fs005 UX / day-board tests | FS-005 / HARDEN | No | No | **Medium** — disclosure depends on injection |
| **SCR-FAT-018** SOS Alert `/scr-fat-018` | FS-006 | Lifecycle board; location/delivery honesty; Break-glass; never gate fire | `SosStatusBanner` / `SosLocationStatus` / `SosDeliveryStatus` / `showSosBreakGlassSheet` **VERIFIED_PRESENT** | No CapabilityHonestyBadge on host; remote delivery mock | SOS Final / Stage-1 SOS UI + FS-001 handoff honesty | Lifecycle `LOCAL_ONLY`/`VERIFIED_PRESENT`; `fs006.remote_delivery` `MOCK_ONLY`; GPS attach `NOT_IMPLEMENTED` OK | FS-006; FS-001 facts only | SOS-UI + FS-006 tests | FS-006 / HARDEN | N for FCM/SMS/telephony | Transport later | **Medium** — UI honest; delivery non-real |
| **SCR-FAT-028** Emergency Setup `/scr-fat-028` | FS-006 | Ladder; readiness honesty NOT_CONFIGURED for push/SMS/calling | `SosReadinessCard` **VERIFIED_PRESENT** | Remote planes not configured | Ladder repos + readiness evaluator | Readiness copy `VERIFIED_PRESENT`; remote `MOCK_ONLY` / NOT_CONFIGURED | FS-006 | SOS / readiness tests | FS-006 / HARDEN | N for real push/SMS | Transport later | **Low–Medium** |
| **SCR-CHD-006** Child SOS in progress `/scr-chd-006` | FS-006 | In-progress honesty; cancel confirm; location/delivery status | `SosLocationStatus` + `SosDeliveryStatus` + cancel sheet **VERIFIED_PRESENT** | Remote delivery mock | SOS child path | Same as FAT-018 planes | FS-006 | CHD-006 / SOS tests | FS-006 / HARDEN | N for live delivery | Transport later | **Low** |
| **FamilyShell / tabs** | PRT-2 | Unchanged by FS campaign | Shell present; **NO MATERIAL FS UI CHANGE** (audit Part 2) | N/A | Router + shell | N/A | PRT-2 | PRT tests | Prior PRT verify | No | No | **None** for FS scope |
| **SCR-CHD-005** SOS button | FS-006 host KEEP | No material FS UI change | KEEP Stage-1 **VERIFIED_PRESENT** as unchanged | N/A | Stage-1 SOS | Fire path separate from delivery mock | FS-006 | CHD-005 tests | Prior | Device for panic UX later | Transport later | **Low** |

---

## Capability planes (cross-cutting, not SCR-bound)

| Capability id | Required (L2/L3) | Code evidence | State | Device | Backend | Risk |
|---|---|---|---|---|---|---|
| `fs_a.sqlite_kernel` | Local DB | `fs_foundation` + `FsSessionKernel` | `VERIFIED_PRESENT` / `LOCAL_ONLY` | Prefer SQLite outside tests | No | Memory fallback = DEGRADED |
| `fs_a.mock_remote` | Outbox port | `MockRemoteAdapter` | `MOCK_ONLY`; live enqueue **DEBT P15-F20** | No | Later | Do not claim sync |
| `fs001.location_domain` / `geofence_eval` | Zones + ENTER/EXIT/NO_SHOW | `core/location/*` | `VERIFIED_PRESENT` | No for pure domain | No | Host bind incomplete on FAT-015/016 |
| `fs001.sos_location_handoff` / `modes_fact_feed` | XSYS seams | handoff + fact feed; P15-F02 wired | `VERIFIED_PRESENT` | No | No | Facts ≠ Mode activation / ≠ SOS fire block |
| `fs001.native_gps` | Live GPS | CapabilityRegistry `notImplemented` | `NOT_IMPLEMENTED` | **Yes** | Optional cloud trail | Claiming live = `MISLEADING` |
| `fs002.web_lists` / `delivery` / `timed_unlock` | Lists + Configured→Verified + temp allow | `core/web_filter/*` | `VERIFIED_PRESENT` | No | No | Unlock must stay temp (Q-WF-09) |
| `fs002.native_block` | VPN/DNS | Registry mockRemote | `MOCK_ONLY` / `REMOTE_UNIMPLEMENTED` | **Yes** | Optional policy sync | UI toggles non-enforcing |
| `fs003.app_dispositions` / protected / exception | Package policy | `core/app_control/*` | `VERIFIED_PRESENT` | No | No | — |
| `fs003.os_intercept` | OS block | Registry mockRemote | `MOCK_ONLY` | **Yes** | Optional | Same honesty risk |
| `fs004.screen_camera_policy` | Prevent/Monitor/Protect | `core/screen_camera/*`; engine never claims enforcement alone | `VERIFIED_PRESENT` | No | No | DesiredMonitoringPrefs must not absorb SC |
| `fs004.capture_pipeline` / `camera_os_plane` | Capture / camera OS | Registry mockRemote | `MOCK_ONLY` | **Yes** | Optional | FAT-065 switches = policy-only |
| `fs005.modes_scheduler` | Lifestyle stack tighten-only | `core/modes/*` | `VERIFIED_PRESENT` when Modes path | No | No | Prefs fallback = `DUPLICATED_AUTHORITY` |
| `fs005.os_wake` | Alarm/Focus wake | Registry mockRemote | `MOCK_ONLY` | **Yes** | No | — |
| `ScheduleWindow` (ST) | Not Mode authority | `schedule_window_repository.dart` still exists | `DUPLICATED_AUTHORITY` residual | No | No | Banner warns; Prefs path DEBT |
| `DesiredMonitoringPrefs` | web/app/notif/location only | Prefs repo remains | Must **not** own screenshot SC | No | No | `WRONG_OWNERSHIP` if re-absorbed |
| `fs006.sos_lifecycle` / readiness / break_glass / exemptions | SOS Final | `core/sos_final/*` | `VERIFIED_PRESENT` | No for local lifecycle | No | OD-14 never gate fire |
| `fs006.remote_delivery` | FCM/SMS/telephony | Registry mockRemote | `MOCK_ONLY` | **Yes** | **Yes** (transport) | Readiness NOT_CONFIGURED honest |
| `fs007.local_classifier` / tickets / suggest_only / UX | Signal plane | `core/offline_ai_safety/*`; no execute; never SOS | `VERIFIED_PRESENT` (heuristic stub) | No for stub | Cloud later | Stub ≠ production ML |
| `fs007.cloud_classify` | Cloud ML | Registry unsupported | `UNSUPPORTED` / `NOT_IMPLEMENTED` | Optional | **Yes** | — |
| `fs007.ai_as_executor` | Forbidden | Structural no `execute()` | `FORBIDDEN` (policy) | — | — | Never implement |

---

## Known-issue investigation (explicit)

| Issue | Finding | Classification |
|---|---|---|
| **FAT-065 LIGHT vs STRUCTURAL** | §11 Visual class = `LIGHT REFINEMENT` with “additive structural panels”; Part 5 §5 lists FAT-065 under **Structural UI changes** without using token `STRUCTURAL UI CHANGE`. Closure/ledger = KEEP/REFINE. | Documentation **inconsistency** — not a code defect. Reconcile vocabulary before any redesign card. Prefer: shell KEEP + **composition STRUCTURAL** inside host. |
| **CHD-024 live-map → silent banner** | Code: `ChildArrivalKeys.liveCard` is `BannerNote` + `childArrivalSilentBanner` — **no** live-map widget. Audit AFTER matches code. | UX reshape `VERIFIED_PRESENT`; GPS still `NOT_IMPLEMENTED`. Same LIGHT vs Part-5 structural note. |
| **Verify triad** | `PHASE-1.5-HARDEN` **passed**; `FS-001-UX` **failed** (stale); `FS-I-RECON` **failed** analyze; CONVERSION_LOG claims FS-001-UX + FS-I-RECON **passed**. | **Verification conflict** — do not treat all cards as green artifacts; trust HARDEN as newest full green; mark earlier JSON `UNVERIFIED`/stale. |
| **REAL LOCAL vs MOCK-REMOTE** | Registry + badges align with closure rollup. | Distinctions hold in code; host dual-bind is the main local gap. |
| **Honest UI / non-enforcing control** | WF/AC/SC/Modes wake/SOS delivery: badges present; engines refuse fake Verified native. | `MISLEADING` residual if user ignores badges; settings are **real policy**, **not** OS enforcement. |
| **Duplicate authority** | Screenshot tool hidden when `_scDoc != null`; Modes vs Prefs fallback; ScheduleWindow repo remains; DesiredMonitoringPrefs separate. | Screenshot duplicate **mitigated**; Modes/Prefs + ScheduleWindow = **open DEBT**. |
| **Routes** | All indexed SCR routes present in `router.dart`. WebBlockPage / AppDenyPage **intentionally unrouted** (hosted). | Unrouted ≠ missing for those interstitials. |

---

## Count rollup (surface primary state — see Report for capability counts)

| Bucket | Count (primary audited SCR/hosted surfaces in Part 1) |
|---|---|
| Primarily `VERIFIED_PRESENT` (local honesty/domain UX) | **14** |
| Primarily `PARTIAL` (under-bound or dual path) | **4** (FAT-015, FAT-016, FAT-017 default, FAT-085/CHD-004 conditional — CHD-004 counted partial) |
| `NEW` hosted interstitial | **1** (AppDenyPage) + WebBlockPage refined |
| Native/remote planes `MOCK_ONLY` / `NOT_IMPLEMENTED` | **7+** capability ids (cross-cutting) |
| Doc `MISLEADING` risk (mitigated) | **3** hosts (map, SC switches, ignore-honesty) |
| Blueprint | **MISSING** |

*End of gap matrix.*
