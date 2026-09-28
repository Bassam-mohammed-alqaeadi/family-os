# PHASE 4 — Vertical Slice Design (07)

**Date:** 2026-09-25  
**Slice =** smallest shippable path: trigger → authority → persist → visible feedback → downstream effect.

## Priority slices (dependency order)

| Slice ID | Name | Wave | Systems | Prerequisites | Readiness | Exit proof |
|----------|------|------|---------|---------------|-----------|------------|
| VS-01 | Identity session + roster restart | W0 | ADM:أ ب | Composition boot | READY | Restart proves roster; RoleGuard |
| VS-02 | Audit append from SOS/privacy | W0 | ADM:و · FS-006 | Audit Local | READY | Append-only; no update/delete API |
| VS-03 | Day board empty/one/many from Identity | W1 | ADM:ز | VS-01 | READY | No hardcoded child names/numerals |
| VS-04 | ST time-request → father approve → child reflect | W2 | SEC:أ | ST Local + Events | READY | Loop closure + Minutes rules if rewarded |
| VS-05 | WF unlock request → temp-allow | W2 | SEC:ج | WF Domain | READY | Prefs not second authority; VPN still MOCK |
| VS-06 | AC policy change → child interpret | W2 | SEC:ب | AC Domain | READY | OS intercept still MOCK |
| VS-07 | Safe zone CRUD → Domain loc_* | W2 | SEC:د | Loc Domain | READY | GPS still NOT_IMPLEMENTED |
| VS-08 | Modes window → lock interpret (≠ ST) | W2 | SEC:ل | Modes Domain | READY | ScheduleWindow non-duplicate |
| VS-09 | Child SOS fire → father alert Local | W2 | SEC:هـ | sos_final | READY | DeliveryClaim local≠FCM |
| VS-10 | Monitoring desired → policy store | W2 | SEC:و | SC Domain | READY | Capture still MOCK |
| VS-11 | EDU assignment create → child result | W3 | EDU:ب | EDU Local | READY | Restart persist |
| VS-12 | Reward Minutes via PolicyEngine.earn | W3 | EDU:و | PolicyEngine | READY | No raw int balance write |
| VS-13 | FS-007 local classify path | W3 | AIC:أ | FS-007 | READY | Advisor cloud not invoked |
| VS-14 | FS-010 durable send/receive Local | W4 | COM:أ | Owner CHAT-* as needed; Identity; Audit | BLOCKED BY POLICY (partial) | No S-COM-050; transport enqueue separate |
| VS-15 | FS-009 usage report Local aggregate | W4 | SEC:ي | ST/WF/AC/Modes facts; Privacy | BLOCKED BY POLICY for PDF | Aggregator≠ST owner |
| VS-16 | FS-008 session metadata Local | W4 | FS-008 | AUD-C* + S-PAR-030 registry | BLOCKED BY POLICY | Mic NAT separate |
| VS-17 | Native GPS live fix | W5 | SEC:د | W2 honesty | BLOCKED BY NATIVE | Real-device fix |
| VS-18 | Native VPN/DNS block | W5 | SEC:ج | W2 | BLOCKED BY NATIVE | Real-device |
| VS-19 | Native OS app intercept | W5 | SEC:ب | W2 | BLOCKED BY NATIVE | Real-device |
| VS-20 | AI Gateway Advisor swap | W7 | AIC:* | Rule 26 seams | BLOCKED BY REMOTE | Zero UI rewrite |

## Slice anti-patterns (forbidden)

- Shipping UI polish as “complete” while authority unbound  
- Claiming READY because widget tests pass on mocks  
- Implementing Native inside a Local slice  
- Resolving AUD/REP/CHAT by agent assumption
