# Security Direction — Gate G1 Recommendation

> **Gate:** G1 — Security direction
> **Status:** Ready for Owner decision
> **Built from:** System universe, registry/services/journeys/screens, Flutter source evidence, and public competitor/capability evidence.
> **This document recommends a direction; it does not authorize Backend, Native, or release claims.**

## 1. Strategic recommendation

Start Family OS security as **Guided Family Safety**, not as a surveillance dashboard and not as a list of technical switches.

The first safety promise should be:

> **A guardian can guide digital routines, act quickly when something matters, and understand the real protection state of each child and device.**

This gives the platform a globally understandable value proposition while leaving room for learning, connection, and intelligence to deepen it later.

### What we deliberately do not promise at the start

- Unrestricted access to every child message, image, app, or social platform.
- Device control or monitoring that the platform cannot actually enforce.
- Emergency delivery that has not been implemented and tested end-to-end.
- Driving, router, or peer-comparison claims before their data and capability basis is trustworthy.

## 2. Recommended release model

The platform remains comprehensive because every current system has a place. Comprehensiveness does **not** mean that every advanced system is presented as launch-ready on day one.

| Sequence | Purpose | Systems / outcomes |
|---|---|---|
| **Safety Foundation** | Establish daily parent value and trust. | Time, apps, web, immediate actions, device protection health, clear parent/child request loops, basic reports, and a truthful safety pulse. |
| **Safety Presence** | Connect digital safety to the family’s physical wellbeing. | Location, safe places/check-ins, SOS, escalation, and meaningful notification coordination—only after actual delivery capability is ready. |
| **Safety Differentiators** | Make Family OS more helpful than a generic control app. | School/focus coordination, learning-time logic, deeper reports, smart routines, selected signal-based insights. |
| **Deliberate Advanced Systems** | Expand only with a defined technical, trust, and operational model. | Content/social monitoring, driving safety, router filtering, peer comparison, global emergency integration, and advanced anti-tamper enforcement. |

## 3. Proposed V2 classification of the 12 systems

| System | Recommendation | Why | Conditions before public commitment |
|---|---|---|---|
| Screen-time management | **Core** | A daily, understandable control loop; existing UI/domain/test foundation is strong. | Per-device truth, schedule conflict rules, child request/response, offline state, and native enforcement plan. |
| Application controls | **Core** | Essential companion to time control and central to parent trust. | Installed-app inventory, per-platform enforcement truth, approval flow, and exception handling. |
| Web filtering | **Core** | Families expect a clear web-safety setting and respectful block/request loop. | Supported-surface contract and real enforcement method; do not imply universal filtering. |
| Location and safe places | **Core commitment, capability-gated** | High daily family value when explicit location state, accuracy, and consent are clear. | GPS/background/permission implementation, stale location model, notification transport, and device support matrix. |
| Emergency and SOS | **Core commitment, safety-gated** | It is central to family confidence but cannot be a decorative button. | Tested delivery ladder, acknowledgement, location handoff, failure/offline behaviour, support playbook. |
| Smart content monitoring | **Explicit Decision Required** | Can differentiate, but accuracy, input access, transparency, and alert harm require a dedicated product/capability decision. | Defined supported signals and sources, confidence/appeal model, human-readable explanation, privacy/support model. |
| Social-platform monitoring | **Explicit Decision Required** | Competitors vary sharply by platform and operating system; a generic claim would be misleading. | Per-platform integration/support matrix and transparent family model. |
| Anti-tamper resilience | **Core baseline + advanced decision** | Device-health and lost-protection guidance are essential; invasive detection/response needs native proof. | Capability matrix, trust levels, non-punitive repair flow, false-positive and recovery model. |
| Immediate lock | **Core commitment, capability-gated** | A clear immediate action creates tangible parent value. | Delivery receipt, essential access exemptions, remote retry/expiry, reversal, device support. |
| Reports and analytics | **Core basic + Differentiator advanced** | A parent needs understandable trends; advanced prediction and comparison must earn trust. | Event-quality definitions, retention, child/guardian views, explainable calculations. |
| Mobility and driving safety | **Deferred Existing System** | Potentially valuable but not necessary to establish the first Family OS safety loop. | Motion/location capability, risk model, battery/false-positive analysis, incident/support process. |
| School mode | **Differentiator** | Connects safety to learning and is a strong Family OS advantage. | Unified routines, education coordination, exemptions, platform enforcement, parent/child explanations. |

## 4. Service-level sequencing recommendation

The service registry is a discovery inventory, not a final contract. The following proposal gives every security service a place without prematurely discarding it.

### Safety Foundation — candidate Core services

| Area | Candidate services | Parent value |
|---|---|---|
| Time and routines | `S-SEC-001` to `S-SEC-004`, `S-SEC-006` | Daily limit, routine/sleep schedule, time request, and per-app boundary. |
| App decisions | `S-SEC-008` to `S-SEC-011` | Allow/block, categories, new-app approval, installation awareness. |
| Web basics | `S-SEC-014` to `S-SEC-016` | Category protection, exceptions, and safe-search expectation. |
| Protection health | `S-SEC-044` as a clear permission-health baseline | Tell the guardian when protection cannot work as expected and guide repair. |
| Immediate action | `S-SEC-047` to `S-SEC-049` | Temporary pause/lock action with a clear outcome and reversal. |
| Basic understanding | `S-SEC-050` | A simple, actionable use report—not raw surveillance data. |

### Safety Presence — candidate Core commitments after G3 readiness

| Area | Candidate services | Parent/family value |
|---|---|---|
| Location and place loop | `S-SEC-019`, `S-SEC-021`, `S-SEC-022`, `S-SEC-025` | Current location state, safe places, arrival/departure events, device battery context. |
| SOS loop | `S-SEC-026`, `S-SEC-027`, `S-SEC-031` | Child starts a persistent request for help; guardians receive an honest status and response path. |

### Differentiators — planned after the foundation is coherent

| Area | Candidate services | Why later |
|---|---|---|
| Learning-aware time | `S-SEC-005`, `S-SEC-007` | Must integrate fairly with learning, tasks, and rewards rather than create loopholes. |
| App context | `S-SEC-012`, `S-SEC-013` | Game alerts and app information improve decisions once a trustworthy app inventory is available. |
| Web extension | `S-SEC-017` | Private/incognito handling is platform-dependent and requires an honest supported-surface design. |
| Location enrichment | `S-SEC-020`, `S-SEC-023`, `S-SEC-024` | History, frequent places, and delayed-arrival insight require high-quality location events and retention choices. |
| SOS escalation | `S-SEC-028`, `S-SEC-029` | Direct calling and outside-family contacts need a reliable delivery/contact model. |
| Reports and routines | `S-SEC-051` to `S-SEC-053`, `S-SEC-058`, `S-SEC-060` | Advanced reports, weekly summary, school scheduling, and focus become powerful after core events and rules are coherent. |

### Explicit decision or advanced-defer candidates

| Area | Services | Reason to hold |
|---|---|---|
| Router filtering | `S-SEC-018` | Requires a distinct home-network product/integration model. |
| National emergency connection | `S-SEC-030` | Country-specific capability and operational promise; no generic global claim. |
| Smart-content monitoring | `S-SEC-032` to `S-SEC-037` | Input access, accuracy, transparency, alert posture, and parent/child trust model remain unapproved. |
| Social-platform monitoring | `S-SEC-038` to `S-SEC-041` | Requires a platform-specific support matrix; generic platform names do not establish a delivery capability. |
| Advanced anti-tamper | `S-SEC-042`, `S-SEC-043`, `S-SEC-045`, `S-SEC-046` | Requires native integrity signals, device policies, false-positive handling, and recovery support. |
| Peer comparison | `S-SEC-054` | Value, fairness, and data basis require a separate decision; never a default metric. |
| Driving safety | `S-SEC-055` to `S-SEC-057` | Needs verified motion/location capability and a clear incident/false-positive posture. |
| Location-triggered school activation | `S-SEC-059` | Depends on trustworthy location and routine resolution. |

## 5. Role job maps

### Primary guardian

| Job | Success looks like | Required system relationship |
|---|---|---|
| Set a healthy boundary | One clear rule applies to the intended child/device and does not accidentally disrupt the rest of the family. | Identity, child/device context, schedules, exceptions, audit. |
| Respond to a request | A child’s request has context; approval/decline is quick, fair, and visible to the child. | Time/app/web requests, notifications, child experience, timeline. |
| Understand risk | The parent sees what changed and why it matters, not a flood of unranked events. | Alert policy, reports, device health, intelligence, Today. |
| Act in an urgent moment | The parent can lock, contact, check location, or respond to SOS—and knows whether it took effect. | Delivery state, devices, emergency, notifications, recovery. |
| Maintain confidence over time | The parent can repair permissions, revise rules, and see a trustworthy history. | Device health, settings desk, audit, support, privacy. |

### Guardian / co-parent

| Job | Success looks like | Required system relationship |
|---|---|---|
| Stay aligned | Sees the same relevant context without duplicate alerts or hidden rule changes. | Family role, alerts, audit, Today. |
| Participate safely | Can approve/review/act only within a visible permission level. | Roles, control scopes, request routing, activity history. |
| Coordinate a response | Knows who received or acknowledged an urgent event. | SOS, notification escalation, location, activity timeline. |

### Child

| Job | Success looks like | Required system relationship |
|---|---|---|
| Understand a boundary | Knows what changed, for how long, why, and what remains available. | Time, apps, web, lock, routines, accessibility/emergency exemptions. |
| Ask fairly | Can request more time or an app/site with useful context and receives a clear answer. | Requests, notifications, parent rule, child status. |
| Stay safe | Has an obvious emergency action and knows which trusted adults are involved. | SOS, location, safe contact circle, delivery status. |
| Preserve autonomy | Does not experience unexplained, humiliating, or inconsistent controls. | Transparency, notification tone, monitoring policy, history. |

## 6. Experience direction for G2

The G2 UX phase should design the safety experience around **four parent moments**, not around feature folders:

1. **Check:** “How is the family right now?” — family pulse, attention queue, each child’s state.
2. **Guide:** “Set a routine or rule.” — concise control, preview of effect, exceptions only when needed.
3. **Respond:** “Something happened.” — alert context, action choices, confirmation, recovery.
4. **Understand:** “What changed over time?” — clear reports and explanations with a next step.

The child experience uses four matching moments: **Know, Ask, Stay Safe, Recover**.

## 7. G1 decisions requested

The following decisions are required to lock Security direction before detailed G2 UX work. The recommendation is intentionally explicit.

| ID | Decision | Options | Recommendation |
|---|---|---|---|
| G1-D01 | Is location and SOS part of the initial Family OS safety promise? | A. Core commitments, capability-gated. B. Postpone both. C. Location only. | **A.** They complete the family safety story, but must remain unavailable/unpromised until G3 proves real delivery. |
| G1-D02 | What is the launch posture for content/social monitoring? | A. Signal/alert-led supported monitoring only. B. Broad content-access promise. C. Exclude all monitoring from the first promise. | **A.** It creates useful differentiation while refusing misleading “see everything” claims; exact sources remain a later explicit decision. |
| G1-D03 | How do we treat driving, router filtering, peer comparison, national-emergency links, and advanced anti-tamper? | A. Present as later/advanced systems. B. Include them in first build. | **A.** Keep them in the connected system universe but outside the first implementation sequence. |
| G1-D04 | What is the default authority model? | A. Primary guardian full control; co-guardian configurable; child can see/explain/request. B. Equal guardian control by default. C. Parent-only visibility with no child explanation. | **A.** It is clear, flexible, and consistent with trust and child usability. |

## 8. Gate result if recommendations are approved

If G1-D01 through G1-D04 are accepted, the next loop will create the G2 Security UX Lock pack: Safety Hub navigation, parent and child control models, settings-desk blueprint, complete screen/state inventory, and visual direction. Backend/Native work remains blocked until G3.
