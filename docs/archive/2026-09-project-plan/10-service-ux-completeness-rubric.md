# 10 — Service UX Completeness Rubric

**Audience:** Bassam (owner) + agents acting as UX partners  
**Voice:** Father / child experience — not engineer jargon  
**When used:** Phase 1.5 (after every ScreenBuild ships). Not during the ScreenBuild wave except as a north-star reminder.  
**Authority:** Policy Register → frozen prototype → this rubric (ControlFit / P11–P12). Does not invent product law.  
**Owner date:** 2026-09-21

---

## Why this exists

A screen that “exists” is not enough. Each **service** must feel complete enough that the father does not need another app (Classroom, Drive, WhatsApp groups, separate filter tools, etc.) for that job.

Safety spine gaps (SET-001…024 / UI-001…018) already closed the control OS for time, filter, lock, SOS, privacy, and boards. Phase 1.5 applies the **same completeness bar** to Education, Studio, Quran, Tasks, and the rest.

---

## Gold example — Education (owner story)

This is the bar every domain must match in spirit:

1. Father creates a **subject** and lessons inside the app.  
2. He adds **sources** to a lesson: PDF file, downloadable video, YouTube link, or upload for the advisor to study.  
3. AI may **propose** how to teach from that source — father **approves** before the child sees it.  
4. Father creates **tests** by hand or from AI suggestions — again, approve first.  
5. Child learns, submits, takes the test.  
6. Father gets **feedback** on the day board / inbox: progress, late work, results — without leaving Family OS.

If any step forces him onto another platform, the service scores below **Usable**.

---

## Six questions (score every domain)

Ask in father/child language. Score each domain **Missing / Shell / Usable**.

| # | Question | Missing | Shell | Usable |
|---|---|---|---|---|
| 1 | **Whole job in-app?** Can the father finish the job without another tool? | Job not offered | Screen exists; critical steps dead or external | End-to-end path inside the app (mock OK until Stage 3) |
| 2 | **Real controls?** Do buttons/cards/pickers match the job (upload, paste link, approve)? | No controls | Decorative toggles / fake CTAs | Controls bind → persist → effect (P11) |
| 3 | **Clear child path?** Does the child know open → do → submit → calm result? | No child surface | Child screen with planted/fake state | Live bind to what father configured |
| 4 | **Feedback to father?** Progress, requests, results return to board/inbox? | One-way only | Static “success” with no loop | Closed loop (P12) with ack |
| 5 | **AI helper, not boss?** Suggest → father approve → then child sees? | AI auto-applies or hidden | Suggest with no approve path | Approve/reject ends every AI action |
| 6 | **Honest empty/error/offline?** No fake names; no pretend ON when the phone cannot? | Fake success / planted kids | Partial honesty | Empty/loading/error/offline + capability honesty |

**Usable** for a P0 domain = all six at Usable (or owner-deferred in QUESTIONS with date).

---

## Domains to score in Phase 1.5

| Domain | Father hubs (examples) | Child side (examples) | Notes |
|---|---|---|---|
| Safety / SOS / location | FAT-014…018, 028 | CHD-005/006, 024 | Largely Usable after SET/UI |
| Screen time / filter / lock | FAT-032, 036, 037 | CHD-004, 021 | Largely Usable after SET |
| Chat / calls | FAT-021…024 | CHD-007…009 | ScreenBuild then loop check |
| Day boards | FAT-010 | CHD-004 | UI-004/005 done |
| **Education + Studio** | FAT-040…051 | CHD-012…017 | **First Phase 1.5 vertical** |
| Quran / faith | FAT-072 + CHD-025… | CHD-025… | After Education |
| Tasks / calendar | FAT-052…055 | CHD-022 | After Quran |
| Privacy / notifications | FAT-058/059 | CHD-010 | SET closed — recheck only if holes |
| AI advisor | FAT-011, 029, 079 | — | Suggest-only already law |
| Platform monitoring | FAT-067/068 | — | Honesty closed — recheck |
| Billing | FAT-056/057 | — | Safety never gated (P-4) |

---

## How agents use this

1. Do **not** redesign Education mid-ScreenBuild wave.  
2. After last SCR ships → run gate [`harness/11_PHASE_15_UX_COMPLETENESS_GATE.md`](../../harness/11_PHASE_15_UX_COMPLETENESS_GATE.md).  
3. Seed GapClose cards from Failed / Shell rows.  
4. ControlFit (P11) when a prototype control cannot do the job — log in GAP_LOG.  
5. Stage 3 backend only after owner accepts Usable for P0 domains (or defers leftovers).

---

## Related

- [`harness/07_COMPLETENESS_AND_LOOPS.md`](../../harness/07_COMPLETENESS_AND_LOOPS.md) — P11 / P12  
- [`harness/10_COMPETITIVE_LENS.md`](../../harness/10_COMPETITIVE_LENS.md) — control fitness vs competitors  
- [`GAP_LOG.md`](../../GAP_LOG.md) — living gap index  
