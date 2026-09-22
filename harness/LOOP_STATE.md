# LOOP_STATE

```
status: RUNNING
current_card: SCR-FAT-062
blocked_by: (none)
last_tick: 2026-09-22
resume_hint: FAT-061 shipped. NEXT=SCR-FAT-062 FamilyPatterns (wired+tested). Chain 062→063→064. Cadence ≥3 ships/wake.
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
