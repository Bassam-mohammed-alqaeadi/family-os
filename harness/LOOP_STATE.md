# LOOP_STATE

```
status: RUNNING
current_card: DEV-4 shipped (tasks + calendar on v6 rows); NEXT = the learning domain (18 screens, the largest) then studio then subscription
blocked_by: (none)
last_tick: 2026-09-24 (DEV-4 · tasks + calendar wired · pushed)
resume_hint: DEV-4 — the first beyond-wave-1 card landed. `app/lib/features/n16_tasks/tasks_ux_bridge.dart` (Stage1TasksRuntime; DriftFamilyTasksRepository over `task` ⋈ `child` + `task_submission`, both lanes — child rows and the parent help lane; DriftCreateTaskRepository inserting a real row with the typed title verbatim and reward = courage + playtime with the split stored; DriftChildTasksRepository whose submitProof writes a real submission and moves the task to PENDING_APPROVAL; DriftSmartChoreDistributorRepository whose approve stamps every row and whose shuffle rotates the chores in storage, each child keeping their own note) and `app/lib/features/n15_calendar/calendar_ux_bridge.dart` (Stage1CalendarRuntime; DriftFamilyCalendarRepository computing the month card from the clock with dots from the rows, nothing from another month or family; DriftAddEventRepository inserting a real `calendar_event`, prayer-relative time stored at the option's nominal hour because the contract has no column for it). Shared `app/lib/core/data/stage1_row_vocabulary.dart` is the one place where row values meet the screens' ARB vocabulary (childOne…childN ordinals · task/status words · the two shared lanes · time and month keys). The six screens resolve the real repositories by default (tests keep injecting their in-memory seams, Rule 25 intact), value mappers show a stored value verbatim instead of a different fact, and both forms list the family's real children instead of three hard-coded slots. MEASURED: analyze --fatal-infos clean · strings gate OK (328 files) · new tests 11 · FULL suite 1590/1590 (was 1579) · 22 of 131 screen files bind a Stage-1 runtime (was 16). NEXT per ADR-054 §11: learning (18 screens · 8 learn_* tables) then studio then subscription; NOTE `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
```

## Field meanings

| Field | Values |
|---|---|
| `status` | `RUNNING` — keep working · `BLOCKED` — unanswered QUESTIONS · `STOPPED` — human stopped the loop |
| `current_card` | Backlog id being worked or next to work |
| `blocked_by` | Question id(s), e.g. `Q-PREFLIGHT-001`, or `(none)` |
| `last_tick` | Date of Orchestrator tick |
| `resume_hint` | One line for the next wake |

## Rules

- Unanswered QUESTIONS → must set `status: BLOCKED` and stop `/loop`.
- After Bassam answers → resume protocol sets `RUNNING` and clears `blocked_by`.
- Never leave `RUNNING` while an unanswered QUESTION exists.
