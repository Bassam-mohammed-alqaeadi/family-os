# LOOP_STATE

```
status: RUNNING
current_card: DEV-8 shipped (the three report surfaces on the v6 rows) — NEXT = DEV-6b (the rest of the studio: preview/approve · materials/lessons · generation outputs · staged project · add from source) then DEV-6c (community library · learning path + stops · results followup)
blocked_by: (none)
last_tick: 2026-09-24 (DEV-8 · reports wired · pushed)
resume_hint: DEV-8 — `app/lib/features/n07_advisor/reports_ux_bridge.dart` holds `Stage1ReportsRuntime` (one shared `FamilyDatabase`) plus `DriftChildUsageReportRepository` (SCR-FAT-069), `DriftWeeklyReportRepository` (SCR-FAT-073) and `DriftFocusReportRepository` (SCR-FAT-051). The reported week starts on Saturday (the prototype bars run Sat → Fri). Usage = that week of `wallet_ledger`: the negative side is spent time per app (ranked, bars relative to the busiest day, retention 30 days) and the positive side is gifted minutes for the apps its rows name. Weekly = earned minutes this week against the week before (a percent the ledger proves); no sleep claim, because the contract keeps no sleep rows; and its one recommendation is the newest `ai_suggestion`, where apply/defer write `applied_at`/`dismissed_at` through `DriftAiRepository`. The delivery choices (whenKey/styleKey/include) live with the repository because no table carries them (declared gap). Focus = `learn_session` kind = FOCUS for the week; the goal is the family's own enabled `focus_schedule` plan ((end−start) × masked days); the advisor note is the newest `focus_advisor_note` whose praise and reward each stamp their own row (the reward also inserting the minutes-only `wallet_ledger` entry with sourceRef `focus`); a schedule toggle writes `enabled`. Fail-closed: no family scope reads nothing and writes nothing, and another family's rows are never touched. MEASURED: analyze --fatal-infos clean · strings gate OK (332 files) · new tests 7 · FULL suite 1618/1618 (was 1611) · 35 of 131 screen files bind a Stage-1 runtime (was 32). NEXT: the studio remains the only domain with screens still on fixtures — DEV-6b (preview/approve over `content_pack.status` + `content_item`; materials/lessons · generation outputs · staged project · add from source) then DEV-6c (community library `community_cache` · learning path + stops · results followup). NOTE `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
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
