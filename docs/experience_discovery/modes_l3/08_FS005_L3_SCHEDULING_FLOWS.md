# 08 — FS-005 L3 Scheduling Flows

**Authority:** MODE-OD-06 · MODE-OD-08 · MODE-OD-09 · MODE-SF-05 · MODE-SF-09 · MODE-SF-10 · MODE-SF-19  
**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

---

## 1. Unified scheduler principle

**One** lifestyle scheduling experience under Modes.

| Must make clear | UX |
|---|---|
| Manual | Activate now / deactivate — instant, skip grace |
| Clock / weekly | Day matrix + start/end |
| Seasonal | Date-range |
| Location-derived | Bind to FS-001 context facts |
| Active / inactive | State chips from state matrix |
| Conflicting schedules | Composition / upcoming explainers |
| Upcoming activation | Timeline on Overview + Scheduler |
| Preview before application | Preview sheet |

**Do not expose** Screen Time `ScheduleWindow` as a competing Modes scheduler. If legacy lifestyle windows appear in ST UI during migration, they deep-link: “Managed in Modes” (**MODE-OD-06**).

---

## 2. Channel combination

A Mode may arm multiple channels (`sch_combined`). Evaluator is **one** FS-005 path (implementation T-MODE-01). UX shows which channel caused current activation.

---

## 3. Manual channel

| Behavior | Spec |
|---|---|
| Activate | Instant · no grace · enters stack |
| Deactivate | Removes manual force; scheduled channels may still apply |
| vs schedule | Manual on while schedule says off = manual wins until deactivated (product clarity in Preview) |

---

## 4. Clock / weekly

| Behavior | Spec |
|---|---|
| Editor | Days + start/end per Mode |
| Upcoming | Next fire shown |
| Grace | Applies on scheduled enter (not manual) |
| Honesty | Do not claim OS Focus/Alarm APIs (T-MODE-02) |

---

## 5. Seasonal

| Behavior | Spec |
|---|---|
| Editor | Start date · end date |
| Example | Ramadan / Vacation seasons |
| Outside range | Channel inactive |

---

## 6. Location-derived

| Behavior | Spec |
|---|---|
| UX | Select FS-001 context (e.g. ENTER school zone for scoped children) |
| Ownership | Geofence geometry **only** in FS-001 |
| Missing zone | CTA → Location; Mode binding disabled until fact exists |
| Unsupported | Honesty if location facts unavailable |

---

## 7. Conflict / overlap UX

When two Modes’ schedules overlap on a child:

1. Both may be `act_active`  
2. ACTIVE STACK shows multi composition  
3. Effective = stricter intersection  
4. Optional conflict notification to authorized parents (T-MODE-09)  

Never force single-Mode UX to “resolve” by auto-disabling another Mode unless parent explicitly deactivates.

---

## 8. Migration honesty (ScheduleWindow)

| Parent sees in ST (legacy) | Correct L3 behavior |
|---|---|
| Sleep/prayer/study windows | Banner: lifestyle schedules live in Modes · [Open Modes] |
| Editing ST window as Mode authority | **Forbidden** in target |

---

## 9. State transitions (scheduler)

```
arm channel → mode_saved → pending_ack → (acked)
condition false → act_inactive / upcoming
condition true (scheduled) → act_grace? → act_active
manual on → act_manual_active (skip grace)
manual off → re-evaluate channels
```
