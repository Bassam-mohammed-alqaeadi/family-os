# 02 — SOS Product Contract

**Status:** FROZEN PRODUCT CONTRACT  
**SOS PRODUCT CONTRACT STATUS: FROZEN**  
**Depends on:** [01_SOS_OWNER_DECISIONS.md](01_SOS_OWNER_DECISIONS.md)  
**Entry:** [13_SOS_FINAL_MASTER_CONTRACT.md](13_SOS_FINAL_MASTER_CONTRACT.md)

---

## 1. Product definition

**SOS is a family safety INCIDENT system.**  
A child (or break-glass path) creates a durable incident that:

1. Activates locally even when degraded.  
2. Notifies guardians through confirmed delivery channels.  
3. Shares essential incident evidence (never audio).  
4. Escalates only to family / trusted contacts.  
5. Ends only via explicit resolve or audited child cancellation.  
6. Remains auditable forever after resolution (no delete).

SOS is **not**: a notification preference, a billing feature, a muteable alert class, or an emergency-services dispatch product.

---

## 2. Users & jobs-to-be-done

| Actor | Primary job |
|---|---|
| Child | Reach family help fast; see honest progress; cancel only if truly safe |
| Primary Parent | Full control: respond, escalate, resolve, configure |
| Mother Full | Partner response + configure settings/contacts/ladder |
| Mother Partner | Acknowledge, respond, escalate — no config |
| Mother Observer | Be informed; view essentials; contact child — no close/escalate/config |

---

## 3. Core product capabilities

| Capability | Classification rule |
|---|---|
| Trigger SOS (3s hold) | Must be AVAILABLE whenever child can open SOS surface (exemptions apply) |
| Local incident create | Always AVAILABLE offline |
| Push / in-app delivery | AVAILABLE / DEGRADED / UNAVAILABLE per platform |
| SMS fallback | AVAILABLE / UNAVAILABLE / NOT CONFIGURED |
| Call fallback / auto-call to family | AVAILABLE / UNAVAILABLE / NOT CONFIGURED |
| Live location | READY / ACQUIRING / STALE / UNAVAILABLE (never blocks activate) |
| Auto escalate to trusted | AVAILABLE if configured; never emergency services |
| Panic Quiet Mode | APPROVED feature — readiness-visible |
| Break-glass | APPROVED — fully audited |
| Audio | **NOT IN PRODUCT** |
| Emergency-service dial | **NOT IN PRODUCT** (future separate approval) |

Every capability UI must show one of: **AVAILABLE · DEGRADED · UNAVAILABLE · NOT CONFIGURED**. Never fake success.

---

## 4. Incident vs notification (OD-19, OD-20)

| Concern | Owns |
|---|---|
| Incident | Lifecycle: IDLE→…→RESOLVED; evidence; actors; audit |
| Delivery / transport | Per recipient × channel: pending / delivered / failed |

A guardian can fail to receive push while the incident remains ACTIVE.  
A delivery can succeed while the incident is still unacknowledged.  
**Never merge these into one status badge.**

---

## 5. Evidence pack (OD-10) — included

- Location (with honesty state)  
- Device state  
- Battery  
- Connection state  
- Delivery history (per channel/recipient)  
- Incident lifecycle timeline  
- Audit trail  

## Evidence — excluded

- Audio recording  
- Audio broadcast  
- Video (not approved)

---

## 6. Modes

### Panic Quiet Mode (OD-12 + RD-01) — FROZEN

**Purpose:** During an **active SOS incident**, the child experience shows **only emergency-critical** information and actions.

**Must keep visible/usable:**

- SOS status (lifecycle honesty)  
- Parent / contact communication  
- Location status (READY / ACQUIRING / STALE / UNAVAILABLE)  
- Explicit cancel / false-alarm confirmation flow  

**Must not:**

- Let entertainment controls, time-limit UI, or device-lock chrome suppress SOS (OD-14)  
- Add extra child-visible complexity  
- Mute parent SOS receipt  
- Introduce audio/video  

**Configure:** Primary + Mother Full. Snapshot `panicQuietModeAtTrigger` on create. Audit toggles.

### Break-glass (OD-13 + RD-02 + Q-SOS-RD-02A/02B) — FROZEN

**Purpose:** Explicit **parent** temporary emergency override — **not** automatic permission, **not** child SOS trigger.

**Who (RBAC only — never device-ownership inference):**

- ✅ Primary Parent  
- ✅ Mother Full  
- ❌ Mother Partner, Mother Observer, Child  

**ALLOWED temporarily:** child device lock / restricted shell bypass for SOS response; screen-time bypass for SOS response; web/app restriction bypass for emergency communication/response; emergency communication surface; access to active SOS and location context; parent SOS notification handling.

**FORBIDDEN:** permanent policy changes; role/permission changes; billing/entitlement changes; disabling SOS; disabling audit; deleting SOS incidents/evidence; bypassing privacy/audit safeguards; creating permanent exceptions; unrestricted “unlock everything”.

**Lifecycle:** `START → REASON/CONTEXT → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT`.

Time-bounded; auto-revoked; never silently alters permanent policy. Distinct from SET-009 lock supersession (separate audit codes).

**Not Break-glass:** Child hold/FAB activation (normal OD-14 exempt path).---

## 7. Non-goals (this contract)

- Replacing national emergency services  
- On-device AI triage of SOS  
- Points/minutes economy interaction  
- Mother Observer admin powers  
- Audio surveillance  

---

## 8. Success definition

SOS is successful when:

1. An incident exists durably after trigger (even offline).  
2. Eligible guardians are notified through best available confirmed channels.  
3. Parents can act within their role matrix.  
4. Location honesty never blocks activation.  
5. Resolution/cancel leaves a complete audit trail.  
6. No UI claims a channel or location capability it does not have.
