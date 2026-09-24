# 03 — FS-005 Role Access Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · MODE-SF-01…03 · MODE-OD-02 · MODE-OD-10 · MODE-OD-13 · MODE-OD-14  
**AuthZ:** RBAC only — **never** device possession  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Role matrix

| Capability | Primary | Co-Parent Full | Co-Parent Partner | Observer | Child |
|---|---|---|---|---|---|
| View Mode catalog / state / honesty | ✓ | ✓ | ✓ | ✓ | Active Mode + restriction/grace disclosure only |
| Create Mode | ✓ | ✓ | ✗ | ✗ | ✗ |
| Edit Mode definition / overlays / schedule | ✓ | ✓ | ✗ | ✗ | ✗ |
| Delete Mode | ✓ | ✓ | ✗ | ✗ | ✗ |
| Activate / deactivate (configuration authority) | ✓ | ✓ | ✗* | ✗ | ✗ |
| Explicit ticket-authorized activate/deactivate | ✓ | ✓ | ✓ if ticket model grants | ✗ | ✗ |
| Author ModeException | ✓ | ✓ | ✗ | ✗ | ✗ |
| Receive Mode notifications | ✓ | ✓ | ✓ (relevant) | ✓ (view-class) | Grace/restriction disclosure |
| Cancel / permanently remove active Mode | ✓ | ✓ | ✗ | ✗ | **✗** |
| End grace as policy cancel | — | — | — | — | **✗** |
| Configure Mode policy from child device | — | — | — | — | **✗** |

\* Partner default: **not** a Mode policy editor; activation/deactivation only where **explicitly authorized** by the global ticket/operational model (**MODE-OD-13**).

---

## 2. Configuration authorship (**MODE-OD-02**)

**Primary + Co-Parent Full** may:

create · edit · schedule · activate · deactivate · delete Modes.

Partner / Observer: **view-only** for Mode configuration unless a specific ticket/decision capability is granted elsewhere.

Child: **cannot** author or configure Modes.

---

## 3. Child visibility (**MODE-OD-10**)

Child **must** see:

- active Mode identity (when applicable)  
- relevant restriction / grace state  

Child **must not**:

- permanently disable or remove an active Mode  
- treat grace as authorization to cancel policy  
- access Mode admin surfaces  

Manual activation remains **instant** (skips grace) for authorized parents.

---

## 4. Safety reachability (**MODE-OD-14**)

Regardless of role and regardless of active Mode(s):

- SOS reachable  
- Required Family Chat reachable  
- Quran required-access path reachable  

No Mode creates emergency lockout.

---

## 5. Non-adoptions

| Rejected |
|---|
| Stage-1 ungated FAT-085 as target AuthZ |
| AuthZ from “who holds the device” |
| Partner as Mode policy editor by default |
| Prototype child grace-clear as target law |
