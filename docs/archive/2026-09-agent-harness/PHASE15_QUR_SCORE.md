# Phase 1.5 — Quran + Athkar score (P15-QUR-001)

**Date:** 2026-09-23  
**Lens:** Father / child experience (not API language)  
**Surfaces:** FAT-072 + CHD-025…027 (Quran/Athkar P0); CHD-028/029 noted as learn-plan adjacent  
**Authority:** Policy Register → prototype → rubric `docs/project-plan/10-service-ux-completeness-rubric.md`

## Domain verdict

| Domain | Overall | Notes |
|---|---|---|
| **Quran + Athkar** | **Shell→lifting** | Plan + recitation earn closed (002–003); offline/athkar board/whisper still open |

## Six-question score

| # | Question | Score | Evidence (father/child words) |
|---|---|---|---|
| 1 | Whole job in-app? | **Shell→lifting** | Plan publish + recitation approve/earn closed. Offline pack + athkar board still open. |
| 2 | Real controls? | **Shell→lifting** | Plan publish + approve→WalletLedger.earn (Rule 5). Download/whisper still toast-only. |
| 3 | Clear child path? | **Usable** | Ward binds father plan; record → parent review → approved status reflects. |
| 4 | Feedback to father? | **Shell→lifting** | Child submit → FAT-072 pending; approve deposits minutes. Athkar→day-board still open (QUR-005). |
| 5 | AI helper, not boss? | **Shell** | Core Quran approve is parent-of-child (good Rule 7 shape). No Quran AI suggest→approve seam; CHD-028/029 auto-apply locally (out of Quran vertical unless scoped in). |
| 6 | Honest empty/error/offline? | **Shell** | Loading + empty exist; no error path; offline tag is fixture-true — download does not prove offline readiness. |

**Usable for P0 Quran** requires all six Usable (or owner deferral in QUESTIONS). **Not Usable yet.**

## Gold-path gaps (priority order)

1. ~~Father cannot set/edit the ward plan that reaches the child~~ → **CLOSED P15-QUR-002**.  
2. ~~Child record never opens father’s pending / approve minutes pretend~~ → **CLOSED P15-QUR-003** (`QuranRecitationRepository` + WalletLedger.earn).  
3. Download / whisper decorative.  
4. Athkar completion one-way — no day-board blessing (P12).  
5. Memorization Review toast-only — father never sees map/review progress.

## Cards seeded

See `harness/BACKLOG.md` Lane 5.5 — `P15-QUR-002`…`007`.

| Card | Status | Summary |
|---|---|---|
| P15-QUR-001 | **done** (score) | This file |
| P15-QUR-002 | **done** | QuranWardPlan FAT-072→CHD-025 |
| P15-QUR-003 | **done** | Recitation submit→approve→earn |
| P15-QUR-004 | ready | Offline download → persist offlineReady on ward |
| P15-QUR-005 | ready | Athkar complete → FAT-010 blessing (P12) |
| P15-QUR-006 | ready | Memorization progress on father FAT-072/board |
| P15-QUR-007 | ready | Whisper encourage delivers to child surface |

**Scope note:** CHD-028/029 kept out of QUR GapClose (education smart-plan shape) unless owner expands vertical.

## Stage 3

Still **blocked**. Do not open `STAGE3-*`.
