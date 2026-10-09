# 04 — Location User Flows (L3.4)

**Authority:** L2 Event Lifecycle · Role Access · Child Silent · Geo-Fence · Offline · SOS Handoff  
**Format:** entry → states → actions → outcomes → audit/evidence → error/offline

---

## F01 — Live View (Standard watch)

| Step | Detail |
|---|---|
| **Entry** | Kids hub · Child profile · notification · shell shortcut |
| **States** | `standard_watch` + freshness + online/offline + optional `confidence_low` |
| **Actions** | Select child · open History · open Zones · Silent locate · switch to Elevated · open SOS |
| **Outcomes** | Parent understands where/when honesty class |
| **Audit/evidence** | View not necessarily audited; sensitive later actions are |
| **Error/offline** | Show offline chip; last_seen/stale/unavailable honesty; no fake live |

---

## F02 — Elevated live

| Step | Detail |
|---|---|
| **Entry** | Control on Live Map: choose **Elevated live** |
| **States** | `elevated_live` × freshness (may still be acquiring) |
| **Actions** | Return to Standard watch · Silent locate · open SOS |
| **Outcomes** | Elevated attention mode engaged (intervals TBD technical — not shown) |
| **Audit/evidence** | Optional audit of mode change (recommended for sensitive elevation — not inventing mandatory score) |
| **Error/offline** | Mode may stay elevated while offline; honesty chips dominate; no “live streaming” claim |

---

## F03 — History

| Step | Detail |
|---|---|
| **Entry** | Live “History” · profile · event deep link |
| **States** | loading / empty / partial_offline / ready |
| **Actions** | Browse days · open stop · (Primary) Export / Archive |
| **Outcomes** | 90d trail understanding; frequent places if Domain provides |
| **Audit/evidence** | Export/Archive → append-only audit |
| **Error/offline** | partial honesty; deny Export if cannot fulfill — honest fail |

---

## F04 — Create Zone

| Step | Detail |
|---|---|
| **Entry** | Zone Library “Create” (Primary / Mother Full) |
| **States** | `zone_draft` until valid |
| **Actions** | Choose Circle or Polygon · draw/edit geometry · name · enable ENTER/EXIT/NO_SHOW · **multi-select children (required)** · Save |
| **Outcomes** | Zone saved → Local Policy Context sync path |
| **Audit/evidence** | Zone create audit (actor, assignment, geometry type) |
| **Error/offline** | Save local + queue sync; **block save** if zero children selected; geometry validation errors |

---

## F05 — Edit Zone

| Step | Detail |
|---|---|
| **Entry** | Library row (Primary / Full) |
| **States** | loaded zone · dirty draft |
| **Actions** | Edit geometry/name/alerts/assignment · Save · Archive/delete per policy |
| **Outcomes** | Updated context for offline engine |
| **Audit/evidence** | Config change audit |
| **Error/offline** | Queue; conflict resolve with cloud authority after sync |

---

## F06 — Assign children

| Step | Detail |
|---|---|
| **Entry** | Embedded in Create/Edit (not a silent default) |
| **States** | selection set empty → invalid; ≥1 → valid |
| **Actions** | Toggle children · Select all (explicit user action — still not a silent default on empty create) |
| **Outcomes** | Assignment list persisted |
| **Audit/evidence** | Assignment delta audited |
| **Error/offline** | Same as save zone |

**Law:** Creating with zero children **forbidden** (Q-LOC-12=B).

---

## F07 — Zone event handling (ENTER / EXIT / NO_SHOW)

| Step | Detail |
|---|---|
| **Entry** | Push / in-app alert |
| **States** | event_unread → opened |
| **Actions** | Open event · go Live focus child · open History · dismiss |
| **Outcomes** | Parent situational awareness |
| **Audit/evidence** | Event already canonical in Domain; open may be telemetry |
| **Error/offline** | Event may arrive later from outbox; never invent delivery |

**Out of flow:** driving/speed/crash (FAT-077).

---

## F08 — Check-In (child → parent)

| Step | Detail |
|---|---|
| **Entry (child)** | Child Safety → Check-In |
| **States** | idle → submitting → acked |
| **Actions** | Tap named place · confirm |
| **Outcomes** | Parent reassurance card; silent evidence attached if available |
| **Audit/evidence** | Check-In event + optional fix evidence |
| **Error/offline** | Child ack still succeeds locally; parent notify queued; evidence may be unavailable |

---

## F09 — Silent Location Request

| Step | Detail |
|---|---|
| **Entry** | Live / profile action (Primary / Partner / Full) |
| **States** | slr_pending → result states |
| **Actions** | Authorize request (parent) · view result |
| **Outcomes** | Honest result on parent side |
| **Audit/evidence** | Request authorization + result class audited |
| **Error/offline** | slr_queued_offline / denied_platform / failed — no child UI branch |

---

## F10 — Integrity warning (soft)

| Step | Detail |
|---|---|
| **Entry** | Domain signals `confidence_low` while parent on Live (± History) |
| **States** | confidence_normal ↔ confidence_low |
| **Actions** | Dismiss/acknowledge warning (non-destructive) · continue viewing |
| **Outcomes** | Parent informed; **no** auto lock/punish |
| **Audit/evidence** | Optional signal log as Domain fact |
| **Error/offline** | Warning may use last signals; never claim spoof-proof |

---

## F11 — Offline location behavior

| Step | Detail |
|---|---|
| **Entry** | Network loss on any parent Location surface |
| **States** | offline · syncing · sync_failed |
| **Actions** | Continue viewing last known · queue mutations · retry |
| **Outcomes** | Honest degraded UX |
| **Audit/evidence** | Local events retained in outbox |
| **Error/offline** | Core path — no fake synced |

---

## F12 — Sync recovery

| Step | Detail |
|---|---|
| **Entry** | Network restored / app foreground |
| **States** | syncing → synced or sync_failed |
| **Actions** | Automatic retry · manual retry CTA |
| **Outcomes** | Cloud authoritative history after ack |
| **Audit/evidence** | Sync completions may be system logs |
| **Error/offline** | Partial sync honesty |

---

## F13 — SOS → Location handoff

| Step | Detail |
|---|---|
| **Entry** | Parent SOS board CTA “Open live map” (when not pure unavailable-without-last-known per SOS contract) |
| **States** | SOS ACTIVE + freshness class; Live opens in child focus; watch mode may default Standard (or Elevated only if user chooses — **not** auto-Find) |
| **Actions** | View Live · Elevated optional · return to SOS |
| **Outcomes** | Geographic context without leaving SOS ownership |
| **Audit/evidence** | SOS evidence samples remain SOS retention class |
| **Error/offline** | Live shows honesty; SOS remains usable |
| **Forbidden** | Break-glass becoming Find; child map |

Child path: SOS board shows status words only (owned by SOS L3 surfaces).
