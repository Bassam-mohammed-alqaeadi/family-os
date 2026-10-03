# Frozen reference assets

These directories are intentionally retained at the repository root because active code/tests or product-fidelity work consume them. They are **reference inputs**, not the current delivery plan.

| Path | Role | Change rule |
|---|---|---|
| `family-os/` | Frozen Arabic prototype, decision history, registry and schema reference | Do not edit casually. Any migration must preserve traceability and update dependent handoff/reference material. |
| `prototype/` | Frozen route registry consumed by Flutter route-generation and router tests | Do not rename or move without updating generation tooling and tests in the same reviewed change. |
| `docs/reference/frozen-prototype-handoff/` | Historical product-law, policy and UX handoff | Consult for product context. If it conflicts with current execution authority, current execution authority wins. |
| `.agents/skills/` | Optional local agent skills | Tooling support only; not product/release authority. |
| `.cursor/mcp.json` | Optional developer-tool configuration | Local convenience only; never a source of policy, scope or deployment truth. |

All historical plans, completed campaigns, disabled automation, academic material and unrelated external reference files have been consolidated under [`docs/archive/`](docs/archive/).
