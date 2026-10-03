# Family OS execution guard

## Read before significant work

1. [`PROJECT_EXECUTION_PLAN.md`](PROJECT_EXECUTION_PLAN.md)
2. [`docs/CURRENT_EXECUTION_PLAN.md`](docs/CURRENT_EXECUTION_PLAN.md)
3. [`docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md)
4. [`docs/product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md`](docs/product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md)
5. [`docs/product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](docs/product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md)
6. The domain contract/runbook named by the requested work.

Historical planning, old continuous-loop automation and completed campaign material live in [`docs/archive/`](docs/archive/) and cannot authorize new work.

## Current scope

The controlled synthetic Children Roster staging release passed on 2026-10-03; minimal evidence is recorded in [`docs/foundation/18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md`](docs/foundation/18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md). The active increment is the familiar, coherent Children Control Centre refinement inside the single isolated, synthetic Flutter Children Roster read defined in [`docs/foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md`](docs/foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md) and [`docs/foundation/20_CHILDREN_CONTROL_CENTRE_REFINEMENT_EXECUTION.md`](docs/foundation/20_CHILDREN_CONTROL_CENTRE_REFINEMENT_EXECUTION.md).

## Hard guards

- Preserve runtime truth. Never use fixtures, local role selection, a mock fallback or a success-looking UI as a substitute for real family/role/child/device/policy facts.
- Keep authorization server-owned for remote facts. Validate scope and role, fail closed, and make source/freshness/capability state visible.
- Treat UX polish, RTL/EN, accessibility, responsive behavior and real loading/empty/error/denied/pending/recovery states as part of each vertical slice.
- Apply Jacob’s Law and the shared Family OS design system: use familiar interaction patterns and coherent family context, never novelty or a one-off mini-app. Familiarity never overrides authorization, runtime truth, privacy or accessibility.
- Do not expose secrets, provider/database URLs, tokens, synthetic identifiers, raw payloads, real data or logs in source, chat, CI or evidence.
- Do not expand beyond the specifically documented plan-19 Flutter roster read into any Flutter mutation, a third client API read, device/native enforcement, recovery/support, provider expansion, production or real-data work without a separate documented decision.
- Use additive forward migrations only. Never alter applied migration history or run a migration on application startup/CI.
- Record only durable evidence actually produced. Passing unit tests, CI and source review are not live staging evidence.
- Preserve `family-os/`, `prototype/` and `docs/reference/frozen-prototype-handoff/` as reference inputs unless a deliberate, tested migration updates their consumers.

## When external access is required

A protected Render/PostgreSQL/OIDC operation is Owner-operated. Prepare and validate the exact runbook, but do not request, store or paste credentials. Stop only for a genuine policy/security decision that is not already resolved by the authority documents; otherwise complete the permitted work.
