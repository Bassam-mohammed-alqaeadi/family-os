# 03 — Location UX State Matrix (L3.2)

**Authority:** L2 Offline · SOS Handoff · LOC-OD-22/23/25 · Event honesty  
**Rule:** No invented numeric thresholds or refresh intervals.

---

## 1. Fix / freshness states (parent Live & SOS handoff)

| State ID | Meaning (UX) | Typical chip | Notes |
|---|---|---|---|
| `acquiring` | Trying to obtain a fix | Acquiring | Never claim live |
| `ready` | Current fix available | Located / Ready | Parent map may show pin; child SOS = “located” word only |
| `last_seen` | Showing last known with age class | Last seen | Honesty about not-now |
| `stale` | Last known considered stale | Stale | Still may show last-known pin with honesty |
| `unavailable` | No fix / no last-known usable | Unavailable | Map may be empty; SOS still openable |

Align with SOS vocabulary (acquiring / located / stale / unavailable) without inventing age minutes.

---

## 2. Connectivity / sync states

| State ID | Meaning | Surfaces |
|---|---|---|
| `online` | Device path usable | Live, History, Zones |
| `offline` | No network | Queue honesty |
| `syncing` | Outbox uploading | Chips; not “synced” yet |
| `synced` | Cloud ack for relevant payload | After proof only |
| `sync_failed` | Retry needed | Honest failure |
| `degraded` | Partial capability (e.g. background limited) | Platform honesty |

**Forbidden:** Fake cloud success (LOC-OD-17).

---

## 3. Live View watch modes (Q-LOC-03=B)

| State ID | Product name | UX meaning | Must not show |
|---|---|---|---|
| `standard_watch` | Standard watch | Default parent watch posture | Refresh ms / Hz |
| `elevated_live` | Elevated live | Elevated attention mode | Invented cadence claims |

Mode is orthogonal to freshness: e.g. `elevated_live` + `acquiring` is valid.

---

## 4. Integrity state (Q-LOC-07=C)

| State ID | Meaning | UX | Forbidden |
|---|---|---|---|
| `confidence_normal` | No soft warning | Default | — |
| `confidence_low` | Soft parent warning (“low location confidence”) | Banner/chip on parent Live (± History) | Child UI · Kernel lock · scores · “spoof-proof” |

---

## 5. Silent Location Request result states

| State ID | Parent sees |
|---|---|
| `slr_pending` | Request authorized; waiting |
| `slr_success_fix` | Honest success with freshness class |
| `slr_stale_last_known` | Stale / last known result |
| `slr_unavailable` | No fix |
| `slr_queued_offline` | Queued for sync |
| `slr_failed` | Failed |
| `slr_denied_platform` | OS/permission denied |

Child: **no** interactive states.

---

## 6. Zone / event states

| State ID | Meaning |
|---|---|
| `zone_draft` | Authoring incomplete (e.g. no children selected) |
| `zone_saved` | Persisted with assignment + geometry |
| `zone_alerts_on/off` | Per-kind or master enablement (ENTER/EXIT/NO_SHOW) |
| `event_enter` / `event_exit` / `event_no_show` | Canonical L-S7 kinds only |
| `event_unread` / `event_opened` | Parent notification hygiene |

---

## 7. Check-In states

| Actor | States |
|---|---|
| Child | `ci_idle` · `ci_submitting` · `ci_acked` (feedback without coords) |
| Parent | `ci_received` · `ci_opened` · evidence attached silently (may be unavailable) |

---

## 8. History / retention honesty states

| State ID | Meaning |
|---|---|
| `history_loading` | Fetching |
| `history_empty` | No trail yet |
| `history_partial_offline` | Local/partial; not claiming full 90d cloud |
| `history_ready` | Trail available |
| `export_idle` / `export_running` / `export_done` / `export_denied` | Primary only; audit |

---

## 9. Sampling band (display honesty only)

Band names may appear in **parent** device/posture honesty if needed — **not** as child controls:

`normal` · `low_battery` · `sos_active`

Never show invented seconds.

---

## 10. Matrix: capability × key states

| Capability | Key states to design for |
|---|---|
| Live | freshness × watch mode × online/offline × confidence_low |
| History | empty/partial/ready × export Primary |
| Zones | draft (no children) / saved / read-only Co-Parent |
| Silent Request | pending → result set above |
| Zone events | enter/exit/no_show × offline queue |
| Check-In | child ack × parent receive |
| SOS handoff | SOS ACTIVE + freshness; open Live |
| Offline | offline / syncing / sync_failed across all parent surfaces |
