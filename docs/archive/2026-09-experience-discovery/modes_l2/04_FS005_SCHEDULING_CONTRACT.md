# 04 — FS-005 Scheduling Contract (L2 Target) — FROZEN

**Status:** **FROZEN** · MODE-SF-05 · MODE-SF-09 · MODE-SF-10 · MODE-SF-19 · MODE-OD-06 · MODE-OD-08 · MODE-OD-09  
**Technical open:** T-MODE-01 · T-MODE-02 · T-MODE-07  

```
OWNER DECISIONS: FROZEN
```

---

## 1. Single lifestyle scheduling authority

**FS-005 owns** lifestyle scheduling and Mode activation semantics (**MODE-OD-06**, **MODE-OD-08**).

There is **one canonical** schedule/evaluation path for Mode activation.

**Forbidden:**

- A second Mode scheduler inside FS-002, FS-003, FS-004, or Screen Time  
- Two independent evaluators that can disagree on `modeActive` / Mode applicability  

---

## 2. Activation channels (**MODE-OD-09**) — all enabled

| # | Channel | Owner of source truth | FS-005 role |
|---|---|---|---|
| 1 | Manual | Authorized parent action | Activate/deactivate immediately (grace skipped) |
| 2 | Clock / schedule | FS-005 schedule definition | Evaluate windows / weekly patterns |
| 3 | Location / geofence-derived | **FS-001** geofence & location truth | **Consume** context → decide Mode activation |
| 4 | Seasonal / date-range | FS-005 seasonal definition | Evaluate date-bounded seasons |

**No second geofence engine inside Modes.**

---

## 3. Legacy Screen Time `ScheduleWindow` (**MODE-OD-06**)

| Statement | Law |
|---|---|
| Is ScheduleWindow a Mode authority? | **No** |
| What is it? | Legacy evidence / input |
| Required reconciliation | Fold lifestyle sleep/prayer/study windows into FS-005 scheduling model **or** expose as Kernel contextual facts — without a competing Mode evaluator |
| Screen Time still owns | Minutes · budget · Temporary Grant · wallets · Unlimited · countable semantics |

Prayer and similar lifestyle windows, if retained as product concepts, live under **FS-005 scheduling** (or Kernel facts), not as a parallel Mode engine under Screen Time.

---

## 4. Evaluation principles

- Applicable Modes for a child/device are those whose **scope includes** that child and whose activation conditions hold.  
- Multiple applicable Modes → composition contract (doc 05).  
- Kernel merges Mode overlay facts with other systems’ policies.  
- Platform wake / Focus / AlarmManager / WorkManager = **T-MODE-02** — **not** frozen here.  

---

## 5. Consistency with sibling L2

| Sibling freeze | FS-005 alignment |
|---|---|
| WF-OD-10 Modes own scheduling | **Aligned** · MODE-OD-08 |
| APP-OD-10 Modes own scheduling | **Aligned** |
| SC-SF-10 Modes own scheduling | **Aligned** |
| LOC owns geofence truth | **Aligned** · MODE-OD-09 / MODE-SF-10 |

---

## 6. Non-adoptions

| Rejected |
|---|
| Stage-1 school TOD store without canonical evaluator |
| FAT-032 ScheduleWindow as independent Mode authority |
| Claiming OS Focus scheduling already implemented |
