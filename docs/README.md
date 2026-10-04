# Family OS documentation

> **Current documentation entry point — 2026-10-04**
>
> This directory separates the active release programme from preserved historical discovery. Start here instead of scanning old phase plans.

## Current authority

Read these in order for active work:

1. [`REAL_PLATFORM_TRANSFORMATION_RECORD.md`](REAL_PLATFORM_TRANSFORMATION_RECORD.md) — product direction: real, truthful Family OS rather than a UI or API demo.
2. [`product_refinement_v2/00_PRODUCT_CHARTER.md`](product_refinement_v2/00_PRODUCT_CHARTER.md) — product charter and scope.
3. [`product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md) — non-negotiable runtime-truth policy.
4. [`product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md`](product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md) — binding familiarity, consistency and refinement standard.
5. [`product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md) — the authorization boundary for implementation.
6. [`CURRENT_EXECUTION_PLAN.md`](CURRENT_EXECUTION_PLAN.md) — live programme position, next controlled operation, and explicit exclusions.

## Active delivery material

| Path | Purpose | Status |
|---|---|---|
| [`foundation/`](foundation/) | Render/PostgreSQL/OIDC foundation, controlled staging evidence, and the bounded connected-roster slice | Active; isolated technical roster verification exists, while product parity and the next capability decision remain open. |
| [`foundation/22_CHILDREN_CONTROL_CENTRE_PRODUCT_PARITY_AUDIT.md`](foundation/22_CHILDREN_CONTROL_CENTRE_PRODUCT_PARITY_AUDIT.md) | Prototype-to-real capability, UX and state-gap audit for `SCR-FAT-012` | Decision-ready; not implementation authorization. |
| [`real_platform/`](real_platform/) | Truthful vertical-slice contracts, including the Children Control Centre | Active; default-app migration and every capability beyond the bounded roster read require their own authorization. |
| [`product_refinement_v2/`](product_refinement_v2/) | Product direction, runtime truth, system contracts and authorization gates | Active product authority. |
| [`OPEN_DECISIONS.md`](OPEN_DECISIONS.md) | Explicit current blockers and decisions; not a legacy backlog | Active. |
| [`REPOSITORY_CONSOLIDATION_REPORT.md`](REPOSITORY_CONSOLIDATION_REPORT.md) | What was archived, retained or deleted and why | Completed 2026-10-04. |

## Preserved reference material

| Path | Purpose | How to use it |
|---|---|---|
| [`../family-os/`](../family-os/) | Frozen Arabic prototype, registry, contracts and decision history | Reference input for product/design fidelity; not the current execution plan. |
| [`../prototype/`](../prototype/) | Frozen registry used by Flutter route-generation tests | Keep stable until the registry is deliberately migrated with matching test changes. |
| [`reference/frozen-prototype-handoff/`](reference/frozen-prototype-handoff/) | Historical policy and UX handoff | Consult for frozen-product context; current authorization is governed above. |
| [`archive/`](archive/) | Dated plans, discovery packs, old harness material and academic deliverables | Read-only history. It cannot authorize current work. |

## Documentation rules

- Do not create a second roadmap, unbounded backlog, or shadow authorization document.
- A document that claims an operation happened must link to durable evidence; source/CI readiness is not live staging evidence.
- New work belongs in an existing active authority folder or in a narrowly named current document. Historical material belongs in `archive/` with a dated index entry.
- Do not put secrets, tokens, origins, real family data, or raw provider/database output in documentation.
