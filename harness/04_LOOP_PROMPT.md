# Loop prompt — every harness tick / `/loop` wake

Paste this block as the agent prompt, or arm `/loop 15m` with it as the wake payload.

---

```
FAMILY OS HARNESS TICK — CONTINUOUS LOOP

Workspace: D:\special projects\family

Algorithm (mandatory order):
1) Read harness/LOOP_STATE.md and QUESTIONS.md
2) If any question lacks a real **Answer:** (not a placeholder) →
     set LOOP_STATE status=BLOCKED, blocked_by=<ids>;
     do NO product work; remind Bassam; STOP /loop; end tick.
3) If LOOP_STATE was BLOCKED and answers now exist →
     follow harness/09_RESUME_PROTOCOL.md; set RUNNING; continue.
4) Read harness/00_NORTH_STAR.md + harness/01_OPERATING_MODEL.md
5) Read harness/BACKLOG.md — ONE card only (NEXT or first status=ready)
6) Read harness/08_SKILLS_MAP.md — load only skills for this card
7) Run workflow from harness/03_WORKFLOWS.md with agents from harness/02_AGENT_ROSTER.md
8) Pillar fail → retry in-loop (not an owner halt)
9) Ambiguity → Blocker writes QUESTIONS.md → LOOP_STATE BLOCKED → STOP loop → message Bassam
10) Ship success → CONVERSION_LOG + BACKLOG NEXT + LOOP_STATE RUNNING current_card=<next>
11) CONTINUOUS LAW (owner cadence 2026-09-21):
    - Immediately start the next ready card in THIS session.
    - Do NOT arm /loop until this wake has shipped ≥3 cards
      (unless BLOCKED by QUESTIONS, or hard context/time budget kill).
    - Prefer chaining beyond 3 while budget remains.
    - When leaving: arm /loop ~15m with THIS SAME PROMPT.
    - Never idle waiting for Bassam without a QUESTION.

Laws:
- Hard stop = unanswered QUESTIONS only
- Phase gates = GATE_READY log only (do not halt)
- One card per logical tick; P1–P12 enforce; P11/P12 when applicable
- Session minimum = 3 Ships per wake (quality unchanged)
- Authority: Policy Register → prototype → handoff
- Never guess
- Owner sequence 2026-09-21: finish all ScreenBuilds → Phase 1.5 UX completeness → Stage 3. Do NOT open STAGE3-* or live backend cards early.
- Phase 1.5 rubric: docs/project-plan/10-service-ux-completeness-rubric.md · gate: harness/11_PHASE_15_UX_COMPLETENESS_GATE.md

Tick report (required):
card_id | workflow | status(done|blocked|retry) | loop_state | next_card | ships_this_wake | armed_loop(yes/no)
```

---

## Arming `/loop` (local)

After the session minimum (≥3 Ships) when leaving:

```
/loop 15m <paste the FAMILY OS HARNESS TICK block above>
```

On BLOCKED: do **not** arm another wake until Bassam answers (or arm a long heartbeat that only checks QUESTIONS — prefer full stop).

## Resume

Bassam answers in QUESTIONS.md → says “resume harness” → run this prompt once → continuous law again.
