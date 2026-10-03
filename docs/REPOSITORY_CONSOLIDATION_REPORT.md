# Repository consolidation report

> **Completed:** 2026-10-04
> **Purpose:** Replace competing historical roadmaps with one active authority map without discarding design, policy, verification or academic history.

## Findings

The repository contained several valid but competing planning eras:

- a 484-file experience-discovery/frontend-campaign tree;
- an older project-plan and continuous agent-harness workflow with its own backlog, question queue, conversion log and automatic Cursor hooks;
- a root roadmap whose backend/native authorization markers predated the approved Foundation wave;
- academic deliverables, a one-off polish experiment and an unrelated external document at the repository root;
- frozen product/specification assets that remain consumed by Flutter tooling and therefore cannot be moved casually.

Leaving these all as peer entry points created a real risk that an agent or operator would follow a closed frontend campaign, an old hard stop or a stale “backend not authorized” marker instead of the currently authorized Foundation/Children Roster work.

## Decisions

| Decision | Rationale |
|---|---|
| Create `docs/README.md`, `docs/CURRENT_EXECUTION_PLAN.md` and `docs/OPEN_DECISIONS.md` | Gives people and agents a short, explicit current authority chain, current scope and external blockers. |
| Replace the root README, execution plan and agent guard | Removes the obsolete continuous-loop entrypoint and makes the current release boundary discoverable from the repository root. |
| Archive historical discovery, project-plan, harness, old root-control, academic, polish and gap-review material under dated `docs/archive/` folders | Preserves evidence and Git history without allowing it to compete as current authority. |
| Disable and archive legacy Cursor hooks/rules | Prevents automatic selection of stale cards, question queues, logs and verification logic. The active Cursor rule now follows current authorization/runtime truth. |
| Keep `family-os/` and `prototype/` in place | Flutter route tooling/tests and frozen-design reference material still use them. Moving them would be a functional migration, not a documentation cleanup. |
| Move the old handoff package to `docs/reference/frozen-prototype-handoff/` | Retains useful frozen-product context while removing it as a root-level execution authority. |
| Delete `docs/experience_discovery.zip` | It duplicated only a subset of preserved discovery files; retaining it would create an opaque second copy with no unique evidence. |

## Resulting structure

```text
app/                         Flutter product application
backend/                     Foundation API, migrations and verifiers
infra/                       Reviewed infrastructure templates
docs/
  README.md                  Documentation entry point
  CURRENT_EXECUTION_PLAN.md  Current programme / next operation
  OPEN_DECISIONS.md          Current external blockers and decisions
  foundation/                Active controlled-staging documentation
  real_platform/             Active vertical-slice contracts
  product_refinement_v2/     Product and authorization authority
  reference/                 Frozen reference material
  archive/                   Dated read-only history
family-os/                   Frozen specification / registry reference
prototype/                   Frozen route-registry reference used by tests
```

## Current operational conclusion

The only active external operation is the Owner-operated synthetic Children Roster staging release. Source changes, local tests and CI do not count as live staging evidence. Flutter remote-authoritative integration, policy/device work, recovery/support, production and real-data usage remain outside the present authorization.

See [`CURRENT_EXECUTION_PLAN.md`](CURRENT_EXECUTION_PLAN.md) for the live path and [`archive/README.md`](archive/README.md) for preserved historical material.
