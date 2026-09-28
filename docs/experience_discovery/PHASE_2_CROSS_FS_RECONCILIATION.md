# PHASE 2 — Cross-FS Reconciliation (FS-008 ↔ FS-009 ↔ FS-010)

**Date:** 2026-09-25  
**Mode:** Analysis only  

---

## 1. System identities

| ID | Title | Product core |
|----|-------|--------------|
| FS-008 | One-Way Audio | Father ambient mic listen (S-PAR-030) |
| FS-009 | PDF Activity Reports | Usage + weekly activity reporting (PDF format OPEN) |
| FS-010 | Ephemeral Family Chat | **Durable** family messaging; ephemeral = transport only |

No ownership collapse between the three.

---

## 2. Authority uniqueness check

| Authority | Owner | Must not duplicate |
|-----------|-------|-------------------|
| Ambient mic sessions | FS-008 | FS-004 SC · FS-006 SOS evidence audio |
| Activity report aggregation | FS-009 | ST raw minutes owner remains ST |
| Weekly recommendation text | Advisor/Insights (Rule 26) | FS-009 hosts only |
| Durable chat messages | FS-010 | Transport · Audit · Notifications |
| Disappearing messages | **NONE** (deleted) | FS-010 must not recreate |
| Audit append-only | Audit Log | All three emit only |
| Identity RBAC | Identity | All three consume |

**PASS** — no duplicate owners introduced in Phase 2 docs.

---

## 3. Cross-system contracts

| From → To | Fact | Notes |
|-----------|------|-------|
| FS-001 → FS-008 | Zone/exit facts | Optional if AUD-C2 binds Gate 7 |
| FS-008 → Audit/Notif | Session events | Mother+child notify |
| FS-008 ↛ FS-006 | No SOS audio evidence | Hard |
| ST/WF/AC/Modes → FS-009 | Usage facts | FS-009 aggregates |
| Privacy → FS-009 | Retention/forget | Honor |
| FS-010 → Modes/ST/AC | Exemption demand | C-1 untouchable |
| FS-010 → Transport | Ciphertext enqueue | Ephemeral relay |
| FS-008/009/010 | Pairwise | No shared stores |

---

## 4. Offline / Local / Native / Remote matrix

| FS | Local | Offline | Native | Remote |
|----|-------|---------|--------|--------|
| 008 | Session metadata target | Partial without mic | Mic capture | E2E seal/listen sync |
| 009 | Report cache target | Stale snapshot OK | Share sheet if PDF later | Email |
| 010 | Durable messages target | Full Local read/send queue | None for text | Relay/push/E2E |

Honesty: none of Native/Remote planes implemented in Phase 2.

---

## 5. Inventory reconciliation (seed)

### Services (subset of 240)

| FS | Registry services |
|----|-------------------|
| 008 | `S-PAR-030` **missing from CSV** — gap |
| 009 | S-SEC-050…053 · S-AIC-019 |
| 010 | S-COM-001…009 (**not** 050) |

### Journeys (subset of 73)

| FS | Journeys |
|----|----------|
| 008 | **none** — gap |
| 009 | JRN-FAT-33 · 36 · 45 |
| 010 | JRN-FAT-11 · JRN-MOT-04 · JRN-CHD-04 |

### Screens (subset of 130)

| FS | Screens |
|----|---------|
| 008 | **none** — gap |
| 009 | SCR-FAT-069 · 073 · 086 |
| 010 | SCR-FAT-021/022 · SCR-CHD-007/008 |

### Systems (42)

| FS | Domain subsystem |
|----|------------------|
| 008 | SEC advanced monitoring (Domain 1 §) |
| 009 | SEC ي reports + AIC weekly |
| 010 | COM أ conversations |

Full 42-letter re-enumeration is **not** redefined here; FS packs map into existing Domain inventory without claiming to replace the 42-system register.

---

## 6. Unresolved register (Phase 2 exit)

| ID | Item | Class |
|----|------|-------|
| AUD-C1 | 60s vs 10 min clip | EXPLICITLY UNRESOLVED |
| AUD-C2 | Reason-anytime vs SOS/zone-only | EXPLICITLY UNRESOLVED |
| AUD-C3 | SOS interaction nuance | EXPLICITLY UNRESOLVED |
| AUD-C6 | iOS support | EXPLICITLY UNRESOLVED |
| AUD-C7 | Insert S-PAR-030 + SCR/JRN | EXPLICITLY UNRESOLVED (registry debt) |
| REP-C1 | PDF export mandate | EXPLICITLY UNRESOLVED |
| REP-C2 | Retention edge cases | EXPLICITLY UNRESOLVED |
| CHAT-C1 | Edit revision depth | EXPLICITLY UNRESOLVED |
| CHAT-C2 | Audit on delete-for-all | EXPLICITLY UNRESOLVED |
| CHAT-C3 | Message SQLite schema | OUT OF SCOPE (implementation) |
| NAT/REM live | All three | OUT OF SCOPE Phase 2 |
| S-COM-050 | Disappearing chat | CLOSED (deleted; FS-010 must not revive) |
| FS810 identity | Titles | CLOSED |
| FS010 vs Domain2 | Interpretation A | CLOSED |

**No BLOCKING items remain for Phase 2 analysis completion** given Owner resolutions.

---

## 7. Acceptance

```text
CROSS-FS RECONCILE: COMPLETE
PHASE 2 ANALYSIS SCOPE: READY FOR ACCEPTANCE AUDIT
```
