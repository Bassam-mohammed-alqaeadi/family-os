# 04 — FS-005 L3 Flow Catalog

**Authority:** Full L2 MODE-OD / MODE-SF  
**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

Each flow lists: actor · entry · preconditions · state · visible · allowed · forbidden · confirm · success · pending · offline · degraded · stale · conflict · unsupported · failure · audit · notification · child consequence · nav.

---

## F01 — Open Modes overview

| Field | Spec |
|---|---|
| Actor | Primary / Full / Partner / Observer |
| Entry | Parent shell → Modes |
| Preconditions | Identity session |
| Current state | `comp_*` + honesty |
| Visible | Active stack · upcoming · catalog shortcuts · honesty strip · SOS |
| Allowed | Navigate catalog/scheduler/stack/audit per role |
| Forbidden | Edit if Partner/Observer; ScheduleWindow twin |
| Success | Hub rendered honestly |
| Offline | Last-acked summary + offline chip |
| Audit | — (view) |
| Nav | Hub |

---

## F02 — Create custom Mode

| Field | Spec |
|---|---|
| Actor | Primary / Full |
| Entry | Catalog → Create custom |
| Preconditions | Configure AuthZ |
| Visible | Builder: name/icon · scope · overlays · schedule · grace · tighten-only notice |
| Allowed | Save draft → preview → save |
| Forbidden | Loosen toggles; URL/package/geofence editors; silent all-children |
| Confirm | Scope explicit; preview recommended |
| Success | `mode_saved` → `mode_pending_ack` |
| Pending / offline | Queued honesty |
| Audit | `mode.created` |
| Notification | Optional to Partner/Observer view-class |
| Child | No change until activated+acked |
| Nav | Mode detail |

---

## F03 — Edit built-in / custom Mode

| Field | Spec |
|---|---|
| Actor | Primary / Full |
| Entry | Catalog → Mode |
| Allowed | Edit identity/scope/overlays/schedule/grace/ModeException links |
| Forbidden | Rename built-in id; add `exams` alias; widen Vacation |
| Confirm | Scope change; delete |
| Success | Version bump · pending ack |
| Audit | `mode.updated` |
| Child | Effective change after ack+activation |

---

## F04 — Delete Mode

| Field | Spec |
|---|---|
| Actor | Primary / Full |
| Confirm | **Required** |
| Forbidden | Child; Partner |
| Success | Removed from evaluation; stack recomposed |
| Audit | `mode.deleted` |
| Notification | Authorized parents |
| Child | Card clears if was only Mode |

---

## F05 — Manual activate (instant)

| Field | Spec |
|---|---|
| Actor | Primary / Full (or Partner with ticket) |
| Entry | Detail / Overview toggle |
| Transition | `act_inactive` → `act_manual_active` (**skip grace**) |
| Visible | Preview of stricter stack impact |
| Confirm | Soft if multi-mode tightens further |
| Success | In ACTIVE STACK; pending ack if needed |
| Offline | Queue activate; parent sees queued |
| Audit | `mode.activated.manual` |
| Notification | Relevant parents; child disclosure |
| Child | Card updates; **no** grace for manual |
| Forbidden | Claim OS Focus enforced without plane |

---

## F06 — Manual deactivate

| Field | Spec |
|---|---|
| Actor | Primary / Full (+ Partner ticket) |
| Transition | `act_*` → `act_inactive` |
| Confirm | If last Mode or stack material change |
| Audit | `mode.deactivated` |
| Child | Card updates; cannot self-deactivate |
| Forbidden | Child grace-clear as deactivate |

---

## F07 — Arm clock / weekly schedule

| Field | Spec |
|---|---|
| Actor | Primary / Full |
| Entry | Unified SCHEDULER |
| Visible | Days · start/end · upcoming · channel = clock |
| Allowed | Save schedule on Mode |
| Forbidden | Second ScheduleWindow UI; invent wake API copy |
| Success | `sch_clock` armed · `act_scheduled_upcoming` |
| Audit | `mode.schedule.updated` |
| Child | Sees upcoming only if product discloses; not admin |

---

## F08 — Arm seasonal / date-range

| Field | Spec |
|---|---|
| Actor | Primary / Full |
| Visible | Start date · end date · timezone honesty TBD |
| Success | `sch_seasonal` |
| Audit | `mode.schedule.seasonal.updated` |
| Forbidden | Invent durations beyond fields parent sets |

---

## F09 — Arm location-derived activation

| Field | Spec |
|---|---|
| Actor | Primary / Full |
| Entry | SCHEDULER → Location context |
| Preconditions | FS-001 geofence exists for selected children |
| Visible | Consumed FS-001 fact chips (e.g. ENTER school zone); link “Manage zones in Location” |
| Allowed | Bind Mode activation to FS-001 context types |
| Forbidden | Draw/edit geofence in Modes; second geofence engine |
| Unsupported | If FS-001 fact unavailable → honesty |
| Audit | `mode.schedule.location_binding.updated` |
| Nav | Deep-link FS-001 for geometry |

---

## F10 — Scheduled activation with grace

| Field | Spec |
|---|---|
| Actor | System evaluator (FS-005) |
| Preconditions | Clock/seasonal/location condition true; not manual |
| Transition | `act_scheduled_upcoming` → `act_grace` → `act_active` |
| Visible | Parent+child grace disclosure |
| Forbidden | Child ends Mode; child “cancel policy” |
| Audit | `mode.grace.started` / `mode.activated.scheduled` |
| Notification | Grace / activated (transport TBD) |
| Child | Grace banner non-cancel |

---

## F11 — Multi-mode composition view

| Field | Spec |
|---|---|
| Actor | Any parent viewer |
| Entry | ACTIVE STACK |
| Visible | List of active Modes · stricter intersection summary · per-plane tighten chips |
| Allowed | Open composition explain; navigate Mode detail |
| Forbidden | “Only one Mode” messaging; loosen one Mode to defeat another |
| Conflict | Explain intersection; notify on material tighten (**T-MODE-09**) |
| Audit | `mode.composition.changed` when material |
| Child | “Several Modes — stricter rules” note |

---

## F12 — Preview-before-apply

| Field | Spec |
|---|---|
| Actor | Primary / Full |
| Entry | Builder save / activate |
| Visible | Affected children · stack after · planes tightened · safety remains reachable |
| Allowed | Apply / cancel |
| Success | Apply → save/activate path |
| Forbidden | Apply that widens vs baseline |

---

## F13 — ModeException create / revoke

| Field | Spec |
|---|---|
| Actor | Primary / Full |
| Visible | Child · Mode · resource · that this is **Mode overlay only** |
| Forbidden | Mutate package store; mint minutes; rewrite URLs; clear Permanent Block; mutate FS-004 permanent |
| Confirm | Required |
| Audit | `mode.exception.*` |
| Cross-link | If user needs App AE / Grant → deep-link correct system |

---

## F14 — Temporary Grant intersects Mode

| Field | Spec |
|---|---|
| Actor | ST decision roles |
| Entry | ST grant approve while Mode scheduled/active |
| Visible | Explicit choice path (complete vs freeze spirit) — **ST surface**; Modes shows context chip |
| Forbidden | ModeException UI posing as Grant; Grant as Mode cancel |
| Nav | ST owns decision; Modes read-only context |

---

## F15 — Child sees Mode deny

| Field | Spec |
|---|---|
| Actor | Child |
| Visible | Source = Mode · active Mode names · SOS/Chat/Quran still available |
| Allowed | Open SOS/Chat/Quran; request paths owned by other systems if any |
| Forbidden | Deactivate Mode; edit schedule; clear Permanent Block |
| Nav | Stay on interstitial / day board |

---

## F16 — Offline / stale / multi-device

| Field | Spec |
|---|---|
| Actor | Parents |
| Visible | Per-device ack matrix · offline · stale · divergence |
| Allowed | Retry sync (no invented TTL) |
| Forbidden | “All devices protected” when any pending/stale |
| Audit | ack/stale facts when available |

---

## F17 — AI suggests Mode

| Field | Spec |
|---|---|
| Actor | Advisor → Primary/Full approve |
| Allowed | Approve applies via Modes configure AuthZ; Reject |
| Forbidden | AI auto-write Mode policy |

---

## F18 — Safety under Mode (invariant flow)

| Field | Spec |
|---|---|
| Actor | Child / Parent |
| Visible | SOS / Required Chat / Quran always actionable |
| Forbidden | Mode UI hiding or disabling them |

---

## Flow index

F01 Overview · F02 Create custom · F03 Edit · F04 Delete · F05 Manual on · F06 Manual off · F07 Clock · F08 Seasonal · F09 Location · F10 Grace activate · F11 Composition · F12 Preview · F13 ModeException · F14 Grant∩Mode · F15 Child deny · F16 Offline/ack · F17 AI · F18 Safety
