# 09 — Offline Location Contract (FROZEN)

**System:** #4 Location & Safe Zones  
**Status:** FROZEN — 2026-09-23  
**Authority:** LOC-OD-16/17 · Event Lifecycle · SOS offline honesty patterns (analogy, not copy-paste of SOS transport)

---

## 1. Honesty law (LOC-OD-17)

| Forbidden | Required |
|---|---|
| Fake cloud success | Distinguish **local persisted** vs **synced** |
| “Delivered to parents” without proof | Pending / queued / failed / synced states |
| Silent drop of safety events | Durable outbox + retry |
| Pretending full history while offline | Show degraded/partial honesty |

---

## 2. Store roles (LOC-OD-16)

| Location | Role |
|---|---|
| Child device | **Bounded operational cache** + local policy context + outbox |
| Parent device | View cache; reconcile after sync |
| Cloud | **Authoritative historical** trail after **successful** sync |

Numeric cache bounds → **OPEN (Q-LOC-17)** — do not invent. Domain must still enforce *some* bound at implementation time once decided.

---

## 3. What must work offline

| Capability | Offline expectation |
|---|---|
| SOS fire + location attach attempt | Local first (SOS Final); queue |
| Geofence local evaluation | Uses Local Policy Context; emits canonical events to outbox |
| Check-In ack | Local accept; evidence best-effort; queue parent notify |
| Silent Location Request | May run on device; result QUEUED_OFFLINE / sync later; parent sees honesty |
| Full cloud history browse | Degraded — no fake completeness |

---

## 4. Outbox / sync

```
Local write → Outbox entry (identity envelope) → Retry with backoff → Cloud ack → Mark synced
```

- Partial sync allowed; UI must not mark entire history synced.  
- Conflict: cloud wins for historical trail after ack; merge chronological samples.  
- Never delete unsynced safety outbox to “clean UX.”

---

## 5. Local Policy Context freshness

- Child evaluates against last successfully synced context.  
- If context older than product tolerance → **OPEN technical/product** freshness label (no invented TTL here).  
- Engine must still evaluate with honesty (“using last policy sync”) rather than inventing cloud-fresh rules.

---

## 6. Platform degraded modes (feasibility — not product numbers)

| Condition | Product honesty |
|---|---|
| Location permission denied | UNAVAILABLE / platform-denied; SOS still fires |
| Background location restricted | Foreground/SOS best-effort; safe-zone delay honesty |
| Low battery | May use band `low_battery` (Q-LOC-04=A · LOC-OD-25); **interval seconds** remain Platform/Technical — never invent rate claims in UI |
| OS kills process | Outbox durability required at implementation |

---

## 7. Non-goals

- Specifying exact retry intervals in this freeze.  
- Claiming FCM/SMS delivery from Location Domain alone.  
- Using offline mode as excuse to expose child location UI.
