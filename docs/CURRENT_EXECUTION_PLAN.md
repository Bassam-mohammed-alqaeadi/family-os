# Current execution plan — Foundation and Children Roster release

> **Status:** Active programme pointer as of 2026-10-04. This is the only live execution summary; it does not replace the detailed contracts or controlled operator runbooks it links to.

## Objective

Build Family OS as a truthful, secure and polished family platform. The present approved increment is deliberately narrow: establish authoritative family/role/children-roster foundations and obtain controlled synthetic staging evidence before any Flutter remote-authority claim or broader device/policy work.

## Current position

| Area | Position | Evidence / authority |
|---|---|---|
| Product direction | Active | [`REAL_PLATFORM_TRANSFORMATION_RECORD.md`](REAL_PLATFORM_TRANSFORMATION_RECORD.md) |
| Runtime truth | Binding | [`product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md) |
| Execution authorization | Foundation wave only | [`product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md) |
| Backend children roster | Source implementation, contract tests and CI complete | [`foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md`](foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md) |
| Controlled staging | Owner-authorized, **not yet executed** | [`foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md`](foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md), [`foundation/12_STAGING_EXECUTION_EVIDENCE.md`](foundation/12_STAGING_EXECUTION_EVIDENCE.md) |
| Flutter roster connection | Not authorized | [`foundation/14_FLUTTER_CONNECTED_FOUNDATION_GATE_ADMISSION_PACKET.md`](foundation/14_FLUTTER_CONNECTED_FOUNDATION_GATE_ADMISSION_PACKET.md), [`foundation/15_FLUTTER_CONNECTED_FOUNDATION_IMPLEMENTATION_PLAN.md`](foundation/15_FLUTTER_CONNECTED_FOUNDATION_IMPLEMENTATION_PLAN.md) |
| Device/policy enforcement, recovery, production | Not authorized by this increment | [`product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md) |

## The next controlled operation

The next operation is the Owner-operated **synthetic Children Roster staging release**. It must follow the exact sequence in [`foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md`](foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md):

1. Select and record one exact reviewed release SHA with passing CI.
2. Manually deploy that SHA to the isolated synthetic Render staging service.
3. Run the reviewed additive migration `005` once through a protected short-lived operator session.
4. Remove temporary database ingress immediately; prove liveness and readiness.
5. Run the synthetic authenticated roster verifier and the optional required read-only audit/outbox evidence check.
6. Retain only approved minimal evidence: SHA, timestamps, pass/fail labels, migration/checksum state, readiness state, and ingress-removal confirmation.

The procedure is intentionally Owner-operated because it requires protected Render/PostgreSQL/OIDC access. Do not place credentials in Git, CI, chat, shell history, source or evidence. Do not represent this document, a successful local test, or a passing CI run as deployment evidence.

## Completion boundary for this increment

The release increment is complete only after the documented staging evidence exists. A successful result proves the narrow family-scoped roster contract only:

- active primary guardian creation and idempotency;
- active guardian reads and co-guardian write denial;
- child and unrelated-principal denial;
- tenant isolation;
- correlated audit/outbox evidence.

It does **not** authorize Flutter remote-authoritative UI, real data, production, public release, device control, policy delivery/enforcement, location claims, recovery/support expansion, or a second API read.

## After staging evidence

Only after the evidence above and a separate governance decision may the programme consider a small Flutter vertical slice. That slice must preserve role-specific UX, source/freshness truth, empty/error/denied/pending states, accessibility, RTL/EN behaviour, responsive polish and corresponding integration/device evidence. It must not simply wire the existing local screen to an API.
