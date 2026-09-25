# LOOP_STATE

```
status: RUNNING
current_card: DEV-6d batch 1 of 2 shipped (six child-learning surfaces on the v6 rows) — NEXT = DEV-6d batch 2 (آذكار · المعلّم · التحديات العائلية · التركيز · أصوات التركيز · القصص · الهدايا = 7 شاشات، ومنها ٣ بلا صفوف في العقد)
blocked_by: (none)
last_tick: 2026-09-25 (DEV-6d batch 1 · child learning wired · pushed)
resume_hint: DEV-6d batch 1 — `app/lib/features/n17_child_learn/learn_followup_bridge.dart` holds six adapters: `DriftChildLessonRepository` (the path's active stop names the lesson, the path's counters fill the slices), `DriftChildFlashcardsRepository` (the approved FLASHCARDS pack's `content_item` rows; reward from the naming `learn_assignment`; flipping/marking is sitting state), `DriftChildSmartPlanRepository` (open `learn_skill_gap` + the path; starting the plan sits a REVIEW `learn_session` naming the gap; completing a stage closes/promotes the stops, updates the path and pays `wallet_ledger`), `DriftChildMemorizationRepository` (`quran_memorization` + `learn_achievement` + `quran_recitation`, the plan names the surah of a recitation, starting a review writes a REVIEW sitting), `DriftChildSmartTilawahRepository` (the ward plan row; tips/praise editorial; device work writes nothing) and `DriftChildQuranWardRepository` (submits a PENDING `quran_recitation` covering the plan's range, reads the father's approval back, gifts = positive `wallet_ledger` entries). `Stage1LearnRuntime` gained `lesson`/`flashcards`/`smartPlan`/`memorization`/`smartTilawah`/`quranWard`. MEASURED: analyze --fatal-infos clean · strings gate OK (336 files) · new tests 7 · FULL suite 1640/1640 (was 1633) · 51 of 130 screen files bind a Stage-1 runtime (was 45). NEXT: DEV-6d batch 2 — الأذكار (`learn_progress` + ATHKAR sittings), المعلّم (`tutor_thread`/`tutor_turn`), التحديات العائلية (`family_challenge`/`family_challenge_day` + ledger), التركيز (`focus_schedule` + FOCUS sittings + `focus_advisor_note`)؛ وأصوات التركيز/القصص/الهدايا تُعلن فراغها العقدي (لا صفوف). NOTE `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
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
