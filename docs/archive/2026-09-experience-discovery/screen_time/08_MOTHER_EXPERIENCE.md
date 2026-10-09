# 08 — Mother Experience (Target)

**Date:** 2026-09-23  
**Principle:** Do **not** clone Father UI and hide buttons. Build level-specific intents.  
**Authority:** `family-os/20_MOTHER_PERMISSIONS.md`, ADR-035/035-b/039, `TimeRequestActor`, `DeviceLockActor`

---

## Levels

| Level | AR | Screen-time posture |
|---|---|---|
| ① Observer | مطّلعة | Read + safety receive |
| ② Partner | مشاركة | Decide requests within ceiling |
| ③ Full | كاملة | Operational control except owner-only |

Father/OWNER remains **Primary** — full policy ownership.

---

## CURRENT vs TARGET by level

### Observer

| Capability | CURRENT | TARGET |
|---|---|---|
| View remaining / schedules / requests list | Largely viewable where role not gated | Explicit read-only Overview + Today + History |
| Approve/deny time | Blocked (`canDecide=false`) | Same — show why (“Observer cannot decide”) |
| Grant minutes | No | No |
| Edit caps/schedules | No | No |
| Instant lock | No | No |
| Anti-tamper | Invisible | Keep invisible (ADR-035-b) |
| SOS / chat / location | Always | Always |

**UX:** Status-first cards; no disabled primary buttons that look tappable. Use explanatory empty CTAs.

### Partner

| Capability | CURRENT | TARGET |
|---|---|---|
| Approve/deny requests | Yes | Yes — dedicated Request Inbox |
| Grant ≤ ceiling (default 30) | Enforced | Show ceiling meter before confirm |
| Edit caps/schedules | No (law + UI) | No — deep-link “Ask Father” |
| Instant lock | No | No |
| See Policy Health | Partial | Read-only health |
| Child-visible deny reason | Required in service | Required in UI |

**UX:** Decision-centric home: pending requests, child’s remaining, last decision outcome. Not a full policy workshop.

### Full

| Capability | CURRENT | TARGET |
|---|---|---|
| Approve/deny + grant ≤ ceiling | Yes (ceiling still applies ADR-039) | Same — ceiling visible; over-ceiling → “Father only” |
| Edit caps/schedules | **Law yes / UI no** | Enable edit with audit + father notification |
| Instant lock | Yes | Yes — show “Father can reverse” |
| Unlock father-blocked app | No | No |
| Anti-tamper | Invisible | Invisible |
| Change own mother level | No | No |

**UX:** Operational console: Overview + Schedule + Apps + Requests + Lock. Economy ledger read/write limited to grants, not channel rule authoring for Quran rewards unless exposed by father.

### Primary (Father) — contrast

Full ownership including: ceilings as rules, anti-tamper, permanent unblock, billing/privacy, mother level, overflow policy, attribution rewards, audit export.

---

## Conflict handling (TARGET = law)

1. Father unlock supersedes mother lock + audit.
2. Simultaneous edits: last-write with actor labels insufficient — prefer **CRDT or version vector** Stage-3; until then **father wins** on conflict + notify mother.
3. Mother grant queued offline must re-check ceiling at flush time.

---

## Traceability

| Requirement | Policy | Role | State | Screen | Event |
|---|---|---|---|---|---|
| Partner approves 20m | ADR-039 | Partner | REQUEST_APPROVED | FAT-033 | time_request.approved |
| Observer blocked | R-2 | Observer | REQUEST_PENDING (unchanged) | FAT-033 | time_request.denied_actor |
| Full edits sleep window | Mother FULL law | Full | POLICY sync | FAT-032 | schedule.updated |
| Full instant lock | ADR-035 | Full | DEVICE_LOCK | FAT-037 | lock.engaged |

See: [10_REQUEST_AND_EXCEPTION_MODEL.md](10_REQUEST_AND_EXCEPTION_MODEL.md).
