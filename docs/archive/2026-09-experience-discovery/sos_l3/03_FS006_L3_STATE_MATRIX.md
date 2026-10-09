# 03 — FS-006 L3 State Matrix

**Authority:** Lifecycle · delivery · location · offline L2  
**Rule:** Do not invent TTL/transport guarantees (T-SOS TBD).  
**Master:** [13_FS006_L3_MASTER_CONTRACT.md](13_FS006_L3_MASTER_CONTRACT.md)

---

## 1. Incident lifecycle states

| State | Meaning | UX |
|---|---|---|
| `IDLE` | No open incident | Entry available |
| `HOLDING` | Child holding | Progress feedback; release → IDLE |
| `FIRING` | Creating local incident | “Starting emergency…”; no “sent” |
| `ACTIVE` | Durable incident open | Child critical + parent console |
| `ACKNOWLEDGED` | Human ack | ≠ resolved |
| `ESCALATING` | Ladder engagement | Show rung + delivery honesty |
| `RESOLVED` | Closed | History retained; not deleted |

Cancel/false-alarm ends open path with auditable terminal reason — still retained.

---

## 2. Delivery states (independent)

| State | Claim allowed |
|---|---|
| `queued` / `offline_queued` | Waiting — not delivered |
| `attempting` | Attempt in progress — not delivered |
| `delivered` | **Only if proven** |
| `failed` | Proven failure |
| `unavailable` | Channel cannot run |
| `degraded` | Partial capability |

**Forbidden copy:** “Sent” / “Delivered” / “Parent notified” without proven delivery fact.

---

## 3. Location honesty (FS-001 attach)

| State | UX |
|---|---|
| `ready` | Location attached |
| `acquiring` | Still activating SOS |
| `stale` | Last-known honesty |
| `unavailable` | SOS still ACTIVE |

---

## 4. Break-glass states

`bg_start` → `bg_reason` → `bg_override_active` → `bg_expired` / `bg_revoked` → audited.

---

## 5. Contact verification

`unverified` · `pending` · `verified` · `revoked` — escalate only if verified.

---

## 6. Platform honesty

`enf_available` · `enf_degraded` · `enf_unavailable` · `enf_unsupported` · `enf_unknown` — for channels/location plane (T-SOS).
