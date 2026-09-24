# 11 — SOS Readiness Model

**Status:** FROZEN (OD-21)  
**SOS PRODUCT CONTRACT STATUS: FROZEN**  
**Audience:** Appropriate parent experience (Primary + Mother Full for config; all guardians see incident-time honesty; Partner/Observer see non-config readiness summaries as needed).

---

## 1. Purpose

Parents must see whether SOS can actually protect the family **before** an emergency — without false confidence.

---

## 2. Capability classification (mandatory)

Every capability row uses exactly one:

| Class | Meaning |
|---|---|
| **AVAILABLE** | Proven working on this device/family config |
| **DEGRADED** | Works with known limitations |
| **UNAVAILABLE** | Cannot work now (OS/permission/network) |
| **NOT CONFIGURED** | Product supports it but family/device setup incomplete |

---

## 3. Readiness checklist (parent)

| Capability | Signals |
|---|---|
| Child SOS trigger reachable | Child app linked; FAB/CHD-005 available; lock exemptions OK |
| Local incident persistence | Child device storage healthy |
| Push / critical alerts | Permission + platform entitlement |
| SMS fallback | Permission/SIM + contact MSISDNs configured |
| Call fallback | Dialer/VoIP + trusted numbers |
| Location | Permission + last successful fix age |
| Trusted contacts ladder | Rung-1 present; backups ≤5; show verified count / unverified warnings |
| Panic Quiet Mode | ON/OFF (informational — active SOS child focus) |
| Break-glass | AVAILABLE for Primary/Full when incident ACTIVE and RBAC allows; Partner/Observer/Child = not applicable |
| Audio / emergency dial | **N/A — excluded** (omit from checklist) |

---

## 4. Where readiness appears

| Surface | Content |
|---|---|
| FAT-028 | Full readiness + config (Primary/Full) |
| FAT-018 empty | Soft CTA if NOT CONFIGURED contacts/channels |
| Settings hub | SOS readiness summary chip |
| Incident board | Live degraded chips (transport/location) — not the setup checklist |

Observer/Partner: may see **summary** “SOS notifications OK / degraded” without edit controls.

---

## 5. Honesty rules

- NEVER show green “SOS ready” if push UNAVAILABLE and no SMS/call configured.  
- DEGRADED is allowed with explanation.  
- Panic Quiet Mode ON ≠ unreadiness.  
- Excluded capabilities are omitted, not marked broken.
