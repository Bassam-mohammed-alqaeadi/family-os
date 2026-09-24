# 11 — FS-003 L2 Master Contract

# FS-003 APPLICATION & SYSTEM CONTROL — L2 POLICY COMPLETE (OWNER DECISIONS FROZEN)

**Date:** 2026-09-24  
**Package:** `docs/experience_discovery/application_control_l2/`  
**Evidence baseline (non-authority):** `docs/experience_discovery/application_control_discovery/`

```
FS-003 DISCOVERY: COMPLETE
FS-003 L2 POLICY: COMPLETE
OWNER DECISIONS: FROZEN
FS-003 L3: READY
IMPLEMENTATION: NOT AUTHORIZED
```

---

## 1. Document index

| # | File |
|---|---|
| 01 | [01_FS003_L2_OWNER_DECISIONS.md](01_FS003_L2_OWNER_DECISIONS.md) |
| 02 | [02_FS003_POLICY_CONTRACT.md](02_FS003_POLICY_CONTRACT.md) |
| 03 | [03_FS003_ROLE_ACCESS_CONTRACT.md](03_FS003_ROLE_ACCESS_CONTRACT.md) |
| 04 | [04_FS003_ENFORCEMENT_CONTRACT.md](04_FS003_ENFORCEMENT_CONTRACT.md) |
| 05 | [05_FS003_APP_IDENTITY_CONTRACT.md](05_FS003_APP_IDENTITY_CONTRACT.md) |
| 06 | [06_FS003_INSTALL_AND_EXCEPTION_CONTRACT.md](06_FS003_INSTALL_AND_EXCEPTION_CONTRACT.md) |
| 07 | [07_FS003_OFFLINE_SYNC_CONTRACT.md](07_FS003_OFFLINE_SYNC_CONTRACT.md) |
| 08 | [08_FS003_EVENT_AUDIT_NOTIFICATION_CONTRACT.md](08_FS003_EVENT_AUDIT_NOTIFICATION_CONTRACT.md) |
| 09 | [09_FS003_CROSS_SYSTEM_BOUNDARIES.md](09_FS003_CROSS_SYSTEM_BOUNDARIES.md) |
| 10 | [10_FS003_DECISION_CLOSURE_REPORT.md](10_FS003_DECISION_CLOSURE_REPORT.md) |
| 11 | this file |

---

## 2. Answers (FROZEN)

| Question | Answer |
|---|---|
| What is an app? | Platform-stable **package ID** + metadata; slugs forbidden as policy identity |
| What does App Control own? | Allow / Block / Exempt / Lock Now / Install / App Access Exception / plane honesty |
| What does Screen Time own? | Budgets, Temporary Grant, wallets, **Limit / Unlimited / Countable** |
| What does Web Filtering own? | URL plane; stricter ∩ with App Control |
| What do Modes own? | **Scheduling**; tighten-only overlays; cannot reopen Permanent Block |
| What does Policy Kernel own? | Merge / notify / action |
| What can Parents do? | See role matrix (03) — configure Primary+Full; tickets Primary+Partner+Full; reopen block Primary only; Observer view-only |
| What can Child do? | Deny/pending + disclosure + Exception Request; ST minutes via ST; no admin |
| What can happen offline? | Last-acked enforce; outbox; deny-until-approved unknowns; SOS/Chat/Quran reachable |
| What is enforceable on-device? | Hybrid verified plane product law; mechanisms = T-APP; honesty mandatory |

---

## 3. Mission (one paragraph)

FS-003 governs **whether a package may be used** under family baseline + per-child override, including deny-until-approved new installs, timed App Access Exceptions (which do not rewrite Permanent Block), and per-app Lock Now overlays — while **Screen Time** owns how much entertainment time remains (including Limit/Unlimited/Countable), **Web Filter** owns which URLs may load, **Modes** own scheduling and may only tighten, and **SOS / Required Family Chat / Quran remain reachable and cannot be denied by App Control**. Enforcement claims require acknowledged policy and a verified capability plane.

---

## 4. Structural + Owner freezes

- **APP-SF-01…18** — structural  
- **APP-OD-01…20** — Owner/Product (**all closed**)  
- **T-APP-01…10** — technical (**all open**)

Key separations:

- **App Access Exception ≠ Temporary Grant ≠ ST Unlimited**  
- **App Access Exempt ≠ ST Unlimited**  
- **Exception = temporary evaluation override; does not delete/rewrite Permanent Block**

---

## 5. Role summary

| Action | Who |
|---|---|
| Configure policy | Primary + Full |
| Set Permanent Block | Primary + Full |
| Reopen Permanent Block | **Primary only** |
| Install / Exception decide | Primary + Partner + Full |
| Observer | View-only |
| Child | Status + Exception Request; no admin |

---

## 6. Cross-check

| Check | Result |
|---|---|
| Q-APP all frozen | **PASS** |
| T-APP open | **PASS** |
| Contradictions in frozen set | **NONE** |
| L3 ready | **Yes** (commission separately) |
| Implementation authorized | **No** |

Full report: [10_FS003_DECISION_CLOSURE_REPORT.md](10_FS003_DECISION_CLOSURE_REPORT.md).

---

## 7. Explicit non-adoptions

Stage-1 Partner-edit · slug keys · Grant-as-app-unlock · Exception rewriting Permanent Block · FS-003 Limit/Unlimited authorship · second scheduler · Modes reopening block · DO/Accessibility as frozen product mechanism · full app surveillance default · silent family-wide install · AuthZ from device holding · Anti-tamper owned by FS-003.

---

## 8. Gate

**L3 READY** — start only under explicit L3 commission.  
**IMPLEMENTATION: NOT AUTHORIZED** without separate post-L3 commission.

---

FS-003 DISCOVERY: COMPLETE  
FS-003 L2 POLICY: COMPLETE  
OWNER DECISIONS: FROZEN  
FS-003 L3: READY  
IMPLEMENTATION: NOT AUTHORIZED  
