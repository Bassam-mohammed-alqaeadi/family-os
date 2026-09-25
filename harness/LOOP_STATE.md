# LOOP_STATE

```
status: RUNNING
current_card: DEV-6d batch 2 of 2 shipped (the child's remaining learning surfaces on the v6 rows) — the learn domain is closed at 57/130 bound; NEXT = n07_advisor (12 شاشة) then n02_day (21) أو ما يسمّيه المالك
blocked_by: (none)
last_tick: 2026-09-25 (DEV-6d batch 2 · learn domain closed · pushed 740424a)
resume_hint: DEV-6d batch 2 — `app/lib/features/n17_child_learn/learn_followup_bridge.dart` now holds twelve adapters; batch 2 added `DriftChildAthkarRepository` (each track one `learn_progress` row keyed `athkarRefEvening`/`athkarRefMorning`; `markSaid` advances the day's row, capped by its own total, and leaves a DONE `ATHKAR` sitting), `DriftChildTutorRepository` (newest `tutor_thread` + its `tutor_turn` rows oldest-first, role 'child' is the child side; the suggested questions stay empty — editorial), `DriftChildFamilyChallengesRepository` (the family's own active `family_challenge`; peers are the family's children in order labelled `childKeyFor`, each child's days from `family_challenge_day` over the challenge's own day range; the finished list is the inactive rows; nothing written), `DriftChildFocusRepository` (`sessionMinutes` is the enabled `focus_schedule` window's own length, `sessionActive` an open FOCUS `learn_session` today, praise only from a `focus_advisor_note` whose `praiseSentAt` is set; `startSession` writes one FOCUS row and never a second), `DriftChildInteractiveStoriesRepository` (the approved `STORY` pack's own `content_item` rows: the first is the chapter, the rest are choices; `choose` writes a DONE `STORY` sitting and the last choice is read back from the rows), `DriftChildComingGiftsRepository` (the child's positive `wallet_ledger` entries with their `source_ref` as the reason, opening the wallet SCR-CHD-019); empty snapshots now carry zeroed counts, never the models' fixture numbers. `Stage1LearnRuntime` gained athkar/tutor/familyChallenges/focus/stories/comingGifts. أصوات التركيز (SCR-CHD-035) stays unbound: the contract keeps no sound or preference row — declared gap. MEASURED: analyze --fatal-infos clean · strings gate OK (336 files) · new tests 8 · FULL suite 1648/1648 (was 1640) · 57 of 130 screen files bind a Stage-1 runtime (was 51). NOTE `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
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
