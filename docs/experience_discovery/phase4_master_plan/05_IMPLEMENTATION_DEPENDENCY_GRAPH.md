# PHASE 4 — Implementation Dependency Graph (05)

**Date:** 2026-09-25  
**Form:** PREREQUISITE → UNIT → UNLOCKS  
**Law:** Do not implement strictly by FS number. Follow dependencies.

## A. Foundation spine (must remain intact)

```text
Identity (FamilyContext, RoleGuard, roster)
    → FsSessionKernel / FsCompositionRuntime boot
        → LocalEventJournal + PolicySync/AuditAppend bridge
            → Audit append-only store
                → Domain Local stores (ST, WF, AC, Loc, Modes, SC, SOS, EDU, Prefs)
                    → Host/router bind (honesty)
                        → Journey loop closure (father↔child)
                            → [GATE] Native planes
                                → [GATE] Remote / AI Gateway / transport
```

## B. Critical edges (planning)

| id | from | to | why | if broken |
|----|------|-----|-----|-----------|
| D-01 | Identity | All SEC/COM/EDU/AIC hosts | ChildId + RBAC | Feature-local identity forks |
| D-02 | Events journal | Policy/Audit bridges | enqueue≠delivery honesty | Silent dual pipelines |
| D-03 | ST prefs/local | Time-request / Minutes paths | Economy + exemptions | Fake balance writes |
| D-04 | PolicyEngine.earn | EDU rewards | Rule 4–6 | Direct int rewards |
| D-05 | FS-001 loc_* | Modes / future road / optional FS-008 | Zone facts | Second location authority |
| D-06 | FS-002 wf_* | Unlock UI | Temp-allow owner | Prefs-as-production drift |
| D-07 | FS-003 ac_* | ST axes | App limits | Dual ST authority |
| D-08 | FS-004 sc_* | Monitoring UI | Policy≠capture | Claim live MediaProjection |
| D-09 | FS-005 modes | Lock interpreters | ≠ ST ScheduleWindow | Twin schedules |
| D-10 | FS-006 sos_final | SOS UI / Audit / Notif | Break-glass Local | Stage1 dual SOS |
| D-11 | FS-007 local classify | Safety UI | Separate from Advisor cloud | Fake on-device LLM |
| D-12 | ST/WF/AC/Modes usage facts | FS-009 aggregator | Reports don't own raw ST | Dual minutes owner |
| D-13 | Advisor/Insights | FS-009 weekly prose host | Rule 26 | FS-009 invents advice |
| D-14 | FS-010 durable messages | Transport ciphertext | Ephemeral=transport only | S-COM-050 revival |
| D-15 | AUD-C* Owner answers | FS-008 Local/NAT | Policy before mic | Invented Gate 7 |
| D-16 | REP-C1 Owner answer | FS-009 PDF plane | Policy before PDF | Fake PDF complete |
| D-17 | CHAT-C1/C2 Owner answers | FS-010 edit/delete audit | Policy before those UX | Invented chat law |
| D-18 | NAT GPS | Live locate journeys | Honesty | Map implies live fix |
| D-19 | NAT VPN/OS intercept/capture/wake | Enforcement claims | Honesty | UI claims OS block |
| D-20 | REM FCM/SMS/Gateway | Delivered SOS / live AI | Honesty | Local fire ≠ delivered |

## C. Forbidden merges

- Mic ≠ FS-004  
- Chat ≠ ST/Modes lock  
- Reports ≠ ST raw minutes owner  
- Audit never feature-owned mutate/delete  
- Transport never owns durable chat messages
