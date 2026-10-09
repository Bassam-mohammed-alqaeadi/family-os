# Family OS

Family OS is a **Global Super App for families**: one coherent Arabic-first and globally usable platform for family identity, safety, control, learning, connection and administration. Its rich prototype is the user-experience promise; the programme replaces mock engines with real, secure and recoverable product capabilities.

## Start here

| Read | Why |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Global Super-App Constitution: prototype promise, system-by-system delivery and hard guards. |
| [`docs/00_MASTER_PLAN.md`](docs/00_MASTER_PLAN.md) | The binding plan: 14 complete functions, the stages, the honest timing, and the first five tasks. |
| [`docs/CURRENT_EXECUTION_PLAN.md`](docs/CURRENT_EXECUTION_PLAN.md) | The live pointer: the one active function, its stage and the immediate decision. |
| [`docs/README.md`](docs/README.md) | The documentation map: what is authoritative, what is evidence, and what is history. |
| [`docs/REAL_PLATFORM_TRANSFORMATION_RECORD.md`](docs/REAL_PLATFORM_TRANSFORMATION_RECORD.md) | Real-platform direction, system sequencing and durable truth standard. |
| [`docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md) | Runtime-truth policy. |
| [`docs/real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md`](docs/real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md) | Active Family Entry & Children Control system: Cover-stage experience and contract specification. |

## Delivery model

```text
Prototype UX promise
→ competitor and user-job analysis
→ control-centre / state design
→ PostgreSQL + Node.js/Express authority
→ Native Android capability where the user job requires it
→ Flutter with truthful roles, states and recovery
→ quality, privacy, accessibility and controlled evidence
→ system locked before the next begins
```

A successful API request, mock interaction or attractive screen is not a completed capability. Every visible user fact and action must have an authorized source, a truthful result and a recovery path.

## Repository layout

| Path | Role |
|---|---|
| `app/` | Flutter product application and shared design system. |
| `backend/` | Node.js/Express Foundation API, PostgreSQL migrations, OpenAPI contract and staging verifiers. |
| `infra/` | Reviewed infrastructure templates; not a deployment record. |
| `docs/` | Current plan, system contracts, audits, product authority and preserved evidence. |
| `family-os/` | Frozen prototype/specification/registry reference. |
| `prototype/` | Frozen route-registry reference used by Flutter tests. |
| `docs/archive/` | Preserved historical material; evidence, never the current execution authority. |

## Branch policy

- `main` is the **only long-lived branch** and the single source of truth.
- Every change goes through a short-lived branch cut from `main` → pull request → green CI → **merge commit** (no squash, no rebase: loop documents cite commit hashes as evidence). The branch is deleted on merge and never outlives one pull request.
- No force-push to `main`. An unmerged branch is deleted only after an annotated `archive/*` tag is pushed on its head and verified on GitHub. Archive tags are never deleted.
- All earlier branches (`arena/*`, `copilot/*`, `cursor/*`, `feat/*`, `discovery/*`) were archived as `archive/*` tags and retired when development was unified on `main` (October 2026). Restore one with `git fetch origin tag archive/<name>` then `git switch -c <branch> archive/<name>`.
- Database migrations are numbered sequentially on `main`; the next one is `114` (enforced by `tools/harness/check_migration_range.sh`).

Full rules: [`docs/GIT_AND_GITHUB_OPERATING_METHOD.md`](docs/GIT_AND_GITHUB_OPERATING_METHOD.md) (Rule 5).

## Verification

```bash
npm ci --prefix backend
npm run check --prefix backend
npm test --prefix backend
```

Flutter and Foundation Gate checks are defined in `.github/workflows/`. Never place provider credentials, database URLs, JWTs, real family data or raw staging responses in source, CI logs or documentation.
