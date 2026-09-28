# PHASE 3 — Full Dependency Graph (09)

**Date:** 2026-09-25  
**Edge form:** OWNER → FACT → CONSUMER → INTERPRETATION  

## Schema

`edge_id` · `owner` · `fact` · `consumer` · `interpretation` · `class`

## Cross-cutting edges

| edge_id | owner | fact | consumer | interpretation | class |
|---------|-------|------|----------|----------------|-------|
| E-ID-01 | Identity | FamilyContext / role | RoleGuard / all FS | Session gates routes | VERIFIED EXISTING |
| E-ID-02 | Identity | Child roster | Day board / EDU / ST | ChildId functions only | VERIFIED EXISTING |
| E-AU-01 | Audit | Append-only log | Privacy UI | No mutate/delete | VERIFIED EXISTING |
| E-EV-01 | Events | Local journal envelope | Policy bridge | Local bind ≠ remote sync | VERIFIED EXISTING |
| E-TR-01 | Transport (future) | Ciphertext enqueue | Chat / SOS delivery | Ephemeral relay; not message owner | DESIGN GAP |
| E-POL-01 | PolicyEngine | Minutes earn | EDU rewards / approvals | Sole earn path | VERIFIED EXISTING |

## FS → FS / Domain edges

| edge_id | owner | fact | consumer | interpretation | class |
|---------|-------|------|----------|----------------|-------|
| E-001-01 | FS-001 | Zone/exit | FS-005 Modes | Mode may consume location | VERIFIED EXISTING |
| E-001-02 | FS-001 | Zone/exit | FS-008 (optional) | Only if AUD-C2 binds Gate 7 | POLICY DECISION REQUIRED |
| E-001-03 | FS-001 | Location facts | COM:ز / road safety | Consume only | OUT OF SCOPE |
| E-002-01 | FS-002 | Block/allow | Child browse path | VPN plane MOCK-REMOTE | NATIVE DEPENDENCY |
| E-003-01 | FS-003 | App policy | OS intercept | MOCK-REMOTE | NATIVE DEPENDENCY |
| E-003-02 | FS-003 / ST | ST axes | Child ST UI | Prefs/local ST owner | VERIFIED EXISTING |
| E-004-01 | FS-004 | Monitoring desired | Capture pipeline | Policy ≠ capture live | NATIVE DEPENDENCY |
| E-004-02 | FS-004 | — | FS-008 mic | **Must not own mic** | VERIFIED EXISTING |
| E-005-01 | FS-005 | Mode windows | Lock interpreters | ≠ ST ScheduleWindow | VERIFIED EXISTING |
| E-006-01 | FS-006 | SOS fire | Audit / Notif | Local; delivery remote mock | REMOTE DEPENDENCY |
| E-006-02 | FS-006 | — | FS-008 | **No SOS evidence audio ownership** | VERIFIED EXISTING |
| E-007-01 | FS-007 | Local classify | Safety UI | Cloud Advisor separate | VERIFIED EXISTING |
| E-008-01 | FS-008 | Session events | Audit / Notif | Mother+child notify (design) | DESIGN GAP |
| E-009-01 | ST/WF/AC/Modes | Usage facts | FS-009 aggregator | FS-009 does not own raw ST | DESIGN GAP |
| E-009-02 | Privacy | Retention/forget | FS-009 | Honor retention | POLICY DECISION REQUIRED |
| E-009-03 | Advisor | Weekly prose | FS-009 host | FS-009 hosts only | VERIFIED EXISTING |
| E-010-01 | FS-010 | Durable message | Transport | Ciphertext enqueue | DESIGN GAP |
| E-010-02 | FS-010 | Exemption demand | Modes/ST/AC | Chat untouchable (C-1) | VERIFIED EXISTING |
| E-010-03 | FS-010 | — | S-COM-050 | Must not recreate | CLOSED |

## Graph reading rule

Consumers **interpret** facts; they do not become a second owner. Conflicts → Gap Register / QUESTIONS — not silent merge.
