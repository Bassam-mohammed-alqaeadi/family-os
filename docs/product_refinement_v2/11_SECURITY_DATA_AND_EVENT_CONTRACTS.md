# Security Data, Event & Delivery Contracts — Gate G3

> **Status:** Technical-readiness design in progress
> **Purpose:** Establish the common language that later Flutter, Backend, Native, notification, reporting, and support work must share.

## 1. Core identity lineage

Every security record is scoped through a consistent lineage:

```text
Account → Family → Membership / role → Child → Managed device → Capability profile
```

A record that cannot identify its family, affected child/device, source, and authorized actor is not eligible for an operational security workflow.

## 2. Canonical entities

| Entity | Required fields / behaviour | Why it exists |
|---|---|---|
| Family | `familyId`, owner/recovery state, locale/timezone baseline, lifecycle state. | Boundary for authorization, privacy, and shared context. |
| Membership | `memberId`, role, permission set, invitation/recovery state, effective period. | Separates family participation from account identity. |
| Child profile | `childId`, age band, family membership, communication/explanation profile. | Scope for policies, reports, and child experience. |
| Managed device | `deviceId`, child assignment, enrollment state, OS/app version, last seen, device lifecycle. | Target for capability and delivery. |
| Capability profile | Versioned supported/limited/unsupported/needs-setup capabilities plus evidence timestamp. | Makes UI truth testable. |
| Policy | `policyId`, type, family/child/device scope, rule content, author, version, lifecycle. | Represents the guardian’s desired rule. |
| Exception | Policy link, reason, author, start/end, precedence, child-visible explanation. | Prevents hidden or permanent overrides. |
| Command | `commandId`, idempotency key, target, expected policy version, expiry, origin, requested action. | Makes remote action delivery reliable and auditable. |
| Delivery receipt | Command link, device timestamp, server receipt time, state, effective-state evidence, error/retry reason. | Separates sending from effective protection. |
| Security event | Immutable event type, source, timestamp(s), family/child/device context, quality/confidence, causality ID. | Source for alerts, timeline, reports, audit, and insight. |
| Alert / incident | Event links, priority, recipients, acknowledgement, escalation/resolution state. | Gives a family an actionable response loop. |
| SOS incident | Initiator, readiness snapshot, location truth, responder state, escalation events, resolution. | Prevents SOS being just a notification. |
| Place / location sample | Consent state, coordinates or reduced precision as appropriate, accuracy, freshness, source, retention class. | Supports safe places and truthful location UX. |
| Report aggregate | Source event window, calculations, data-quality flag, explanation, visibility scope. | Prevents opaque reports and misleading trends. |
| Audit event | Actor, action, affected resource, before/after reference, outcome, support visibility. | Supports trust, recovery, and family coordination. |

## 3. Policy contract

A policy must express enough information for the rule engine, native device adapter, parent UI, child explanation, and audit history to agree.

```text
Policy
- identity: policyId, type, version, lifecycle
- authority: author, role, familyId, authorization basis
- scope: childId(s), deviceId(s), app/site/place/context selector
- normal rule: limit/allow/deny/schedule/notification behaviour
- precedence: family default, child rule, routine, temporary exception
- temporal model: timezone, recurrence, start/end, expiry
- child explanation: localized reason/category and request availability
- delivery requirements: required capability, target devices, effective-state expectation
- audit links: prior version, mutation source, change reason
```

### Policy types in the security programme

- Screen-time and routine policy.
- App access / approval policy.
- Web category/exception policy.
- Device protection-health policy.
- Immediate action / temporary lock policy.
- Location-sharing and safe-place policy.
- SOS readiness/escalation policy.
- Notification preference/escalation policy.
- School/focus routine policy.

Advanced monitoring, driving, router, and peer-comparison policy types remain unimplemented until their explicit product/capability decisions are complete.

## 4. Command contract

A command is used when the guardian expects a device effect. It is never represented only by a boolean in the parent UI.

```text
Command request
- commandId + idempotencyKey
- family / child / target device
- actor and authorization context
- command type and policy/version reference
- requested payload and child-visible consequence
- created time, expiry, priority
- requested confirmation level

Command lifecycle
- accepted → dispatched → received → applied | limited | rejected | expired | failed
- a receipt identifies device evidence and observed/effective state
- retry is safe because the idempotency key is stable
```

### Command requirements

- Every retry must be idempotent.
- A delayed device cannot apply a command after its expiry without a new valid evaluation.
- A command must be evaluated against current capability and policy version before application.
- A reversal is a new auditable command, not deletion of history.
- Parent UI shows the actual lifecycle state rather than assuming dispatch equals success.

## 5. Event envelope

All security producers use an event envelope before an event can create an alert, timeline entry, report aggregate, or insight.

```text
SecurityEvent
- eventId, type, schemaVersion
- familyId, childId?, deviceId?
- occurredAtDevice?, observedAtServer, receivedAtServer
- source: child client | native adapter | backend evaluator | guardian action | support action
- sourceTrust: reported | verified | inferred | unknown
- causalityId / commandId / policyId?
- data-quality: fresh | stale | partial | unavailable
- severity and confidence where relevant
- visibility classification and retention class
```

This event model handles examples such as time boundary reached, app request created, permission revoked, device offline, place entered, SOS started, guardian acknowledged, command failed, or a report became available.

## 6. Alert, notification, and timeline relationship

```text
Security event (fact)
  → policy/priority evaluation
    → alert or incident (actionable family state)
      → notification deliveries (channel attempts)
      → timeline entry (history)
      → report / insight input (aggregate only)
```

- A notification delivery receipt does not close an alert.
- An alert acknowledgement does not prove a device command was applied.
- A report never hides the source quality of its data.
- An SOS incident remains open until a defined resolution state is recorded; a push receipt is not resolution.

## 7. Privacy and data boundaries

| Data class | Minimum contract |
|---|---|
| Device health | Store only the operational facts needed to explain protection state; disclose the state and repair implication. |
| Location | Capture consent, precision/accuracy, freshness, visibility, retention class, and access audit. Never render stale data as live. |
| Policy / action history | Preserve authorization, author, scope, and before/after reference so guardians can resolve conflicts. |
| Child requests | Visible to the relevant child and authorized guardians; expiry and decision explanation are retained appropriately. |
| Safety signals | Store source, confidence, user visibility, appeal/feedback capability, and strict access boundaries. |
| SOS | Restrict access to intended responders/support workflow; retain an auditable incident record and clear resolution model. |
| Reports | Carry source window, data-quality flag, and visibility scope; never expose a peer comparison by default. |

Retention durations, regional data placement, legal basis, and external support access are later operating decisions. The data model must support them rather than hard-code an assumption now.

## 8. API surface categories for later implementation

No API is implemented in this phase. The eventual service boundary groups operations as follows:

| Category | Example operations |
|---|---|
| Family & authorization | Load family context, memberships, permission evaluation, recovery-safe role changes. |
| Device & capability | Enroll/unenroll device, report capability/health, read support matrix, repair readiness. |
| Policy | Read/mutate/version/revert policies, resolve effective policy for a child/device/time. |
| Commands | Request action, query delivery receipt, cancel valid queued action, submit effective-state acknowledgement. |
| Events/timeline | Ingest validated device/backend events, read scoped timeline, retrieve audit history. |
| Alerts/SOS | Open/acknowledge/escalate/resolve incidents, read response state, notification preference. |
| Location/places | Read consent/state, manage places, retrieve suitably scoped/fresh location history. |
| Reports/insights | Read source-qualified aggregate/report, submit usefulness feedback, manage report preferences. |
| Privacy/support | Read data visibility, export/delete request state, view support-safe diagnostics. |

## 9. Contract acceptance checks

Before a service or adapter is accepted, it must prove:

1. Authorization cannot be inferred from a client-side role label alone.
2. Family/child/device context is validated at every boundary.
3. Policy, command, receipt, event, alert, notification, and audit links can be traced.
4. Offline, duplicate, delayed, out-of-order, and expired commands have deterministic outcomes.
5. A device’s effective state cannot overwrite a newer authorized policy version.
6. Data quality/freshness is surfaced to the product layer.
7. Visibility and retention classes exist before sensitive data becomes broadly queryable.
