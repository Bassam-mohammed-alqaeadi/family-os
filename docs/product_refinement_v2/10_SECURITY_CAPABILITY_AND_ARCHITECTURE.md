# Security Capability & Architecture Readiness — Gate G3

> **Status:** Technical-readiness design in progress
> **Purpose:** Define a truthful target architecture for approved security UX without choosing an implementation stack prematurely or claiming capabilities the repository does not yet have.
> **Current reality:** Flutter local/mock-first foundation; no production Backend, Native enforcement adapters, remote command delivery, or production push delivery are currently implemented.

## 1. Architecture outcome

The future security platform must make a single user-visible promise reliable:

> A guardian can see the effective protection state of a child/device, request a change, understand delivery, and recover when the platform cannot complete it.

The architecture therefore distinguishes four things that must never be conflated:

| State | Meaning | Example |
|---|---|---|
| Desired policy | What an authorized guardian saved. | “No social apps after 8:30 PM.” |
| Assigned policy | Which child/device/context should receive it. | “Applies to Maya’s Android phone.” |
| Delivery state | Whether the device received/queued/rejected the change. | “Queued: device last seen 18 min ago.” |
| Effective state | What the capable device confirms is active now. | “School routine active until 2:45 PM.” |

A local UI preference must never be shown as an effective remote protection state.

## 2. Target platform topology

```text
Parent / guardian client     Child device experience / agent       Support tools
          │                           │                                 │
          └─────────────── authenticated API / command gateway ────────┘
                                      │
 ┌───────────────────────────────────┼────────────────────────────────────┐
 │ Family identity & roles            │ Policy / rule service              │
 │ Device enrollment & capability     │ Command & delivery service          │
 │ Event / activity timeline          │ Notification service                 │
 │ Location & place service           │ Emergency incident service           │
 │ Reports / aggregates               │ Audit / privacy / support service    │
 │ Signal & insight service (later)   │ Subscription / entitlement service   │
 └───────────────────────────────────┴────────────────────────────────────┘
                                      │
                       Native device adapters and OS services
                 Android-specific                 iOS-specific
```

The topology is modular by responsibility. It does not mandate microservices on day one: a well-designed modular backend may initially deploy as a smaller number of services while preserving these domain boundaries.

## 3. Non-negotiable architecture principles

1. **Family context is explicit.** Every request, rule, device, event, alert, and audit entry carries a family relationship and authorization context.
2. **Device capability is data.** A control is evaluated against a stored, current capability profile—not guessed by UI.
3. **Commands are asynchronous.** Remote actions have IDs, expiry, idempotency, delivery receipt, and effective-state confirmation.
4. **Events are append-only facts.** A report, alert, audit entry, and notification derive from a traceable event source.
5. **Policy is versioned.** Each saved change has author, time, scope, previous version, effective version, and reversal history.
6. **Privacy is enforcement architecture.** Data scope, visibility, retention, export/delete workflow, and support access are not UI labels; they are server-enforced boundaries.
7. **Native agents report facts, not product decisions.** A device adapter reports capability, health, and observed/effective state. Product policy remains coherent in the shared platform.
8. **Graceful degradation is designed.** The system reports unknown/limited/offline honestly and preserves a recovery path.

## 4. Domain responsibilities

| Domain | Owns | Must not own |
|---|---|---|
| Identity & family | Accounts, family, membership, guardian roles, child membership, recovery ownership. | Device enforcement decisions. |
| Device enrollment & capability | Device identity, enrollment, OS/app version, granted capabilities, health, last seen, capability changes. | Family policy semantics. |
| Policy & rule service | Rules, schedules, scope, exceptions, precedence, revisions, policy evaluation. | Direct native OS calls. |
| Command & delivery | Idempotent commands, queue, receipts, expiry, retries, delivery/effective status. | Editing UI state silently. |
| Event & activity timeline | Immutable events, causality links, family/child/device context, audit projection. | Long-term report interpretation without source lineage. |
| Notification service | Recipient selection, priority, channel, grouping, delivery receipt, preference/quiet-hours evaluation. | Source-of-truth safety state. |
| Location & place service | Location samples, freshness/accuracy, places, place events, consent/state. | Pretending a stale sample is live. |
| Emergency incident service | SOS lifecycle, responders, acknowledgement, escalation, resolution, evidence. | Guaranteed public-emergency response without approved integration. |
| Reporting & insights | Aggregates, report data quality, explanations, confidence, feedback loop. | Automatic punitive action. |
| Privacy, audit & support | Data access controls, retention action, export/delete request, support diagnostics and audit. | Bypassing guardian/child visibility rules. |

## 5. Native capability programme

The following table is a feasibility and implementation checklist, not an assertion that a platform feature is available today. Exact OS requirements, entitlements, store rules, and permission behaviour must be revalidated at implementation time.

| Product capability | Android discovery / adapter work | iOS discovery / adapter work | Product behaviour until proven |
|---|---|---|---|
| Screen time / app controls | Evaluate installed-app inventory, usage observation, permitted control path, background reliability, and power-management impact. | Evaluate Family Controls, Managed Settings, Device Activity entitlements and family authorization flow. | Show local/planned capability state only; do not imply device enforcement. |
| Web filtering | Evaluate browser scope, network/DNS/VPN options, supported surface, background durability, and explicit consent/setup. | Evaluate eligible Network Extension / filtering capabilities and approval constraints. | State exactly which browser/network contexts are supported; otherwise provide no false global filter. |
| Immediate lock / pause | Validate the allowed consumer-device restriction path, essential-access exemptions, delivery receipt, reversal, and recovery. | Validate the allowed Managed Settings restriction path; do not describe it as a universal device lock. | Use requested/queued/confirmed/limited states, never a binary fake lock. |
| Location / safe places | Validate foreground/background location, geofence limits, notification delivery, stale data, battery, and permission changes. | Validate Core Location background behaviour, authorization, place-event limitations, notification and battery effects. | Show freshness, accuracy, sharing state, and limitation before any “live” claim. |
| SOS | Validate local trigger, push/notification delivery, location handoff, background state, fallback channels, acknowledgement, and incident persistence. | Validate equivalent trigger/background/notification/location pathways and their restrictions. | Present readiness and delivery uncertainty; never imply emergency services response. |
| Device health / anti-tamper | Define detectable facts, platform integrity signals, permission state, user-remediation, false positives, and update/reset behaviour. | Define only facts legitimately observable under iOS capability boundaries; do not invent broad tamper monitoring. | Use “protection limited / needs setup” with a repair guide. |
| Content / social signals | Define supported source, lawful integration, on-device/server processing, confidence, user transparency, and opt-in boundaries per source. | Same; expect stricter data access and platform limitations. | No general social/content monitoring promise. Treat as a later explicit product decision. |
| Driving safety | Validate motion/location inputs, trip state, accuracy, battery, incident confidence, and emergency workflow. | Validate comparable iOS inputs and background viability. | Deferred existing system; no capability claim. |
| School / focus mode | Connect policy engine to actual device restriction and education schedule state. | Connect Family Controls/Managed Settings capability to schedule/focus design. | Can show planned routine, but only confirmed enforcement is presented as active. |

## 6. Parent and child client responsibilities

### Parent / guardian client

- Read family pulse, rules, capability truth, activity, reports, and incident state.
- Create a signed/authorized policy mutation or command request.
- Render delivery receipts, conflict resolution, and recovery paths.
- Never independently decide that a child device has applied an action.

### Child client / device agent

- Render child explanations, request status, SOS state, and locally applicable routines.
- Receive policies/commands only after device/family authorization.
- Report capability, device health, acknowledgements, and effective state with provenance/time.
- Preserve safe local behaviour when temporarily offline where the OS permits it.
- Never expose guardian-only state, support diagnostics, or hidden data through child UI.

## 7. Capability lifecycle

```text
Enrollment
  → capability discovery
  → guardian consent / device setup
  → capability confirmed
  → policy can be assigned
  → command received
  → effective state reported
  → health monitored
  → capability changes / repair / unenrollment
```

Each stage can fail or become stale. The device-health model must retain this history so the guardian sees why a rule is not effective.

## 8. Architecture decisions deliberately deferred

The G3 design intentionally does not select:

- A cloud provider, database vendor, queue, or analytics vendor.
- A specific push-notification provider.
- A final identity vendor.
- A final network-filtering technology.
- A vendor for maps/geocoding or communication delivery.
- A final monitoring/AI model or content-processing approach.

These are implementation choices evaluated against the approved product contracts, platform feasibility, cost, operating regions, security posture, and delivery team capacity. Selecting them before the contracts would be premature.
