# LOOP_STATE

```
status: RUNNING
current_card: DEV-3 shipped (contract v6); NEXT = the first beyond-wave-1 screen bound to the new tables
blocked_by: (none)
last_tick: 2026-09-24 (DEV-3 · contract v6 — 32 tables + migration + tests)
resume_hint: ADR-054 contract v6 landed in `lib/core/data/family_database.dart` — 32 new tables (learn_assignment/progress/session/result/skill_gap/streak/achievement · quran_plan/recitation/memorization · wallet_ledger · family_challenge + family_challenge_day (composite PK {challengeId, childId, dayIndex}) · tutor_thread/turn · content_pack/item · learning_path + learning_path_stop · attribution_rule · focus_schedule + focus_schedule_app · focus_advisor_note · community_cache · task · task_submission · chore_distribution · calendar_event · subscription_state · billing_event · invite · pairing_token), registered in `@DriftDatabase`, `schemaVersion 6` with `if (from < 6)`. Local tables 22→54 = the Postgres contract's own count; `family-os/_CONTRACTS/schema.sql` gained the same 30 new tables (libpg_query: 31 statements parse) plus a v6 verification DO block (no ARB key · no text column in the appendix). New `test/core/data/contract_v6_test.dart` (5 tests: fresh v6 · a v5→v6 upgrade recreates all 32 · real rows survive the upgrade · no `*key` column · family scope column present). MEASURED: analyze --fatal-infos clean · strings gate OK (326 files) · suite 1579/1579 (was 1574, +5). NOTE: `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
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
