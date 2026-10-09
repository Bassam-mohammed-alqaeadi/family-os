# 08 — SOS Failure & Offline Contract

**Status:** FROZEN  
**Source:** OD-16, OD-17, OD-09

---

## 1. Offline-first activation

```
Trigger
  → write local incident (durable)
  → UI ACTIVE (local)
  → enqueue sync + channel jobs
  → attempt push / SMS / call per availability
  → confirm each channel independently
```

**Forbidden:** Showing “Sent to parents” based only on local create.

**Allowed honesty copy:** “SOS started on this device — notifying family…” / “Waiting for confirmation…”

---

## 2. Failure playbooks

| Failure | Incident | Transport | UX | Recovery |
|---|---|---|---|---|
| No internet | ACTIVE local | PENDING / DEVICE_OFFLINE | Sync pending | Queue + retry + fallbacks |
| No location | ACTIVE | LOCATION_UNAVAILABLE | Honesty chip | Retry acquire; use last-known→STALE |
| Stale location | ACTIVE | LOCATION_STALE | Label age | Refresh |
| Low battery | ACTIVE | evidence | Battery chip; maybe slower pings | Never block |
| Child offline (parent view) | ACTIVE | last sync time | Offline since | SMS/call to child if configured |
| Parent offline | ACTIVE | DELIVERY_PENDING/FAILED for that parent | Others may DELIVERED | Retry on reconnect; missed-incident inbox |
| Push failed | ACTIVE | DELIVERY_FAILED(push) | Try SMS/call | Fallback |
| SMS unavailable | ACTIVE | channel UNAVAILABLE/NOT CONFIGURED | Honest | Continue other channels |
| Call unavailable | ACTIVE | same | Honest; skip auto-call | Manual when available |
| Partial escalate | ESCALATING | mixed delivery | List per contact | Retry failed rungs |
| Persist fail (disk) | May fail fire | — | Hard error + retry | Critical; rare |

---

## 3. Channel confirmation rules (OD-09)

| Channel | “Success” means |
|---|---|
| In-app | Guardian session received incident payload |
| Push | Provider + device ack / equivalent confirmed receipt policy |
| SMS | Gateway accepted **and** best-effort delivery receipt if available; else “submitted” ≠ “delivered” — label honestly |
| Call | Dialer/VoIP reports connected or ringing started per platform capability — label “Call placed” vs “Answered” separately if knowable |

If uncertain: **PENDING**, not DELIVERED.

---

## 4. Reconnection

1. Child reconnect → drain outbox → reconcile server incident id → refresh deliveries.  
2. Parent reconnect → fetch open incidents → if any ACTIVE/ACK/ESCALATING, force incident board / badge.  
3. Conflict: server wins on lifecycle if advanced (e.g. already RESOLVED); merge evidence chronologically.

---

## 5. Never-do list

- Cancel incident because location failed  
- Cancel incident because push failed  
- Auto-dial emergency services on any failure  
- Claim SMS/call success without confirmation  
- Delete incident on resolve  
- Let quiet hours / lock / subscription hide failure recovery UI for SOS
