# LOOP_STATE

```
status: RUNNING
current_card: PERS-2d
blocked_by: (none)
last_tick: 2026-09-24
resume_hint: PERS-1 + PERS-2a + PERS-2b + PERS-2c shipped. PERS-2c = location/emergency as real rows per ADR-051: location_ping (+90-day prune), geofence with shape CIRCLE|POLYGON, geofence_vertex, geofence_schedule (weekly windows + expect_by => NO_SHOW), geofence_event (+accuracy evidence), sos_alert (+acknowledged_by/at, request_id dedup, delete refused). geofence_engine.dart is pure Dart: haversine, ray-casting point-in-polygon (concave-safe), bounding circle for OS registration, accuracy gate + hysteresis band, schedule windows incl. midnight-crossing, noShowDueAt. Suite 984/984 (was 934); analyze clean; commit local (ADR-043..051 + PERS-2b/2c all unpushed). NEXT=PERS-2d communication/AI/audit — then Phase 3 screens, child dashboard first (25 placeholders). OPEN: CI must run `dart run build_runner build` before `flutter test` — *.g.dart is gitignored by policy. Push needs the GitHub token. /loop 5m.
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
