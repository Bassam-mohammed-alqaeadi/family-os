# LOOP_STATE

```
status: RUNNING
current_card: PERS-2b
blocked_by: (none)
last_tick: 2026-09-24
resume_hint: PERS-1 + PERS-2a shipped (durable KV over 13 seams; Drift identity core account/family/member/child; suite 908/908; pushed 25b519a). NEXT=PERS-2b: devices + permissions tables (device, device_permission, device_health, mode_unlock_attempt). Then PERS-2c location/SOS, PERS-2d communication/AI/audit — then Phase 3 screens, child dashboard first (25 placeholders). /loop 5m.
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
