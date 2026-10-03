# 01 — FS-006 L2 Owner Decisions Register

**System:** FS-006 — SOS / Emergency Safety System  
**Status:** **OWNER DECISIONS FROZEN** — imported from SOS Final (2026-09-23) · FS wrapper 2026-09-24  
**Sole product-law authority:** [`../sos_final/`](../sos_final/) · OD-01…OD-21 · RD-01…RD-05 · Q-SOS-RD-02A/02B/03A **CLOSED**  
**Evidence (non-authority):** [`../sos_discovery/`](../sos_discovery/) · Stage-1 Flutter  

**Entry:** [12_FS006_L2_MASTER_CONTRACT.md](12_FS006_L2_MASTER_CONTRACT.md) · [11_FS006_DECISION_CLOSURE_REPORT.md](11_FS006_DECISION_CLOSURE_REPORT.md)

```
FS-006 DISCOVERY: COMPLETE
FS-006 L2 POLICY: COMPLETE
OWNER DECISIONS: FROZEN
FS-006 L3: READY
IMPLEMENTATION: NOT AUTHORIZED
```

---

## A. Import rule (critical)

| Rule |
|---|
| This L2 package is a **wrapper** that places frozen SOS Final into the FS sequence. |
| It does **not** reopen, reinterpret, weaken, or replace OD/RD. |
| **No new Q-SOS-*** questions. |
| Presentation vocabulary normalizes Mother → **Co-Parent** (Full / Partner / Observer) and Father → **Primary Parent** **without changing permissions**. |
| Stage-1 mocks are evidence only — never product proof of delivery. |

**Canonical Final entry:** [`../sos_final/13_SOS_FINAL_MASTER_CONTRACT.md`](../sos_final/13_SOS_FINAL_MASTER_CONTRACT.md)

---

## B. Structural freezes (FS-006 / cross-system) — FROZEN

| ID | Frozen structural law | Source |
|---|---|---|
| **SOS-SF-01** | Vocabulary: **Primary Parent · Co-Parent · Child** (presentation); permissions = SOS Final OD-01…04 | Identity · Final |
| **SOS-SF-02** | AuthZ = **RBAC** only — never device possession | Q-SOS-RD-02A |
| **SOS-SF-03** | SOS always reachable; outside subscription · quiet hours · ST · entertainment · device lock · Modes · ordinary FS-002/003/004 gates | OD-14 · sibling L2 |
| **SOS-SF-04** | SOS is an **INCIDENT**; incident ≠ delivery | OD-19 · OD-20 |
| **SOS-SF-05** | ACK ≠ RESOLVED; RESOLVED does not delete | OD-05 · OD-18 |
| **SOS-SF-06** | Audio / video evidence **EXCLUDED**; no SOS mic broadcast | OD-11 · RD-03 |
| **SOS-SF-07** | National/local emergency dial **EXCLUDED** | OD-08 · OD-07 · OD-15 |
| **SOS-SF-08** | Break-glass temporary · allowlisted · audited · auto-revoke; never permanent policy mutation | RD-02 |
| **SOS-SF-09** | Panic Quiet = emergency-critical-only child UI (RD-01) | OD-12 |
| **SOS-SF-10** | FS-001 owns location facts/history; SOS attaches/consumes | FS-001 · OD-16 |
| **SOS-SF-11** | Policy Kernel interprets SOS facts/temporary overrides; does not invent SOS domain facts | Kernel |
| **SOS-SF-12** | Audit append-only for lifecycle + break-glass | Constitution · RD-03 |
| **SOS-SF-13** | AI suggest-only; no autonomous SOS policy execution | Constitution |
| **SOS-SF-14** | Offline: local-first · durable persist · outbox/retry · no false “sent” | OD-17 |
| **SOS-SF-15** | Operational evidence **90 days**; core+audit **indefinite** | RD-03 / Q-SOS-RD-03A |
| **SOS-SF-16** | Stage-1 mock fire/delivery = **non-authority** | Discovery |
| **SOS-SF-17** | Register P-4 “audio” wording superseded by OD-11 where conflicting | Final closure |
| **SOS-SF-18** | No second SOS product-law pack — `sos_final/` remains sole law | This wrapper |

---

## C. Owner decisions imported (OD → SOS-OD mapping)

Permissions unchanged; vocabulary normalized.

| FS ID | Imports | Frozen law (normalized vocabulary) |
|---|---|---|
| **SOS-OD-01** | OD-01 | **Co-Parent Observer:** receive; view essential; contact child. **Cannot** acknowledge, resolve, escalate, configure, break-glass. |
| **SOS-OD-02** | OD-02 | **Co-Parent Partner:** receive; view; ack; respond; escalate. **No** nuclear config / break-glass. |
| **SOS-OD-03** | OD-03 | **Co-Parent Full:** Partner powers + manage settings, contacts, escalation config + **break-glass**. |
| **SOS-OD-04** | OD-04 | **Primary Parent:** full SOS control. |
| **SOS-OD-05** | OD-05 | ACKNOWLEDGED ≠ RESOLVED. |
| **SOS-OD-06** | OD-06 | Child cancel only via confirm → false-alarm → parents informed → auditable. |
| **SOS-OD-07** | OD-07 | Auto-call family/trusted first. Never auto national emergency. |
| **SOS-OD-08** | OD-08 | National/local emergency numbers **EXCLUDED**. |
| **SOS-OD-09** | OD-09 | Push/in-app; SMS/call fallbacks; confirm before success claim. |
| **SOS-OD-10** | OD-10 | Evidence: location, device, battery, connection, delivery, lifecycle, audit. No audio/video. |
| **SOS-OD-11** | OD-11 | Audio **EXCLUDED**. |
| **SOS-OD-12** | OD-12 | Panic Quiet Mode **APPROVED** (RD-01). |
| **SOS-OD-13** | OD-13 | Break-glass **APPROVED** (RD-02 + Q-SOS-RD-02A/02B). |
| **SOS-OD-14** | OD-14 | Never gated by subscription, quiet hours, screen-time, entertainment, device lock (and Modes / ordinary package-web-camera gates per cross-system). |
| **SOS-OD-15** | OD-15 | Auto-escalation trusted only — never emergency-service dispatch. |
| **SOS-OD-16** | OD-16 | Location fail still activates; READY/ACQUIRING/STALE/UNAVAILABLE. |
| **SOS-OD-17** | OD-17 | Offline: local first; persist; queue; retry; fallbacks; no false “sent”. |
| **SOS-OD-18** | OD-18 | RESOLVED does not delete; lifecycle auditable. |
| **SOS-OD-19** | OD-19 | SOS is an **INCIDENT**. |
| **SOS-OD-20** | OD-20 | Delivery state ≠ incident state. |
| **SOS-OD-21** | OD-21 | Readiness visible honestly to appropriate parents. |

### RD imports (CLOSED — not reopened)

| FS ID | Imports | Frozen behavior |
|---|---|---|
| **SOS-RD-01** | RD-01 | Active SOS child = emergency-critical only |
| **SOS-RD-02A** | Q-SOS-RD-02A | Break-glass: Primary + Co-Parent Full; RBAC; never device-ownership |
| **SOS-RD-02B** | Q-SOS-RD-02B | Allowlist / forbidden / lifecycle START→REASON→OVERRIDE_ACTIVE→EXPIRY→AUTO_REVOKE→AUDIT |
| **SOS-RD-03** | Q-SOS-RD-03A | Ops evidence 90d; core+audit indefinite; no A/V |
| **SOS-RD-04** | RD-04 | Contact verify UNVERIFIED→PENDING→VERIFIED→REVOKED |
| **SOS-RD-05** | RD-05 | Max 5 backups; priority 1…5; rung-1 immutable |

---

## D. Q-SOS status

| Status |
|---|
| **NONE open** |
| Prior Q-SOS-RD-02A/02B/03A remain **CLOSED** in `sos_final/` |
| FS-006 Discovery opened **no** new Q-SOS |

---

## E. Technical still OPEN (imported from Discovery)

**T-SOS-01…14 = OPEN / TBD** — see [11_FS006_DECISION_CLOSURE_REPORT.md](11_FS006_DECISION_CLOSURE_REPORT.md).  
Do not invent SMS/FCM/workers/schema/TTLs/algorithms in L2.
