# 09 — SOS Backend & Device Requirements

---

## Backend

| Need | Priority | Notes |
|---|---|---|
| Ungated `POST /sos` | P0 | No entitlement / mother-level / quiet-hour gate |
| Idempotent `request_id` | P0 | Deduplicate offline retries |
| `POST /sos/{id}/ack` | P0 | Distinct from resolve if OWNER confirms |
| `PATCH /sos/{id}/resolve` | P0 | Manual only; record actor |
| Escalation worker | P0 | Honor backup `delaySeconds`; national step |
| Delivery receipt store | P0 | Per guardian / channel |
| Location ingest | P0 | Stream or periodic pings while ACTIVE |
| Immutable audit | P0 | Full lifecycle |
| Push fan-out critical | P0 | Father + mother all levels + optional guardians |
| SMS / email gateway | P1 | Fallback + backups |
| Voice / LiveKit audio | P1/P2 | Only if OWNER keeps P-4 audio |

Swap rule (constitution 25): feature code talks to Repository interfaces only; API impl later.

---

## Notifications

| Platform | Requirement | Constraint |
|---|---|---|
| iOS | Critical Alerts entitlement | Apple approval (`PLATFORM CONSTRAINT`) |
| Android | High-priority FCM + possible full-screen intent | DND / OEM battery quirks |
| Both | Bypass quiet hours in product prefs | Already modeled; OS still required |

---

## Location

- Foreground + background location permissions  
- Last-known cache for offline fire  
- Battery-aware cadence while ACTIVE  
- Honest “unavailable / stale” states  
- Bind FAT-014 / SOS board to same session stream  

---

## Telecom

| Capability | Use |
|---|---|
| Device dialer (`tel:`) | Call child / contacts (simple path) |
| In-app VoIP | Optional richer path — OWNER |
| SMS intent or gateway | Fallback + backup rung |
| Emergency number dial | National escalate — **OWNER** auto vs manual |

Bark/Android lesson: emergency services ≠ family contacts — keep separate.

---

## Offline / device

- Local SOS outbox on child device  
- Airplane-mode acceptance test (UF-08)  
- Ignore battery optimizations honesty tile where required  
- Mic permission if audio ships  
- Notification permission preflight (non-blocking for local ACTIVE)  

---

## Entitlement / billing boundary

- `SosFireService` must remain free of billing imports  
- Plans UI may *mention* SOS as included forever — never gate  
- Tests: expired plan still fires (UI-007)  

---

## What exists today vs required

| Area | Today | Required |
|---|---|---|
| Backend | Schema only | Full API + worker |
| Push | None | Critical channel |
| Location | Fixtures | Real stream |
| SMS/Call | Stubs | Real or honest disabled |
| Offline | Unproven | Outbox + tests |
| Device perms | Not SOS-specific | Full matrix |
