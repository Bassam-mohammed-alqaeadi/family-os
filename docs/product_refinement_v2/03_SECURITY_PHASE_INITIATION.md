# Security & Digital Safety — Phase Initiation

> **Loop card:** SEC-DISCOVERY-01
> **Status:** In discovery
> **Goal:** Make the first pillar product-ready as a connected, globally credible Family OS capability.
> **Not yet authorized:** Backend implementation, Native implementation, or release claims.

## 1. Parent outcome

A guardian can open Family OS and answer, quickly and confidently:

1. Is every child and device okay right now?
2. Is anything urgent or requiring my decision?
3. What rule or setting is active, for whom, and why?
4. What can I change safely right now?
5. Did the action actually take effect?

The result is not a wall of surveillance data. It is a calm, understandable safety control centre with a path to detail whenever the guardian needs it.

## 2. Security promise under exploration

**Family OS helps a guardian guide digital life and respond to safety concerns with clear, flexible controls, understandable signals, and honest device capability.**

This is a working product promise to test and refine; it is not yet a public marketing claim.

## 3. The 12-system security model

| Security system | Parent outcome | Child-facing clarity | Capability / trust question to resolve |
|---|---|---|---|
| Screen-time management | Set healthy, flexible time boundaries and understand today’s use. | Know remaining time, routine, and how to request more. | What is enforced versus reported on each platform? |
| Application controls | Decide what apps may be used and when. | See permitted status and a clear request path. | What can be reliably blocked, limited, or merely observed? |
| Web filtering | Apply age-appropriate browsing guardrails with exceptions. | Receive a respectful explanation and request channel. | Which web contexts, browsers, and categories are controllable? |
| Location and safe places | Know location-sharing state and receive meaningful place events. | Understand sharing, check-ins, and privacy expectations. | What continuity, accuracy, consent, and battery limits exist? |
| Emergency and SOS | Reach a trusted family response path in an urgent situation. | Use a simple, reliable safety action. | What works offline, in the background, and across devices? |
| Smart content monitoring | Surface only meaningful signals that merit parent attention. | Avoid unexplained or humiliating surveillance experiences. | What data is available, how reliable is it, and how is it explained? |
| Social-platform monitoring | Highlight safety concerns in supported contexts. | Know the boundary and receive support rather than opaque punishment. | Which platforms and signals are technically and ethically supportable? |
| Anti-tamper resilience | Detect lost protection and guide the family back to a healthy state. | Explain required device setup without blame. | Which integrity indicators and repair paths are available? |
| Immediate lock | Pause access when the guardian needs an immediate intervention. | Understand the state, permitted essentials, and resolution path. | What essential access must remain and what confirmation proves effect? |
| Reports and analytics | Turn activity into understandable patterns and decisions. | See progress appropriately, without being reduced to a score. | Which events are accurate enough for trends and retention? |
| Mobility and driving safety | Identify meaningful driving-risk context and support safer choices. | Receive constructive feedback and emergency support. | What can actually be detected on supported platforms? |
| School mode | Protect a child’s focus during designated study/school periods. | Know when and why distractions are limited. | How do schedules, education needs, and guardian overrides cooperate? |

## 4. Security information architecture hypothesis

The initial UX should not expose twelve systems as twelve equal tabs. The current working hierarchy is:

```text
Today dashboard
  └─ Safety hub
      ├─ Family safety pulse
      ├─ Child safety profile
      │   ├─ Time and routines
      │   ├─ Apps and web
      │   ├─ Location and check-ins
      │   ├─ Devices and protection health
      │   ├─ Activity and reports
      │   └─ Advanced safety signals
      ├─ Alerts and actions
      ├─ Family rules / routines
      └─ Safety settings desk
```

This is an hypothesis, not a final IA. It will be challenged against actual journeys, role needs, and platform limits.

## 5. Shared-platform contracts to define

Security cannot be designed alone. This phase must define its contract with:

- **Identity and family:** guardian authority, child membership, safe contacts, recovery.
- **Devices:** supported state, health, setup, permissions, last connection, repairs.
- **Today:** what is a daily priority versus background information.
- **Notifications:** urgency, escalation, quiet periods, acknowledgement, and duplicate suppression.
- **Education:** focus, school mode, learning schedules, and reward interactions.
- **Communication:** check-ins, SOS, family notification, and trusted response.
- **Intelligence:** source events, confidence, explanations, thresholds, and human override.
- **Privacy and support:** visibility, data history, audit events, troubleshooting, and recovery.

## 6. Core journeys to model before G1/G2

1. Parent sees a useful safety pulse on an ordinary day.
2. Parent sets or changes a routine for one child without affecting another child unintentionally.
3. Child sees time remaining and requests a fair exception.
4. Parent approves, declines, changes, or reverses an app/web decision.
5. A device loses a required permission or protection becomes unhealthy.
6. A child enters/leaves a safe place; the event reaches the right guardian without alert fatigue.
7. Child triggers SOS; the family receives, acknowledges, and resolves the event.
8. Parent performs an immediate lock and receives truthful delivery status.
9. Parent understands a safety insight, its confidence, source, and recommended action.
10. School mode cooperates with education and emergency exceptions.
11. A guardian with limited permissions interacts safely without causing a conflict.
12. The app is offline, a child device is offline, or a command is delayed/outdated.

## 7. Edge cases that are mandatory, not polish

- Two guardians make conflicting rule changes.
- A rule applies to multiple devices with different capabilities.
- A command is queued, fails, expires, or arrives out of order.
- A child device is new, replaced, removed, or factory-reset.
- The child needs emergency/health/accessibility access during a restrictive state.
- Location is stale, inaccurate, deliberately paused, or temporarily unavailable.
- A scheduled rule spans time zones, daylight-saving changes, holidays, or travel.
- An alert repeats, is acknowledged by the wrong guardian, or lacks context.
- A monitoring signal is uncertain, outdated, or false-positive.
- The child’s age or family role changes.
- A subscription entitlement changes while a rule remains important.
- The platform does not support the claimed capability on the active device.

## 8. Current source evidence

The existing Flutter feature tree shows active interface areas for screen time, web filtering, lock, smart modes, emergency, notifications, privacy, devices, identity, linking, and day/dashboard patterns. It is an important source of current UI/technical evidence, but it is not proof of completed Native enforcement, remote delivery, or production Backend behaviour.

The security registry contains 60 services across the 12 systems. The current registry also identifies four security services without a registered user journey: `S-SEC-012`, `S-SEC-013`, `S-SEC-023`, and `S-SEC-029`. Their product role will be resolved during discovery rather than assumed.

## 9. SEC-DISCOVERY-01 deliverables

The first active loop will produce:

1. A code-and-registry evidence map for all 12 security systems.
2. A global competitor and capability parity map, separated from product decisions.
3. Parent, guardian, and child job maps.
4. A proposed V2 classification for each security system: Core, Differentiator, Deferred Existing System, or Explicit Decision Required.
5. A preliminary connected Safety Hub / Today / Device / Notification architecture.
6. A decision package for Gate G1, including clear recommendations and unresolved questions.

## 10. G1 completion test

Gate G1 is ready only when each of the 12 systems has a defined user problem, affected roles, system relationship, preliminary user value, major capability uncertainty, candidate classification, and clear reason for being included, deferred, or held for decision.
