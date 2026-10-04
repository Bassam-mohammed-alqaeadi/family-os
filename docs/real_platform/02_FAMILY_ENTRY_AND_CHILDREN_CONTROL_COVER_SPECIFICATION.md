# Family Entry & Children Control — Cover Specification

> **System:** Family Entry & Children Control — the first active Global Super-App system, selected 2026-10-04.
>
> **Stage:** **Cover** remains the system design authority. On 2026-10-04, the product owner separately admitted the bounded name-and-age primary-guardian create-child capability for real implementation; see [`03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md`](03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md). No broader child, device, policy, location, provider or release capability is admitted.
>
> **Authority:** [`../../AGENTS.md`](../../AGENTS.md), [`../CURRENT_EXECUTION_PLAN.md`](../CURRENT_EXECUTION_PLAN.md), [`01_CHILDREN_CONTROL_CENTRE_SLICE.md`](01_CHILDREN_CONTROL_CENTRE_SLICE.md), and [`../foundation/22_CHILDREN_CONTROL_CENTRE_PRODUCT_PARITY_AUDIT.md`](../foundation/22_CHILDREN_CONTROL_CENTRE_PRODUCT_PARITY_AUDIT.md).

## 1. System outcome

A family member can enter the correct family context, understand who can do what, see an honest child roster or setup state, and take the next real step without encountering a mock, ambiguous authority or fake result.

The system must grow toward the prototype's complete Children Control Centre promise, not stop at a connected list. It will do so in real capability slices, beginning with the smallest high-value lifecycle that can be made authoritative and recoverable.

```text
Identity and session
→ family context
→ roster or honest setup state
→ authorised child-profile lifecycle
→ child context and repair/setup guidance
→ later device/policy controls only when their real engines exist
```

## 2. Product boundary

### In the system

- account/session entry needed to obtain an authorized family context;
- family selection and clear family-switch behaviour;
- primary guardian, co-guardian and child treatment;
- child roster, empty/setup, access, unavailable and recovery states;
- a durable child-profile lifecycle when explicitly admitted;
- child control-centre information architecture, source/freshness explanation and setup/repair patterns;
- audit/result representation for sensitive child-profile changes;
- AR/EN, RTL/LTR, responsive and accessible experience quality.

### Not automatically included

- device enrollment, monitoring, background services, location, battery, app usage or health claims;
- screen-time, web-filter or bedtime enforcement;
- child account/recovery lifecycle beyond the specifically selected capability;
- AI, voice, image or external provider integration;
- realtime messaging, notification transport, billing, real-data rollout or public release.

A later capability can enter this system only when its source, purpose, role/scope, consent/privacy, operational risk and recovery story are specified.

## 3. People, jobs and experience promise

| Person | Primary job | What a successful experience means |
|---|---|---|
| Primary guardian | Establish the family/child context and make authorised changes confidently | Understands active family and scope; can complete the admitted profile action; receives a clear server-confirmed result or recovery path. |
| Co-guardian | Understand family/child context and participate within explicit authority | Sees what is available to them and why; never receives a misleading editable control or hidden parent-level result. |
| Child | Understand rules and setup relevant to them without receiving parent control | Receives a separate, respectful transparency/request route only when that capability is selected; never falls into the parent control centre. |
| Support/operations (future) | Diagnose safely without unnecessary family-data exposure | Audit/result identifiers and redacted diagnostics are usable without exposing credentials, raw payloads or unrelated family data. |

## 4. Target information architecture

The final control centre follows this hierarchy. Only nodes with a real source are interactive; unavailable future capabilities are not disguised as working controls.

```text
Children
├─ Family context
│  ├─ active family name and family switch
│  ├─ source / freshness / session explanation
│  └─ role and scope explanation
├─ Attention and setup
│  └─ one clear repair, request or next-step path per real issue
├─ Child collection
│  ├─ verified child identity
│  ├─ age/profile summary only from the profile source
│  ├─ one meaningful next action
│  └─ child-context entry once its read model exists
├─ Shared controls
│  ├─ scope, impact and lifecycle truth
│  └─ edit / request / read-only treatment by role
└─ Activity and advanced help
   └─ progressive disclosure of history, explanations and recovery
```

### Interaction principles

- **Context first:** a user always knows which family and child a change affects.
- **One primary next step:** a card never presents a cloud of equal-weight controls.
- **Progressive disclosure:** advanced detail, policy history and repair diagnostics do not obscure the immediate family task.
- **Truth before decoration:** a badge, colour, warning ring or toggle only appears when a source provides the fact it implies.
- **Role explanation:** unavailable is explained in plain language; role labels are not the only permission UX.
- **System continuity:** shared Family OS tokens, familiar controls and the same loading/empty/denied/retry grammar apply across family surfaces.

## 5. Required experience states

| State | Source of truth | Required user experience | Must never happen |
|---|---|---|---|
| Signing in / loading family context | Identity + family discovery | Progress without exposing token/endpoint detail; cancellation/retry where meaningful | Show seeded family or a previous family's children as current. |
| Family selection | Server-returned authorized families | Active context and role explanation before roster access | Let a typed/guessed family ID become authority. |
| Populated roster | Server-authoritative child projection | Readable, tappable only when a real child context exists; source/session explanation | Invent device, health, location or policy status. |
| Empty roster | Server response | Setup explanation and the admitted next action, if one exists | Present a fake child or a success-looking policy desk. |
| Pending child-profile action | Server request lifecycle | Clear pending state, duplicate submission protection and an accessible cancel/back path where allowed | Report completion before a server-confirmed response. |
| Validation/conflict | Typed API response | Plain-language correction/retry preserving safe form input | Lose input silently or leak raw response data. |
| Denied | Server authorization result | Explain scope without showing hidden family/child detail | Let client role logic override server denial. |
| Unavailable/network | Transport/API classification | Explain whether retry is safe and retain no stale roster as current authority | Replace failure with local/mock data. |
| Setup/repair | Named source reports a gap | One concrete repair/request path and clear boundary | Imply a device/policy is connected or applied. |

## 6. Source and contract map

| Capability | Current fact | Required authoritative source before it is real | System decision |
|---|---|---|---|
| Family context and roster | Node.js/Express family discovery and `GET /children` foundation exists | Existing server authority, typed Flutter adapter and isolation/migration plan | Reuse; remove normal-route mock fallback when migrated. |
| Child profile creation | Backend has a narrow primary-guardian `POST /children` foundation for name and age | Node.js/Express contract, idempotency, server role/scope check, audit/result, Flutter typed mutation client and refreshed roster | **Admitted 2026-10-04; implementation is bounded by [`03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md`](03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md).** |
| Child detail/control-centre entry | Prototype route exists | New minimum child-detail read model, source/freshness, authorization and repair state | Define after creation lifecycle shape is accepted. |
| Edit/delete profile | Local prototype action only | Lifecycle/safeguarding policy, API contract, conflict/reversal/audit and role matrix | Separate decision; never infer from create. |
| Device connection | Local/prototype record only | Authorized Native enrollment/capability/repair source and server linkage | Later Native capability slice. |
| Shared policies | Local UI/projection only | Policy version, scope, delivery, applied/verified receipt and audit | Later policy/enforcement capability slice. |
| Location/health/battery/activity | Mock/local display values | Separate consented, fresh and privacy-reviewed sources | Absent until built. |

## 7. Admitted first real capability: create child profile

The product owner admitted this narrow capability on 2026-10-04. The binding implementation record is [`03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md`](03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md); this section retains the system journey and contract principles.

### User journey

```text
Primary guardian sees an honest empty/setup roster
→ chooses “Add child profile”
→ enters only server-supported profile information
→ reviews family scope and effect
→ sends one idempotent request
→ sees pending, validation, conflict, denied, unavailable or confirmed outcome
→ confirmed roster refreshes from the server
→ an audit-safe result explains what changed and the next setup step
```

### Capability contract requirements

- **Role:** server verifies active primary guardian; the client never elevates a co-guardian.
- **Scope:** server-returned active family ID only; no arbitrary IDs or cross-family input.
- **Data minimisation:** start with the existing authoritative fields only (`displayName`, `ageYears`). Avatar, emoji, colour, device or health are not silently persisted as profile facts.
- **Idempotency:** client creates a safe per-attempt request key; retry/replay and changed-payload conflict are explicit states.
- **Durability:** only a server `201`/idempotent response produces success; roster refresh reads the accepted server projection.
- **Audit/result:** the system keeps the user-facing outcome understandable without exposing internal IDs, raw payloads or correlation details.
- **Recovery:** map 400, 401, 403, 409, 429/503 and network/invalid-response states to intentional UI.

## 8. Cover deliverables and exit gate

Before the system moves beyond this bounded mutation into **Compete**, broader real-engine work or a larger family-control surface, the following must be reviewed together:

1. Primary-guardian, co-guardian and child journey maps, including what each sees at every state.
2. Phone/tablet AR/EN, RTL/LTR wireflows for family context, roster, empty/setup, create-profile, pending, success, denied, conflict and recovery.
3. Component contract for child cards, family header, source/freshness badge, attention item and action/result surface.
4. Node.js/Express/OpenAPI contract delta, authorization matrix, idempotency behaviour, audit event and error mapping for the selected action.
5. Data classification, retention, consent/guardian policy, abuse/rate-limit and support/operations review.
6. Migration plan that prevents default routes from mixing remote authority with local/mock fallback.
7. Acceptance plan covering API, repository, widget, role, fault, responsive, accessibility and controlled synthetic integration evidence.

The Cover stage exits only when product, UX, backend, mobile, security/privacy and quality can describe the same user journey without an unowned state, fake result or undefined recovery path.
