# 03 — FS-005 L3 State Matrix

**Authority:** L2 Offline/Sync · Composition · Scheduling · Enforcement honesty  
**Rule:** States are UX-visible. **Do not invent TTL numbers** (T-MODE-05 TBD). Do not invent wake mechanisms (T-MODE-02 TBD).

**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

---

## 1. Mode definition states

| State ID | Meaning | Parent UX |
|---|---|---|
| `mode_draft` | Builder unsaved | Save disabled until valid identity+scope |
| `mode_saving` | Persist in flight | Spinner · block double-save |
| `mode_saved` | Domain/outbox accepted | Success · not “enforced” |
| `mode_pending_ack` | Saved > device acked | “Awaiting child device acknowledgement” |
| `mode_acked` | Device acked this version | May claim applied when plane OK |
| `mode_stale` | Ack overdue (TTL TBD) | Stale honesty chip |
| `mode_deleted` | Soft-removed from catalog | Gone from active evaluation |

---

## 2. Activation / lifecycle states

| State ID | Meaning | UX |
|---|---|---|
| `act_inactive` | Mode not applying | Off / scheduled future |
| `act_scheduled_upcoming` | Will activate at known time/context | Upcoming chip |
| `act_grace` | Grace transition (scheduled path) | Child + parent grace disclosure |
| `act_active` | Mode applicable now | In ACTIVE STACK |
| `act_manual_active` | Manually forced on (instant, no grace) | Badge “Manual” |
| `act_deactivating` | Parent/system turning off | Transient |
| `act_conflict_composing` | Multiple active; computing stricter | Composition sheet |

Manual → `act_manual_active` **skips** `act_grace`.

---

## 3. Composition states

| State ID | Meaning | UX |
|---|---|---|
| `comp_none` | No Mode active | Empty stack |
| `comp_single` | One Mode | Simple card |
| `comp_multi` | ≥2 Modes | Stack + “stricter applies” |
| `comp_explained` | Parent opened composition detail | Intersection explanation |

**Forbidden state:** UI that asserts “only one Mode can be on.”

---

## 4. Enforcement / honesty states

| State ID | Meaning | Allowed claim |
|---|---|---|
| `enf_enforced` | Last-acked Mode overlay + verified planes for affected systems | Overlay active on device |
| `enf_pending_policy` | Plane OK; Mode not acked | Pending — not enforced |
| `enf_degraded` | Partial plane | Limited + what still works |
| `enf_unavailable` | Plane down | No enforced claim |
| `enf_unsupported` | Platform cannot | Unsupported honesty |
| `enf_unknown` | Not assessed | No protected claim |
| `enf_offline_last_acked` | Offline; running last-acked | Honest offline + last-acked |

---

## 5. Scheduler channel states

| State ID | Channel |
|---|---|
| `sch_manual` | Manual on/off |
| `sch_clock` | Clock / weekly window |
| `sch_seasonal` | Date-range season |
| `sch_location` | FS-001 context derived |
| `sch_combined` | Multiple channels armed on one Mode |

Conflict of schedules → composition / upcoming explainers — **not** a second evaluator.

---

## 6. Exception / grant / cross-system deny labels

| Label | System | Modes UI |
|---|---|---|
| `x_mode_exception` | FS-005 ModeException | Editable in Modes |
| `x_app_access_exception` | FS-003 | Deep-link only |
| `x_temp_grant` | Screen Time | Deep-link only |
| `x_permanent_block` | FS-003 | Deep-link; Mode cannot reopen |
| `x_web_block` | FS-002 | Deep-link |
| `x_camera_restrict` | FS-004 | Deep-link |
| `x_instant_lock` | Instant Lock | Above Modes |

---

## 7. Safety reachability (invariant)

| State | Always |
|---|---|
| SOS | Reachable |
| Required Family Chat | Reachable |
| Quran required path | Reachable |

No Mode state may set these to unavailable.
