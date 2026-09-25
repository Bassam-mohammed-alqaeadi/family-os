# LOOP_STATE

```
status: RUNNING
current_card: DEV-6b shipped (the content side of the studio on the v6 rows) — NEXT = DEV-6c (community library over `community_cache` · learning path screen with its stops · results followup)
blocked_by: (none)
last_tick: 2026-09-24 (DEV-6b · studio content wired · pushed)
resume_hint: DEV-6b — `app/lib/features/n14_studio/studio_content_bridge.dart` holds the content side of the studio: `DriftAddFromSourceRepository` (SCR-FAT-041 — each gate stages a `GENERATED` `content_pack` with `status = STAGED` and `source_ref` naming the door), `DriftGenerationOutputsRepository` (SCR-FAT-043 — the staged pack's items, the P1 gate read from `content_item.phase_locked`), `DriftPreviewApproveRepository` (SCR-FAT-044 — quiz options encoded in `body_ref` as `key:1;key:0`, approve/reject move the row's status and stamp `approved_at`/`approved_by_account`, and the same snapshot goes to the child's `ApprovedPackRepository` until the child side reads rows), `DriftMaterialsLessonsRepository` (SCR-FAT-048 — subject packs with counts from their own items, path flag only where a real `learning_path` row exists) and `DriftStagedProjectRepository` (SCR-FAT-047 — `learning_path` + stops; confirming a stage marks it done, promotes the next, updates the path and pays `wallet_ledger`). `Stage1StudioRuntime` gained the five getters and the pack's `status` is the queue shared by 041→043→044. Fail-closed everywhere: no family scope reads nothing and writes nothing. MEASURED: analyze --fatal-infos clean · strings gate OK (334 files) · new tests 7 · FULL suite 1625/1625 (was 1618) · 40 of 131 screen files bind a Stage-1 runtime (was 35). NEXT: DEV-6c — the community library over `community_cache`, the learning path screen with its stops, and the results followup. NOTE `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
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
