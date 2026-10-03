# Family OS

Family OS is being developed as a truthful, role-aware family platform: polished parent, co-guardian and child experiences backed by explicitly scoped runtime sources, authorization, durable evidence and honest capability states.

## Start here

| Read | Why |
|---|---|
| [`docs/README.md`](docs/README.md) | Documentation map and authority order. |
| [`docs/CURRENT_EXECUTION_PLAN.md`](docs/CURRENT_EXECUTION_PLAN.md) | Current release position, next controlled operation and exclusions. |
| [`docs/REAL_PLATFORM_TRANSFORMATION_RECORD.md`](docs/REAL_PLATFORM_TRANSFORMATION_RECORD.md) | Product direction and the real-platform standard. |
| [`docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md) | Runtime-truth policy. |
| [`docs/product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](docs/product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md) | Current authorization boundary. |

## Repository layout

| Path | Role |
|---|---|
| `app/` | Flutter product application. |
| `backend/` | Fail-closed Foundation API, schema migrations, OpenAPI contract and staging verifiers. |
| `infra/` | Reviewed infrastructure templates; not a deployment record. |
| `docs/foundation/` | Controlled staging, release and evidence procedures. |
| `docs/real_platform/` | Active vertical-slice and runtime-truth contracts. |
| `docs/product_refinement_v2/` | Product authority and execution gates. |
| `family-os/` | Frozen prototype/specification/registry reference. |
| `prototype/` | Frozen route-registry reference used by Flutter tests. |
| `docs/reference/frozen-prototype-handoff/` | Historical product-law and UX handoff reference. |
| `docs/archive/` | Preserved historical plans and disabled automation; never current authority. |

## Current release boundary

The immediate approved work is a controlled, synthetic staging release of the narrowly scoped Children Roster API. It is **not** evidence of a production deployment, remote-authoritative Flutter UI, real-data usage, device enforcement or policy delivery. The exact owner-operated procedure is [`docs/foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md`](docs/foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md).

## Verification

```bash
npm ci --prefix backend
npm run check --prefix backend
npm test --prefix backend
```

Flutter and Foundation Gate checks are defined in `.github/workflows/`. Do not put provider credentials, database URLs, JWTs, real family data or raw staging responses in the repository, CI logs or documentation.
