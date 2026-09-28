# FINAL USER EXPERIENCE VERIFICATION PLAN

**Date:** 2026-09-26  
**Type:** PLAN / DESIGN ONLY — no production code changes; no verification execution in this task.  
**Owner tester:** Bassam (physical devices). Cursor prepares artifacts and accepts Fail logs after Owner runs.  
**KEEP + REFINE:** Do not redesign. Judge the product as built against Policy Register + frozen prototype + Owner decisions.

---

## 0. Governance progress report

| Field | Value |
|---|---|
| CURRENT PHASE | Frontend closed; CE-B0→B5 COMPLETE; VX-B0…B7 PASSED; **STOP — await Owner authorize D-FINAL** |
| TASK PHASE | Pre–D-FINAL User Experience Verification Plan (docs only) |
| STATUS | **ALIGNED** — planning / documentation only |
| REQUIRED GATE | Owner says authorize D-FINAL (or equivalent) before phone execution begins |
| PRODUCTION CODE CHANGE | **NO** |
| Out of bounds | Native implementation, Backend, harness BACKLOG cards, `core/policy/`, unauthorized `tokens.dart` edits, redesign |

Companions (this folder):

1. `FINAL_USER_EXPERIENCE_TEST_MATRIX.md`
2. `FINAL_USER_EXPERIENCE_STEP_BY_STEP_CHECKLIST.md`
3. `FINAL_USER_EXPERIENCE_EXPECTED_RESULTS.md`
4. `FINAL_USER_EXPERIENCE_EVIDENCE_TEMPLATE.md`
5. `FINAL_USER_EXPERIENCE_COVERAGE_REPORT.md`

Authority inputs (do not invent beyond these):

| Source | Use |
|---|---|
| `FINAL_VISUAL_UX_JOURNEY_MATRIX.json` / `.md` | 145 surfaces, journeys, data sources, native/remote, findings |
| `family-os/_REGISTRY/journeys.csv` | 73 journeys (FAT 45 · MOT 9 · CHD 18 · SHR 1) |
| `family-os/_REGISTRY/screens.csv` | Catalog screen IDs |
| `FINAL_VISUAL_UX_JOURNEY_VERIFICATION_PROGRAM.md` | Visual/UX/honesty/state standards |
| `FINAL_VISUAL_UX_JOURNEY_FINDINGS.md` | FVX-* → remapping; D1–D12 / OD-13/14 |
| `FINAL_VISUAL_UX_JOURNEY_EXECUTION_PLAN.md` | Batch closures; D-FINAL position |
| `D_FINAL_OWNER_TEST_PLAN.md` | Device §13 sheet (nested inside Phase 2 here) |
| Policy Register + Constitution | Law; minutes; RoleGuard; SOS ungated; no fake AI execute |
| `AGENTS.md` / `PROJECT_EXECUTION_PLAN.md` | Phase / STOP markers |

---

## 1. Purpose

Determine whether the **actual end-user experience** of the complete Family OS frontend is:

- **Correct** — right role, family, child, screen, and effect  
- **Coherent** — same data/status across surfaces  
- **Usable** — hierarchy, targets, Back, keyboard, scroll  
- **Honest** — no fake success / sync / native / remote / AI  
- **Persistent** — Local-claimed data survives kill → relaunch  
- **Navigable** — journeys complete; wrong-role never lands in gallery  

Widget-test green ≠ UX PASS. Navigation success ≠ journey complete. Render ≠ capability real.

---

## 2. Inventory of truth (reconciled)

| Item | Count | Notes |
|---|---|---|
| Systems | **42** domain/subsystem pairs (services.csv); matrix groups them as ADM/SEC/COM/… labels | Plan covers both: Matrix §1 lists matrix groups; journeys map to services |
| Journeys | **73** | Father 45 · Mother 9 · Child 18 · Shared 1 |
| Catalog screens | **130** = 128 live + 2 OOS (FAT-039 tombstone; FAT-077 → FAT-075 per D11) | |
| Non-catalog surfaces | **15** | sys3 identity + `/gallery` (dev) |
| Total surfaces | **145** | All get SIP + VIS packs |
| Roles under test | Father / Primary · Wife / Co-Parent (level-limited) · Child · Shared | Mother cases use MOT journeys + Father invite path |
| Locales | Arabic RTL · English LTR | D1 |
| Devices | A ≤360 dp · B normal | §13 |
| Font | 1.0 default · 1.3 on system homes | |

---

## 3. Result classifications (only these)

| Code | Full name | When |
|---|---|---|
| **PASS** | PASS | Observable match + required evidence |
| **FAIL** | FAIL | Observable mismatch → log finding + Screen ID |
| **BLOCKED-NATIVE** | BLOCKED-NATIVE | Needs native; **honesty of closed UI must still PASS** |
| **BLOCKED-REMOTE** | BLOCKED-REMOTE | Needs backend; **honesty of closed UI must still PASS** |
| **OWNER-DECISION** | OWNER-DECISION | New ambiguity only (D1–D12 / OD-13/14 already answered — do not re-ask) |
| **NOT-APPLICABLE** | NOT-APPLICABLE | Criterion does not apply |

No scores, stars, or “mostly works.”

---

## 4. Execution phases (exact order)

Execute via `FINAL_USER_EXPERIENCE_STEP_BY_STEP_CHECKLIST.md`. Do not reorder unless a crash forces a Fail log and skip.

| Phase | Content | Case IDs |
|---|---|---|
| **0** | Prep: build install, Evidence header, start AR | — |
| **1** | Full application lifecycle | `UXV-LC-01`…`27` |
| **2** | Device §13 + D-FINAL nest + variants | `UXV-DEV-*` |
| **3** | All 73 journeys step-by-step | `UXV-JRN-<id>-Snn` |
| **4** | Every surface SIP + states + visual | `UXV-SCR-<id>-*` |
| **5** | Cross-screen + honesty + finding remap | `UXV-X-*` · `UXV-HON-*` · `UXV-FD-*` |
| **6** | Closeout: Fail log → Coverage questions → pack to Cursor | — |

---

## 5. Screen Interaction Protocol (SIP)

**Hard rule:** Do **not** invent buttons, tabs, FABs, or fields from memory or from “typical” apps. Only verify **controls that are actually visible** on the live surface (or clearly documented in Matrix `control_primary` / `control_secondary` and confirmed on screen).

For every surface `UXV-SCR-<SCR-ID>-SIP`:

### 5.1 Screen header (record once)

| Field | Capture |
|---|---|
| Screen title (ARB) | exact text |
| Route | e.g. `/scr-fat-010` |
| Role allowed | Matrix `rbac` / RoleGuard outcome |
| Origin journey(s) | Matrix `journeys` |
| Required family/child context | present / missing / wrong |
| Expected data source | Matrix `data_source` + honesty class |
| Starting state | empty / loading / populated / error / closed |

### 5.2 Control enumeration (live)

Walk the screen top→bottom, then fixed chrome (AppBar, FAB, bottom nav, sheets). For **each** interactive element observed, assign `UXV-SCR-<id>-CTL-<n>` and classify type:

button · card · list row · icon action · FAB · tab · switch · chip · dropdown · text field · search · checkbox/radio · dialog · bottom sheet · nav affordance · other

### 5.3 Nine-field action record (every CTL)

1. **Precondition** — role, family, child, prior data, locale, online/offline  
2. **Exact user action** — tap / long-press / type / swipe / Back  
3. **Expected UI response** — visible change (enabled, selection, sheet open…)  
4. **Expected data/state change** — repository / local store effect (or “none — display only”)  
5. **Expected navigation** — stay / push / pop / go / RoleGuard redirect  
6. **Expected feedback** — toast / banner / inline / none  
7. **What must NOT happen** — fake success, wrong child, crash, gallery land, silent no-op on primary CTA, jargon  
8. **Persistence expectation** — none / session / kill-relaunch / N-A  
9. **PASS/FAIL evidence** — screenshot ID + observed text + navigation note  

Canonical field meanings: `FINAL_USER_EXPERIENCE_EXPECTED_RESULTS.md` §2–§3.

### 5.4 Mandatory behaviors per screen (when present)

| Behavior | Check |
|---|---|
| Back | Drill-down uses stack return to origin (G-17); does not exit app mid-flow |
| Close / Cancel | Dismisses without unintended write |
| Save / Apply | Immediate UI + Local persistence when Local-claimed |
| Delete / Remove | Confirmation → effect → list updates |
| Confirmation | Destructive requires confirm |
| Loading | Shared loading state; no blank hang forever without indicator |
| Empty | Designed empty (not crash / not fake rows) |
| Error | Shared error + retry where applicable; no false “server” blame for local |
| Offline | Honest offline/local; no fake sync |
| Unavailable / NC / RC | Glossary honesty; preference may save; never claim enforcement/delivery |
| Success / failure feedback | Visible; not hidden under FAB |

### 5.5 State pack `UXV-SCR-<id>-ST-*`

Where Matrix `states` lists them, force or observe:

| Suffix | State |
|---|---|
| `E` | Empty |
| `L` | Loading |
| `Er` | Error |
| `Off` | Offline |
| `NC` | Native-closed honesty |
| `RC` | Remote-closed honesty |
| `1` / `M` | One item / many |

### 5.6 Visual pack `UXV-SCR-<id>-VIS`

On relevant screens (all system homes; any FAIL candidate; maps; forms; sheets):

hierarchy · readability · typography · spacing · alignment · RTL/LTR · icons · chevrons · cards · buttons · touch ≥48dp · clipping · overflow · keyboard · scrolling · fixed elements · FAB · bottom nav · dialogs · sheets · feedback · contrast · responsive (A/B widths)

Variants: AR RTL · EN LTR · font 1.0 · font 1.3 (homes) · Device A / B as scheduled.

---

## 6. Journey-first method

For each journey `JRN-*` in Matrix + `journeys.csv`:

| Field | Source |
|---|---|
| Journey ID / name | CSV |
| User role | CSV `user` (الأب / الأم / الابن / مشترك) |
| Starting state | Phase 1 / journey trigger |
| Entry point | First screen entry in Matrix |
| Steps | One checklist row per screen in journey order |
| Expected after each step | Purpose + exit of that screen |
| Screen reached | Screen ID |
| Data/state changes | Matrix data_source + Local claims |
| Exit condition | Goal from CSV |
| Failure / edge branches | Er / Off / NC / RC / RoleGuard |
| Persistence checkpoint | If mutate → kill → relaunch → related screens |
| Related screens / systems | Matrix |
| Related tests / evidence | Matrix `evidence` column (automated support only) |

**Traceability:** every live catalog screen must appear in ≥1 journey **or** be covered by Phase 4 SIP (Coverage Report lists orphans if any).

Father↔child loops (time approve, chat, SOS, friend/app approval): verify both sides in the same session when both roles available on device (SHR-008).

---

## 7. Full application lifecycle (`UXV-LC-*`)

| ID | Flow | Pass when |
|---|---|---|
| LC-01 | First / cold launch | Welcome or honest session restore; no debug toast |
| LC-02 | Fresh install empty DB | Empty family / empty chat seed rules (OD-09: threads from roster, no mock messages) |
| LC-03 | Existing local data relaunch | Roster/chat/tasks/settings persist |
| LC-04 | Authenticated session | Father → Today; Child → My Day |
| LC-05 | Session expired / recovery | sys3 recovery surfaces honest |
| LC-06 | Role father | FAT-010 |
| LC-07 | Role mother | Today + level-limited controls |
| LC-08 | Role child | CHD-004 |
| LC-09 | Family select/switch | Correct family scope everywhere |
| LC-10 | Child select/switch | Active child consistent |
| LC-11 | AR→EN | Labels + LTR |
| LC-12 | EN→AR | Labels + RTL |
| LC-13 / 14 | RTL↔LTR chrome | FABs/chevrons directional |
| LC-15 | Offline start | Honest local/offline |
| LC-16 | Online→offline | No fake sync success |
| LC-17 | Offline→online | No false delivered claims |
| LC-18 | Kill→relaunch | Persistence of Local mutations |
| LC-19 | Back chains | Push stack integrity |
| LC-20 | Repeated open/close | Sheets/dialogs clean |
| LC-21…24 | Empty / populated / loading / error | Shared components |
| LC-25…27 | NC / RC / local-only honesty | Glossary; no jargon |

---

## 8. Data & state verification chain

For every mutating operation:

**Before → Action → Immediate UI → Screen result → Stored result → Relaunch result → Related screen result**

Watch especially:

active child · family · identity/name · SQLite / Local KV · settings · tasks · calendar · location · safe zones · screen time · app rules · SOS · reports · chat · Quran · education · device · alerts · audit/events

**Must detect:** wrong-child · wrong-family · stale UI · demo presented as real · non-persistent Local claim · fake/demo without LOCAL_DEMO banner.

---

## 9. Cross-screen consistency (`UXV-X-*`)

Same person, child, family, status, setting, and name must match across Today / Kids / Profile / Chat / Alerts / Education / SOS subject. See Matrix §6.

---

## 10. Capability honesty (`UXV-HON-*`)

Never PASS a capability because the screen renders. Explicitly FAIL:

fake success · fake delivery · fake sync · fake AI execute · fake native enforcement · fake remote · technical jargon in user AR/EN · mock as real

Billing must never gate SOS / family chat / location (Constitution).

---

## 11. Finding remapping

Every FVX-* (and local-reality / N-*) listed in the Matrix maps to `UXV-FD-<finding>`. CLOSED code findings still need **device confirmation** where marked PENDING-DEVICE. New defects get new FVX-R / UXV IDs — do not silently absorb into PASS.

---

## 12. Roles

| Role | How to obtain | Focus |
|---|---|---|
| Father / Primary | Login / create family | All FAT journeys; invite; billing parent-only; audit owner-only |
| Wife / Co-Parent | Invite accept (MOT-01) + level | MOT journeys; level-limited controls; SOS ungated |
| Child | Device mode / SHR-008 | CHD journeys; transparency; SOS; chat; minutes |

Wrong role → RoleGuard → **role home + polite toast** (D4); never gallery.

---

## 13. Device & visual variants

| Variant | Cases |
|---|---|
| Device A ≤360 dp | `UXV-DEV-A-*` |
| Device B normal | `UXV-DEV-B-*` |
| Arabic RTL | `UXV-DEV-AR` + journey AR runs |
| English LTR | `UXV-DEV-EN` |
| Font 1.0 / 1.3 | `UXV-DEV-F10` / `F13` |

Nest `D_FINAL_OWNER_TEST_PLAN.md` inside Phase 2; do not duplicate conflicting instructions — this plan is the master order; D-FINAL sheet is the device report form.

---

## 14. Flutter / automated support (Owner-run; focused)

Automated tests **support** evidence; they do **not** replace SIP or device journeys.

| Gate | When | Command (Owner runs) |
|---|---|---|
| Analyze | Before D-FINAL session | `cd app && flutter analyze` |
| System homes render | Visual smoke | `cd app && flutter test test/goldens/vx_b7_system_homes_render_test.dart` |
| Scoped regressions | After Fail fixes only | targeted `flutter test <path>` named in Fail log |
| Full suite | Certification / end-of-program only | `cd app && flutter test` then `python .cursor/hooks/verify_ship.py verify --full` |

No large suite mid-checklist unless Certification gate.

---

## 15. Evidence requirements

Every case needs the evidence type listed in the Evidence Template:

screenshot · observed text/state · navigation result · data observation · restart confirmation · device info

Store under Owner’s session folder (phone gallery + notes). Case IDs must match Matrix.

---

## 16. What this plan deliberately does **not** do

- Redesign UI or invent screens/journeys/controls  
- Implement Native or Backend  
- Treat mock-bound Advisor/Insights as live AI  
- Mark BN/BR criteria PASS for enforcement — only honesty PASS  
- Replace D-FINAL Owner device authority with Cursor automation  

---

## 17. Exit criteria (plan complete when executed)

The UX of the frontend is **certified ready for D-FINAL close** only when:

1. All 73 journeys classified  
2. All 145 surfaces SIP+VIS classified  
3. Lifecycle + device variants classified  
4. Cross-screen + honesty + findings remapped classified  
5. Fail log empty **or** accepted residual list with OWNER disposition  
6. Coverage Report questions all YES (or explicit documented gap)

**STOP after planning:** execution waits for Owner “authorize D-FINAL” / “go”.

---

## 18. Traceability chain (mandatory)

```
System → Journey → Screen → Interactive element (CTL-n) → Action
  → Expected UI → Expected state/data → Evidence → PASS|FAIL|BN|BR|OD|NA
```

Coverage Report proves this chain is complete for the known inventory.
