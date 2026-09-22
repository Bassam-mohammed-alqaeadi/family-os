# Operating Model — how the harness runs

## Why this exists

The harness is a **continuous machine**. It keeps shipping backlog cards without waiting for Bassam — **except** when it must ask a real question in [`QUESTIONS.md`](../QUESTIONS.md). Then it **stops**. After you answer, it **resumes**.

See [`LOOP_STATE.md`](LOOP_STATE.md) and [`09_RESUME_PROTOCOL.md`](09_RESUME_PROTOCOL.md).

## Continuous loop law

1. After a successful **Ship**, the Orchestrator must **not idle**.
2. Immediately open the next `ready` / NEXT card in the same session.
3. **Session minimum (owner 2026-09-21):** ship **at least 3** cards per wake/session before leaving. Prefer chaining beyond 3 until context/time budget is exhausted.
4. Only when leaving after the minimum (or hard budget kill): arm `/loop` **15m** with [`04_LOOP_PROMPT.md`](04_LOOP_PROMPT.md). Never idle waiting for Bassam without a QUESTION.
5. Pillar fail → retry Builder in-loop (not an owner halt).
6. Linked SET/UI still open → either close them first, or write QUESTIONS if law is ambiguous — do not invent.
7. **Hard stop = only unanswered QUESTIONS.** Nothing else.

## One-task law

Exactly **one** backlog card per *logical* tick (build → verify → ship). Never batch screens into one Ship. After Ship, the *next* tick in the **same session** starts the next card (see session minimum above).

## Loop cadence

1. Read [`LOOP_STATE.md`](LOOP_STATE.md) + [`QUESTIONS.md`](../QUESTIONS.md).  
2. If unanswered QUESTIONS → set `BLOCKED`, halt (no work).  
3. If was BLOCKED and answers now present → resume (see [`09_RESUME_PROTOCOL.md`](09_RESUME_PROTOCOL.md)).  
4. Read [`BACKLOG.md`](BACKLOG.md) → NEXT or first `ready` card.  
5. Choose workflow ([`03_WORKFLOWS.md`](03_WORKFLOWS.md)); spawn agents ([`02_AGENT_ROSTER.md`](02_AGENT_ROSTER.md)).  
6. On success → Ship → update CONVERSION_LOG + BACKLOG NEXT → LOOP_STATE `RUNNING` → **continue**.  
7. On ambiguity → Blocker → QUESTIONS → LOOP_STATE `BLOCKED` → **stop loop**.  
8. On pillar fail → retry; do not Ship; do not ask Bassam unless law is ambiguous.

## Stop conditions (hard halt only)

| Condition | Action |
|---|---|
| Product law ambiguous | QUESTIONS.md + BLOCKED |
| Owner decision required (protected law, irreversible product choice) | QUESTIONS.md + BLOCKED |
| Unanswered QUESTIONS already open | Stay BLOCKED; do no work |

These are **not** hard stops (retry or continue):

- Pillar P1–P12 fail → fix and retry  
- Phase F0–F7 boundary → log `GATE_READY` in CONVERSION_LOG; **keep looping**  
- Analyze/test red → fix in-loop  

## Owner gates (notify-only — do not halt)

| Gate | Meaning |
|---|---|
| F0–F7 phase end | Append `GATE_READY \| Fx \| …` to CONVERSION_LOG so Bassam can inspect when free |
| Merge / PR | Agents open PRs; Bassam merges when ready — loop keeps building on the branch |
| Money / store / legal | Always QUESTIONS if the agent would need to invent these |

Bassam’s continuous job: **answer QUESTIONS**. Everything else the harness drives.

## Backlog lane priority

1. Foundation (F0 → F2) — **done**  
2. GapClose SET-001…024 — **done**  
3. GapClose UI-001…018 — **done**  
4. Screen waves W1 → W3 — **active until every SCR shipped**  
5. **Phase 1.5** Service UX completeness (after all SCR) — see [`11_PHASE_15_UX_COMPLETENESS_GATE.md`](11_PHASE_15_UX_COMPLETENESS_GATE.md)  
6. Global gaps G1–G8 (may run inside 1.5 / Stage 2)  
7. Later Stage 3–4: Platform / AI / Billing / Growth — **forbidden until Phase 1.5 gate**  

**Hard stop on backend:** Lane 6 `STAGE3-*` stays deferred until Phase 1.5 closes or owner defers leftovers in QUESTIONS.

## Evidence pack (every Ship)

- Pillar checklist P1–P12 (N/A where inapplicable)  
- Test / analyze summary  
- Fidelity screenshots when UI changed  
- GAP_LOG update when closing SET/UI  
- Update [`LOOP_STATE.md`](LOOP_STATE.md)  

## Anti-patterns

- Waiting for Bassam after Ship when no QUESTION exists  
- Treating phase gates as hard stops  
- Guessing instead of QUESTIONS  
- Shipping VISUAL-only settings / wrong controls / open father↔child loops  
