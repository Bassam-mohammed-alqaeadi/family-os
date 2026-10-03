# Family OS — current execution plan

> **Status:** Active pointer, updated 2026-10-04. Previous phase plans, campaigns, question queues and continuous-loop instructions are preserved under [`docs/archive/`](docs/archive/); they are not execution authority.

## Authority order

1. [`docs/REAL_PLATFORM_TRANSFORMATION_RECORD.md`](docs/REAL_PLATFORM_TRANSFORMATION_RECORD.md) — product outcome and non-negotiable real-platform direction.
2. [`docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md) — truthfulness requirements.
3. [`docs/product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](docs/product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md) — approved scope.
4. [`docs/CURRENT_EXECUTION_PLAN.md`](docs/CURRENT_EXECUTION_PLAN.md) — current position and next operation.
5. Domain/runbook documents named by the current plan — operational detail only within the approved scope.

When documents conflict, do not average them or revive an older plan. Follow the highest applicable current authority and record a required new decision in [`docs/OPEN_DECISIONS.md`](docs/OPEN_DECISIONS.md).

## Current phase

**Controlled Children Roster staging release preparation.** Source hardening, contracts, tests and CI have been completed. Live staging remains unexecuted until the Staging Owner uses the protected, synthetic-only procedure in [`docs/foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md`](docs/foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md).

## Scope guard

Do not start or imply:

- a Flutter remote-authoritative roster integration or an additional Flutter API read;
- device registration, native control, policy delivery/enforcement, GPS/location truth or provider expansion;
- recovery/support implementation, real data, production, public/beta release or customer access.

Each needs evidence from the current increment and separate authorization. Product/UX refinement remains part of every eventual vertical slice; it is not a postponed cosmetic pass.
