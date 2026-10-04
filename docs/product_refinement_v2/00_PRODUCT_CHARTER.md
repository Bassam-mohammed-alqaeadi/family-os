# Product Charter — Family OS Product Refinement V2

> **Status:** Active product charter under the Global Super-App Constitution — 2026-10-04
> **Strategic authority:** [`../../AGENTS.md`](../../AGENTS.md) and [`../CURRENT_EXECUTION_PLAN.md`](../CURRENT_EXECUTION_PLAN.md).
> **Program position:** The earlier Foundation Wave established reusable technical evidence. It is retained as a historical implementation decision, not as the ceiling for product design. Delivery now selects one system at a time, preserves the prototype's valuable UX promise, and builds the real Node.js/Express, PostgreSQL, Native-where-needed and Flutter engine behind that system.

## 1. Product outcome

Family OS will become a single, globally usable family platform that brings together digital safety, family connection, learning, family intelligence, and operating administration.

The user experience must feel simple:

- A parent quickly understands what matters today, what needs a decision, and what changed for each child.
- A child has a respectful, motivating experience rather than a collection of surveillance controls.
- A guardian can act with confidence because the platform explains its state, its limits, and the result of every important action.

The complexity required to deliver this experience belongs behind the scenes. Beautiful screens are necessary, but they are not sufficient: every visible control must represent a real, understandable, and recoverable product state.

## 2. Product principles

1. **One platform, not a bundle of apps.** Every current system participates in a shared family context and contributes to the family experience.
2. **Calm first.** The primary screen communicates the state of the family; it does not expose 42 systems as competing destinations.
3. **Control without clutter.** Common decisions are quick; advanced controls appear progressively in a coherent settings desk.
4. **Truth before appearance.** A control never implies a platform capability, device state, or delivery guarantee that does not exist.
5. **Every action closes its loop.** The user receives an understandable result, proof where appropriate, and a recovery path when the action cannot complete.
6. **Respect every family member.** Parent control, child dignity, guardian collaboration, and clear consent are designed together.
7. **Global by design.** RTL/LTR, localization, accessibility, time zones, calendars, age differences, and cultural flexibility are product requirements—not late polish.
8. **Flexible per family, child, device, and moment.** A global default is useful only when a guardian can understand and tailor it.
9. **Evidence-led delivery.** Existing code and registries show what exists; actual operating-system capability determines what can be promised.
10. **Future scope stays future.** Attractive ideas outside the current system universe do not silently enter the build.

## 3. Shared platform spine

Every system must declare how it integrates with the following shared capabilities. A system can be exempt from an item only with a recorded reason.

| Shared capability | Platform responsibility |
|---|---|
| Family identity | Family, household, members, roles, guardian relationship, and recovery ownership. |
| Child and device context | The active child, applicable devices, device health, and capability availability. |
| Roles and permissions | Who may see, configure, approve, act, or receive a result. |
| Policy and settings desk | Defaults, per-child overrides, schedules, exceptions, history, and reversal. |
| Activity timeline | A coherent account of meaningful events and user actions across systems. |
| Notification center | Actionable, deduplicated, preference-aware alerts and confirmations. |
| Today dashboard | The concise daily view of priorities, progress, and recommended next actions. |
| Insight and intelligence | Explanations, patterns, recommendations, and human-controlled assistance. |
| Privacy, data, and support | Data visibility, export/delete/help paths, diagnostics, and auditability. |

## 4. People we design for

| Person | Primary need | Experience promise |
|---|---|---|
| Primary guardian | Understand, decide, and protect without becoming a system administrator. | Clear family pulse, full but manageable controls, proof of outcomes. |
| Guardian / co-parent | Participate within explicit permissions and shared context. | No duplicated work, no ambiguous authority, no surprise changes. |
| Child | Grow, communicate, learn, and understand boundaries. | A respectful, motivating experience with visible explanations and safe requests. |
| Support operator (future operating concern) | Help a family recover safely. | Auditable states, diagnostic context, and least-privilege assistance. |

## 5. Scope boundary

### Active product-refinement universe

The registered 42 systems / 240 services are in scope for analysis and eventual platform planning. This is **not** a promise to implement all of them in the first release. Each is classified through Product Refinement V2 as Core, Differentiator, Deferred Existing System, or Explicit Decision Required.

### Future Developments — explicitly excluded now

The following are not part of current product refinement, the current information architecture, Backend contracts, Native work, or release commitments:

- Expanded religion and values systems beyond the existing registered education system.
- Advanced home organization: shopping, meal planning, recipes, and household planning extensions.
- Financial responsibility products: allowance, savings, child wallet, budget, payments, or financial partnerships.
- One-way audio and other new candidate surveillance/context systems.

They are retained only as post-launch discovery candidates in the system universe.

### Delivery boundary today

This program creates an approved product, UX, capability, quality, and implementation-readiness foundation. It does **not** authorize production Backend or Native implementation. The current Flutter application remains a source of technical and UI evidence; it must not be presented as a remote, native-enforced product where it is not one.

### Runtime and backend truth

Family OS forbids production hard-coded family/product outcomes and fake success states. Dynamic state must come from an authoritative runtime service or an honestly labeled local/offline cache. The approved infrastructure boundary is Render as the system of record and paid/usage-dependent backend platform; Firebase is limited to individually reviewed no-cost auxiliary services. See `16_RUNTIME_TRUTH_POLICY.md` and `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md`. This records architecture direction only and does not authorize Backend or Native implementation.

## 6. Quality bar

A system is not product-ready merely because its happy-path screen is attractive. It is ready only when it has:

- A specific family problem, target people, outcome, and value proposition.
- Complete journeys for every affected role.
- A visual hierarchy that makes the next action clear.
- Empty, loading, offline, permission-needed, unsupported, error, success, and recovery states where applicable.
- A complete parent settings desk, including scope, schedules, exceptions, consequences, history, and reversal.
- Truthful platform/device capability states.
- Data, event, notification, audit, and support implications defined.
- Abuse, conflict, timing, and failure cases reviewed.
- Testable acceptance criteria and a sequenced implementation plan.

## 7. Definition of done: Security Product Ready

The first pillar is complete only when the 12 security systems have a reconciled product model; a shared security information architecture; role-based journeys; a visual screen/state map; settings and permission design; Android/iOS capability truth; technical dependency map; reliability and abuse analysis; measurable acceptance criteria; and an approved implementation sequence.

It is deliberately distinct from **Security Feature Complete** and **Security Release Ready**, which happen only after later implementation and verification gates.

## 8. Decision governance

- This charter is the source of product direction for Product Refinement V2.
- Accepted and pending decisions belong in `04_DECISION_REGISTER.md`.
- Product work proceeds autonomously unless it reaches a recorded approval gate.
- Irreversible scope, commercial promise, invasive capability, or Backend/Native authorization decisions require the Owner's approval.
- No legacy priority, legacy status, or prior phase label can silently change a V2 decision.
