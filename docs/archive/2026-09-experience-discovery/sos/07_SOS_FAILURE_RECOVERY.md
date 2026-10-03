# 07 — SOS Failure & Recovery

**CURRENT FACT:** Most degraded paths are unmodeled; fire mock always succeeds.  
**PROPOSED DESIGN:** honest degraded overlays while ACTIVE (see state machine).

---

## Failure matrix

| Failure | CURRENT | TARGET behavior | Recovery |
|---|---|---|---|
| **No internet** | UNKNOWN / unproven | Local ACTIVE UI; queue `POST /sos`; try SMS if SIM | Sync on reconnect; show queued |
| **No location** | Demo labels always shown | Fire anyway; UI “location unavailable” / last-known | Retry GPS; never block fire |
| **Low battery** | % fixture only | Reduce ping cadence; never block fire | Low-battery honesty chip |
| **Child device offline** | N/A (single process mock) | Parent sees last-known + offline since | Ladder SMS/call to child number |
| **Parent offline** | Sim always delivers | Retry push; SMS fallback to parent | In-app badge on reopen |
| **Notification failure** | Not modeled | Mark delivery failed; escalate channel | Retry + backup SMS/email |
| **SMS available** | Absent | Send trusted-contact / parent SMS | Receipt tracking |
| **SMS unavailable** | — | Mark channel N/A; continue push/call | Honest chip |
| **Call available** | Snackbar / chat nav | Auto or manual dial/VoIP | Log attempt |
| **Call unavailable** | — | Disable auto-call with reason | Manual retry |
| **Quiet hours** | Critical still “delivered” in sim | OS critical alert still rings | N/A (must pierce) |
| **Subscription expired** | Fire works (arch) | Same forever | N/A |
| **Time expired / device lock** | Exempt surface helpers | SOS still reachable | N/A |
| **Partial audio fail** | Audio absent | Location still; honest “audio unavailable” | Retry mic perm |
| **Duplicate fire / storm** | Limited UI guards | Coalesce by `request_id` | Drop dupes without dropping ACTIVE |
| **False alarm cancel** | Child resolve clears | Notify guardians cancel/safe (**OWNER** text) | Audit entry |

---

## Recovery principles (PROPOSED)

1. **Never claim success** without channel evidence.  
2. **Never refuse fire** for network/location/plan/lock.  
3. **Prefer degraded active** over silent failure.  
4. **Idempotent** server ingest via `request_id`.  
5. **Father-set ladder continues** even if one parent unreachable (P-5).

---

## Test obligations (from UF-08 / service catalog — not all present)

- Subscription expired → fire still works (partially covered UI-007).  
- Time expired → SOS reachable (UI-011).  
- Airplane mode → must PASS (REQUIRED; **not proven on device** — UNKNOWN).
