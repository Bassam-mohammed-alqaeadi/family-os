# 01 — Project Understanding (Inventory)
**Mission:** Discovery phases 0–1 · Branch `discovery/master-plan`  
**Date:** 2026-09-19 · **Authority:** Section A of `handoff/11_MASTER_DISCOVERY_COMMAND.md` wins on conflict  
**Status:** CHECKPOINT — awaiting owner audit before phase 3

---

## 0. Freeze statement (Phase 0)

| Constraint | Status |
|---|---|
| No production Flutter / backend / API implementation | **Honored** |
| No rewrite of frozen prototype screens | **Honored** |
| No edits to `family-os/` specs, `handoff/` law, or `family_os_app.html` | **Honored** |
| Planning output only under `docs/project-plan/` | **Honored** |
| All 26 constitution rules remain in force | **Honored** |

---

## 1. What this repository is

Family OS («عائلتي») is a **documentation + frozen prototype** package preparing a Flutter family digital-wellbeing OS. The product is **one app, role-based** (not two apps). UI language: Arabic RTL; engineering language: English.

| Layer | Path | Authority |
|---|---|---|
| Frozen UI ground truth | `family-os/family_os_app.html` | LAW (ADR-030, v1.0) |
| Constitution (26 rules) | `handoff/01_CURSOR_CONSTITUTION.md` + `.cursor/rules/constitution.mdc` | LAW |
| Policy Register | `handoff/04_POLICY_REGISTER_EN.md` (+ Arabic `40_…`) | **SUPREME LAW** |
| Architecture | `handoff/02_ARCHITECTURE.md` | LAW |
| Screen/service/journey registry | `family-os/_REGISTRY/*.csv` | LAW (counts: see §3) |
| DB contract | `family-os/_CONTRACTS/schema.sql` (20 tables) | LAW |
| Living gap / API scaffolds | `GAP_LOG.md`, `API_CONTRACT.md` | Extend later (empty today) |
| Arabic ADR archive | `family-os/00_*.md`–`44_*.md` | Archive — consult, do not modify |

---

## 2. Top-level inventory

### Present
- `handoff/` — docs 00–11 (START_HERE → Master Discovery Command)
- `family-os/` — prototype HTML, ADRs, `_REGISTRY/`, `_CONTRACTS/`, `_archive/`
- `.cursor/` — constitution rule, hooks (`hooks.json` + 6 scripts), `mcp.json` (local)
- Root scaffolds: `GAP_LOG.md`, `API_CONTRACT.md`, `HOOK_ALERTS.md`, `README.md`
- `polish-lab/`, `_reference/` — design/reference labs
- `docs/project-plan/` — **this discovery package** (new)

### Absent (Flutter conversion not started)
- No `pubspec.yaml`, `lib/`, `test/`, `android/`, `ios/`
- No `QUESTIONS.md`, `CONVERSION_LOG.md`
- No `tokens.dart`, generated router, `core/policy/`, mock repos

**Verdict:** Repository state = **frozen design + law + registry**. Implementation phase F0 has not begun.

---

## 3. Canonical registry counts

Per Section A2: trust sealed counts; **flag deltas — do not overwrite**.

| Artifact | Sealed claim (A2 / START_HERE) | Actual CSV (2026-09-19) | Verdict |
|---|---:|---:|---|
| Screens | **129 active** | **130 rows** = 129 active **+ 1 tombstone** | **Match** — see below |
| Services | **240** | **240** | Match |
| Journeys | **73** | **73** | Match |

**CWF-001 — RESOLVED by owner audit (ADR-034).** `screens.csv` holds 130 rows, but `SCR-FAT-039` («وضع المدرسة») is a **tombstone row**: its name field carries `[محذوفة نهائيًا بقرار أد-١٢ + ق-١٢ في 37]`, matching Register **§G-2** ("Official screen count: 129 — FAT-039 permanently deleted"). Verified: it is the **only** tombstone in the registry. `SCR-FAT-086` (لحظات عائلتنا) is legitimate — present in the frozen prototype and bound to `JRN-FAT-45` (لحظة الفخر الأسبوعية, wave 1).

**Counting convention for all discovery docs:** *129 active screens + 1 tombstone (FAT-039)*. The registry is **not** edited (additive-only law).

**Screens by wave (CSV rows incl. tombstone):** W1=51 · W2=46 · W3=33 (=130)

**Services by domain (CSV):** SEC 60 · COM 39 · EDU 65 · AIC 34 · ADM 42 (=240)

**Journeys by actor (CSV):** FAT/الأب 45 · MOT/الأم 9 · CHD/الابن 18 · SHR/مشترك 1 (=73)

Parent-app rows total 86, of which **85 are active** (86 − FAT-039 tombstone) — exactly matching the sealed FAT 85 / CHD 37 / SHR 7 split.

---

## 4. Major modules (service domains)

| Domain | Purpose | Primary consumers |
|---|---|---|
| **ADM** | Account, family create, pairing, invites, devices, roles, billing/privacy shell | Father (owner); Mother (delegated); Child (pairing) |
| **SEC** | Screen time, schedules, locks, app control, web filter, location, SOS, geofence | Father sets; Mother by level; Child experiences |
| **COM** | Family chat, direct/subgroup, LiveKit calls, call log | All primary actors; never locked by time/subscription |
| **EDU** | Tasks, Quran, learning, challenges, minutes economy | Father assigns rewards; Child earns; Mother tasks ≠ minutes |
| **AIC** | Family Advisor, insights, tutor hooks, alerts | Suggest-only; Father approves; three gateway repos (Rule 26) |

Architecture maps these to feature folders `features/nXX_<system>/` (54 audited systems — detail in later phases).

---

## 5. Data & AI contracts (as-is)

**Schema (`schema.sql`) — 20 tables:**  
`account`, `family`, `member`, `child`, `invite`, `pairing_token`, `device`, `device_permission`, `device_health`, `mode_unlock_attempt`, `location_ping`, `geofence`, `geofence_event`, `sos_alert`, `conversation`, `message`, `call_log`, `ai_event`, `ai_suggestion`, `audit_log`

**Role CHECKs already match actor model intent:**
- `member_role`: `OWNER` | `PARENT` | `GUARDIAN` (Child is **not** a member row — separate `child` table)
- `guardian_is_observer`: GUARDIAN ⇒ OBSERVER only
- `owner_is_full`: OWNER ⇒ FULL
- Device modes: `PARENT` | `CHILD_LOCKED` | `CHILD_PREVIEW`

**AI:** `ai_suggestion` / `ai_event` tables support Rule 26 (Brain = backend; app = hooks). No execute path in product law.

**GAP_LOG / API_CONTRACT:** header-only scaffolds (0 rows). Phase 13/9 will extend, not fork.

---

## 6. Supporting systems already installed

| System | Path | Role in discovery |
|---|---|---|
| Cursor hooks | `.cursor/hooks.json` + 6 scripts | Enforce Rules 4/12/13/14/21/22 + MCP hygiene during later coding |
| Design tokens doc | `handoff/06_DESIGN_TOKENS.md` | F0 input — not extracted to Dart yet |
| Acceptance scenarios | `handoff/05_ACCEPTANCE_SCENARIOS.md` | 5 scenarios / 71 checks → future CI |
| Preflight | `handoff/10_PREFLIGHT_CHECKLIST.md` | Owner gates before F0 (FVM, fonts, branch protection, etc.) |
| Global gaps | `handoff/07_GLOBAL_GAPS.md` | 8 readiness gaps structurally closed in architecture |

---

## 7. CONFLICT-WITH-FROZEN register (inventory phase)

| ID | Conflict | Evidence | Action |
|---|---|---|---|
| **CWF-001** | Screen count 129 vs 130 | Tombstone `SCR-FAT-039` + Register §G-2 | **RESOLVED-BY-OWNER-AUDIT** (ADR-034): 129 active + 1 tombstone |
| **CWF-002** | START_HERE / root README still say **22** constitution rules | Files vs `01_CURSOR_CONSTITUTION.md` title **26** | Doc hygiene — constitution file wins; update START_HERE in a later owner-approved doc commit (out of discovery touch scope for `handoff/`) |
| **CWF-003** | Some product README rows still cite 71 journeys / 128 screens | Stale table vs CSV 73/130 rows | Flag only — do not overwrite registry |
| **CWF-004** | Registry still names **points / XP** as reward currency | `S-EDU-030` نقاط · `S-EDU-032` استبدال النقاط بوقت شاشة · `S-EDU-033` XP ومستويات + 5 screens + 2 journeys | Conflicts Rule 4 / Register **E-1** (minutes only). Register is supreme → registry naming is legacy. **REQUIRES PRODUCT DECISION** (ADR-036) |
| **CWF-005** | `S-EDU-036` «أقسام تنافسية» (competitive divisions) | Register **G-8**: no demotivating leaderboard | **REQUIRES PRODUCT DECISION** (ADR-037) |

Frozen product decisions (minutes-only, no OTP, one-app, AI suggests-never-acts, offline-first, SOS free forever, SCR-SHR-004 deleted) — **no conflict found**; treated as inputs.

---

## 8. Risks for later phases (not resolved here)

1. Mother has **journeys** but **no separate app column** in screens (uses الوالدان / FAT screens with RoleGuard) — phase 2 matrix must make this explicit.
2. Economy + PolicyEngine not coded yet — pure law.
3. Preflight A1–A5 (Flutter pin, fonts, branch protection, CI) still owner-action items before F0.
4. Workspace nesting (`family-os/family-os`) vs MCP/hooks path — operational risk for agents, not a product conflict.

---

## 9. Dependencies for phase 2+

- Actor model locked (Section A3) → drives `03-role-permission-matrix.md`
- Registry + Policy Register → drive service catalog (phase 3)
- Schema CHECKs → validate permissions model (no parallel schema)

**Next after owner checkpoint:** Phase 3 — service catalog (`04-service-catalog.md`).
