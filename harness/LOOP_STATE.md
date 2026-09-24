# LOOP_STATE

```
status: RUNNING
current_card: PERS-2
blocked_by: (none)
last_tick: 2026-09-24
resume_hint: PERS-1 shipped (durable storage over 13 store seams; settings survive restart; suite 902/902). NEXT=PERS-2: keep every remaining screen on the durable seams + start Drift for the 20-table _CONTRACTS schema. Then Phase 3 screens — child dashboard first (25 placeholders). /loop 5m.
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
