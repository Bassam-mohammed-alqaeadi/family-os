# 01 — FS-004 L2 Owner Decisions Register

**System:** FS-004 Screen & Camera Control  
**Status:** **OWNER DECISIONS FROZEN** — 2026-09-24  
**Evidence baseline:** `docs/experience_discovery/screen_camera_discovery/` (CURRENT only — **non-authority**)  
**Target AuthZ vocabulary:** Primary Parent · Co-Parent (Observer / Partner / Full) · Child  
**Legacy Father/Mother · FAT-065 mock · FAT-034 camera slug:** evidence only — **not** target law  

**Entry:** [11_FS004_L2_MASTER_CONTRACT.md](11_FS004_L2_MASTER_CONTRACT.md) · [10_FS004_DECISION_CLOSURE_REPORT.md](10_FS004_DECISION_CLOSURE_REPORT.md)

```
FS-004 DISCOVERY: COMPLETE
FS-004 L2 POLICY: COMPLETE
OWNER DECISIONS: FROZEN
FS-004 L3: READY
IMPLEMENTATION: NOT AUTHORIZED
```

---

## A. Structural freezes (global / cross-system) — FROZEN

| ID | Frozen structural law | Source |
|---|---|---|
| **SC-SF-01** | Vocabulary: **Primary Parent · Co-Parent · Child** | Identity / WF-SF-09 / APP-SF-01 |
| **SC-SF-02** | AuthZ = **RBAC**; **never** device-possession / Device Owner inference | SOS · WF-SF-05 · APP-SF-02 |
| **SC-SF-03** | Primary ≠ Co-Parent Full for owner-only / sensitive export classes by default | WF-SF-06 · APP-SF-03 |
| **SC-SF-04** | **SOS remains governed by SOS Final.** FS-004 invents **no** SOS microphone/audio broadcast. P-4 Register audio wording is **superseded**. | SOS Final · **SC-OD-08** |
| **SC-SF-05** | **Microphone / Domain-1 ambient recording / generic mic parental block = OUT of FS-004** | **SC-OD-05** |
| **SC-SF-06** | Offline honesty: no fake cloud success; **`enforced` only** with acked policy + verified plane | Offline-first · WF-SF-04 · APP-SF-09 |
| **SC-SF-07** | Never claim camera/screen protection when plane is `unsupported` / `unknown` / `unavailable` / unverified | WF-SF-10 · APP-SF-10 · **SC-OD-04/06** |
| **SC-SF-08** | Audit append-only; AI suggests, never executes without authorized approval | Constitution |
| **SC-SF-09** | Domain emits **facts**; **Policy Kernel** interprets → notify/action | Kernel boundary |
| **SC-SF-10** | FS-005 Modes owns **scheduling**; FS-004 creates **no** second scheduler | FS-002/003 · mandatory rule 1 |
| **SC-SF-11** | Modes may **tighten** FS-004 restrictions; must **not** silently weaken or permanently remove them | Mandatory rule 2 |
| **SC-SF-12** | FS-003 package Allow/Block ≠ FS-004 hardware/OS camera control — separate planes | **SC-OD-02** |
| **SC-SF-13** | Screen Time minutes / budgets / grants / Unlimited **outside** FS-004 | ST Final · APP-OD-12 |
| **SC-SF-14** | Web Filter remains URL-plane; no silent cross-system mutation | WF-OD-12 spirit · mandatory 5–6 |
| **SC-SF-15** | Capture monitoring is **configured + child-transparent**; **no** silent full-device / full open-app surveillance by default | **SC-OD-01/10** · APP-OD-16 spirit |
| **SC-SF-16** | Stage-1 mocks (FakeCamera, FAT-065 toggle, FAT-034 camera slug) = **non-authority** | Discovery |
| **SC-SF-17** | Family OS essential camera workflows and emergency reachability protected via **explicit exception / protected matrix** — not silent bypass | **SC-OD-07** |
| **SC-SF-18** | iOS = capability honesty; no false Android-equivalent claims without verification | **SC-OD-06** |

---

## B. Owner / Product freezes (ED 2026-09-24)

| ID | Q | Choice | Frozen law |
|---|---|---|---|
| **SC-OD-01** | Q-SC-01 | **Combo** | Scope = **Prevent + Monitor + Protect**. Owns: parental camera control; screenshot/screen-recording control where supportable; configured screenshot monitoring; protection of Family OS sensitive surfaces. Monitoring must be **explicitly configured and child-transparent**. No silent full-device surveillance. |
| **SC-OD-02** | Q-SC-02 | **OS + FS-003 split** | Camera control = **OS/device-level policy**; package control remains **FS-003**. Planes separate. Blocking Camera **package** ≠ disabling hardware/OS camera. |
| **SC-OD-03** | Q-SC-03 | **Both** | Screen control = **prevention + monitoring**. Support capture prevention where platform can enforce; configured screenshot monitoring where platform can provide. **No** implication of universal third-party screenshot/recording blocking. |
| **SC-OD-04** | Q-SC-04 | **Hybrid honesty** | Product intent may require device-level camera restriction; **mechanism = T-SC verification**. Do **not** freeze DO / AppOps / Accessibility / VPN / MediaProjection as product mechanism. Honesty states: `enforced` · `degraded` · `pending_policy` · `unavailable` · `unsupported` · `unknown` · `disabled_by_permission`. Never claim success without **acked policy + verified capability**. |
| **SC-OD-05** | Q-SC-05 | **OUT** | **Microphone OUT of FS-004.** No Domain-1 ambient/surround recording; no generic mic parental blocking; no new FS-004 mic subsystem. |
| **SC-OD-06** | Q-SC-06 | **Honesty** | iOS = capability-based honesty. Intent platform-neutral where meaningful; unsupported controls surface honestly. No Android-equivalent promise without proof. |
| **SC-OD-07** | Q-SC-07 | **Matrix** | Safety / Family OS exceptions = **explicit protected matrix**. Never make emergency access unreachable. Protect essential Family OS camera use: QR/enrollment; approved Family OS camera workflows; Family OS call camera where feature requires it. Quran unaffected (ordinary required path not FS-004-controlled). SOS per SOS Final only. Exceptions are **explicit policy**, not silent bypasses. |
| **SC-OD-08** | Q-SC-08 | **SOS Final** | **Follow SOS Final: no SOS audio.** FS-004 has **no** SOS mic/audio broadcast. P-4 audio superseded. |
| **SC-OD-09** | Q-SC-09 | **FS-004 owns P-7** | **P-7 screenshot monitoring owned by FS-004.** Smart Alerts / FAT-065 may be presentation/entry/notification surface only. FS-004 owns policy/domain semantics. Smart Alerts must **not** own a second screenshot-monitoring policy. **No duplicate configuration source.** |
| **SC-OD-10** | Q-SC-10 | **Mandatory** | Child transparency **mandatory** when monitoring active. Persistent/clear enough for trust model. No silent screenshot surveillance. No child admin controls. |
| **SC-OD-11** | Q-SC-11 | **Align FS-002/003** | Configure: **Primary + Full**. Exception / monitoring-related request decide (where applicable): **Primary + Partner + Full**. Observer: **view-only**. Child: **no configure**; transparency + permitted status only. Never AuthZ from device possession. |
| **SC-OD-12** | Q-SC-12 | **Baseline+override** | **Family baseline + per-child override**; child override wins. Enforcement state child-scoped; multi-device via offline-first architecture. |

---

## C. Q-SC closure map

| Q-ID | Status | Maps to |
|---|---|---|
| Q-SC-01 … Q-SC-12 | **CLOSED** | SC-OD-01 … SC-OD-12 |

**Owner/Product decisions remaining:** **NONE**

---

## D. Technical / Platform still OPEN (T-SC-01…12)

| ID | Topic | Frozen product side | Open |
|---|---|---|---|
| **T-SC-01** | Camera enforcement plane | Hybrid law SC-OD-04 | DO / AppOps / other after verification |
| **T-SC-02** | Screenshot **prevention** feasibility | Prevention where enforceable SC-OD-03 | FLAG_SECURE vs third-party limits |
| **T-SC-03** | Screen recording detect/prevent | Honesty SC-OD-03/04 | MediaProjection etc. after verification |
| **T-SC-04** | P-7 screenshot-on-open agent | FS-004 owns policy SC-OD-09 | Agent implementation |
| **T-SC-05** | Persist monitoring app scope / picker | Domain owns config SC-OD-09 | Schema/storage |
| **T-SC-06** | Extend `perm_key` | Honesty / health | CAMERA / SCREEN_CAPTURE keys? |
| **T-SC-07** | MonitoringFeature / transparency sync | SC-OD-10 mandatory transparency | Implementation mapping |
| **T-SC-08** | Tamper permission-disable scope | Anti-tamper adjacent | Which perms alert |
| **T-SC-09** | Real camera plugins vs OS camera restrict | Protected matrix SC-OD-07 | Conflict resolution UX/tech |
| **T-SC-10** | OEM / restricted-permission honesty | SC-OD-04/06 | Matrix content |
| **T-SC-11** | Ack / stale TTL / sync algorithms | SC-SF-06 | Numbers / algorithms |
| **T-SC-12** | iOS FamilyControls / equivalents | SC-OD-06 | Feasibility proof |

**No invented TTLs, durations, schemas, or API selections.**

---

## E. Explicit non-adoptions

| Non-adoption |
|---|
| Silent full-device / open-app surveillance |
| Mic / ambient Domain-1 inside FS-004 |
| SOS audio under FS-004 |
| Package Block = hardware camera off |
| Universal third-party screenshot block claim |
| Hard-coded DO / Accessibility / MediaProjection as product mechanism |
| Second FS-004 scheduler |
| Duplicate screenshot policy in Smart Alerts |
| Stage-1 FAT-065 toggle as enforcement proof |
| AuthZ from device holding |
| Invented technical values |

---

## F. Separation laws (normative — FROZEN)

| A | B |
|---|---|
| **FS-004 OS/device camera policy** | **FS-003 Camera package Allow/Block** |
| **Capture prevention** (where enforceable) | **Configured capture monitoring** (transparent) |
| **Family OS surface protection** (e.g. sensitive UI) | **Third-party app capture block** (not universally claimed) |
| **FS-004** | **Microphone / SOS audio / Domain-1 ambient** (OUT) |
