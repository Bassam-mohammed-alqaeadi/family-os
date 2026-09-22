# Phase 1.5 — Service UX Completeness Gate

**Status:** ARMED — run only after the last SCR ScreenBuild ships.  
**Owner sequence (2026-09-21):** Screens → **this gate** → Stage 3 backend.  
**Rubric:** [`docs/project-plan/10-service-ux-completeness-rubric.md`](../docs/project-plan/10-service-ux-completeness-rubric.md)

---

## Entry condition

All rows in [`BACKLOG.md`](BACKLOG.md) Lane 5 (SCR-*) are `done` or `deferred` (tombstones only).  
Log in CONVERSION_LOG:

```text
GATE_READY | Phase-1.5-entry | all ScreenBuilds shipped | start UX completeness
```

Do **not** open `STAGE3-*` until Exit condition below.

---

## Algorithm

1. Walk each rubric domain with Bassam (or agent as UX partner using owner language).  
2. Score Missing / Shell / Usable per the six questions.  
3. Seed GapClose cards (SET-style) into BACKLOG for every Shell/Missing on P0 domains.  
4. Implement cards mock-first (Rule 25); ControlFit + GAP_LOG when controls change.  
5. **First vertical:** Education + Studio (FAT-040…051 + child learning). Then Quran → Tasks/Calendar → remaining Wave 2/3 holes.  
6. Re-score until P0 domains are Usable or owner-deferred in QUESTIONS.

---

## Exit condition (Stage 3 unlock)

Owner accepts Usable for P0 domains (or dated deferrals in QUESTIONS).  
Log:

```text
GATE_READY | Phase-1.5-exit | UX completeness accepted | Stage 3 unblocked
```

Then Lane 6 `STAGE3-*` may flip from `deferred` to `ready` one card at a time.

---

## Anti-patterns

- Starting Firebase / live uploads / live YouTube / live AI APIs before exit  
- Redesigning Education during the ScreenBuild wave  
- Reopening closed SET/UI without a Phase 1.5 score proving a hole  
- Scoring in “API” language instead of father/child experience  

---

## Tick report line (when gate runs)

```text
phase15 | domain=<name> | score=Missing|Shell|Usable | cards_seeded=<n> | stage3_still_blocked=yes
```
