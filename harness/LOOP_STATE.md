# LOOP_STATE

```
status: RUNNING
current_card: (await Owner orientation — Visual Polish)
blocked_by: (none)
last_tick: 2026-09-28
resume_hint: LOCATION-1B CLOSED. Notifications + Emergency Cover shipped. Visual Polish next when Owner orients. LOCATION-1 / EMERGENCY-COMPETE verify evidence may still be owed. Native/Backend NOT AUTHORIZED. Q-PRT-1 + Q-FVX-D9 Answer labels normalized — harness unblocked.
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
