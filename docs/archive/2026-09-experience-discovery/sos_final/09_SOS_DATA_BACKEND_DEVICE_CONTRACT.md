# 09 — SOS Data, Backend & Device Contract

**Status:** FROZEN (contracts only — no code)  
**SOS PRODUCT CONTRACT STATUS: FROZEN**  
**Exclusions:** No audio fields/APIs; no national emergency number fields.

---

## 1. Domain model (incident-centric)

### SosIncident (logical)

| Field | Notes |
|---|---|
| id | UUID |
| requestId | Idempotency |
| familyId, childId | |
| status | ACTIVE \| ACKNOWLEDGED \| ESCALATING \| RESOLVED |
| terminalReason | HELPED \| FALSE_ALARM \| OTHER (when RESOLVED) |
| triggeredAt, acknowledgedAt, resolvedAt | |
| acknowledgedBy, resolvedBy | account ids |
| triggerSource | HOLD (child). Break-glass is **not** a create source (RD-02). |
| locationState | READY\|ACQUIRING\|STALE\|UNAVAILABLE |
| lastLat, lastLon, locationUpdatedAt, accuracyM | nullable |
| batteryPercent, connectionState | evidence |
| panicQuietModeAtTrigger | bool snapshot |
| evidenceRetainUntil | optional; default triggeredAt+90d policy (RD-03) |

### SosDeliveryAttempt

| Field | Notes |
|---|---|
| incidentId, recipientId | |
| channel | PUSH \| IN_APP \| SMS \| CALL |
| state | PENDING \| DELIVERED \| FAILED |
| attemptedAt, confirmedAt | |
| errorCode | nullable |

### SosLadderConfig / SosBackupContact

| Field | Notes |
|---|---|
| rung1 parents | fixed father+mother |
| backups | max **5**; `priority` 1…5 unique; displayName; relation; msisdn?; delaySeconds; enabled; **verificationStatus** UNVERIFIED\|PENDING\|VERIFIED\|REVOKED |
| **No** emergencyServiceNumber field |

### SosBreakGlassOverride

| Field | Notes |
|---|---|
| id, incidentId, actorId | actor must pass RBAC (Primary or Mother Full) |
| capabilityId | **Must** be on Q-SOS-RD-02B allowlist |
| reason / context | required at START |
| startedAt, endsAt | time-bounded |
| state | START \| REASON_CAPTURED \| OVERRIDE_ACTIVE \| EXPIRED \| AUTO_REVOKED \| ENDED |
| endedAt, endReason | EXPIRY \| MANUAL \| SUPERSEDED |

### Evidence retention (Q-SOS-RD-03A) — FROZEN

| Class | Retention | Examples |
|---|---|---|
| Operational samples | **90 days** | location samples; delivery attempts/results; device snapshots; battery/connectivity; escalation event details; communication state |
| Core header + lifecycle audit | **Indefinite** | incident identity; family/child refs; trigger time; ack; escalation; resolve/cancel; actors; Break-glass audit; core lifecycle events |
| Audio/video | **Forbidden** | — |

`evidenceRetentionDays` default = 90 for operational samples only.

### SosReadiness / FamilySosSettings

| Field | Notes |
|---|---|
| panicQuietMode | bool — active-incident child critical-only (RD-01) |
| channel capabilities snapshot | per device |
| lastReadinessCheckAt | |
| evidenceRetentionDays | 90 (operational samples only) |

### Evidence timeline entries

Operational samples + lifecycle events — **no audio/video blobs**. Sample purge after 90 days; audit retained indefinitely.

---

## 2. Schema alignment

Existing `sos_alert` (`ACTIVE|ACKNOWLEDGED|RESOLVED`) is the base.  
**PROPOSED additive (future migration — not implementing now):**

- `escalating` representation (status value or flag)  
- `terminal_reason`  
- `trigger_source` (HOLD)  
- delivery_attempt table  
- ladder/contacts with phone + **verification_status** + **priority** + max 5  
- break_glass_override table  
- evidence retention policy metadata  
- **Forbid** audio/video columns  

`resolved` never deletes incident/audit rows (OD-18). Evidence **samples** may archive after 90 days (RD-03).

---

## 3. API sketch (ungated safety)

| Method | Purpose | AuthZ |
|---|---|---|
| POST /sos | Create incident | Child device; no plan check |
| POST /sos/{id}/ack | Acknowledge | Primary/Full/Partner |
| POST /sos/{id}/escalate | Trusted escalate | Primary/Full/Partner |
| PATCH /sos/{id}/resolve | Resolve | Primary/Full/Partner |
| POST /sos/{id}/cancel | False-alarm cancel | Child of incident |
| GET /sos/active | Open incidents | Guardians by role |
| GET /sos/{id}/deliveries | Transport states | Guardians |
| GET/PUT /sos/ladder | Config | Primary/Full |
| POST /sos/contacts/{id}/verify | Start verification | Primary/Full |
| PUT /sos/settings/panic-quiet | Mode | Primary/Full |
| POST /sos/{id}/break-glass | Start override | Authorized parent |
| POST /sos/break-glass/{id}/end | End override | Actor/system |

All mutating routes audit. Observer GET allowed; mutating ACK/ESC/RES/break-glass/config rejected.

---

## 4. Backend workers

1. **Notify worker** — push fan-out; record attempts.  
2. **Fallback worker** — SMS/call on failure if configured.  
3. **Escalation timer** — VERIFIED backups by priority only.  
4. **Verification port** — abstract SMS/OTP (no provider lock-in).  
5. **Evidence retention worker** — 90-day sample purge; never delete audit.  
6. **Break-glass expiry worker** — end overrides at `endsAt`.  
7. **Sync reconciler** — outbox drain.  

No emergency-services dialer worker. No audio worker.

---

## 5. Device requirements

| Capability | Classification |
|---|---|
| Local durable store + outbox | Required |
| Push critical / high priority | Required where OS allows |
| SMS send | Optional fallback |
| Call dialer intent / VoIP | Optional fallback to family-trusted |
| Location FG/BG | Required for READY; soft-fail to UNAVAILABLE |
| Mic / audio record | **NOT REQUIRED — excluded** |
| Emergency number integration | **NOT IN SCOPE** |

Permissions UX: request location/notifications honestly; never block local ACTIVE on deny.

---

## 6. Platform constraints

- iOS Critical Alerts entitlement may be UNAVAILABLE until approved → classify readiness.  
- Android OEM battery / DND quirks → DEGRADED possible.  
- Airplane mode: local ACTIVE + queue; SMS may still work with SIM on some devices — detect, don’t assume.

---

## 7. Repository seams (Rule 25)

Future interfaces (names indicative):

- `SosIncidentRepository`  
- `SosDeliveryRepository`  
- `SosLadderRepository` (exists — extend, no national number)  
- `SosReadinessRepository`  
- `SosFireService` → becomes incident starter (still entitlement-free)

Mock today; API later; zero UI source coupling.
