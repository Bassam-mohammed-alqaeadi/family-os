# 06 — FS-005 Exception and Grace Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · MODE-SF-13 · MODE-SF-18 · MODE-OD-10 · MODE-OD-11  
**Technical open:** T-MODE-06  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Three distinct instruments (**MODE-OD-11**)

| Instrument | System | Meaning |
|---|---|---|
| **ModeException** | FS-005 | Exception to the **current Mode overlay** only |
| **App Access Exception** | FS-003 | Package-specific application exception |
| **Temporary Grant** | Screen Time | Minutes / time economy |

**Never conflate.** UI and Kernel must keep separate identities and side effects.

---

## 2. ModeException — allowed effects

- Pierce / soften **only** the Mode overlay restriction for the scoped child × resource × Mode context  
- Remain subordinate to Instant Lock, Permanent Block, SOS protection, and other higher layers  
- Remain subject to Screen Time minutes rules after Mode allow (Register: allowed-in-mode still time-governed)  

## 3. ModeException — forbidden effects

A ModeException must **never**:

- become a package policy mutation (FS-003 store)  
- create Screen Time minutes / grants / wallet credits  
- rewrite Web Filter URL lists  
- remove Permanent App Block  
- mutate FS-004 permanent camera/capture policy  
- gate or disable SOS  

---

## 4. Temporary Grant ∩ Mode start

Screen Time Temporary Grant remains ST-owned. When a grant intersects Mode activation, product must require an explicit parent choice path (Register Ruling C spirit: complete vs freeze) — **UI/duration parameters are not invented here**. ModeException is **not** that choice.

---

## 5. Grace (**MODE-OD-10**, **MODE-SF-18**)

| Rule | Law |
|---|---|
| Nature | Parent-/Mode-defined **transition** before scheduled Mode fully applies |
| Child role | Sees grace / restriction state; **cannot** permanently cancel Mode via grace |
| Manual activation | **Always instant** — skips grace |
| Duration numbers | Register reference **default 2 · clamp 0–5** remains **parameter reference only** — **do not invent new numbers** in L2 |
| Prototype child “أنهيت” clear | **Rejected** as target law |

Delivery of grace countdown = **T-MODE-06**.

---

## 6. Child permanence rule

Child must not permanently disable or remove an active Mode. Ending a grace UI affordance (if any in L3) must not equal Mode deactivation authority.
