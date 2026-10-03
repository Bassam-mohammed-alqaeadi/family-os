# Family OS execution guard

## Read before significant work

1. [`PROJECT_EXECUTION_PLAN.md`](PROJECT_EXECUTION_PLAN.md)
2. [`docs/CURRENT_EXECUTION_PLAN.md`](docs/CURRENT_EXECUTION_PLAN.md)
3. [`docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md)
4. [`docs/product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](docs/product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md)
5. The domain contract/runbook named by the requested work.

Historical planning, old continuous-loop automation and completed campaign material live in [`docs/archive/`](docs/archive/) and cannot authorize new work.

## Current scope

The active increment is the controlled, synthetic Children Roster staging release defined in [`docs/foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md`](docs/foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md). Source/CI readiness is complete; live deployment, migration and authenticated verification evidence are not yet recorded.

## Hard guards

- Preserve runtime truth. Never use fixtures, local role selection, a mock fallback or a success-looking UI as a substitute for real family/role/child/device/policy facts.
- Keep authorization server-owned for remote facts. Validate scope and role, fail closed, and make source/freshness/capability state visible.
- Treat UX polish, RTL/EN, accessibility, responsive behavior and real loading/empty/error/denied/pending/recovery states as part of each vertical slice.
- Do not expose secrets, provider/database URLs, tokens, synthetic identifiers, raw payloads, real data or logs in source, chat, CI or evidence.
- Do not expand into Flutter remote integration, a second client API read, device/native enforcement, recovery/support, provider expansion, production or real-data work without a separate documented decision.
- Use additive forward migrations only. Never alter applied migration history or run a migration on application startup/CI.
- Record only durable evidence actually produced. Passing unit tests, CI and source review are not live staging evidence.
- Preserve `family-os/`, `prototype/` and `docs/reference/frozen-prototype-handoff/` as reference inputs unless a deliberate, tested migration updates their consumers.

## When external access is required

A protected Render/PostgreSQL/OIDC operation is Owner-operated. Prepare and validate the exact runbook, but do not request, store or paste credentials. Stop only for a genuine policy/security decision that is not already resolved by the authority documents; otherwise complete the permitted work.
