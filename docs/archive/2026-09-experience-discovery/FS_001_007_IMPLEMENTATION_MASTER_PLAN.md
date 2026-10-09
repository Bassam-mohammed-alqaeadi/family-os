# FS-001 → FS-007 Implementation Master Plan

**Status:** AUTHORIZED — Bassam Master Implementation Commission (2026-09-24)  
**Workspace:** `D:\special projects\family`  
**Stack law:** UI → Domain → Repository/Service Interfaces → SQLite/local state + Mock Remote Adapter  
**Backend:** **FORBIDDEN** in this campaign (no Node/Render/Firestore/live API)  
**Visual law:** KEEP + REFINE Stage-1 / L3 screens — no redesign  

This document is the **single campaign authority** for implementing Family-OS systems FS-001…FS-007 after Discovery + L2 + L3 freezes. L3 packages previously marked `IMPLEMENTATION: NOT AUTHORIZED` are **superseded for gate status only** by this Owner commission; product law inside those packages remains binding.

---

## 0. Authority & preflight

### Authority order (conflicts)

1. Policy Register (`handoff/04_POLICY_REGISTER_EN.md`) + Cursor Constitution  
2. Per-system **L2 Final / Owner freeze** packages  
3. Per-system **L3 UX** packages (behavioral surfaces)  
4. This master plan (sequencing, seams, migration)  
5. Stage-1 app / prototype / `schema.sql` — **evidence of gaps only**  

### Harness preflight (2026-09-24)

| Check | Result |
|---|---|
| `LOOP_STATE` | `RUNNING` · was `P15-QUR-004` |
| Unanswered `QUESTIONS.md` | **None** (all Q-* resolved) |
| Owner commission | **FS-001…FS-007** supersedes Quran NEXT for this campaign |
| P15-QUR-004…007 | **parked** (`deferred_campaign`) — resume after Phase I or Owner re-order |

### Design packages (approved)

| ID | System | L2 / Final | L3 |
|---|---|---|---|
| **FS-001** | Location & Geofencing | `location_final/` | `location_l3/` |
| **FS-002** | Web Filtering | `web_filtering_l2/` | `web_filtering_l3/` |
| **FS-003** | Application & System Control | `application_control_l2/` | `application_control_l3/` |
| **FS-004** | Screen & Camera Control | `screen_camera_l2/` | `screen_camera_l3/` |
| **FS-005** | Special / Custom Modes | `modes_l2/` | `modes_l3/` |
| **FS-006** | SOS | `sos_final/` (+ `sos_l2/`/`sos_l3/`) | Screen eng. + prior SOS-UI slice |
| **FS-007** | Offline AI Safety | `offline_ai_safety_l2/` | `offline_ai_safety_l3/` |

### Repo evidence (baseline)

- ~129 ScreenBuild screens exist; many FS-relevant surfaces are **Stage-1 mock / Prefs**.  
- Persistence today: **in-memory Prefs stores** — no `sqflite` / Drift / SharedPreferences in `pubspec.yaml`.  
- Native Android: bare `FlutterActivity`; no VPN/DO/UsageAccess enforcement yet.  
- SOS Flutter UI slice **shipped** (`CONVERSION_LOG` SOS-UI) — lifecycle honesty + RBAC + Break-glass **UI/domain seams**; remote delivery still MOCK-REMOTE.  
- Identity abstractions exist under `app/lib/core/identity/`.  
- Web filter / app access / smart modes / location screens exist as Stage-1 — **not** L2/L3 complete product.

### Constitution note on `core/policy/`

Rule 21 requires Owner decision to modify `core/policy/`. **This commission is that decision** for **additive** FS seams required by frozen L2 (same pattern as SOS-UI). Prefer:

- New FS ownership modules under `app/lib/core/<fs>/` or feature `domain/` first.  
- Touch existing `core/policy/*` only when the frozen contract extends an already-owned Stage-1 type (web filter, SOS, app access, modes) — **additive**, never silent product redesign.  
- Never edit `tokens.dart` or `.cursor/rules/` in this campaign.

---

## 1. Implementation phases

| Phase | Name | Goal | Exit |
|---|---|---|---|
| **0** | Preflight + Plan | Harness clear; this file on disk | Plan written; BACKLOG FS lane armed |
| **A** | Shared foundations | Capability honesty, local SQLite kernel, MockRemote port, delivery pipeline vocabulary, shared RBAC helpers, audit append seam, identity binding | Card `FS-A-FOUND` verify green |
| **B** | FS-001 Location | Domain facts/geometry/history; zones circle+polygon; ENTER/EXIT/NO_SHOW; silent child; SOS handoff; offline honesty | `FS-001-*` cards done |
| **C** | FS-002 Web Filtering | Own allow/block/dict/categories; unlock tickets; enforcement honesty plane; Modes chip only | `FS-002-*` done |
| **D** | FS-003 App Control | Own package dispositions; install/exception; protected apps; Lock Now overlay ≠ permanent | `FS-003-*` done |
| **E** | FS-004 Screen & Camera | Prevent + Monitor + Protect; five-way separation; child transparency | `FS-004-*` done |
| **F** | FS-005 Modes | Unified scheduler authority; tighten-only; composition stack; grace | `FS-005-*` done |
| **G** | FS-006 SOS | Complete vs `sos_final` — lifecycle, readiness, evidence retention, Break-glass; **no duplicate location/web/app engines** | `FS-006-*` done |
| **H** | FS-007 Offline AI | Classification **signal** plane only; signed model honesty; tickets; no auto policy mutation; no SOS fire | `FS-007-*` done |
| **I** | Reconciliation | Cross-system source-of-deny; visual KEEP/REFINE; closure report; parks lifted | Closure report + verify `--full` |

Each phase is sliced into **harness cards** (one card per tick). Ship only after `python .cursor/hooks/verify_ship.py verify` exits 0.

---

## 2. Family-OS dependency graph

```
                    ┌─────────────────┐
                    │  Identity (S3)  │
                    │ family/child/   │
                    │ device/RBAC     │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
   ┌───────────┐      ┌────────────┐      ┌────────────┐
   │ FS-001    │──────│  Policy    │──────│ FS-006 SOS │
   │ Location  │ facts│  Kernel*   │ acts │ Final      │
   │ Domain    │      │ (interpret)│      │ lifecycle  │
   └─────┬─────┘      └─────┬──────┘      └─────┬──────┘
         │ location triggers│                   │ location honesty only
         ▼                  ▼                   ▼
   ┌───────────┐      ┌────────────┐      ┌────────────┐
   │ FS-005    │─────▶│ FS-002 WF  │      │ FS-003 App │
   │ Modes     │tighten│ (lists)   │      │ (packages) │
   │ scheduler │ only │            │      │            │
   └─────┬─────┘      └─────┬──────┘      └─────┬──────┘
         │                  │                   │
         │           ┌──────┴───────┐           │
         │           ▼              ▼           │
         │    ┌────────────┐  ┌────────────┐    │
         └───▶│ FS-004 SC  │  │ FS-007 AI  │◀───┘
              │ prevent/   │  │ classify   │ suggest-only
              │ monitor/   │◀─│ signal     │──▶ human approve
              │ protect    │  └────────────┘
              └────────────┘

* Kernel = existing PolicyEngine + sync buses — interpret notify/ticket/deny;
  FS-007 never becomes a second policy engine.
```

**Hard ownership (do not duplicate stores):**

| Concern | Owner |
|---|---|
| Location facts / zones / trail | **FS-001** |
| URL/category/allow/block/dict | **FS-002** |
| Package allow/block/exception/install | **FS-003** |
| Screenshot monitoring policy + OS camera prevent/protect | **FS-004** |
| Lifestyle schedule / mode stack | **FS-005** |
| SOS incident lifecycle / ladder / Break-glass | **FS-006** (`sos_final`) |
| On-device safety classification signals | **FS-007** |
| Minutes / earn / ST limits | Screen Time Final (out of commission except seams) |
| Road Safety FAT-077 | Separate (FS-001 does not absorb) |

---

## 3. Subsystem order

**Default (confirmed):**

1. Phase A — shared foundations  
2. FS-001 Location  
3. FS-002 Web Filtering  
4. FS-003 Application Control  
5. FS-004 Screen & Camera  
6. FS-005 Modes  
7. FS-006 SOS (reconcile + deepen prior SOS-UI)  
8. FS-007 Offline AI Safety  
9. Phase I — cross-system reconciliation + closure report  

**Reorder only if** Impact Analysis proves a shared-file deadlock; log the reason in the change ledger.

---

## 4. Shared-file risk map

| Hot file / area | Risk | Mitigation |
|---|---|---|
| `app/lib/app/router.dart` | Route collisions / RoleGuard drift | Additive routes; Impact Analysis per card; no batch screen IDs |
| `app/lib/core/i18n/app_*.arb` | Merge conflicts; hardcoded strings | One ARB PR-style per phase; Rule 12 always |
| `app/lib/core/policy/*` | Silent law change | Additive only; commission-authorized; document in ledger |
| `app/lib/core/policy/policy_sync_bus.dart` | Cross-system event storms | Typed FamilyEvents; per-owner channels |
| `app/lib/core/design/components/*` | Duplicate widgets | Rule 15 — promote once |
| `app/lib/features/n02_day/location_*` | FS-001 REPLACE vs KEEP | Prefer ADAPT repos behind L2 contracts |
| `app/lib/features/n04_web_filter/*` | FS-002 ownership | ADAPT → authoritative WF store |
| `app/lib/features/n03_screen_time/child_apps_*` | FS-003 vs ST axes | Keep ST limit/countable separate from AC block |
| `app/lib/features/n09_smart_modes/*` | FS-005 vs ScheduleWindow | Modes = scheduler authority; migrate dual schedulers |
| `app/lib/features/n10_emergency/*` | FS-006 vs location | SOS owns lifecycle; FS-001 owns facts |
| `app/android/**` | Native permission / Device Admin | Narrow platform channels; honesty when UNAVAILABLE |
| SQLite schema migrations | Data loss | Versioned migrations; checkpoint before migrate |
| Other 35+ systems (chat, studio, advisor, billing…) | Regression | Scoped + periodic full verify; no drive-by edits |

---

## 5. Cross-system contracts

| Edge | Contract |
|---|---|
| FS-001 → Kernel / Alerts | Canonical ENTER/EXIT/NO_SHOW events only (Q-LOC-18=A) |
| FS-001 → FS-006 | Location honesty words + samples for ACTIVE SOS; Break-glass ≠ Find My Child |
| FS-001 → FS-005 | Location **facts** may trigger schedules; Modes own interpretation |
| FS-005 → FS-002/003/004 | Tighten-only overlays; chips + deep-link; no permanent weaken |
| FS-002 ↔ FS-003 | Browser package allow ≠ URL allow |
| FS-003 ↔ Screen Time | Limit/Unlimited/Countable/Grant stay ST; Permanent Block stays AC |
| FS-004 ↔ FS-007 | FS-004 owns monitoring **policy**; FS-007 classifies approved inputs |
| FS-007 → FS-002/003/005 | Suggest-only hand-off; human approve; **never** silent mutation |
| FS-007 → FS-006 | **Forbidden** to fire SOS |
| All → Audit | Append-only; no update/delete methods |
| Offline honesty | Configured → Published → Delivered → Applied → Verified (where applicable) |
| Capability vocabulary | `IMPLEMENTED` · `MOCK-REMOTE` · `DEGRADED` · `UNSUPPORTED` · `NOT IMPLEMENTED` (+ UI honesty PENDING/UNAVAILABLE/VERIFIED as designed) |

RBAC must be enforced in **UI + domain + repository + execution** (not hide-button-only): Primary, Co-Parent Full / Partner / Observer, Child — per each L3 role matrix.

---

## 6. Migration / reconciliation strategy

Per subsystem: **KEEP / ADAPT / REPLACE / REMOVE / ADD**

### Phase A

| Item | Strategy |
|---|---|
| Memory Prefs stores | **ADAPT** — keep interface; add SQLite-backed store for FS tables |
| `MockRemoteAiStageFlags` pattern | **KEEP** as template for Mock Remote Adapter |
| Identity runtime | **KEEP** / bind FS entities to FamilyId/ChildId/DeviceId |
| Capability registry | **ADD** — honest status table for FS capabilities |
| Delivery/ack pipeline types | **ADD** shared enums/value types |

### FS-001

| Item | Strategy |
|---|---|
| FAT-014/015/016/017 screens | **KEEP** chrome; **ADAPT** to L3 LOC-P-* behavior |
| `location_*_mock.dart` / repos | **ADAPT** → domain models + SQLite; mocks become fixtures |
| Circle-only zones | **ADAPT** + **ADD** polygon |
| Silent child / Check-In / Silent Request | **ADD** per L2 |
| Road Safety FAT-077 | **KEEP** separate — do not merge |

### FS-002

| Item | Strategy |
|---|---|
| Stage-1 six categories | **ADAPT** toward L3 taxonomy with TBD honesty (Q-WF-05) |
| `WebFilterPolicy*` | **ADAPT** — become authoritative list owner |
| Unlock inbox | **KEEP** loop; align timed temporary approve (Q-WF-09) |
| Router add-on | **KEEP** optional; separated from enf_* plane |
| VPN/DNS real block | **MOCK-REMOTE** / **DEGRADED** honesty until native — no fake “blocked on device” |

### FS-003

| Item | Strategy |
|---|---|
| FAT-034/035 | **ADAPT** evidence → AC hub/inventory |
| `AppAccessRule` | **ADAPT** — separate Permanent Block from ST axes |
| Install / Exception | **ADD** flows |
| Protected SOS/Chat/Quran/Family OS | **ADD** invariants |
| Device Admin / package intercept | **MOCK-REMOTE** / platform honesty |

### FS-004

| Item | Strategy |
|---|---|
| Desired monitoring prefs (Stage-1) | **ADAPT** into FS-004 policy store |
| Camera prevent / protect / monitor UX | **ADD** L3 surfaces (or refine existing settings hosts) |
| Mic / SOS audio | **REMOVE** from scope (never ship) |
| Real MediaProjection | **MOCK-REMOTE** / **UNSUPPORTED** on iOS honesty |

### FS-005

| Item | Strategy |
|---|---|
| FAT-085 Smart Modes | **ADAPT** to Modes hub |
| `ScheduleWindow` dual authority | **ADAPT** → Modes owns lifestyle schedule; ST windows remain ST |
| Vacation loosen | **REMOVE** / do not ship |
| Child cancel mode | **REMOVE** / do not ship |

### FS-006

| Item | Strategy |
|---|---|
| SOS-UI slice (CHD-005/006, FAT-018/028) | **KEEP** + **ADAPT** to full `sos_final` |
| Delivery / FCM / SMS / telephony | **MOCK-REMOTE** with honesty |
| Evidence retention layers | **ADD** local SQLite operational 90d + indefinite core audit |
| National emergency dial / audio | **REMOVE** (forbidden) |

### FS-007

| Item | Strategy |
|---|---|
| Advisor/Insights/Tutor (Rule 26) | **KEEP** separate — do not absorb |
| Local classifier | **ADD** interface + heuristic/stub signed-model honesty for v1 |
| Real NN weights | Optional fixture model; **DEGRADED** if missing — never fake confirmed hits |
| Auto policy mutation | **REMOVE** (forbidden) |

---

## 7. Test strategy

| Layer | Proof |
|---|---|
| Domain unit | State machines, RBAC matrices, ownership invariants, offline queue |
| Repository | SQLite persistence, migration, ack/delivery states |
| Widget | Render empty/loading/one/many/error; live buttons; ARB; semantics ≥48dp |
| Integration / loop | Father configure → child reflect (P12); suggest≠execute (FS-007) |
| Cross-system | Source-of-deny; Modes tighten-only; SOS never gated; AI never fires SOS |
| Regression | `verify_ship.py` auto tier; `--full` every 3 ships + Phase I |

Use Dart MCP (`project-0-family-dart`) for analyze/test when helpful.

---

## 8. Real-device validation strategy

**Target device:** Samsung SM-S906U · Android 16 · API 36  

| Wave | What to validate on device |
|---|---|
| A | App install; SQLite file survives process kill; capability badges render |
| B | Location permission honesty; background sampling states; zone create; offline queue |
| C–E | Enforcement claims match capability (no fake VPN block) |
| F | Mode schedule fire locally; grace UX |
| G | SOS hold 3s; readiness; Break-glass RBAC; no subscription gate |
| H | Classifier degrade honesty; child transparency card |
| I | Full smoke of FS hubs + sibling systems still navigate |

Document each device pass/fail in the change ledger / closure report. Emulator may prove logic; **Samsung pass** required for location/SOS native claims marked `IMPLEMENTED`.

---

## 9. Rollback / checkpoint strategy

| Checkpoint | Mechanism |
|---|---|
| After each Ship | `CONVERSION_LOG.md` line + BACKLOG/LOOP_STATE + `.verify/*.json` |
| After each Phase | Ledger section `CHECKPOINT-FS-*` with capability table |
| SQLite migrate | Schema version N→N+1; keep previous DB copy in debug builds when feasible |
| Git commits | **Only if Owner asks** (user rule). Prefer file checkpoints. If recoverability requires commit, note in LOOP_STATE — never force-push |
| Failed verify | Fix in-loop; never mark `done` on failing gate |

---

## 10. Known mock debt to replace (campaign scope)

| Debt | Target honesty |
|---|---|
| In-memory location pins / zones | SQLite FS-001 domain + optional MockRemote sync |
| Web filter “enforced” without native plane | Delivery states + DEGRADED/MOCK-REMOTE |
| App block without OS intercept | Same |
| Screenshot monitoring without capture pipeline | Policy real; observations MOCK-REMOTE / empty honesty |
| SOS FCM/SMS/siren/call | MOCK-REMOTE / UNAVAILABLE — UI already partial |
| Cloud AI classify | Out of v1 — local only |
| Multi-device authoritative sync | MockRemote Adapter queues; cloud authoritative **later** (Stage 3) |

---

## 11. Explicitly out-of-scope backend work

- Node / Render / Firestore / Firebase project wiring  
- Live FCM / APNs production  
- Live SMS / telephony / national emergency numbers  
- Cloud ML inference gateway  
- Billing / subscription enforcement (SOS/location/chat remain forever-free)  
- STAGE3-API / STAGE3-AI backlog cards  
- Redesign of non-FS systems (chat, studio, education, Quran) except necessary seams  

---

## 12. Risks to the other 35+ systems

| Risk | Guard |
|---|---|
| Router / shell breakage | Additive routes; PRT shell tests in full suite |
| ARB key collisions | Prefixed keys `fs001_*` … `fs007_*` where new |
| PolicyEngine economy breakage | No FS card writes Minutes except via existing earn paths |
| Education / Quran parked cards | Explicit `deferred_campaign`; do not delete work |
| Screen Time confusion with FS-003/004 | Documented axis separation; ST Final remains owner of limits |
| Performance (SQLite on UI isolate) | Repositories async; no heavy work in build() |
| Agent touching forbidden dirs | Constitution; Impact Analysis before shared edits |

---

## 13. Harness card skeleton (Lane FS)

| id | phase | status | goal |
|---|---|---|---|
| FS-A-FOUND | A | **done** | Shared capability registry + SQLite kernel + MockRemote port + delivery vocabulary |
| FS-001-DOM | B | **done** | Location domain models + SQLite trail/zones |
| FS-001-UX | B | **done** | ADAPT FAT-014…017 + silent/check-in/SLR honesty |
| FS-001-XSYS | B | **done** | SOS handoff + Modes fact feed + tests |
| FS-002-OWN | C | **done** | Authoritative WF store + list screens honesty |
| FS-002-ENF | C | **done** | Delivery plane + unlock timed approve + child interstitial |
| FS-003-OWN | D | **done** | AC dispositions + protected apps + exception |
| FS-003-UX | D | **done** | Hub/inventory/deny/disclosure ADAPT |
| FS-004-OWN | E | **done** | Prevent/Monitor/Protect policy store |
| FS-004-UX | E | **done** | Parent + child transparency surfaces |
| FS-005-OWN | F | **done** | Unified scheduler + stack + tighten-only |
| FS-005-UX | F | **done** | FAT-085 ADAPT + child mode card |
| FS-006-LIFE | G | **done** | sos_final lifecycle/evidence/readiness |
| FS-006-XSYS | G | **done** | Cross-check location/web/app exemptions |
| FS-007-SIG | H | **done** | Classifier signal + ticket + suggest-only |
| FS-007-UX | H | **done** | Parent review + child transparency |
| FS-I-RECON | I | **done** | Cross-system + closure report + verify --full |

Cards may split further if a tick exceeds one-system rule; never batch unrelated systems in one Ship.

---

## 14. Change ledger location

- Per-ship: `CONVERSION_LOG.md` (one line)  
- Campaign running ledger: `docs/experience_discovery/FS_001_007_CHANGE_LEDGER.md` (create on first Phase A edit)  
- Final closure: `docs/experience_discovery/FS_001_007_CLOSURE_REPORT.md` (Phase I)  
- Gap closes: `GAP_LOG.md` when closing SET/UI-linked holes  

---

## 15. Immediate next action

1. Arm BACKLOG Lane FS with cards above; set **NEXT = FS-A-FOUND**.  
2. Park P15-QUR-004…007 as `deferred_campaign`.  
3. Execute **FS-A-FOUND** (Inspect → Impact → Plan → Edit → Analyze → Test → Document → Checkpoint).  
4. Continue autonomously through Phase I or halt only on true `QUESTIONS.md` blocker.

---

*End of Master Plan — 2026-09-24*
