# 12 — SOS Validation Contract

**Status:** FROZEN acceptance criteria for future implementation  
**SOS PRODUCT CONTRACT STATUS: FROZEN**  
**This document does not run tests; it defines what must be proven later.**  
**Owner decisions remaining:** NONE.

---

## A. Product / policy validations

| ID | Criterion | Pass condition |
|---|---|---|
| V-01 | Observer cannot resolve | UI absent + API 403 |
| V-02 | Observer cannot escalate | UI absent + API 403 |
| V-03 | Observer cannot configure | FAT-028 blocked |
| V-04 | Partner can ack/escalate/resolve | Allowed |
| V-05 | Partner cannot configure ladder | FAT-028 blocked |
| V-06 | Full can configure | FAT-028 edit OK |
| V-07 | Primary full control | All actions OK |
| V-08 | ACK ≠ RESOLVE | Separate actions & states |
| V-09 | Child cancel confirms | Sheet required; event FALSE_ALARM |
| V-10 | Parents informed on cancel | Delivery/notify attempted + audited |
| V-11 | No auto emergency-service dial | No code path / no UI |
| V-12 | No hardcoded emergency numbers | Grep/contract clean |
| V-13 | No audio SOS | No fields/UI/permissions |
| V-14 | Never subscription-gated | Expired plan still fires |
| V-15 | Quiet hours cannot mute | Critical delivery true |
| V-16 | Lock/expiry exempt | SOS reachable |
| V-17 | Location fail still activates | UNAVAILABLE + ACTIVE |
| V-18 | Offline local create | Durable + queue |
| V-19 | No “sent” without confirm | PENDING until DELIVERED |
| V-20 | Resolve does not delete | Record readable after |
| V-21 | Delivery state independent | Can be FAILED while ACTIVE |
| V-22 | Readiness visible | Parent readiness surface |
| V-23 | Panic Quiet Mode | Active SOS critical-only child UI; does not mute parents; audited |
| V-24 | Break-glass | Primary/Full RBAC only; allowlist enforced; Partner/Observer/Child rejected; lifecycle START→…→AUTO_REVOKE→AUDIT; no permanent policy mutation |
| V-25 | Trusted auto-escalate only | VERIFIED backups by priority; max 5 |
| V-26 | Backup verification lifecycle | Non-VERIFIED excluded from escalation |
| V-27 | Evidence retention | 90d operational samples; indefinite core+audit; no audio/video |
| V-28 | Max 5 backups | Enforce on upsert |
| V-29 | Break-glass not device-inferred | AuthZ from RBAC only |
| V-30 | Break-glass forbidden list | Permanent policy/role/billing/SOS-disable/audit-disable/delete/privacy-bypass/unlock-all rejected |

---

## B. Screen validations

| Screen | Must prove |
|---|---|
| CHD-005 | 3s hold; offline fire; parent lean; OD-14 reachability (not Break-glass) |
| CHD-006 | Critical-only under Panic Quiet; receipts; cancel confirm; location honesty |
| FAT-018 | Role variants; ACK vs RESOLVE; Observer no mutate; Break-glass Primary/Full only; VERIFIED escalate |
| FAT-028 | Rung-1 locked; ≤5 + priority + verify; Full/Primary edit; Partner/Observer blocked; Panic Quiet; no national number; no mute |

---

## C. Quality gate for this documentation task

| Check | Result |
|---|---|
| No audio in contracts | REQUIRED PASS |
| No national emergency number design | REQUIRED PASS |
| Observer limits documented | REQUIRED PASS |
| ACK ≠ RESOLVE | REQUIRED PASS |
| Child cancel auditable | REQUIRED PASS |
| Exemptions listed | REQUIRED PASS |
| Offline explicit | REQUIRED PASS |
| Screens mapped KEEP/EXTEND/MODIFY | REQUIRED PASS |
| Application code unchanged | REQUIRED PASS for this task |
| No remaining Owner decisions | REQUIRED PASS — open list empty |
| Contract status FROZEN | REQUIRED PASS on master |

---

## D. Out of scope for validation here

- Running `flutter test` / verify_ship  
- Implementing Observer UI corrections  
- Creating harness backlog cards  

Those follow in later authorized implementation phases.
