# Children Control Centre — Prototype-to-Real Product Parity Audit

> **Status:** Decision-ready product/UX audit — 2026-10-04.
>
> **Purpose:** Turn the existing prototype's visible user experience into a sequence of truthful, real capabilities. This is **not** an authorization to add a Flutter mutation, migrate the default application, connect device/policy/location data, or make a market/release claim.
>
> **Authority:** [`19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md`](19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md), [`20_CHILDREN_CONTROL_CENTRE_REFINEMENT_EXECUTION.md`](20_CHILDREN_CONTROL_CENTRE_REFINEMENT_EXECUTION.md), [`../real_platform/01_CHILDREN_CONTROL_CENTRE_SLICE.md`](../real_platform/01_CHILDREN_CONTROL_CENTRE_SLICE.md), and the binding [`../product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md`](../product_refinement_v2/18_JACOBS_LAW_AND_EXPERIENCE_CONTINUITY.md).

## 1. Executive verdict

The connected `ChildrenControlCentre` is a **real, narrow roster foundation**: it reads an authorized family roster from the server and treats session, access, unavailable and network states honestly. It is not yet the market-level Children Control Centre represented by the prototype.

The existing `ChildrenListScreen` and its related child routes are a useful **experience reference**, not a data or security specification. They show the user's expected journey—child cards, an open-child path, setup/repair, shared rules and role-aware controls—but several values and actions are local, seeded or fabricated. Copying their cards or toggles into the connected surface would create a misleading product.

The correct product outcome is neither of these extremes:

- not a technical roster with a successful GET request declared "polished"; and
- not a visually rich prototype whose buttons imply device, location or policy truth that does not exist.

The required outcome is a sequence of real vertical slices in which **each visible capability has an authorized source, role/scope rule, outcome, failure/recovery state and an intentionally refined place in the control-centre hierarchy**.

## 2. What was assessed

| Surface | Role in this audit | Current fact |
|---|---|---|
| `app/lib/features/n02_day/children_list_screen.dart` | Frozen-prototype UX reference for `SCR-FAT-012` | Presents roster rows, profile navigation, add/delete affordances, shared-policy controls, device/status language and setup/repair patterns. Its legacy paths include local/in-memory data and client-side seams. |
| `app/lib/features/n01_linking/add_child_screen.dart` and `app/lib/features/n02_day/child_profile_screen.dart` | Related prototype journeys | Show a child-creation flow and a rich child hub, but currently use local identity/device/mock projections. |
| `app/lib/foundation_gate/children_control_centre.dart` | Current connected presentation | Uses a server-authoritative family roster only; children show name and age and the screen deliberately has no mutation, device or policy model. |
| `GET /v1/families/{familyId}/children` | Current backend truth | Returns only a durable child-profile roster. The OpenAPI contract explicitly excludes device, location and policy state. |
| `POST /v1/families/{familyId}/children` | Existing backend foundation, not current Flutter scope | Can create a primary-guardian child profile with `displayName`, `ageYears` and an idempotency key. It is not wired into the Flutter slice and does not authorize a broader child-management UX. |

### Working rule

A prototype affordance is **experience evidence**: it tells us what a user expects to find and how a journey could be organized. It is never proof that the data is available, an action is authorized, or a capability may be marketed.

## 3. Current experience: strengths and missing product value

### Strengths to retain

- The connected surface makes the active family, roster count, server/current-session source and guardian context legible.
- It has intentional loading, empty, access-denied, unavailable, network, retry, family-switch and sign-out states.
- It does not fabricate device, policy, location, health, battery or enforcement information.
- The controller owns identity, token handling, API calls and server-result classification; the presentation widget does not become a second authority.
- The screen uses shared Family OS tokens and has focused Arabic/English, RTL, responsive, dynamic-type and semantic coverage.

### Product gaps

1. **No meaningful next step from a child card.** A parent can recognize a child but cannot enter a truthful child context, learn what is set up, or resolve an attention item.
2. **No management journey.** The prototype's add child, edit/delete, device-link and shared-rules journeys are not backed by the connected product surface.
3. **No control-centre information architecture.** The current page is a protected roster view, not yet a hierarchy of family context, attention/setup, child controls, shared rules, activity and advanced explanation.
4. **No capability lifecycle.** A parent cannot distinguish a saved draft from a configured, delivered, applied or verified policy because no such source exists yet.
5. **No unified main-app migration.** The connected surface is isolated. The normal `SCR-FAT-012` route still has legacy local/mock seams and must not silently mix them with remote facts.
6. **No product-complete role journey.** The roster API correctly denies unauthorized access, but the future primary-guardian, co-guardian and child experiences need action-specific server authorization and clear request/read-only treatment.

## 4. Prototype-to-real parity map

| User-visible capability | Prototype experience today | Truth available now | What is required before it becomes real | Delivery classification |
|---|---|---|---|---|
| Active family context and roster | Child list, family-scoped local/runtime paths and child count | Family discovery plus server roster | Preserve family switch, keep source/freshness visible, and remove normal-route fallback during migration | Current foundation; retain and refine |
| Child identity card | Avatar, name, age, health/status treatment and a tappable row | `id`, `displayName`, `ageYears` only | A child-context contract and route. Never derive an avatar, health or device state from the roster | Next read-model/design decision |
| Open a child control centre | Tapping a row opens `SCR-FAT-013` | No connected child-detail source | Define minimum child detail, route ownership, availability/repair states and authorization before navigation is enabled | New API/read-model decision |
| Add a child | Local form includes name, age, emoji and colour; local creation/persistence | Backend `POST /children` supports only name + age for the primary guardian | Explicit Flutter-mutation authorization; typed client; idempotency; validation; duplicate/conflict/retry UX; audit-safe outcome; roster refresh. Do not retain unsupported emoji/colour as if server profile facts | Candidate first mutation slice; not authorized now |
| Edit or remove a child | Local update/delete seams | No connected edit/delete endpoint | Separate lifecycle and safeguarding policy, API contract, role matrix, confirmation/recovery and audit plan | Separate product/security decision |
| Device link/setup | Prototype routes and local device-management records | No device API or trusted runtime source; default source is unavailable | Native/device enrollment decision, capability contract, consent, link receipts, freshness, repair and audit model | Explicitly outside current scope |
| Device/battery/location/health/time-left summaries | Prototype cards can show these labels and warning rings | None from the roster endpoint | Independent, authorized, fresh sources for each fact. Location and health require additional privacy/consent decisions | Do not render as current facts |
| Shared rules: time cap, bedtime, web filter | Local bottom sheet, scope chips, dropdown and switch | `FamilyPolicySource` is an unavailable/local boundary, not an enforcement source | Policy domain contract, role/scope rules, persistence, versioning, approval, delivery/application/verification receipts, native enforcement and audit | Explicitly outside current scope |
| Shared-policy status and exceptions | Prototype implies saved settings and exceptions | No authoritative policy lifecycle | The UI must show source, scope, effect and lifecycle truth—not a success-looking toggle | Later policy vertical slice |
| Setup/repair attention | Prototype has repair cards | Roster empty and network/error states exist | Define which source may raise each attention item and give it one real repair path | Can be designed now; connect per source later |
| Role treatment | Client-side role gates and local fallbacks influence UI | Server controls roster access; discovery role is display context only | Per-action server authorization plus primary/co-guardian/child state matrix. A client gate may explain but never decide access | Required for every future mutation |
| Recovery and safety states | Local error/empty states, some local demos | Strong connected 401/403/503/network handling | Preserve this quality for every new capability, including conflict, pending, rollback and audit/result states | Current foundation; extend consistently |
| Activity and change history | A future control-centre expectation, not a real source on this screen | No child-control activity projection | Define event/audit projection, privacy redaction, pagination/retention and role visibility | Later read-model decision |

## 5. Target information architecture

This is the target **structure**, not permission to render inactive controls as active:

```text
Children
├─ Active family context
│  ├─ family switch
│  ├─ source / freshness / availability explanation
│  └─ role-specific scope explanation
├─ Attention and setup (only when a real source raises it)
│  └─ one understandable repair or request path
├─ Children
│  └─ child control cards
│     ├─ verified identity or explicit setup-needed state
│     ├─ only sourced device/policy status
│     ├─ one relevant next step
│     └─ open child control centre when its source exists
├─ Shared controls
│  ├─ scope and impact summary
│  ├─ configuration and lifecycle state
│  └─ edit / request / read-only treatment by role
└─ Advanced and activity
   └─ explanation, history and recovery through progressive disclosure
```

The completed roster-only increment proves only its own connected foundation. Under the Global Super-App strategy, the other nodes are retained as product targets and are brought online system by system when their Node.js/Express, PostgreSQL or Native source and role/safety contract exist. They must not be represented by persuasive but non-working toggles in the meantime.

## 6. Recommended product sequence

The sequence below follows the large-product-team pattern: validate the user job and interaction model, authorize one capability boundary, build the full vertical slice across design/backend/mobile/security/QA, then measure it before the next capability.

### Step 0 — Complete this parity audit and the visual/interaction specification

- Treat the prototype as a research/reference input, tagging every visible value and action as `real now`, `local/demo`, `needs contract`, or `out of scope`.
- Produce state maps and responsive AR/EN designs for primary guardian, co-guardian and child—not one parent screen with hidden buttons.
- Define the content hierarchy, card anatomy, action priority, empty/setup, denied, pending, success, failure, retry and repair states before implementation.
- Correct all documents and release language so technical roster verification is never described as full Children Control Centre completion.

### Step 1 — Authorize one bounded child-profile lifecycle slice

The most natural candidate is a **primary-guardian create-child-profile** flow because a narrow server contract already exists. It still requires a separate authorization decision; the current Flutter roster scope is read-only.

A complete slice would include:

```text
Entry from a truthful empty/setup roster state
→ accessible form for name and age only
→ authenticated, idempotent create request
→ pending / validation / duplicate-conflict / denied / unavailable / retry states
→ server-confirmed roster refresh
→ role-safe audit/result explanation
```

It must deliberately omit device enrollment, child accounts, location, policies, emoji/colour as authoritative profile properties, and a public release claim.

### Step 2 — Define and deliver a child-detail read model

Before a child card can open a real control centre, decide the minimum profile fields, source provenance, freshness, role visibility and repair states. Build its API/read model and UI together; do not navigate from the roster into a local/mock profile.

### Step 3 — Evaluate device linkage as its own capability

This requires a separate native/security/privacy authorization. The first truthful experience may be link/setup/repair state only. It cannot claim monitoring, location, battery, policy delivery or enforcement by inference.

### Step 4 — Deliver policy configuration and enforcement as a separate vertical slice

A policy toggle becomes real only with end-to-end scope, validation, authorization, durable configuration, delivery, application/verification evidence, failure/recovery and audit. The UI must distinguish every lifecycle stage.

### Step 5 — Add requests, explanations and activity only from authorized projections

Co-guardian request flows, child transparency, approvals and history should follow the capability sources above. They are not decorative additions to the roster.

## 7. Operating model and gates

| Discipline | Required outcome before a slice is called complete |
|---|---|
| Product | Clear user job, role/scope policy, explicit non-goals and measurable acceptance criteria |
| UX/content | Familiar information architecture, action hierarchy, copy, source/freshness language, AR/EN and all role/state variants |
| Backend/data | Versioned contract, authorization, tenant isolation, validation, idempotency for mutations, durable source of truth and safe audit events |
| Mobile | Shared design-system composition, typed client/source boundary, no seeded fallback on normal routes, accessible responsive implementation and truthful local state |
| Security/privacy | Data classification, consent where necessary, least privilege, abuse/rate-limit handling, sensitive-action confirmation and redaction rules |
| Quality/operations | Contract/unit/widget/integration tests; fault states; operational diagnostics without raw family data; controlled synthetic evidence |
| Release | Product review verifies capability parity and truthfulness; a passing request or CI run alone cannot grant a product-ready or market-ready label |

## 8. Definition of parity for this programme

A capability reaches parity with the prototype only when the user can find and complete the intended job with equal or better clarity **and** all of the following are true:

1. every visible fact has an identified source, freshness and provenance;
2. every actionable control has server/native-authorized scope, effect, result and recovery;
3. the UI explains unavailable, setup, pending, denied and failed states as intentionally as success;
4. role differences are purposeful and do not rely on client-side authorization;
5. the interaction is usable in Arabic RTL and English LTR, on phone/tablet, with enlarged text, screen readers and keyboard/focus where applicable;
6. tests and controlled synthetic evidence support the exact claim; and
7. the slice is approved under the applicable execution authorization before it is exposed, marketed or expanded.

## 9. Immediate conclusion

The next work is **not** to attach more server endpoints to the present roster layout. It is to use this audit to create the target Children Control Centre interaction/state specification, then seek one intentional capability authorization and deliver that capability as a fully refined real vertical slice.

Until then, the correct current label is:

> **Connected, server-authoritative read-only Children Roster foundation — not a complete or market-ready Children Control Centre.**
