# 08 — SOS Data & Event Model

---

## CURRENT FACT — in-app models

### `SosAlert` (`core/policy/sos_alert.dart`)

| Field | Type | Notes |
|---|---|---|
| id | String | |
| childId | String | Parametric |
| childDisplayName / childEmoji | String | From fixture — Rule 23 |
| pressedAt | DateTime | |
| locationLabel | String | Display string, not lat/lon |
| batteryPercent | int | |
| movementLabel | String | |
| accuracyMeters | int | |
| recipientLabels | List\<String\> | Display only |
| status | active \| resolved | No ACKNOWLEDGED |
| pinFracX / pinFracY | double | Decorative map |

### `SosLadder` / `SosBackupContact`

- `presentParentIds`, `backups[]` with `id`, `name`, `relation`, `delaySeconds`, `enabled`
- **No phone, email, or channel enum**

### `SosFireResult`

- `fired`, `at`, `recipientDeliveries[]` (`NotificationDeliveryResult`)

### Repository seams (Rule 25)

- `SosFireService` → `MockSosFireService`
- `SosLadderRepository` → Prefs / InMemory
- `SosAlertRepository` → InMemory only (no Prefs/API impl)

---

## Schema FACT — `sos_alert` table

| Column | Notes |
|---|---|
| id, family_id, child_id | Identity |
| triggered_at, received_at | Timestamps |
| lat, lon | Nullable location |
| status | ACTIVE \| ACKNOWLEDGED \| RESOLVED |
| resolved_by, resolved_at | Manual close |
| request_id | UNIQUE — dedupe retries |

Comment in schema: never deleted; not gated by subscription/permission.

**CURRENT:** Flutter does not read/write this table.

---

## API contract intent (prototype/17)

| Method | Purpose |
|---|---|
| POST /sos | Create — no subscription / permission gate |
| POST /sos/{id}/ack | Guardian acknowledged |
| PATCH /sos/{id}/resolve | Manual close only |

---

## PROPOSED events (not implemented)

| Event | When | Payload sketch |
|---|---|---|
| SosTriggered | Hold complete / local ACTIVE | childId, requestId, deviceId, at |
| SosDeliveryAttempted | Per channel | alertId, recipientId, channel, attempt |
| SosDeliverySucceeded / Failed | Result | alertId, recipientId, channel, error? |
| SosLocationUpdated | Ping | alertId, lat, lon, accuracy, battery, at |
| SosAcknowledged | Parent ack | alertId, actorId, at |
| SosEscalated | Manual/timer | alertId, rung, contactId, channel |
| SosResolved | Close | alertId, actorId, actorRole, reason |
| SosFalseAlarm | If distinct from resolve | alertId, childId |
| SosChannelDegraded | Capability loss | alertId, channel, reason |

Emit via Rule 26 EventBus → sync queue when AI hooks apply; SOS itself is safety-critical and must not depend on AI.

---

## Audit

- `AuditLogEntryKind.sosAlert` exists.
- Append-only audit repo (no update/delete) — constitution Rule 10.
- **GAP:** closing SOS via FAT-018/CHD-006 does not clearly append a lifecycle audit entry in-repo (verify before claiming CLOSED).

---

## Mapping CURRENT → SCHEMA (target)

| App today | Schema / target |
|---|---|
| active | ACTIVE |
| (missing) | ACKNOWLEDGED |
| resolved | RESOLVED |
| locationLabel | lat/lon + reverse-geocode label |
| recipientLabels | derived from ladder + delivery table |
| escalateCount | escalation_attempts child table (**PROPOSED**) |
