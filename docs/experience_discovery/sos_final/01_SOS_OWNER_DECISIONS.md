# 01 — SOS Owner Decisions (Frozen)

**SOS PRODUCT CONTRACT STATUS: FROZEN**

**OD-01…OD-21:** FROZEN — Owner approved 2026-09-23 — **do not reopen**.  
**RD-01…RD-05 + Q-SOS-RD-02A/02B/03A:** CLOSED 2026-09-23.  
**Owner decisions remaining:** **NONE**.

**Entry:** [13_SOS_FINAL_MASTER_CONTRACT.md](13_SOS_FINAL_MASTER_CONTRACT.md) · [SOS_CONTRACT_CLOSURE_REPORT.md](SOS_CONTRACT_CLOSURE_REPORT.md) · [12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md](12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md)

**Exception rule:** Only a demonstrated platform constraint that makes a frozen requirement technically impossible may be reported explicitly — never silently redesigned.

---

## OD register (frozen)

| ID | Frozen rule |
|---|---|
| OD-01 | Mother Observer: receive; view essential; contact child. **Cannot** resolve, escalate, configure. |
| OD-02 | Mother Partner: receive; view; ack; respond; escalate. **No** nuclear config. |
| OD-03 | Mother Full: Partner + manage settings, contacts, escalation config. |
| OD-04 | Primary Parent: full SOS control. |
| OD-05 | ACKNOWLEDGED ≠ RESOLVED. |
| OD-06 | Child cancel only via confirm → false-alarm → parents informed → auditable. |
| OD-07 | Auto-call family/trusted first. Never auto national emergency. |
| OD-08 | National/local emergency numbers **EXCLUDED**. |
| OD-09 | Push/in-app; SMS/call fallbacks; confirm before success claim. |
| OD-10 | Evidence: location, device, battery, connection, delivery, lifecycle, audit. No audio/video. |
| OD-11 | Audio **EXCLUDED**. |
| OD-12 | Panic Quiet Mode **APPROVED** (RD-01). |
| OD-13 | Break-glass **APPROVED** (RD-02 + Q-SOS-RD-02A/02B). |
| OD-14 | Never gated by subscription, quiet hours, screen-time, entertainment, device lock. |
| OD-15 | Auto-escalation trusted only — never emergency-service dispatch. |
| OD-16 | Location fail still activates; READY/ACQUIRING/STALE/UNAVAILABLE. |
| OD-17 | Offline: local first; persist; queue; retry; fallbacks; no false “sent”. |
| OD-18 | RESOLVED does not delete; lifecycle auditable. |
| OD-19 | SOS is an **INCIDENT**. |
| OD-20 | Delivery state ≠ incident state. |
| OD-21 | Readiness visible honestly to appropriate parents. |

---

## Explicit exclusions

1. Audio / video evidence.  
2. National/local emergency numbers in this SOS pack.  
3. Auto emergency-service dial.

---

## RD + Q register (all CLOSED)

| ID | Status | Frozen behavior |
|---|---|---|
| **RD-01** | CLOSED | During active SOS, child sees only emergency-critical info/actions (status, contact, location honesty, cancel). Entertainment/time/lock UI must not suppress SOS. |
| **RD-02 + Q-SOS-RD-02A** | CLOSED | Break-glass: **Primary + Mother Full** only. Partner/Observer/Child forbidden. **RBAC** authorization — never device-ownership inference. |
| **RD-02 + Q-SOS-RD-02B** | CLOSED | Narrow allowlist (lock/shell, screen-time, web/app for emergency response, emergency comms surface, active SOS+location context, parent SOS notification handling). Forbidden: permanent policy/role/billing changes, disable SOS/audit, delete evidence, privacy bypass, permanent exceptions, unlock-everything. Lifecycle: START→REASON/CONTEXT→OVERRIDE_ACTIVE→EXPIRY→AUTO_REVOKE→AUDIT. |
| **RD-03 + Q-SOS-RD-03A** | CLOSED | Operational evidence samples **90 days**. Core incident header + immutable lifecycle audit **indefinite**. No audio/video. |
| **RD-04** | CLOSED | UNVERIFIED→PENDING→VERIFIED→REVOKED; escalate only if VERIFIED; phone change re-verifies; abstract transport; audited. |
| **RD-05** | CLOSED | Max **5** backups; priority **1…5**; verified badges; rung-1 immutable. |
