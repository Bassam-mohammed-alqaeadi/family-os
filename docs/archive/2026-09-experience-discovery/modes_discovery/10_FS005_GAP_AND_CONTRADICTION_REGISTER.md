# 10 — FS-005 Gap and Contradiction Register

**Mode:** Explicit gaps and contradictions. No silent resolution.  
**Master:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

---

## A. Contradictions

| ID | Conflict | Left | Right | Disposition |
|---|---|---|---|---|
| **MODE-C-01** | Lifestyle schedule ownership | Sibling L2: FS-005 owns scheduling | Stage-1: ST `ScheduleWindow` sets `modeActive` | **OPEN** Q-MODE-08 |
| **MODE-C-02** | Single vs multi active | Flutter/proto single `activeId` | Register M-B + `ModeConflictResolver` for two modes | **OPEN** Q-MODE-05 |
| **MODE-C-03** | Tighten vs loosen | FS-002/003 L2 tighten-only | Prototype vacation widens allow list | **OPEN** Q-MODE-07 |
| **MODE-C-04** | Catalog id | Register/Flutter `exams` | Prototype list `famtime` (exams elsewhere in proto) | **OPEN** Q-MODE-03 |
| **MODE-C-05** | School auto-location | S-SEC-059 hosted on FAT-085 (copy) | No geofence→activate implementation | Gap + honesty |
| **MODE-C-06** | Custom modes | Register “create your own” | Proto toast; Flutter switch-only | Gap |
| **MODE-C-07** | Family scope | Proto `kids[]` multi | Prefs per single `childId` | **OPEN** Q-MODE-01 |
| **MODE-C-08** | AuthZ | Eng doc Primary+Full | FAT-085 ungated | **OPEN** Q-MODE-02 |
| **MODE-C-09** | Schema name | Lifestyle `FamilyMode` expected | SQL has `device_mode` only | Gap / naming |
| **MODE-C-10** | Grace UX | Register M-D + proto child banner | Domain only in Flutter; child clear grace in proto = GAP-A-CHILD-015 | **OPEN** Q-MODE-10 |
| **MODE-C-11** | Sync buses | Modes lean activation bus | ST `PolicySyncBus` separate | **OPEN** T-MODE-04 |
| **MODE-C-12** | Allow lists | Register property #4 | Not on `SmartModeRow`; not fed from FAT-034 | Gap |

---

## B. Gaps (priority-ish)

| ID | Gap | Severity |
|---|---|---|
| **MODE-GAP-01** | No clock auto-activation for school times | High |
| **MODE-GAP-02** | No durable FamilyMode persistence / schema | High |
| **MODE-GAP-03** | No mode allow-list / exception stores | High |
| **MODE-GAP-04** | No RoleGuard / AuthZ matrix on FAT-085 | High |
| **MODE-GAP-05** | No audit events for activate/deactivate | Medium |
| **MODE-GAP-06** | No conflict father notification | Medium |
| **MODE-GAP-07** | No GrantOnModeStart UI | Medium |
| **MODE-GAP-08** | No FS-002/003/004 mode context emitters | Medium |
| **MODE-GAP-09** | No geofence handoff (consume FS-001 fact) | Medium |
| **MODE-GAP-10** | No device ack / multi-device | Medium |
| **MODE-GAP-11** | No seasonal date-range model | Low–Med |
| **MODE-GAP-12** | No OS enforcement / Focus | High (honesty) |
| **MODE-GAP-13** | Preview-before-apply (registry) absent | Low |
| **MODE-GAP-14** | Driving mode (P-10) not in catalog | Low (scope) |

---

## C. Fake / simulated behaviors (must stay labeled)

| Behavior | Label |
|---|---|
| FAT-085 activation as device-wide Focus | **SIMULATED** |
| In-memory prefs as family sync | **MOCK** |
| S-SEC-059 location auto | **DOCUMENTED ONLY** |
| Prototype custom builder CTA | **MOCK** |
| CHD-004 tint as enforcement | **UI only** |

---

## D. Owner questions (product)

| ID | Question |
|---|---|
| **Q-MODE-01** | Mode scope: family-wide, per-child, or both (with which default)? |
| **Q-MODE-02** | Who may configure Modes? Primary only vs Primary + Co-Parent Full vs other? |
| **Q-MODE-03** | Built-in catalog: keep Register 6+custom; adopt/reject `famtime`; confirm `exams`? |
| **Q-MODE-04** | Are parent-created custom modes in v1? |
| **Q-MODE-05** | Stacking: single active only, or multi-mode with M-B intersect? |
| **Q-MODE-06** | When ST ScheduleWindow and Modes disagree, which wins / how does Kernel merge? |
| **Q-MODE-07** | Tighten-only always, or may Modes loosen relative to baseline (vacation)? |
| **Q-MODE-08** | Scheduling ownership: Modes absorbs S1, ST keeps calendars as facts, or dual — **do not freeze in Discovery** |
| **Q-MODE-09** | Activation channels in v1: manual / clock / geofence / seasonal — which set? |
| **Q-MODE-10** | Child visibility + grace: may child end grace? What does child see? |
| **Q-MODE-11** | Exception model: ModeException vs App Access Exception vs Temporary Grant boundaries for Modes UI |
| **Q-MODE-12** | Which planes may Modes overlay in v1: apps / web / location-context / screen-camera? |
| **Q-MODE-13** | Co-Parent: activate-only vs configure vs neither? |
| **Q-MODE-14** | Confirm SOS/chat/Quran copy under active Mode (reachability already frozen)? |

---

## E. Technical questions (platform / sync)

| ID | Question |
|---|---|
| **T-MODE-01** | One schedule evaluator vs multiple competing producers? |
| **T-MODE-02** | Android/iOS wake / Focus / alarms — verification only; no product pick here |
| **T-MODE-03** | Drift/SQL shape for FamilyMode (absent today) |
| **T-MODE-04** | Merge activation into PolicySyncBus vs dedicated Modes outbox? |
| **T-MODE-05** | Device ack + stale TTL parameters (values not invented) |
| **T-MODE-06** | Grace countdown delivery channel |
| **T-MODE-07** | FS-001 → Modes “at school” fact handoff |
| **T-MODE-08** | Typed Kernel mode-context fact without rewriting FS-002/003 stores |
| **T-MODE-09** | M-B conflict notification pipeline |
| **T-MODE-10** | Audit event type catalog for Modes |

**No mechanisms selected. No TTLs invented. No ownership silently frozen.**
