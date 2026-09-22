# Workflows

Each backlog card maps to exactly one workflow. Orchestrator runs steps in order; any FAIL returns to Builder (or Completeness) before Ship.

---

## ScreenBuild

**When:** Screen / foundation / component cards (F0+, wave screens).

1. Planner  
2. Builder  
3. Design + UX + ControlFit (parallel)  
4. Completeness (if card lists settings or linked SET ids)  
5. Verifier  
6. A11y (if UI)  
7. Fidelity (if UI)  
8. Policy (if economy/safety/AI)  
9. Trust  
10. LoopClosure (if parent-configured service or linked SET with propagation)  
11. Ship  

**Hard rule:** cannot Ship while linked SET/UI ids remain `CONVERSION-BACKLOG` unless QUESTIONS.md records owner deferral.

---

## GapClose

**When:** Lane GapClose SET or UI.

1. Planner (read 08 or 09 annex for that id)  
2. Completeness  
3. ControlFit  
4. LoopClosure (always for SET; for UI when cross-role)  
5. Builder (implement closure)  
6. Verifier + Trust (+ Policy if needed)  
7. Ship → mark GAP_LOG `CLOSED`

---

## LoopClose

**When:** Explicit loop-repair card (P12 broken arrow).

1. LoopClosure (specify broken arrow + failing tests)  
2. Builder  
3. Completeness  
4. Verifier  
5. Ship  

---

## ControlFit

**When:** Wrong control type identified without full SET rewrite.

1. ControlFit (specify lawful replacement)  
2. Builder  
3. Design + UX  
4. Completeness  
5. Verifier  
6. Ship  

---

## Ship (sub-workflow)

Used only as the terminal step of other workflows — see Ship agent in `02_AGENT_ROSTER.md`.

---

## Blocked

**When:** Ambiguity or owner gate missing.

1. Blocker → QUESTIONS.md  
2. HALT (no further subagents)  

Resume only after Bassam answers under the question with a date.

---

## Stage 0 note

Until Flutter exists, ScreenBuild/GapClose for code cards stay `blocked_until_stage1` except doc-only harness work. Foundation cards F0-A/B become `ready` after preflight answers in QUESTIONS.md.
