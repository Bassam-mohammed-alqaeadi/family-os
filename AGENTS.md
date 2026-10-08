# Family OS Global Super-App Constitution (The Execution Guard)

## 1. Authority and execution pointer

This document sets the product direction. Before significant work, read the live system-selection and delivery pointer in [`docs/CURRENT_EXECUTION_PLAN.md`](docs/CURRENT_EXECUTION_PLAN.md), then the applicable domain contract.

The authority order is:

1. this Global Super-App Constitution — strategic direction, delivery model and the gates below;
2. [`docs/00_MASTER_PLAN.md`](docs/00_MASTER_PLAN.md) — the binding scope and sequence: 14 complete functions, the stages, the honest timing and the first five tasks. It supersedes the scope and schedule of the master plan's sections 6 and 7;
3. [`docs/CURRENT_EXECUTION_PLAN.md`](docs/CURRENT_EXECUTION_PLAN.md) — the one active function, its current stage and the next decision;
4. [`docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md) and [`docs/product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md`](docs/product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md) — truth and experience requirements;
5. system-specific contracts, privacy/security decisions and runbooks — operational detail for the selected function.

## 1.1 The two gates, and the one honesty measure

These were added on 2026-10-06, after a full audit of the code measured the platform at
2.5 of 42 systems sold as complete and zero usable families. They are binding on every
function from now on, and they are the answer to how that gap happened.

**Surface Wiring Gate.** No function is complete on four pieces of evidence together:
(1) the contract — every route in `app.js` present in `openapi/foundation.v1.json`, with
a drift test that fails when they differ; (2) the client — a Dart method that names the
route and reads its fields; (3) the surface — a screen reachable from a user journey,
never a file nothing imports; (4) the journey — a test proving a guardian reached the
outcome and saw a truthful state.

**Environment Gate.** No work touching SQL is complete until it actually runs on real
PostgreSQL in CI. Written migrations are not evidence; executed migrations are.

**The one honesty measure.** Every function is measured on four columns — table,
contract, client, screen-and-journey. A function is real at 4/4 or it is not real. No
report may describe a function as complete while any column is empty, and the measure is
published in every status report.

Foundation and staging documents preserve real technical evidence. They do not reduce the product destination to the smallest endpoint that has already been implemented.

## 2. The Grand Vision

Family OS is not a simple app; it is a **Global Super App** for families, designed to replace fragmented single-purpose apps such as Life360 for safety, Qustodio for parental control, and NotebookLM/Duolingo for learning. It must anticipate family needs and provide a seamless, flexible and beautiful experience that matches or exceeds leading global products.

## 3. The true meaning of polishing (عملية الصقل)

- **The prototype is the target.** The rich, colourful prototype is a promise to the user, not a draft to discard.
- **Do not delete — build.** If a valuable UI feature relies on mock data, retain its user value and build the data, backend and device services needed to make it real.
- **Competitive UX completion.** Polishing includes analysing strong competitors, finding missing journeys, controls and states, designing them coherently in the Family OS system, and wiring them to truthful runtime sources.
- **Runtime truth.** Production must never present fake data or a fake outcome. We solve mock gaps by building the real data pipeline, not by shrinking the product into a technical demo.

## 4. System-by-system execution (نظام بنظام)

Development proceeds vertically **system by system**, not as disconnected screen work. One selected system remains in focus until it passes its agreed exit gate; supporting design, backend, quality and Native work may proceed only in service of that system.

For every system:

1. **Domain selection:** lock one user problem and its affected family roles.
2. **Competitive analysis:** learn from global products without copying their branding or private workflows.
3. **UX gap analysis:** make the prototype journey, controls, states, settings and recovery good enough to compete.
4. **The real engine:** build the complete vertical slice as required: PostgreSQL data model → **Node.js/Express backend API** → authorised Native Android services where the capability requires them → Flutter UI.
5. **Lock and ship:** verify truth, roles, privacy, reliability, accessibility and experience quality before moving to the next system.

A system does not require Native work merely because another system will. Conversely, a device-control claim cannot be called real until its necessary Native lifecycle is implemented and evidenced.

## 5. Hard guards

- **No scattered development:** do not open unrelated systems before the active system reaches its exit decision.
- **No mock persistence:** no production outcome may originate from mock/seed data, a local role picker or a hidden fallback. Test and explicit demo routes remain separate.
- **One capability, one truth:** every visible state has a source, freshness, authorization scope, result and recovery path.
- **Server-owned authorization:** the client explains permission but does not decide it for remote or sensitive actions.
- **Keep and refine:** preserve valuable prototype UX while replacing its mock engines with real ones. Never let a technical shortcut force a degraded product journey.
- **Family OS continuity:** use the shared Arabic-first design system, familiar interaction patterns, role-aware flows, AR/EN, RTL/LTR, accessibility and responsive states.
- **Security and privacy:** never expose credentials, tokens, raw payloads, family identifiers or sensitive diagnostics in source, CI, evidence or chat.
- **Deliberate high-risk decisions:** production/public release, real-data expansion, invasive device capability, provider use and irreversible policy changes require explicit system-level decisions and evidence.

> **Historical note:** earlier Foundation Wave documents remain evidence of the base that was built. They are no longer the global product ceiling. The Global Super-App strategy builds truthful real engines to fulfil the user experience promised by the prototype.

## 6. Readiness pointer for execution honesty

Operational readiness classification and claim boundaries are maintained in
[`docs/RELEASE_READINESS.md`](docs/RELEASE_READINESS.md), and the concise handoff
for the next coding session is [`docs/NEXT_AGENT_RUNBOOK.md`](docs/NEXT_AGENT_RUNBOOK.md).
Use those files to avoid contradictory “complete / not authorized” wording when the
branch already contains real Foundation backend slices.
