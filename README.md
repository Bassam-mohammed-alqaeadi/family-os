# Family OS — "عائلتي"
Family digital-wellbeing OS. **Design v1.0 is FROZEN (ADR-030)** — this repo is the single source of truth for the Flutter build.

## Start here (in order)
1. `handoff/00_START_HERE.md` — map of everything + how to work
2. `handoff/01_CURSOR_CONSTITUTION.md` — the 22 binding rules (mirrored in `.cursor/rules/`)
3. `handoff/02_ARCHITECTURE.md` — mandatory architecture & structure
4. `handoff/03_EXECUTION_PHASES.md` — phases F0→F7 + first task cards
5. `handoff/04_POLICY_REGISTER_EN.md` — **SUPREME LAW** for business logic

## The frozen prototype
Open `family-os/family_os_app.html` in a browser — 129 fully navigable screens (Arabic, RTL). This is the pixel/behavior reference for every conversion task.

## Repository map
| Path | Purpose |
|---|---|
| `handoff/` | English engineering handoff for the Flutter conversion (constitution, architecture, phases, supreme policy law) |
| `family-os/` | Frozen prototype + Arabic decision record (docs 00→44, ADRs) + `_REGISTRY/` (canonical CSV registries: 240 services, 73 journeys, 129 screens) |
| `docs_academic/` | Academic documentation (Arabic, RTL): use-case chapters و7-0→و7-5, 12 UC diagrams, plans, tools — see its README for reading order |
| `docs/project-plan/` | Cursor discovery outputs (PR #1–#3): product model, role matrix, service catalog, gap-closure specs |
| `.cursor/` | Cursor governance: rules (constitution) + hooks (shell/MCP guards, audit log) |

## Language policy
Engineering language: English (handoff/, code, commits). Product UI language: Arabic first via ARB (i18n from day one). Arabic docs in `family-os/*.md` are the historical decision record (ADR-001→031) — consult, don't modify.
