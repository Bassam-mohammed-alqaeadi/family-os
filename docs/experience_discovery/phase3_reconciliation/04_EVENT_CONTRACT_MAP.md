# PHASE 3 — Event / Contract Map (04)

**Date:** 2026-09-25  
**Law:** `queued_locally` / DeliveryClaim ≠ remote delivery  

## Schema

`channel_or_event` · `producer` · `consumer` · `delivery_claim` · `class`

## Channels

| channel_or_event | producer | consumer | delivery_claim | class |
|------------------|----------|----------|----------------|-------|
| LocalEventJournal append | Feature emitters / LocalEventEmitter | Journal store; Policy bridge | Local durable only | VERIFIED EXISTING |
| LocalEventPolicyBridge | Journal | Policy sync / interpretation | Local bind | VERIFIED EXISTING |
| PolicySyncBus | Prefs/Domain writers | Subscribed runtimes | In-process local | VERIFIED EXISTING |
| AuditAppend | SOS / privacy / FS emitters | Audit repository | Local append; no remote | VERIFIED EXISTING |
| SOS lifecycle (fire / escalate / resolve / break-glass) | FS-006 sos_final | Alert UI; Audit; Notif prefs | Local fire; remote FCM/SMS MOCK-REMOTE | NATIVE DEPENDENCY / REMOTE DEPENDENCY |
| Time-request create / approve | Child ST / Father inbox | ST policy; Minutes via PolicyEngine | Local | VERIFIED EXISTING |
| Web unlock request / grant | WF screens | WF temp-allow | Local; VPN still MOCK-REMOTE | VERIFIED EXISTING |
| Modes evaluate-on-open | FS-005 | Lock/interpret consumers | Local; OS wake MOCK-REMOTE | NATIVE DEPENDENCY |
| FamilyEvent typed bus (Rule 26) | Features | Sync queue / AI hooks | Enqueue local; AI Gateway remote later | REMOTE DEPENDENCY |
| Advisor suggestion approve/reject | FatherSession | AdvisorRepository | Local decision; no execute() | VERIFIED EXISTING |
| Chat send / edit / delete-for-all (FS-010 target) | Chat UI | Durable store + Transport enqueue | Local durable + ciphertext queue; delivery remote | DESIGN GAP |
| Mic session start/stop (FS-008 target) | Father listen UI | Session metadata + Audit/Notif | Local metadata; mic NAT | REGISTRY GAP |
| Report generate / share (FS-009 target) | Report UI | Aggregator + share sheet | Local cache; email/PDF remote OPEN | POLICY DECISION REQUIRED |
| Identity roster seed events | Identity runtime | Day board | Local | VERIFIED EXISTING |

## Orphan / honesty notes

| Finding | class |
|---------|-------|
| No producer may claim FCM/SMS delivered from local enqueue alone | VERIFIED EXISTING |
| Cloud AI classify channel UNSUPPORTED until Gateway | REMOTE DEPENDENCY |
| FS-008/009/010 event contracts exist in analysis packs — not production-wired | DESIGN GAP |
