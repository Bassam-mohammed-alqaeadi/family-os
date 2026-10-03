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

The controlled synthetic Children Roster staging release passed on 2026-10-03; minimal evidence is recorded in [`docs/foundation/18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md`](docs/foundation/18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md). The immediate approved work is the isolated, synthetic Flutter roster-read slice in [`docs/foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md`](docs/foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md). It is **not** a production deployment, a general remote-app authorization, real-data usage, device enforcement or policy delivery.

## Verification

```bash
npm ci --prefix backend
npm run check --prefix backend
npm test --prefix backend
```

Flutter and Foundation Gate checks are defined in `.github/workflows/`. Do not put provider credentials, database URLs, JWTs, real family data or raw staging responses in the repository, CI logs or documentation.
