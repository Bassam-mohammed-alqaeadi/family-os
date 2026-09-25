# LOOP_STATE

```
status: RUNNING
current_card: DEV-5a shipped (the five learn screens + the father-child seams on v6 rows); NEXT = DEV-5b (lesson · flashcards · smart plan over content_item + learn_progress) then DEV-5c (quran group · family challenges · tutor)
blocked_by: (none)
last_tick: 2026-09-24 (DEV-5a · learning domain wired · pushed)
resume_hint: DEV-5a — `app/lib/features/n17_child_learn/learn_ux_bridge.dart` holds `Stage1LearnRuntime` and six Drift adapters over the v6 learning tables: CHD-012 reads learn_assignment + learn_progress + learn_streak + learn_achievement + wallet_ledger + learning_path (level = earned achievements, bar = the path's percent or the mean of learn_progress); CHD-019 reads signed ledger balances per app and badges only from real learn_achievement rows; CHD-029 reads outstanding learn_skill_gap rows and its completeSession writes a real learn_session (so the sitting survives a reopen, ADR-042); CHD-016 reads the last learn_result plus the ledger entries written with it; and the two education seams write/read learn_assignment and learn_session + learn_result + wallet_ledger. The publishing host travels inside `request_id` as `<source>:<token>` (the contract has no source column) and the cta follows host first, subject second (`learnCtaFor`); scope resolves from the identity runtime at load time and every adapter refuses an unowned child (read nothing, write nothing). Five screens bind the real repos by default, tests keep injecting their in-memory seams. MEASURED: analyze --fatal-infos clean · strings gate OK (329 files) · new tests 7 · FULL suite 1597/1597 (was 1590) · 27 of 131 screen files bind a Stage-1 runtime (was 22). NEXT per ADR-054 §11: DEV-5b (lesson · flashcards · smart plan over content_item + learn_progress — text stays a reference into the signed bundle), then DEV-5c (quran_* group · family_challenge · tutor_thread/turn); focus · focus_sounds · interactive_stories · coming_gifts belong to the studio card, not learn_*. NOTE `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
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
