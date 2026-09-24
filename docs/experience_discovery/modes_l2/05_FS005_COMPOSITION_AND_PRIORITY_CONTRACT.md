# 05 — FS-005 Composition and Priority Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · MODE-SF-07 · MODE-SF-08 · MODE-SF-16 · MODE-OD-05 · MODE-OD-07  
**Technical open:** T-MODE-09  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Multi-mode stacking (**MODE-OD-05**)

**Multiple active Modes are allowed.**

When multiple Modes apply to the same child at the same time:

| Rule | Law |
|---|---|
| Composition | Effective Mode overlay = **intersection / stricter result** across applicable Modes |
| Safety above Modes | Instant Lock, Permanent Block, SOS, and other higher-priority systems remain **above** Modes |
| Loosen ban | No Mode may **permanently loosen** another system’s restrictions |
| Stage-1 single active | **Rejected** as target law |

---

## 2. Priority ladder (product)

Illustrative merge order for access (aligns Register / ST Precedence / sibling L2):

1. SOS / protected reachability (never denied by Mode)  
2. Instant Device Lock (where applicable)  
3. Permanent App Block / hard blocks  
4. **Active Mode overlay(s)** — stricter intersection + ModeException  
5. Screen Time minutes / cap / grant / wallet rules  
6. Other domain allows  

Exact Kernel encoding remains Kernel/ST territory; Modes supply **overlay facts**, not a private bypass ladder.

---

## 3. Tighten-only composition (**MODE-OD-07**)

Across Modes and vs baseline policy:

- Effective result may only be **as strict or stricter** than the underlying non-Mode policy for the same plane.  
- Intersection of allow-sets = narrowest wins.  
- A permissive Mode **cannot** reopen what a stricter Mode or underlying Permanent Block already denies.  

**Rejected:** prototype Vacation widen of allowed apps.

---

## 4. Cross-system tighten

When Mode overlays FS-002 / FS-003 / FS-004:

| Plane | Composition with Mode |
|---|---|
| FS-002 | Mode may only **tighten** filter outcome; never rewrite lists |
| FS-003 | Mode may only **tighten** access context; never reopen Permanent Block; never mutate package store |
| FS-004 | Mode may only **tighten**; never permanently remove camera/capture policy |
| ST | Mode may supply context to Kernel; **never** own or mint minutes |

Stricter intersection with App Control ∩ Web Filter (**WF-OD-12** / **APP-SF-08**) remains in force; Mode is an additional tighten layer, not a rewrite tool.

---

## 5. Conflict notification

When multi-mode stricter intersection materially changes effective policy, authorized parents should be notifiable (**Register M-B spirit**). Delivery channel = **T-MODE-09**.
