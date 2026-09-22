# Family — Agent Harness workspace

**Purpose:** a continuous agent loop that builds Family OS. It keeps shipping cards until it must ask you a question — then it stops; after you answer, it resumes.

```text
work → ship → next card → … → QUESTION? → STOP → you answer → RESUME → work …
```

## Start here

| Doc | Role |
|---|---|
| [`harness/00_NORTH_STAR.md`](harness/00_NORTH_STAR.md) | Why + ambition |
| [`harness/LOOP_STATE.md`](harness/LOOP_STATE.md) | RUNNING / BLOCKED / STOPPED |
| [`harness/04_LOOP_PROMPT.md`](harness/04_LOOP_PROMPT.md) | Paste every tick or `/loop 20m` |
| [`harness/09_RESUME_PROTOCOL.md`](harness/09_RESUME_PROTOCOL.md) | After you answer QUESTIONS |
| [`harness/BACKLOG.md`](harness/BACKLOG.md) | What to build next |
| [`QUESTIONS.md`](QUESTIONS.md) | **Only hard stop** for the loop |

## Layout

| Path | Role |
|---|---|
| `app/` | Flutter app — Flutter 3.35.7 / Dart 3.9.2 |
| `harness/` | Operating system for agents |
| `prototype/` | Frozen HTML + registries + contracts |
| `handoff/` | Product law |
| `docs/project-plan/` | SET/UI gap specs |
| `GAP_LOG.md` | Living gap status |
| `CONVERSION_LOG.md` | One line per shipped card |
| `.cursor/` | Rules, MCP (Dart/Playwright/Memory/Context7), hooks that chain ticks |

## Your job (Bassam)

1. Answer `QUESTIONS.md` when the loop blocks  
2. Say **resume harness** (or let the next `/loop` tick resume)  
3. Own money / store / legal; merge PRs when you want  

You do **not** pick the next card — BACKLOG + continuous law do.

## Quality

Pillars P1–P12 — fail = retry in-loop, not an owner halt (unless law is ambiguous → QUESTION).

## Status

- Continuous loop OS: **installed**  
- F0-0 scaffold: done  
- **NEXT:** F0-A (design tokens) — say **run the harness loop** to start  
