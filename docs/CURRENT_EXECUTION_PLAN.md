# Current execution plan — connected Children Roster slice

> **Status:** Active programme pointer as of 2026-10-04. This is the only live execution summary; it does not replace the detailed contracts, authorization decisions, operator runbooks or evidence it links to.

## Objective

Build Family OS as a truthful, secure and polished family platform. The completed Foundation increment established authoritative family/role/children-roster facts and obtained controlled synthetic staging evidence. The present approved increment is the next narrow vertical slice: render that already verified Children Roster truth in an isolated Flutter client without expanding into mutations, device/policy work or a public product claim.

## Current position

| Area | Position | Evidence / authority |
|---|---|---|
| Product direction | Active | [`REAL_PLATFORM_TRANSFORMATION_RECORD.md`](REAL_PLATFORM_TRANSFORMATION_RECORD.md) |
| Runtime truth | Binding | [`product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md) |
| Execution authorization | Foundation wave plus the bounded connected roster read | [`product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md), [`foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md`](foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md) |
| Backend Children Roster | Source, contract tests and CI complete | [`foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md`](foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md) |
| Controlled staging | **Executed and passed** on synthetic staging, 2026-10-03 | [`foundation/18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md`](foundation/18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md) |
| Flutter family discovery | Completed bounded Foundation Gate | [`foundation/14_FLUTTER_CONNECTED_FOUNDATION_GATE_ADMISSION_PACKET.md`](foundation/14_FLUTTER_CONNECTED_FOUNDATION_GATE_ADMISSION_PACKET.md), [`foundation/15_FLUTTER_CONNECTED_FOUNDATION_IMPLEMENTATION_PLAN.md`](foundation/15_FLUTTER_CONNECTED_FOUNDATION_IMPLEMENTATION_PLAN.md) |
| Flutter Children Roster read | Authorized; implementation and isolated verification next | [`foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md`](foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md) |
| Device/policy enforcement, recovery, production | Not authorized | [`product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md) |

## The next authorized operation

Implement and verify the **isolated Flutter-connected Children Roster read** exactly as defined in [`foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md`](foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md):

1. Extend the existing isolated Foundation Gate composition root only; do not wire the default mock-first application.
2. After server-authoritative family discovery and explicit family selection, make one authenticated `GET /v1/families/{familyId}/children` request against the approved HTTPS synthetic staging origin.
3. Render only returned child profile roster facts, clear source/freshness messaging, role-specific read-only context, and explicit loading/empty/denied/unavailable/network/retry/sign-out states.
4. Keep all family, roster and token state volatile; do not create any Flutter mutation or local persistence path.
5. Pass focused Foundation Gate CI, then perform the Owner-only synthetic Android-emulator verification without retaining secrets, identifiers, origin values, raw payloads or screenshots containing data.

## Completion boundary for the connected roster increment

This increment is complete only after the isolated implementation, focused CI and Owner-only synthetic emulator evidence required by plan 19 exist.

A successful result proves only a server-authoritative, read-only roster presentation for the approved synthetic Android-emulator scope. It does **not** authorize a Flutter mutation, default-app migration, another API read, device control, policy delivery/enforcement, location claims, recovery/support, real data, production or public release.

## Why the boundary remains narrow

The staging PASS proves that the backend is authoritative for this contract, not that every product surface or future capability is ready. The connected UI must keep that truth legible: a roster profile is not a child device, an applied policy, a current location, a health signal or a security-enforcement receipt.
