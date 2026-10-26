# Family OS Global Super-App Constitution (The Execution Guard)

## 1. Authority and execution pointer

This document sets the product direction. Before significant work, read the live system-selection and delivery pointer in [`docs/CURRENT_EXECUTION_PLAN.md`](docs/CURRENT_EXECUTION_PLAN.md), then the applicable domain contract.

The authority order is:

1. this Global Super-App Constitution — strategic direction, delivery model and the gates below;
2. [`docs/00_MASTER_PLAN.md`](docs/00_MASTER_PLAN.md) — the binding scope and sequence: 14 complete functions, the stages, the honest timing and the first five tasks. It supersedes the scope and schedule of the master plan's sections 6 and 7;
3. [`docs/CURRENT_EXECUTION_PLAN.md`](docs/CURRENT_EXECUTION_PLAN.md) — the one active function, its current stage and the next decision;
4. [`docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md`](docs/product_refinement_v2/16_RUNTIME_TRUTH_POLICY.md) and [`docs/product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md`](docs/product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md) — truth and experience requirements;
5. system-specific contracts, privacy/security decisions and runbooks — operational detail for the selected function.

**Tooling:** the agent chooses verification tools per task type by [`docs/development/AI_TOOLING_POLICY.md`](docs/development/AI_TOOLING_POLICY.md); that policy does not override this document.

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

**The one honesty measure.** Every function is measured on five columns — table,
contract, client, screen-and-journey, **on-the-phone**. A function is real at 5/5 or it
is not real. No report may describe a function as complete while any column is empty,
and the measure is published in every status report. The fifth column **"on the phone"**
was approved by the owner (**Taha**, 2026-10-10) applying §4 below: a device-control
claim cannot be real until its native lifecycle is implemented and **evidenced on a
real phone build**. It is marked ✅ only by a "passed" row in
`docs/safety_phase/PHONE_CHECKS.md` (release build, dated, test accounts); before that
it is ◐ at best. The first four columns alone remain the historical record of what was
built; the fifth is what the family actually experiences.

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

## 5.1 Durable Git guard (never trust the environment to remember)

The workspace is disposable, and so is every setting that lives outside Git. A repaired
environment is not a repaired repository: if the fix is not committed, the next session
starts broken again. Therefore the guard against repeated push failure lives **inside the
repository** and is re-applied in one command:

```bash
tools/git/git-doctor.sh repair     # start of every session (idempotent, non-destructive)
tools/git/git-doctor.sh push       # instead of a bare push: proves GitHub received the SHA
tools/git/git-doctor.sh check      # network, auth, settings, hooks, sync
tools/git/git-doctor.sh self-test  # offline proof that the guard still works
```

- `.githooks/pre-push` enforces the no-force-push rule mechanically: a non-fast-forward push
  or a branch deletion is refused locally, before anything reaches GitHub. `main` has no
  override at all.
- **Fail closed:** a push whose ancestry cannot be proven (missing remote object, shallow
  clone, any inconclusive `merge-base` result) is *refused*, not allowed after a warning.
  The fix is to prove it — `git fetch origin` then merge, or `git-doctor.sh repair` to
  complete a shallow history — not to bypass the guard.
- **Tags are absolute:** moving or deleting an existing tag is refused **always, with no
  override** — not even `FAMILY_OS_ALLOW_FORCE_PUSH=1`. Tags are references other people
  cite (`archive/*` in the branch log, loop documents), so a local override cannot be
  trusted with them. Creating a new tag is always allowed. A deliberate override exists for short-lived branches only, is opt-in via
  `FAMILY_OS_ALLOW_FORCE_PUSH=1`, and is written to `.git/family-os-push-guard.log`.
- `Git Guard CI` runs the self-test on every pull request, so a broken guard fails CI
  instead of failing silently.
- The guard never edits a tracked file and never reads a secret from the environment.

> **Historical note:** earlier Foundation Wave documents remain evidence of the base that was built. They are no longer the global product ceiling. The Global Super-App strategy builds truthful real engines to fulfil the user experience promised by the prototype.
