# SYS-SEC-NOTIF-0 — Notifications inventory (Owner)

**Date:** 2026-09-27  
**Screens:** SCR-FAT-058 (settings) · SCR-FAT-019 (hub) · SCR-FAT-020 (detail)  
**Method:** Core now · wire later · cloud/Native last  
**Status:** **CLOSED** (2026-09-27) — Owner scoped suite +61 EXIT:0; wire-later hooks remain for Location/AI/…; next campaign = UX local seed (not this card)

---

## Plain picture

Notifications is the **family mailbox**: three urgency lanes, parent settings that save, an inbox, and detail. Other systems (SOS, location, AI…) must **drop events into this mailbox** — they do not invent a second alerts list.

---

## Present (shipped · local Stage-1)

| Piece | What the user sees / what the code does |
|-------|----------------------------------------|
| FAT-058 three cards | Critical (info, no mute) · Important (child requests, Advisor, quiet hours) · Reassurance (summary digest, evening digest time) |
| Prefs persist | Local KV via PrefsMisc (`prefs_notif`); father and mother have separate rows |
| SOS never muted | Banner + policy forbid mute fields; quiet hours never silence Critical |
| FAT-019 hub | Three lanes; empty honesty; rows from real local producers |
| Live producers | SOS active · tamper bus · pending time · app install · friend request |
| FAT-020 detail | Local projection for SOS + tamper; other kinds via mock templates until wired |
| Delivery gate | `NotificationDelivery` — critical always; child-request / analysis respect prefs + quiet hours |
| Catalog seam | `family_alert_catalog.dart` — live vs hook kinds; single registration map |

### Role behaviour (current target)

| Role | Settings | Hub | Detail |
|------|----------|-----|--------|
| Father | Edits own prefs | Full; filters by **father** prefs | Full |
| Mother | Edits own prefs | Full; filters by **mother** prefs (BLEND-1) | Block needs `MotherLevel.full` (from Identity) |
| Child | Read-only / lean | Lean empty (not a parent inbox) | Lean empty |

---

## Missing / thin (honest)

| Gap | Meaning | When |
|-----|---------|------|
| Digests not scheduled | Toggles save; no evening clock job yet | After soft producers exist |
| Shell unread badge | No tab badge count | After unread model |
| Reassurance lane empty | UI ready; no live arrive/tasks rows yet | Location / Tasks wire |
| Cloud push / SMS | In-app local only | Backend / Native authorized |
| AI stranger smart copy | Templates/hooks only | AI campaign |

---

## Hooks (wire-later register here)

| Kind | Lane | Owner system | Status |
|------|------|--------------|--------|
| `sos` | critical | sos | **live** |
| `tamper` | critical | lock_bypass | **live** |
| `timeRequest` | important | screen_time | **live** |
| `appApproval` | important | apps | **live** |
| `friendRequest` | important | circle | **live** |
| `arrive` | reassurance | location | hook |
| `leaveZone` | critical | location | hook |
| `battery` | important | devices | hook |
| `games` | important | screen_time | hook |
| `stranger` / `smartSafety` | crit / important | ai | hook |
| `tasksDone` | reassurance | tasks | hook |

### Wire contract (every later campaign)

1. Flip kind `hook` → `live` in `family_alert_catalog.dart`.
2. Emit from the owning Local domain (repo / bus).
3. Project into `ProjectingAlertsHubRepository` (+ detail if FAT-020).
4. Call through `NotificationDelivery` (Critical never muted).
5. **Do not** add a parallel inbox screen.

### Recommended wire order

Location → devices / screen-time deepen → SOS polish (same `sos` kind) → AI → tasks → digest scheduler + optional shell badge → cloud push last.

---

## Platform mailbox law

1. One mailbox — catalog + projecting repos only.  
2. Three lanes only (S-ADM-028).  
3. SOS / Critical never muted.  
4. UI never knows data source (Rule 25).  
5. Roles via lean / authority — not a second app.

---

## Verification

Focused suite: `test/features/n06_notifications/` + hub/detail projection + `notification_delivery_test` — Owner confirmed green 2026-09-27.
