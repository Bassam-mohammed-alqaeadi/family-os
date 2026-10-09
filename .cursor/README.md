# Cursor configuration

The previous continuous-loop harness, automatic task selection and historical enforcement hooks were disabled and preserved under [`../docs/archive/2026-09-cursor-harness/`](../docs/archive/2026-09-cursor-harness/).

Current work must follow the repository-level authority map in [`../PROJECT_EXECUTION_PLAN.md`](../PROJECT_EXECUTION_PLAN.md) and [`../AGENTS.md`](../AGENTS.md). No automatic hook may select a historical card, mutate an old conversion log, or treat a prior frontend campaign as the current phase.

`mcp.json` remains an optional local-tool configuration. It is not a source of product or release authority.
