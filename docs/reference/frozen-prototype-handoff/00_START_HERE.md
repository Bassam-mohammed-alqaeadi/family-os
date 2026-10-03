# Family OS "عائلتي" — Cursor Handoff Package
**Version**: Design v1.0 (FROZEN — ADR-030) · **Date**: 2026-09-18 · **Language of product UI**: Arabic (RTL) — English is the engineering language.

## What this repository contains
| Path | What it is | Authority level |
|---|---|---|
| `family-os/family_os_app.html` | ⭐ THE FROZEN PROTOTYPE — 129 screens, single file, fully navigable. This is the pixel/behavior source of truth. | **LAW** |
| `handoff/01_CURSOR_CONSTITUTION.md` | The 22 binding rules for Cursor. Read before ANY task. Also mirrored in `.cursor/rules/`. | **LAW** |
| `handoff/02_ARCHITECTURE.md` | Chosen architecture and mandatory project structure. | **LAW** |
| `handoff/03_EXECUTION_PHASES.md` | Phases F0→F7 with owner gates and the first 3 task cards. | Plan |
| `handoff/04_POLICY_REGISTER_EN.md` | English digest of the Policy Register (doc 40) — the supreme reference on any conflict. | **SUPREME LAW** |
| `handoff/05_ACCEPTANCE_SCENARIOS.md` | The 5 walkthrough scenarios (71 checks) that became acceptance tests. | Test spec |
| `handoff/06_DESIGN_TOKENS.md` | Exact design tokens extracted from the frozen prototype CSS. | **LAW** |
| `handoff/07_GLOBAL_GAPS.md` | The 8 global-readiness gaps and where each is structurally closed. | Plan |
| `family-os/_REGISTRY/screens.csv` | Registry of all 129 screens (IDs, titles, app, tab). Router is GENERATED from this. | **LAW** |
| `family-os/_CONTRACTS/schema.sql` | Database contract — Drift schema derives from it. | **LAW** |
| `family-os/*.md` (Arabic docs 00–43) | Full decision history (ADR-001→031), audits, session minutes. Consult when context is needed; do not modify. | Archive |

## How to work (non-negotiable)
1. **One task = one system (or one screen).** Never batch-convert.
2. Every task card names: system number, its screens, the original HTML snippet, related policy clauses, acceptance criteria.
3. On ANY ambiguity: **STOP. Write the question in `QUESTIONS.md`. Do not guess.**
4. Every completed task appends one line to `CONVERSION_LOG.md`.
5. Conflicts resolve in this order: `04_POLICY_REGISTER_EN.md` → frozen prototype → architecture doc → ask the owner.

## The product in one paragraph
A family digital-wellbeing OS (parent + child experiences in ONE app, role-based). Parent has full sovereignty; AI ("Family Advisor") only suggests, never acts. The ONLY reward currency is **minutes** (set by the father per task). Safety features (SOS, location, family chat) are free forever and never gated by subscription. Offline-first. Arabic-first (RTL) with i18n from day one.
