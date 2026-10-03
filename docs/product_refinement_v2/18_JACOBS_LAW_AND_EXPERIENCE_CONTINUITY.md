# Familiarity, continuity and Jacob’s Law

> **Status:** Binding product and delivery standard
> **Decision:** PRV2-021
> **Applies to:** Every Family OS role, screen, control centre, settings desk, API-connected vertical slice, design-system component, localization and release review.

## 1. Product decision

Family OS follows **Jacob’s Law**: people spend most of their time in other digital products, so familiar patterns, language, hierarchy and interaction behaviour reduce cognitive load. Family OS must meet users at that learned baseline, then improve clarity, safety and family-specific control without becoming a visual clone of another product.

This is not permission to copy a competitor’s branding, content, private workflows or limitations. It is a requirement to avoid novelty for novelty’s sake.

## 2. The operating rule

```text
Recognisable pattern
+ Family OS design system and Arabic-first identity
+ truthful source / authorization / capability state
+ role-aware explanation and recovery
= a familiar, coherent Family OS experience
```

When familiarity conflicts with truth, authorization, privacy, accessibility or safety, the truthful and safe behaviour wins. The UI must then explain the difference in familiar, plain language.

## 3. System-wide continuity requirements

Every vertical slice must use the shared Family OS experience spine rather than inventing a mini-application:

| Experience element | Required continuity |
|---|---|
| Navigation | A user can predict where family context, child context, controls, activity and help live. Use established mobile patterns: clear title, back/family switch, progressive disclosure and a stable primary action location. |
| Family context | Every family-scoped view states which family/child context is active and never silently changes it. |
| Roles | Primary guardian, co-guardian and child receive purposeful experiences. A hidden/disabled button is not a substitute for explaining the permitted scope. Server authorization remains decisive. |
| States | Loading, empty/setup, unavailable, denied, pending, error/retry, repair and success use the same visual grammar and plain-language recovery pattern across the product. |
| Controls | A control communicates value, effect, scope, eligibility, capability status, result and recovery. It does not become a mystery toggle. |
| Source and freshness | Remote, local-only, cached and unavailable states are recognizable without forcing the user to read technical diagnostics. |
| Design system | Reuse tokens, elevation, radii, typography, icon rhythm, touch targets and semantic patterns. Do not add one-off visual conventions to solve a single screen. |
| Global quality | Arabic/RTL is first-class; English/LTR, dynamic type, screen readers, focus order, phone/tablet/landscape and reduced cognitive load are required, not later polish. |

## 4. Familiar patterns Family OS may use

- A concise family-context header before a family-scoped list or dashboard.
- A clear collection/list/grid for children, with a recognisable card hierarchy and one understandable next step.
- Semantic section headings, concise summaries and progressive disclosure for advanced detail.
- Familiar loading, empty, permission-denied, unavailable and retry states with a clear recovery action where recovery exists.
- Read-only presentation for a role that may see a result but cannot change it.
- An explicit “not connected / not available yet” boundary rather than a fabricated device, policy or location card.

## 5. What Family OS must not do

- Copy another product’s appearance or call an unfamiliar interaction “premium” merely because it is novel.
- Scatter a family journey across unrelated screens, role pickers or temporary global fallbacks.
- Show a primary-looking action that cannot actually execute, or hide its effect/scope/eligibility.
- Make a co-guardian experience a degraded copy of the primary guardian, or make a child experience a hidden parent surface.
- Mix remote-authoritative data with seeded/local fallback data without an unmistakable source boundary.
- Use visual polish to obscure unavailable devices, policies, delivery receipts, freshness or authorization.

## 6. Required refinement sequence

No API-connected screen is accepted as a finished experience merely because its request succeeds. The implementation sequence is:

```text
Current-screen and user-job audit
→ familiar information architecture and state matrix
→ shared design-system composition and AR/EN copy
→ responsive/accessibility implementation with controlled state fakes
→ typed source/API connection
→ automated state/role/visual verification
→ controlled synthetic device/emulator evidence
```

The sequence is iterative, not a backend-first handoff: design refinement and truthful source integration evolve together. A technical adapter may be built early for safety, but it does not complete the user experience until the visual/state/role gates pass.

## 7. Definition of done for every refined screen

A screen may be called refined only when reviewers can answer “yes” to all of these:

1. Would a user recognise the navigation, list, control, state and recovery pattern without retraining?
2. Does the screen remain distinctly Family OS through the shared Arabic-first design system and family-specific context?
3. Does every displayed value have a declared source, freshness and capability boundary?
4. Does every role receive the correct meaningful experience without client-side authorization theatre?
5. Are empty, denied, unavailable, error/retry and repair states as intentional as the happy path?
6. Do AR/EN, RTL/LTR, dynamic type, semantics, touch targets and responsive layouts pass review?
7. Does the screen avoid unimplemented actions, fabricated status and unbounded scope expansion?
8. Do component/widget/integration tests and the relevant operator evidence match the claim being made?

## 8. Current application — Children Control Centre

`SCR-FAT-012` is the first active application of this standard. Its implementation must use the familiar control-centre pattern—family context, clear roster hierarchy, role-aware read-only treatment, recognisable recovery states and progressive disclosure—while showing only the narrow profile-roster truth currently available.

The current isolated Flutter roster read is a technical connection, not a declaration that the Children Control Centre is visually complete. Its refinement/acceptance sequence is recorded in [`../foundation/20_CHILDREN_CONTROL_CENTRE_REFINEMENT_EXECUTION.md`](../foundation/20_CHILDREN_CONTROL_CENTRE_REFINEMENT_EXECUTION.md).
