# PHASE 3 — Data Ownership Map (03)

**Date:** 2026-09-25  
**Honesty:** Local / Stage1 InMemory / mock AI / NAT / REM are distinct states  

## Schema

`entity_or_store` · `namespace` · `runtime_honesty` · `owner` · `consumers` · `class`

## Stores

| entity_or_store | namespace | runtime_honesty | owner | consumers | class |
|-----------------|----------|-----------------|-------|-----------|-------|
| Family context / session | identity_* / FsSessionKernel | Local SQLite/kv (Phase 1.75) | Identity Domain | Router, RoleGuard, all FS | VERIFIED EXISTING |
| Children roster | identity / children list | Local persist (DOM-IDENTITY) | Identity | Day board, journeys | VERIFIED EXISTING |
| Location zones / history | loc_* | Domain SQLite; GPS fix NOT_IMPLEMENTED | FS-001 | Map UI, Modes, FS-008 optional | VERIFIED EXISTING |
| Web filter rules / temp-allow | wf_* | Domain SQLite; VPN block MOCK-REMOTE | FS-002 | WF screens, unlock | VERIFIED EXISTING |
| App control policy | ac_* | Domain SQLite; OS intercept MOCK-REMOTE | FS-003 | AC screens, ST axes | VERIFIED EXISTING |
| Screen Time policy / schedules / time-requests | st_* / prefs_misc ST | Local persist (DOM-ST-02*) | Screen Time | Child ST UI, inbox | VERIFIED EXISTING |
| Modes windows | modes_* | Domain SQLite | FS-005 | School mode UI | VERIFIED EXISTING |
| Screen/camera desired monitoring | sc_* + DesiredMonitoring | Domain + prefs; capture MOCK-REMOTE | FS-004 | Monitoring screens | VERIFIED EXISTING |
| SOS ladder / settings / alerts / break-glass | sos_* | sos_final Local; delivery MOCK-REMOTE | FS-006 | n10 hosts (bound) | VERIFIED EXISTING |
| Offline AI local classifier state | fs007 local | Local classify real; cloud UNSUPPORTED | FS-007 | Safety UI | VERIFIED EXISTING |
| Audit log | audit_* | Local append-only; no update/delete | Audit | Privacy UI, all emitters | VERIFIED EXISTING |
| Notification prefs | notif prefs | Local prefs-misc | ADM notifications | Notif screens | VERIFIED EXISTING |
| Privacy collection prefs | privacy prefs | Local prefs-misc | ADM privacy | Privacy screens | VERIFIED EXISTING |
| Device lock / anti-tamper prefs | lock/at prefs | Local prefs-misc; OS lock NAT | Prefs-misc | Lock / monitoring screens | VERIFIED EXISTING |
| Education assignments / results | edu local | Local persist (DOM-EDU-LOCAL) | EDU Domain | EDU screens | VERIFIED EXISTING |
| Local event journal / outbox | events_* | Local journal; enqueue≠delivery | Events core | Policy bridge, sync later | VERIFIED EXISTING |
| Advisor / Insights / Tutor mocks | mock AI repos | InMemory mock — Rule 26 seam | AIC (cloud later) | AI screens | REMOTE DEPENDENCY |
| Chat messages (target FS-010) | com chat | Analysis only; durable target; transport ephemeral | FS-010 | Chat screens | DESIGN GAP |
| Ambient mic session metadata (target FS-008) | aud_* TBD | No inventory service row; NAT mic | FS-008 | (no SCR yet) | REGISTRY GAP |
| Activity report cache (target FS-009) | rep_* TBD | Aggregation design; PDF OPEN | FS-009 | Report screens | DESIGN GAP |
| Subscription / billing | adm billing | Mock / remote later | ADM subscription | Owner screens | REMOTE DEPENDENCY |
| Quran content | licensed assets | Boundary — no AI verses | EDU Quran | Quran screens | REMOTE DEPENDENCY |

## Dual-authority watch (must stay closed)

| Risk | Status | class |
|------|--------|-------|
| Modes vs ST ScheduleWindow twin | Documented non-duplicate | VERIFIED EXISTING |
| Stage1 location under-bind vs Domain loc_* | Phase 1.75 residual tracked historically | VERIFIED EXISTING |
| Chat message store vs Transport ciphertext | Owner A: durable chat; ephemeral transport | VERIFIED EXISTING |
| S-COM-050 disappearing store | Deleted | CLOSED |
