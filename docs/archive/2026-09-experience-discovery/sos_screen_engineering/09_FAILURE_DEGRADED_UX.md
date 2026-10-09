# 09 — Failure & Degraded UX

**Authority:** OD-09/16/17 · failure contract · capability classes

---

## 1. Display classes (never optimistic)

| Class | Meaning | Example copy intent |
|---|---|---|
| SUCCESS | Confirmed | Delivery confirmed |
| PARTIAL | Some channels ok | Push failed — SMS submitted |
| DEGRADED | Works with limits | Location stale (12 min) |
| UNAVAILABLE | Cannot now | Call unavailable on this device |
| NOT_CONFIGURED | Setup missing | No verified backup contacts |

---

## 2. Per-scenario UX

| Scenario | Screens | Class | UI |
|---|---|---|---|
| No active SOS | FAT-018, CHD-006 | — | Empty + CTA |
| No location | CHD-006, FAT-018 | UNAVAILABLE | Location chip; SOS stays ACTIVE |
| Stale location | both | DEGRADED | Age label + last-known map if any |
| Location acquiring | both | DEGRADED/ACQUIRING | Progress honesty |
| Device offline (child) | CHD-005/006 | DEGRADED | Sync pending; local ACTIVE |
| Parent offline | FAT-018 | DEGRADED | Delivery pending/failed for that parent |
| Network degraded | all | DEGRADED | Retry affordance |
| Notification failed | FAT-018 | PARTIAL/FAILED | Try SMS/call fallback status |
| SMS unavailable | FAT-018/028 | UNAVAILABLE / NOT_CONFIGURED | Honest chip |
| Call unavailable | FAT-018/006 | UNAVAILABLE | Disable auto-call; keep chat if AVAILABLE |
| Retry | all | — | Explicit retry; PENDING until confirm |
| Partial delivery | FAT-018/006 | PARTIAL | Per-recipient rows |
| Low battery | both | DEGRADED | Battery chip; never block SOS |
| Permission missing | FAT-014/018 | DEGRADED | Soft; fire still allowed |
| Verification pending | FAT-028 | — | PENDING badge; not escalatable |

---

## 3. Incident vs transport

Lifecycle chip ≠ delivery chip. Example legal UI: `ACTIVE` + `DELIVERY_FAILED(push)` + `DELIVERY_PENDING(sms)`.

## 4. Copy rules

- Forbidden: “Sent to all parents” without confirmations.  
- Prefer: “Notifying family…” / “Waiting for confirmation…” / “Push failed”.  
- Arabic-first ARB; English parity.
