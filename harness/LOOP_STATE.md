# LOOP_STATE

```
status: RUNNING
current_card: DEV-6c shipped (the studio's remaining five surfaces on the v6 rows) — the studio domain is closed; NEXT = DEV-5b (الدرس/البطاقات/الخطة الذكية)
blocked_by: (none)
last_tick: 2026-09-25 (DEV-6c · studio follow-up wired · pushed)
resume_hint: DEV-6c — `app/lib/features/n14_studio/studio_followup_bridge.dart` holds the rest of the studio: `DriftCommunityLibraryRepository` (SCR-FAT-046 — `community_cache` ordered by community rating, kind/author tokens mapped to the screen's closed vocabularies, publish-offer line empty by contract), `DriftLearningPathRepository` (SCR-FAT-047 — the acting child's newest `learning_path` + stops in `sort_order`; MASTERED/DONE → mastered, ACTIVE → current, else locked; subtitle from status/kind; reward only when the row has one), `DriftResultsFollowupRepository` (SCR-FAT-050 — newest `learn_result` with the previous same-`skill_ref` result as the change, first open `learn_skill_gap`, `DONE` `learn_session` rows as activities whose minutes are summed from `wallet_ledger` by `source_ref`), and `DriftQuranProgressRepository` (SCR-FAT-051 — active `quran_plan` + newest `quran_recitation` + `ANY` `learn_streak`; approve moves the pending row to `APPROVED` and pays the reward once through the ledger — a second tap earns nothing; cycling moves the active flag between stored plans; whisper/download/playback write nothing). SCR-FAT-042's `_onCapture` stages `AddSourceKind.camera` through `AddFromSourceRepository` before FAT-043. `Stage1StudioRuntime` gained `communityLibrary`/`learningPath`/`resultsFollowup`/`quranProgress`. Also fixed: `DriftChildDailyReviewRepository.completeSession()` now stamps `startedAt: Value(now)` so the injected clock matches `_doneToday()` (the review card broke across a date boundary). MEASURED: analyze --fatal-infos clean · strings gate OK (335 files) · new tests 8 · FULL suite 1633/1633 (was 1625) · 45 of 130 screen files bind a Stage-1 runtime (was 40). NEXT: DEV-6c is done — move to DEV-5b (the lesson / flashcards / smart plan side) then DEV-5c (Quran / challenges / tutor). NOTE `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
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
