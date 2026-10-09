# 06 — Event Lifecycle Contract (FROZEN)

**System:** #4 Location & Safe Zones  
**Status:** FROZEN — 2026-09-23  
**Authority:** Approved lifecycle law (brief) · LOC-OD-14/15/17/18

---

## 1. Canonical lifecycle (normative)

```
Definition
  → Geometry
  → Assignment
  → Local Policy Context
  → Local Evaluation
  → Dwell / Hysteresis
  → Canonical Event
  → Policy Interpretation
  → Notification / Action
  → Audit
  → Offline Queue
  → Sync
```

Each arrow is a **stage boundary**. A stage may only claim success for itself.

---

## 2. Stage contracts

| Stage | Producer | Output | Honesty rule |
|---|---|---|---|
| Definition | Parent configure UI → Domain | Zone id + metadata | Not yet enforceable on device |
| Geometry | Domain | Circle or Polygon validated | Invalid geometry rejected |
| Assignment | Domain | Child/family binding | Identity context required |
| Local Policy Context | Sync → child | Bounded snapshot | Stale context must be labeled; no fake “up to date” |
| Local Evaluation | Offline engine | Candidate enter/exit | Uses last-known fix honesty |
| Dwell / Hysteresis | Engine | Confirmed transition | Alert **kinds** frozen ENTER/EXIT/NO_SHOW (Q-LOC-06=A); **numeric** thresholds remain Technical — engine must support parameters without inventing product numbers |
| Canonical Event | Domain | Typed event + identity context | Immutable once emitted (append) |
| Policy Interpretation | Policy Kernel | Action decision | AI may suggest only if ever involved — no execute |
| Notification / Action | Notifications / parent surfaces | Delivered/failed/pending | Never “sent” without proof |
| Audit | Audit log | Append-only record | No update/delete |
| Offline Queue | Device outbox | Queued payloads | Durable across restart |
| Sync | Sync layer | Cloud ack | **No fake cloud success** |

---

## 3. Event identity envelope (LOC-OD-18)

Every canonical event **must** include:

- `eventId` (unique)  
- `familyId`  
- `childId`  
- `deviceId` and/or `enrollmentId`  
- `occurredAt` (device clock + honesty about skew when known)  
- `kind`  
- optional `geofenceId` / geometry version  
- optional `fix` / integrity signals (facts only)

---

## 4. Event families (floor)

| Family | Examples | Notes |
|---|---|---|
| Fix / ping | location sample | Trail Class A |
| Geofence | ENTER, EXIT, NO_SHOW | L-S3/L-S4/L-S7/L-S9 (L-S7 = these kinds only) |
| Check-In | child ack + silent evidence | L-S5 |
| Silent Request | authorized request → result state | L-S6 |
| SOS attach | samples bound to incident | L-S12 / SOS Final |
| Integrity | anti-spoof signals | L-S10; soft parent warning only (Q-LOC-07=C); no Kernel punish |

---

## 5. Silent Location Request lifecycle (LOC-OD-08)

```
Parent authorize request
  → Domain records request (audit)
  → Child device executes (no child UI)
  → Result state: SUCCESS_FIX | STALE_LAST_KNOWN | UNAVAILABLE | DENIED_PLATFORM | QUEUED_OFFLINE | FAILED
  → Parent sees honest result
  → Sync when possible
```

No child accept/reject branch exists.

---

## 6. Check-In lifecycle (LOC-OD-13)

```
Child Safety ack (named place)
  → Domain attaches silent evidence (if available)
  → Canonical Check-In event
  → Kernel/Notification → parent reassurance
  → Audit + Sync
```

Child never enters a map/history flow.

---

## 7. Ordering & conflict

- Local events ordered by `occurredAt` + monotonic device seq when available.  
- After sync, **cloud is authoritative for history** (LOC-OD-16).  
- On conflict with SOS lifecycle, **SOS Final** wins for incident state; location samples merge chronologically as evidence.

---

## 8. Forbidden shortcuts

- UI toggle that skips Canonical Event + Kernel.  
- Claiming Notification success before delivery proof.  
- Claiming Sync success while only local-write succeeded.  
- Dropping identity context to “make mocks pass.”
