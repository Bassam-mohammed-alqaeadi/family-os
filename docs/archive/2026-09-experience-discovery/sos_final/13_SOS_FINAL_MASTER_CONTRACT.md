# 13 — SOS Final Master Contract

# SOS PRODUCT CONTRACT STATUS: FROZEN

**Authoritative entry point for the Family OS SOS Experience Contract.**  
**OD-01…OD-21 frozen:** 2026-09-23  
**RD-01…RD-05 closed:** 2026-09-23  
**Q-SOS-RD-02A / 02B / 03A closed:** 2026-09-23  
**Owner decisions remaining:** **NONE**

**Prior discovery (historical):** `docs/experience_discovery/sos/`  
**Closure:** [SOS_CONTRACT_CLOSURE_REPORT.md](SOS_CONTRACT_CLOSURE_REPORT.md)  
**Decisions file:** [12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md](12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md) (empty open list)

**Exception rule:** Only a demonstrated platform constraint that makes a frozen requirement technically impossible may surface a new question — and must be reported explicitly, never silently redesigned.

---

## 1. What this is

Implementation-ready **Product · Policy · UX · Screen · State · Data · Backend** contract for Family OS SOS — **without application code**.

---

## 2. Document index

| # | File |
|---|---|
| 01 | [01_SOS_OWNER_DECISIONS.md](01_SOS_OWNER_DECISIONS.md) |
| 02 | [02_SOS_PRODUCT_CONTRACT.md](02_SOS_PRODUCT_CONTRACT.md) |
| 03 | [03_SOS_POLICY_CONTRACT.md](03_SOS_POLICY_CONTRACT.md) |
| 04 | [04_SOS_UX_CONTRACT.md](04_SOS_UX_CONTRACT.md) |
| 05 | [05_SOS_SCREEN_ARCHITECTURE.md](05_SOS_SCREEN_ARCHITECTURE.md) |
| 06 | [06_SOS_ROLE_AND_PERMISSION_CONTRACT.md](06_SOS_ROLE_AND_PERMISSION_CONTRACT.md) |
| 07 | [07_SOS_STATE_AND_EVENT_CONTRACT.md](07_SOS_STATE_AND_EVENT_CONTRACT.md) |
| 08 | [08_SOS_FAILURE_AND_OFFLINE_CONTRACT.md](08_SOS_FAILURE_AND_OFFLINE_CONTRACT.md) |
| 09 | [09_SOS_DATA_BACKEND_DEVICE_CONTRACT.md](09_SOS_DATA_BACKEND_DEVICE_CONTRACT.md) |
| 10 | [10_SOS_COMPETITIVE_LESSONS.md](10_SOS_COMPETITIVE_LESSONS.md) |
| 11 | [11_SOS_READINESS_MODEL.md](11_SOS_READINESS_MODEL.md) |
| 12a | [12_SOS_VALIDATION_CONTRACT.md](12_SOS_VALIDATION_CONTRACT.md) |
| 12b | [12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md](12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md) |
| — | [SOS_CONTRACT_CLOSURE_REPORT.md](SOS_CONTRACT_CLOSURE_REPORT.md) |

---

## 3. Frozen decision stack

### OD-01…OD-21 (unchanged)

Observer/Partner/Full/Primary powers · ACK≠RESOLVE · auditable child cancel · trusted-only auto-call/escalate · no national numbers · no audio · Panic Quiet + Break-glass approved · permanent exemptions · location/offline honesty · incident≠delivery · readiness visible.

### RD + Q freezes

| ID | Frozen rule |
|---|---|
| RD-01 | Active SOS child UI = emergency-critical only |
| RD-02 / **Q-SOS-RD-02A** | Break-glass: Primary + Mother Full only; RBAC-gated; never device-ownership inference |
| RD-02 / **Q-SOS-RD-02B** | Narrow allowlist; forbidden list; lifecycle START→REASON→ACTIVE→EXPIRY→AUTO_REVOKE→AUDIT |
| RD-03 / **Q-SOS-RD-03A** | Operational evidence **90 days**; core header + lifecycle audit **indefinite**; no audio/video |
| RD-04 | Backup verify UNVERIFIED→PENDING→VERIFIED→REVOKED |
| RD-05 | Max 5 backups; priority 1…5; rung-1 immutable |

---

## 4. Break-glass final semantics (frozen)

- **Who:** Primary Parent, Mother Full.  
- **Not:** Partner, Observer, Child.  
- **AuthZ:** RBAC only.  
- **What:** Temporary bypass of allowlisted response blockers (lock/shell, screen-time, web/app for emergency comms, emergency communication surface, active SOS + location context, parent SOS notification handling).  
- **Not what:** Permanent policy, roles, billing, disable SOS/audit, delete evidence, privacy bypass, permanent exceptions, unlock-everything.  
- **Lifecycle:** START → REASON/CONTEXT → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT.  
- **Not** a child SOS create path (child uses HOLD + OD-14 exemptions).

---

## 5. Evidence retention final semantics (frozen)

| Layer | Retention | Contents |
|---|---|---|
| Operational samples | 90 days | Location samples, delivery attempts/results, device/battery/connectivity snapshots, escalation events, communication state |
| Core + audit | Indefinite | Incident identity, family/child refs, trigger time, ack, escalation, resolve/cancel, actors, Break-glass audit, core lifecycle events |
| Audio/video | **Forbidden** | — |

Resolve/cancel must not erase the indefinite audit layer.

---

## 6. Architecture (frozen)

```
Child                         Cloud                            Parent
─────                         ─────                            ──────
HOLD → local incident         SosIncident + deliveries         Critical notify
CHD-006 critical-only         Ladder ≤5 VERIFIED by priority   FAT-018 role UI
outbox + location honesty     Verification port (abstract)     Break-glass (Primary/Full)
OD-14 exemptions              Escalation timer (trusted only)  FAT-028 config
SMS/call fallbacks            Evidence 90d · Audit forever     Readiness
                              Break-glass expiry worker
                              No audio · no emergency dial
```

**Capability classes:** AVAILABLE | DEGRADED | UNAVAILABLE | NOT CONFIGURED.

---

## 7. Screen map (frozen)

| ID | Decision |
|---|---|
| CHD-005 | MODIFY — child trigger |
| CHD-006 | EXTEND — active + cancel; Panic Quiet critical-only |
| FAT-018 | EXTEND — incident console; Break-glass Primary/Full |
| FAT-028 | EXTEND — ≤5 + verify + Panic Quiet |

---

## 8. State model (frozen)

**Incident:** IDLE → HOLDING → FIRING → ACTIVE → ACKNOWLEDGED → ESCALATING → RESOLVED  

**Transport / location / device:** independent.  

**Backup verification:** UNVERIFIED → PENDING → VERIFIED → REVOKED  

**Break-glass override:** START → REASON/CONTEXT → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT  

---

## 9. Non-goals (frozen)

- Audio/video evidence  
- National emergency dialing in this SOS pack  
- Parent mute of SOS receipt  
- Observer/Partner Break-glass  
- Child Break-glass  
- Silent permanent policy mutation  

---

## 10. Implementation rule

No application code may claim SOS contract compliance until validation (12a) passes.  
This freeze task **does not** implement SOS and **does not** modify application code.

**Application code modified by this freeze:** **NO.**
