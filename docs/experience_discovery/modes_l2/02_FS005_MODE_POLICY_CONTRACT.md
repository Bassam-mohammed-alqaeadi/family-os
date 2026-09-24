# 02 — FS-005 Mode Policy Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · MODE-SF-05…12 · MODE-OD-01…07 · MODE-OD-12  
**Non-authority:** Stage-1 `SmartModePrefs`, prototype `familyModes`, discovery inventory  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Canonical Mode entity

One Mode model for **built-in and custom** modes (**MODE-OD-03**, **MODE-OD-04**).

Required conceptual properties (product law — not schema):

| Property | Law |
|---|---|
| Identity | Name + visual identity; built-ins from canonical catalog; customs parent-authored |
| Scope | All children **or** explicit selected children (**MODE-OD-01**) |
| Scheduling | Represented under FS-005 authority (**MODE-OD-08**); channels per **MODE-OD-09** |
| Overlay intent | Tighten-only restrictions toward FS-003 / FS-002 / FS-004 / location context / ST context (**MODE-OD-07**, **MODE-OD-12**) |
| Exceptions | ModeException only (**MODE-OD-11**) |
| Entry behavior | Grace transition (parent-/Mode-defined); manual skips grace (**MODE-SF-18**, **MODE-OD-10**) |

---

## 2. Built-in catalog (canonical)

| Built-in | Notes |
|---|---|
| Sleep | — |
| School | — |
| Study | Covers education/exam-style intent; **`exams` is not a separate built-in** |
| Ramadan | Seasonal-capable |
| Vacation | Tighten-only; **no widen** |
| Family Time | Normalized from prototype `famtime` |

**Forbidden:** duplicate aliases as separate modes; resurrecting `exams` / `famtime` as parallel ids.

---

## 3. Custom Modes

Enabled. Same entity, lifecycle, AuthZ, tighten-only rules, and evaluation path as built-ins.

---

## 4. Targeting

| Rule | Law |
|---|---|
| Family baseline | Modes may be defined as applying to all children |
| Explicit selection | Selected child set must be explicit on the Mode |
| No silent expansion | Applying to one child must **not** silently expand to all |
| Per enrolled device | Enforcement/ack is per enrolled child device (sync contract) |

---

## 5. What a Mode may do

- Activate / deactivate via authorized channels  
- Emit **contextual overlay facts** for Kernel merge  
- Temporarily **tighten** applicable planes relative to underlying policy  
- Carry ModeExceptions that pierce **only** the Mode overlay  

## 6. What a Mode must not do

- Own package policy storage (FS-003)  
- Own or rewrite URL lists (FS-002)  
- Own geofence definitions (FS-001)  
- Own camera enforcement mechanisms (FS-004)  
- Own Screen Time minutes / grants / wallets / Unlimited  
- Reopen Permanent App Block  
- Permanently weaken FS-004  
- Gate SOS / Required Family Chat / Quran required path  
- Mutate other systems’ permanent stores silently  

---

## 7. Honesty

Stage-1 FAT-085 toggle + activation bus = **non-authority**. Target product claims **enforced** only with acknowledged Mode policy + verified capability planes on each overlay system.
