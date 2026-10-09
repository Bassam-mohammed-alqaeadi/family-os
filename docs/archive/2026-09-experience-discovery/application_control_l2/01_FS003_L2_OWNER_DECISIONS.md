# 01 — FS-003 L2 Owner Decisions Register

**System:** FS-003 Application & System Control  
**Status:** **OWNER DECISIONS FROZEN** — 2026-09-24  
**Evidence baseline:** `docs/experience_discovery/application_control_discovery/` (CURRENT only — **non-authority**)  
**Target AuthZ vocabulary:** Primary Parent · Co-Parent (Observer / Partner / Full) · Child  
**Legacy Father/Mother Stage-1 · FAT-034/035 · slug mocks:** evidence only — **not** target law  

**Entry:** [11_FS003_L2_MASTER_CONTRACT.md](11_FS003_L2_MASTER_CONTRACT.md) · [10_FS003_DECISION_CLOSURE_REPORT.md](10_FS003_DECISION_CLOSURE_REPORT.md)

```
FS-003 DISCOVERY: COMPLETE
FS-003 L2 POLICY: COMPLETE
OWNER DECISIONS: FROZEN
FS-003 L3: READY
IMPLEMENTATION: NOT AUTHORIZED
```

---

## A. Structural freezes (global / cross-system) — FROZEN

| ID | Frozen structural law | Source |
|---|---|---|
| **APP-SF-01** | Vocabulary: **Primary Parent · Co-Parent · Child** (not Stage-1 Father/Mother as target labels) | Global Identity / WF-SF-09 |
| **APP-SF-02** | AuthZ = **RBAC** (role + Co-Parent level). **Never** infer authority from device possession / Device Owner | SOS Q-SOS-RD-02A · WF-SF-05 |
| **APP-SF-03** | **Primary ≠ Co-Parent Full** for owner-only / sensitive classes by default | WF-SF-06 |
| **APP-SF-04** | **SOS / Required Family Chat / Quran remain reachable and cannot be denied by App Control.** Family OS itself is likewise protected. | Constitution · SOS Final · WF-SF-02 · ST P0 · **APP-OD-09** |
| **APP-SF-05** | **Permanent App Block** is never opened by Minutes, Temporary Grant, Unlimited, or wallets (**Ruling A** / ST **P2**) | Policy Register · ST Precedence Final |
| **APP-SF-06** | **ST Unlimited** bypasses **daily entertainment cap only** — never permanent block, Instant Lock, hard Mode/schedule, or App Access Exception semantics | ST-OD-010 · **APP-OD-12** |
| **APP-SF-07** | **App Access Exception ≠ Temporary Grant ≠ ST Unlimited.** Temporary Grant is Screen Time **minutes** only (child-wide, ST-ADD-001). | ST Final · **APP-OD-06** |
| **APP-SF-08** | App Control ∩ Web Filter = **stricter intersection**; clear **source-of-deny**; no silent cross-system mutation | **WF-OD-12** |
| **APP-SF-09** | Offline honesty: no fake cloud success; **`enforced` only** with acknowledged policy + verified capability plane | Offline-first · WF-SF-04 analog |
| **APP-SF-10** | Never claim package blocking / install governance where capability plane is unavailable / unsupported / unknown | WF-SF-10 analog · **APP-OD-14** |
| **APP-SF-11** | Audit = **append-only**; AI suggests, never executes without authorized approval | Constitution · WF-SF-07/08 |
| **APP-SF-12** | Domain emits **facts**; **Policy Kernel** interprets → notify / action; FS-003 does not own Kernel | Kernel boundary |
| **APP-SF-13** | Stage-1 FAT-034 Partner-edit, slug inventory, prefs-only sync, mock FAT-035, anti-tamper UI = **non-authority** | Discovery Master |
| **APP-SF-14** | Screen Time owns: daily entertainment budget, Temporary Grant (minutes), earned wallets, **Limit / Unlimited / Countable** semantics and authorship (S-1), child-level multi-device budget (ST-OD-001) | ST Final · **APP-OD-12** |
| **APP-SF-15** | Instant Device Lock is **P1** — distinct from Permanent Block (**P2**) and from per-app **Lock Now** overlay (**APP-OD-13**) | ST Precedence · **APP-OD-13** |
| **APP-SF-16** | **App Access Exception** is a **temporary evaluation override**; it does **not** delete or rewrite the underlying Permanent Block policy | **APP-OD-06** |
| **APP-SF-17** | **App Access Exempt ≠ ST Unlimited.** Exempt does not bypass Instant Device Lock, SOS rules, or unrelated higher-priority layers | **APP-OD-12** |
| **APP-SF-18** | FS-005 Modes owns scheduling; FS-003 creates **no** second scheduler; Modes are **tighten-only** and **cannot reopen Permanent Block** | **APP-OD-10** · **APP-OD-11** |

---

## B. Owner / Product freezes (ED 2026-09-24)

| ID | Q | Choice | Frozen law |
|---|---|---|---|
| **APP-OD-01** | Q-APP-01 | **C** | **Family baseline + optional per-child override.** Child override wins when present. |
| **APP-OD-02** | Q-APP-02 | **B** | Configure App Control policy: **Primary + Co-Parent Full** only. Partner/Observer **cannot** configure. **Do not** inherit Stage-1 Partner-edit. |
| **APP-OD-03** | Q-APP-03 | **B** | Set Permanent Block: **Primary + Co-Parent Full** only. |
| **APP-OD-04** | Q-APP-04 | **A** | Reopen / clear Permanent Block: **Primary only**. |
| **APP-OD-05** | Q-APP-05 | **C** | Approve/deny new installs: **Primary + Partner + Full**. Observer **cannot**. |
| **APP-OD-06** | Q-APP-06 | **B** | **App Access Exception is ENABLED** (timed package access override; distinct from ST Temporary Grant and ST Unlimited). |
| **APP-OD-07** | Q-APP-07 | **B** | Approve/deny App Access Exceptions: **Primary + Partner + Full**. Observer **cannot**. |
| **APP-OD-08** | Q-APP-08 | **A** | Unknown/new package default = **Deny-until-approved** when no applicable class default exists. |
| **APP-OD-09** | Q-APP-09 | **A+matrix** | Protected (cannot be denied by App Control): **SOS, Family OS, Required Family Chat, Quran**. Other system/OEM packages follow an explicit protected/controllable matrix (content of non-core matrix rows = technical/content follow-up; core four are frozen protected). |
| **APP-OD-10** | Q-APP-10 | **A** | **FS-005 Modes owns scheduling.** FS-003 must **not** create a second scheduler. |
| **APP-OD-11** | Q-APP-11 | **A** | Modes are **tighten-only**. Modes **cannot** reopen Permanent Block. |
| **APP-OD-12** | Q-APP-12 | **A** | **Screen Time** owns Limit / Unlimited / Countable semantics and authorship. **FS-003 owns package access only** (Allow / Block / Exempt / Lock Now / Install / Exception overlays). |
| **APP-OD-13** | Q-APP-13 | **B** | Per-app **Lock Now** is **enabled** as a temporary deny overlay — separate from Permanent Block and Instant Device Lock. |
| **APP-OD-14** | Q-APP-14 | **A** | Product law = **Hybrid verified enforcement plane**. Do **not** freeze Device Owner, Accessibility, VPN, etc. as the product mechanism. Mechanisms remain **T-APP** verification items. |
| **APP-OD-15** | Q-APP-15 | **A** | **Anti-tamper** remains a **separate subsystem**. FS-003 consumes capability/integrity facts; does **not** own uninstall/management-removal resistance. |
| **APP-OD-16** | Q-APP-16 | **B** | Audit: policy mutations + install decisions + exceptions + **relevant deny events** + enforcement-state transitions. **Do not** enable full foreground/open-app surveillance as default. |
| **APP-OD-17** | Q-APP-17 | **extended A** | Child sees only: deny/pending status, general reason/disclosure, and Exception Request (enabled). **No admin surface.** |
| **APP-OD-18** | Q-APP-18 | **A** | Install approval is **child-scoped by default**. Do **not** silently create family-wide approval. |
| **APP-OD-19** | Q-APP-19 | **C-constrained** | Restore Baseline clears **child overrides** and **temporary overlays** (exceptions, Lock Now, pending holds as applicable) per baseline model; **does not** erase/reopen Permanent Block unless authorized through **APP-OD-04** (Primary). |
| **APP-OD-20** | Q-APP-20 | **A** | Observer = **view-only**: status, honesty, policy summary; **no** mutation and **no** decision authority. |

---

## C. Q-APP closure map

| Q-ID | Status | Maps to |
|---|---|---|
| Q-APP-01 | **CLOSED** | APP-OD-01 |
| Q-APP-02 | **CLOSED** | APP-OD-02 |
| Q-APP-03 | **CLOSED** | APP-OD-03 |
| Q-APP-04 | **CLOSED** | APP-OD-04 |
| Q-APP-05 | **CLOSED** | APP-OD-05 |
| Q-APP-06 | **CLOSED** | APP-OD-06 |
| Q-APP-07 | **CLOSED** | APP-OD-07 |
| Q-APP-08 | **CLOSED** | APP-OD-08 |
| Q-APP-09 | **CLOSED** | APP-OD-09 |
| Q-APP-10 | **CLOSED** | APP-OD-10 |
| Q-APP-11 | **CLOSED** | APP-OD-11 |
| Q-APP-12 | **CLOSED** | APP-OD-12 |
| Q-APP-13 | **CLOSED** | APP-OD-13 |
| Q-APP-14 | **CLOSED** | APP-OD-14 |
| Q-APP-15 | **CLOSED** | APP-OD-15 |
| Q-APP-16 | **CLOSED** | APP-OD-16 |
| Q-APP-17 | **CLOSED** | APP-OD-17 |
| Q-APP-18 | **CLOSED** | APP-OD-18 |
| Q-APP-19 | **CLOSED** | APP-OD-19 |
| Q-APP-20 | **CLOSED** | APP-OD-20 |

**Owner/Product decisions remaining:** **NONE**  
**Silent closures:** **NONE** — all closed by explicit Owner freeze above.

---

## D. Technical / Platform still OPEN (no invented numbers)

| ID | Topic | Frozen product side | Open parameter |
|---|---|---|---|
| **T-APP-01** | Package discovery implementation | Package ID identity (contract 05) | Exact PackageManager / OEM APIs |
| **T-APP-02** | On-device enforcement mechanism(s) | Hybrid law (APP-OD-14) | DO / PO / Accessibility / UsageStats / hide / other **after verification** |
| **T-APP-03** | Launch interception feasibility | Honesty states required | Mechanism + residual bypass classes |
| **T-APP-04** | Policy ack / stale TTL | APP-SF-09 | Exact TTL values |
| **T-APP-05** | Sync / conflict algorithms | Outbox + ack | Batching, conflict resolution |
| **T-APP-06** | Exception / Lock Now / pending durations | Timed overlays (APP-OD-06/13) | Exact minutes/hours |
| **T-APP-07** | Multi-package → product grouping | Package ID remains key | Taxonomy / metadata source |
| **T-APP-08** | System/OEM controllable matrix rows beyond core protected four | APP-OD-09 core protected set | Full matrix content / OEM lists |
| **T-APP-09** | Reboot / force-stop recovery hooks | Must restore last-acked policy | Implementation hooks |
| **T-APP-10** | Notification delivery channel | Domain emits events | FCM vs local — not claimed until proven |

---

## E. Explicit non-adoptions (still)

| Non-adoption |
|---|
| Stage-1 Father/Mother Partner-edit as target AuthZ |
| Mock slug IDs as policy identity |
| Mock FAT-035 as final UX law |
| Temporary Grant as app unlock |
| App Access Exception rewriting Permanent Block |
| FS-003 authorship of Limit / Unlimited / Countable |
| Second scheduler inside FS-003 |
| Modes reopening Permanent Block |
| Hard-coded DO / Accessibility / VPN as product mechanism |
| Full open-app surveillance as default |
| Silent family-wide install approval |
| AuthZ from device possession |
| Anti-tamper owned by FS-003 |

---

## F. Separation laws (normative — FROZEN)

| A | B | C |
|---|---|---|
| **App Access Exception** | **Temporary Grant (ST)** | **ST Unlimited** |
| Timed evaluation override for a **package** | Extra **minutes** today (child-wide) | Bypass **daily entertainment cap only** |
| Does **not** delete Permanent Block (APP-SF-16) | Never opens Permanent Block (APP-SF-05) | Never opens Permanent Block (APP-SF-06) |
| FS-003 | Screen Time | Screen Time |

| **App Access Exempt** | **ST Unlimited** |
|---|---|
| Access disposition: package not subject to App Control entertainment deny for access plane | Time disposition: may continue past daily cap |
| Does **not** bypass Instant Device Lock, SOS rules, or higher layers (APP-SF-17) | Does **not** bypass Instant Lock, Permanent Block, Mode harden, SOS |
