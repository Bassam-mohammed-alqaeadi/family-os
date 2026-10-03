# Resume protocol — after QUESTIONS

## When the loop stops

The harness writes a question into [`QUESTIONS.md`](../QUESTIONS.md), sets [`LOOP_STATE.md`](LOOP_STATE.md) to `BLOCKED`, and stops auto-continue / `/loop`.

## What you do (Bassam)

1. Open `QUESTIONS.md`.  
2. Under the open question, fill **Answer:** with a real decision and a date (not “_(Bassam)_” placeholders).  
3. Say **“resume harness”** in chat — **or** wait for the next `/loop` tick (it detects answers automatically).

## What the Orchestrator does on resume

1. Read QUESTIONS — confirm every open item has a real Answer.  
2. Set LOOP_STATE `status: RUNNING`, `blocked_by: (none)`.  
3. Set the blocked backlog card back to `ready` (or keep NEXT).  
4. Run [`04_LOOP_PROMPT.md`](04_LOOP_PROMPT.md) immediately.  
5. Continue continuous loop law (Ship → next card → …).

## Do not

- Re-ask the same answered question.  
- Stay idle after answers appear.  
- Require Bassam to name the next card — BACKLOG NEXT handles that.  
