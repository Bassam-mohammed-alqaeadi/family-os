# LOOP_STATE

```
status: RUNNING
current_card: DEV-6a shipped (studio core: board · create assignment · attribution on v6 rows); NEXT = DEV-6b (preview/approve + materials/lessons + generation outputs + staged project over content_pack/content_item) then DEV-6c (community library · focus report · learning path · results followup)
blocked_by: (none)
last_tick: 2026-09-24 (DEV-6a · studio core wired · pushed)
resume_hint: DEV-6a — `app/lib/features/n14_studio/studio_ux_bridge.dart` holds `Stage1StudioRuntime` and three Drift adapters. SCR-FAT-040 reads recent content from `content_pack` and draws its suggestion lane from the family's outstanding `learn_skill_gap` rows; SCR-FAT-049 names the child by order (childOne… — Rule 23), shows the newest gap with the reward a family `attribution_rule` sets, and publishes homework in the father's own words (plus the skill-gap and family-question paths) into the DEV-5a `learn_assignment` seam; SCR-FAT-045 reads the child's `attribution_rule` rows and on assign writes enabled/assigned/schedule_day_mask on them, inserts one `wallet_ledger` entry per enabled wallet (education/play — minutes only, ع-١) and publishes the attribution assignment. Schedule is stored as the day mask it means (bit 0 = today, bits 5–6 = the weekend); «أُسند» is the row's own flag. Fail-closed: an empty family reads nothing and publishes nothing, and an unowned child is never written to. MEASURED: analyze --fatal-infos clean · strings gate OK (330 files) · new tests 7 · FULL suite 1604/1604 (was 1597) · 30 of 131 screen files bind a Stage-1 runtime (was 27). NEXT per ADR-054 §11.3: DEV-6b — preview/approve over `content_pack.status` (+ `content_item` for the lesson block and the rule seconds; the option text itself stays in the signed bundle, a separate deliverable), then materials/lessons · generation outputs · staged project · add from source; DEV-6c — community library (`community_cache`) · focus report (aggregating learn_session kind = FOCUS) · learning path (+ stops) · results followup. NOTE `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
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
