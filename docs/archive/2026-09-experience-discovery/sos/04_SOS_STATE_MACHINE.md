# 04 — SOS State Machine

**CURRENT app states:** `active` | `resolved` (`SosAlertStatus`).  
**Schema / REQUIRED states:** `ACTIVE` | `ACKNOWLEDGED` | `RESOLVED`.  
**PROPOSED** intermediate UX states below are design — not implemented unless marked CURRENT.

---

## Overview diagram

```
IDLE
  │ hold start
  ▼
HOLDING ──(release early)──► IDLE (cancelled protection message)
  │ hold complete (3s)
  ▼
FIRING ──(seed alert)──► ACTIVE
                            │
          ┌─────────────────┼─────────────────┐
          ▼                 ▼                 ▼
     ACKNOWLEDGED      ESCALATED*        RESOLVED
     (schema/intent)   (flag on ACTIVE)  (parent or child)
          │                 │
          └────────► RESOLVED

DEGRADED_* overlays may apply while ACTIVE (network/location/battery/channel).
```

\* CURRENT: escalate only increments a counter; state remains `active`.

---

## States

### IDLE

| Field | Content |
|---|---|
| Entry | No active alert in `SosAlertRepository` |
| Allowed | Open CHD-005; start hold |
| Forbidden | Show ACTIVE boards as live |
| UI | CHD-005 idle; FAT-018 empty → setup CTA |
| Events | — |
| Notifications | — |
| Data | — |
| Child device | Normal; FAB visible (except on 005/006) |
| Recovery | N/A |

### HOLDING (CURRENT UI)

| Field | Content |
|---|---|
| Entry | Pointer down on hold button |
| Allowed | Complete hold; release/cancel |
| Forbidden | Fire before duration |
| UI | Countdown; pulse |
| Events | — |
| Notifications | — |
| Data | — |
| Child device | Holding |
| Recovery | Release → cancelled-early message → IDLE |

### FIRING (CURRENT UI)

| Field | Content |
|---|---|
| Entry | Hold completed |
| Allowed | Await `fireAndSeedSosAlert` |
| Forbidden | Second concurrent fire (guarded by flags) |
| UI | “Firing…” status |
| Events | Mock `SosFireResult` |
| Notifications | Simulated critical deliveries |
| Data | Seed `SosAlert` active |
| Child device | Navigate CHD-006 |
| Recovery | If seed fails — **UNKNOWN** / error path limited |

### ACTIVE (CURRENT + target)

| Field | Content |
|---|---|
| Entry | Active alert seeded / `POST /sos` (target) |
| Allowed | Parent: call, map, resolve, escalate. Child: call father, confirm-safe |
| Forbidden | Mute SOS; paywall; drop without audit (target) |
| UI | FAT-018 coral board; CHD-006 coral board |
| Events CURRENT | resolve; escalate++ |
| Events TARGET | location updates; delivery receipts; ack |
| Notifications CURRENT | none after fire |
| Notifications TARGET | piercing critical; updates; cancel/resolve notices |
| Data | status active; fixture meta today |
| Child device | In-progress UI; exemptions remain |
| Recovery | Resolve → empty; reopen CHD-005 |

### ACKNOWLEDGED (SCHEMA / PROPOSED — not in app enum)

| Field | Content |
|---|---|
| Entry | Parent ack API / UI |
| Allowed | Continue live map/call; escalate; resolve |
| Forbidden | Treat as closed |
| UI | Parent saw badge; child “parent acknowledged” (honest) |
| Events | `SosAcknowledged` |
| Notifications | Optional ack toast to other guardians |
| Data | `status = ACKNOWLEDGED`; `received` actor |
| Child device | Update status card from live receipts |
| Recovery | Still ACTIVE-like until RESOLVED |

### ESCALATED (PROPOSED flag on ACTIVE)

| Field | Content |
|---|---|
| Entry | Manual escalate CTA or timer ladder |
| Allowed | Further national escalate; resolve |
| Forbidden | Silent failure without UI |
| UI | Escalation status on FAT-018 |
| Events | `SosEscalated` with channel results |
| Notifications | Backup SMS/call attempts |
| Data | escalation log |
| Child | Optional “help expanding” honesty |
| Recovery | Channel failure → degraded UI |

### RESOLVED (CURRENT)

| Field | Content |
|---|---|
| Entry | `resolve(alertId)` parent or child |
| Allowed | View empty; open setup; history (target) |
| Forbidden | Show as live |
| UI | Empty boards; toasts; nav away |
| Events | resolve (CURRENT in-memory) |
| Notifications TARGET | “resolved / safe” to guardians |
| Data | cleared active; resolved list in memory |
| Child | Toast → CHD-004 |
| Recovery | New trigger creates new alert id |

### DEGRADED overlays (PROPOSED)

`DEGRADED_NO_NETWORK`, `DEGRADED_NO_LOCATION`, `DEGRADED_NO_SMS`, `DEGRADED_NO_CALL`, `DEGRADED_PARENT_UNREACHABLE`, `DEGRADED_LOW_BATTERY`

Entry: capability probe fails while ACTIVE.  
Forbidden: claim “live broadcast” or “delivered” without evidence.  
Recovery: retry; queue; fallback channel; honest status chips.

---

## Forbidden global actions (law)

- Gate SOS behind subscription, quiet hours, time expiry, or device lock
- Show mute-SOS control to any role
- Remove father/mother from rung 1
- Delete SOS audit history (audit repo has no update/delete)
