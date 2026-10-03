# 01 — FS-002 L2 Owner Decisions Register

**System:** FS-002 Web Filtering  
**Status:** **OWNER DECISIONS FROZEN** — 2026-09-23  
**Evidence baseline:** `docs/experience_discovery/web_filtering_discovery/` (CURRENT only — non-authority)  
**Target AuthZ vocabulary:** Primary Parent · Co-Parent (Observer / Partner / Full) · Child  
**Legacy Father/Mother Stage-1:** evidence only — **not** target law  

**Entry:** [11_FS002_L2_MASTER_CONTRACT.md](11_FS002_L2_MASTER_CONTRACT.md) · [10_FS002_DECISION_CLOSURE_REPORT.md](10_FS002_DECISION_CLOSURE_REPORT.md)

```
DISCOVERY: COMPLETE
OWNER DECISIONS: FROZEN
L2 POLICY: COMPLETE
TECHNICAL/PLATFORM PARAMETERS: OPEN
L3: COMPLETE
IMPLEMENTATION: NOT AUTHORIZED
```

---

## A. Structural freezes (global) — unchanged

| ID | Frozen structural law |
|---|---|
| **WF-SF-01** | Independent gate from Minutes / Temporary Grant / wallets |
| **WF-SF-02** | Never disable SOS / required chat / Quran paths |
| **WF-SF-03** | Web Filter Domain = facts; Policy Kernel = interpretation → notify/action |
| **WF-SF-04** | Offline honesty; no fake cloud success; acked policy only for enforced claims |
| **WF-SF-05** | AuthZ = RBAC (role + Co-Parent level); never device-holder inference |
| **WF-SF-06** | Primary ≠ Co-Parent Full for owner-only/sensitive classes by default |
| **WF-SF-07** | Audit append-only |
| **WF-SF-08** | AI suggests; does not execute without authorized approval |
| **WF-SF-09** | Vocabulary: Primary Parent · Co-Parent · Child |
| **WF-SF-10** | Never claim filtering where capability plane unavailable/unsupported |

---

## B. Owner / Product freezes (ED 2026-09-23)

| ID | Q | Choice | Frozen law |
|---|---|---|---|
| **WF-OD-01** | Q-WF-01 | **C** | **Family default + optional per-child overrides.** Family baseline applies unless a child-specific override exists. |
| **WF-OD-02** | Q-WF-02 | **B** | Configure policy (level/categories/lists): **Primary + Co-Parent Full** only. Partner/Observer **cannot** edit. **Do not** inherit Stage-1 father-only bug. |
| **WF-OD-03** | Q-WF-03 | **B** | Unlock approve/deny: **Primary + Co-Parent Partner + Co-Parent Full**. Observer **cannot**. |
| **WF-OD-04** | Q-WF-04 | **D** | **Hybrid enforcement.** Primary = verified on-device enforcement agent/equivalent. Fallback = only **verified** platform-supported mechanisms. Do **not** hard-code VPN/DNS/DO as the final technical mechanism in product contracts. Unverified = honest degraded/unsupported. No claim when plane unavailable. |
| **WF-OD-05** | Q-WF-05 | **B** | **Large normative category model** as target direction. Do **not** freeze Stage-1 six categories. Do **not** treat arbitrary registry count as final taxonomy. Exact taxonomy = separate technical/content contract. |
| **WF-OD-06** | Q-WF-06 | **A** | Forced Safe Search / restricted search **in-scope and mandatory** wherever the active platform can enforce it. Unsupported → honest capability state. No false universal claim. |
| **WF-OD-07** | Q-WF-07 | **D** | Private/incognito = **platform-dependent honesty matrix**. No fake “incognito blocked” success. |
| **WF-OD-08** | Q-WF-08 | **C** | First-class v1: **Allowlist + Blocklist + Custom keyword dictionary**. Deterministic precedence in Filtering Model Contract. |
| **WF-OD-09** | Q-WF-09 | **B** | Approved exceptions = **timed temporary allows**. Durations = Technical (T-WF-01) — **not invented**. Never silently convert approval → permanent allowList. |
| **WF-OD-10** | Q-WF-10 | **C** | Scheduling authority = **FS-005 Modes**. No second Web Filter scheduler. Filter **consumes** Mode policy context. |
| **WF-OD-11** | Q-WF-11 | **D** | Home-router DNS = **optional add-on behind explicit honesty**. FAT-078 mock must **never** imply real router protection. Not part of core on-device enforcement claim. |
| **WF-OD-12** | Q-WF-12 | **C** | App/System Control ∩ Web Filter = **stricter intersection**. Permissive gate must not override deny from the other. UX must show clear source-of-deny. |
| **WF-OD-13** | Q-WF-13 | **B** | Modes may **only tighten** Web Filter. Modes must **not** weaken or bypass base filter policy. |
| **WF-OD-14** | Q-WF-14 | **B** | Audit/evidence: **Deny events + unlock request lifecycle + approve/deny decisions**. No full browse-history surveillance unless separately authorized later. |
| **WF-OD-15** | Q-WF-15 | **B** | Child sees: **block/interstitial + non-interactive “family filter active” disclosure**. No lists, categories, rules, integrity details, or admin controls. |

---

## C. Q-WF closure map

| Q-ID | Status | Maps to |
|---|---|---|
| Q-WF-01 | **CLOSED** | WF-OD-01 |
| Q-WF-02 | **CLOSED** | WF-OD-02 |
| Q-WF-03 | **CLOSED** | WF-OD-03 |
| Q-WF-04 | **CLOSED** | WF-OD-04 |
| Q-WF-05 | **CLOSED** | WF-OD-05 |
| Q-WF-06 | **CLOSED** | WF-OD-06 |
| Q-WF-07 | **CLOSED** | WF-OD-07 |
| Q-WF-08 | **CLOSED** | WF-OD-08 |
| Q-WF-09 | **CLOSED** | WF-OD-09 |
| Q-WF-10 | **CLOSED** | WF-OD-10 |
| Q-WF-11 | **CLOSED** | WF-OD-11 |
| Q-WF-12 | **CLOSED** | WF-OD-12 |
| Q-WF-13 | **CLOSED** | WF-OD-13 |
| Q-WF-14 | **CLOSED** | WF-OD-14 |
| Q-WF-15 | **CLOSED** | WF-OD-15 |

**Owner/Product decisions remaining:** **NONE**

---

## D. Technical / Platform still OPEN (no invented numbers)

| ID | Topic | Frozen product side | Open parameter |
|---|---|---|---|
| **T-WF-01** | Temporary-allow duration | Timed temporary (WF-OD-09) | Exact minutes/hours |
| **T-WF-02** | Classification vendor / database | Large normative categories (WF-OD-05) | Vendor + taxonomy content contract |
| **T-WF-03** | On-device agent / fallback feasibility | Hybrid law (WF-OD-04) | VPN/DO/DNS/other as **implementation** choices after verification |
| **T-WF-04** | Policy ack / stale TTL | Ack honesty (WF-SF-04) | Exact TTL values |
| **T-WF-05** | Sync batching / conflicts | Outbox + ack | Algorithms |

---

## E. Explicit non-adoptions (still)

Stage-1 six categories · father-only configure · permanent allow on approve · fixture classifier as taxonomy · FAT-078 mock as live protection · capability-table “full” as proof of enforcement · registry arbitrary count as final taxonomy.
