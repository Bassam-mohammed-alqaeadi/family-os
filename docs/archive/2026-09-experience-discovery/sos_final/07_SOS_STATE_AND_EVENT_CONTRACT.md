# 07 — SOS State & Event Contract

**Status:** FROZEN  
**SOS PRODUCT CONTRACT STATUS: FROZEN**  
**Principle (OD-19, OD-20):** Incident lifecycle ≠ transport/delivery state.

---

## 1. Why separation is mandatory

| If merged… | Failure mode |
|---|---|
| “Delivered” = “Resolved” | Parents think emergency is over when only push arrived |
| “Failed push” = “Inactive” | Child thinks help cancelled when incident still ACTIVE |
| “Location unavailable” = “Cannot SOS” | Violates OD-16 |
| Single badge | Observer/Partner misread urgency |

**Incident state** answers: *What is the family emergency status?*  
**Transport state** answers: *Did channel X reach recipient Y?*  
**Location/device states** answer: *What evidence quality do we have?*

---

## 2. Incident lifecycle (frozen)

```
IDLE
  → HOLDING          (pointer down; no incident yet)
  → FIRING           (hold complete; creating local incident)
  → ACTIVE           (durable incident exists)
  → ACKNOWLEDGED     (eligible parent acknowledged; still open)
  → ESCALATING       (trusted escalation in progress / rung advanced)
  → RESOLVED         (closed; retained; not deleted)
```

### Cancel path

From ACTIVE | ACKNOWLEDGED | ESCALATING (if still open):  
Child confirm → **RESOLVED** with terminal reason `FALSE_ALARM` **or** explicit terminal status `CANCELLED` stored as closed subtype.

**Frozen choice for contracts:** use terminal reason on RESOLVED:

- `RESOLVED_HELPED`  
- `RESOLVED_FALSE_ALARM`  
- `RESOLVED_OTHER`

Incident record always retained (OD-18).

### Entry / allowed / forbidden (summary)

| State | Entry | Allowed | Forbidden |
|---|---|---|---|
| IDLE | No open incident | Start hold | Show as live emergency |
| HOLDING | Pointer down | Complete / release | Create incident early |
| FIRING | Hold done | Persist local | Claim remote sent |
| ACTIVE | Persist ok | Ack/Escalate/Resolve/Cancel(child)/Contact | Observer ack/escalate/resolve |
| ACKNOWLEDGED | Ack action | Escalate/Resolve/Contact/Cancel(child) | Treat as closed |
| ESCALATING | Escalate/auto | Continue rungs/Resolve/Cancel(child) | Emergency-service auto dial |
| RESOLVED | Resolve/cancel | View history | Mutate as live; delete |

---

## 3. Independent transport / degraded states

These attach to incident or to (incident, recipient, channel) — **never replace lifecycle.**

| State | Scope | Meaning |
|---|---|---|
| DELIVERY_PENDING | recipient×channel | Attempt not confirmed |
| DELIVERED | recipient×channel | Confirmed delivery |
| DELIVERY_FAILED | recipient×channel | Confirmed failure |
| LOCATION_ACQUIRING | incident | Seeking fix |
| LOCATION_STALE | incident | Last-known old |
| LOCATION_UNAVAILABLE | incident | No usable location |
| LOCATION_READY | incident | Fresh fix (companion to OD-16 READY) |
| DEVICE_OFFLINE | device | No network |
| NETWORK_DEGRADED | device | Poor/partial connectivity |

UI may show multiple simultaneously, e.g. `ACTIVE + DELIVERY_PENDING + LOCATION_ACQUIRING`.

---

## 4. Canonical events

| Event | Producer | Consumers | Audit |
|---|---|---|---|
| SosIncidentCreated | Child (HOLD) | Sync, notify fan-out | Yes |
| SosDeliveryAttempted | Notifier | UI receipts | Yes |
| SosDeliveryConfirmed | Notifier | UI | Yes |
| SosDeliveryFailed | Notifier | Fallback engine | Yes |
| SosLocationUpdated | Child device | Parent/child UI | Yes (sampled) |
| SosAcknowledged | Partner+ | Child UI, others | Yes |
| SosEscalated | Partner+ / timer | Trusted notify | Yes |
| SosResolved | Partner+ | Stop streams, notify | Yes |
| SosFalseAlarmCancelled | Child | Parent notify | Yes |
| SosBreakGlassInvoked | Primary / Mother Full (RBAC) | Policy Kernel temp override | Yes — actor, allowlisted capability, reason/context, expiry |
| SosBreakGlassAutoRevoked | System at EXPIRY | Clear override | Yes |
| SosBreakGlassEnded | Parent/system | Clear override | Yes |
| SosPanicQuietModeChanged | Primary/Full | Child active UI | Yes |
| SosLadderConfigured | Primary/Full | Escalation engine | Yes |
| SosContactVerificationChanged | Primary/Full / verifier port | Escalation eligibility | Yes |
| SosEvidencePurged | Retention worker | Storage meta | Yes (does not delete audit) |

**No events** for audio capture/broadcast.

**triggerSource:** `HOLD` (child). Break-glass is a **separate override lifecycle**, not incident create.

### Break-glass override state machine (frozen)

```
START → REASON/CONTEXT → OVERRIDE_ACTIVE → EXPIRY → AUTO_REVOKE → AUDIT
```

Early manual end also → AUDIT. Never writes permanent policy.
---

## 5. Auto-escalation machine (trusted only)

While incident in ACTIVE or ACKNOWLEDGED:

- Order backups by **priority 1…5** (RD-05).  
- Consider only **VERIFIED** + enabled (RD-04).  
- Timer per `delaySeconds` after trigger or after non-ack policy.  
- On fire: mark ESCALATING; attempt configured channels; record delivery states.  
- **Never** interpret as emergency-service dispatch (OD-15, OD-08).

---

## 6. Idempotency

- `request_id` unique per create (schema).  
- Duplicate sync retries must not create duplicate ACTIVE incidents for same request.  
- Ack/Resolve are idempotent per actor where possible.
