# LOOP_STATE

```
status: STOPPED
current_card: (Phase 1.5 COMPLETE — no next feature armed)
blocked_by: (none)
last_tick: 2026-09-24
resume_hint: PHASE-1.5-HARDEN shipped. FS lane CLOSED. P15-QUR-004…007 still deferred_campaign. Stage 3 NOT STARTED. Do NOT auto-start P15-QUR or Stage 3 — Owner must explicitly re-arm.
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
