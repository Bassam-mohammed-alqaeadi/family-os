# Platform System Universe — Product Refinement V2

> **Purpose:** The complete system map for a connected Family OS.
> **Discovery baseline:** 42 registered systems, 240 registered services, 73 journeys, and 130 screens.
> **Important:** Counts and names are evidence from the current registry; its legacy priorities, waves, and statuses are not V2 scope decisions.

## 1. The platform model

The systems below are not five isolated departments. They form one platform:

```text
Family identity + members + devices + permissions
                    │
      ┌─────────────┼────────────────┐
      │             │                │
Digital safety   Family connection  Learning & growth
      │             │                │
      └────── events, timeline, Today dashboard ──────┘
                    │
          Family intelligence + advice
                    │
      Privacy, support, notification, subscription
```

This means, for example, a study routine can affect screen controls, a completed task can appear in Today, a location concern can produce a clear notification, and an insight can explain a change without turning any system into a disconnected screen.

## 2. Registered system universe (active analysis)

### Security & Digital Safety — SEC — 60 services

| # | System | Services | Platform connection to prove |
|---:|---|---:|---|
| 1 | Screen-time management | 7 | Child/device context, schedules, Today, notifications, child request path. |
| 2 | Application controls | 6 | Device capability, approvals, rules, events, reports. |
| 3 | Web filtering | 5 | Child/device context, category policy, exceptions, activity/reporting. |
| 4 | Location and safe places | 7 | Consent, devices, timeline, family communication, emergency escalation. |
| 5 | Emergency and SOS | 6 | Identity, trusted contacts, location, notification escalation, recovery. |
| 6 | Smart content monitoring | 6 | Explainable signals, child context, alert controls, privacy/support. |
| 7 | Social-platform monitoring | 4 | Capability truth, alerts, trust settings, action paths. |
| 8 | Anti-tamper resilience | 5 | Device health, rule integrity, recovery, guardian notification. |
| 9 | Immediate lock | 3 | Child/device target, allowed exceptions, acknowledgement, reversal. |
| 10 | Reports and analytics | 5 | Events, Today, insights, export/privacy, parent decisions. |
| 11 | Mobility and driving safety | 3 | Device truth, location, alert escalation, reporting. |
| 12 | School mode | 3 | Schedules, education context, device policy, parent override. |

### Family Connection — COM — 39 services

| # | System | Services | Platform connection to prove |
|---:|---|---:|---|
| 13 | Conversations | 9 | Family identity, safe contacts, notifications, moderation/settings. |
| 14 | Calls | 6 | Contacts, device capability, availability, notifications, recovery. |
| 15 | Media and files | 5 | Consent, safety, storage/access, conversation context. |
| 16 | Safe contact circle | 5 | Family roles, approvals, visibility, emergency connections. |
| 17 | Family calendar | 6 | Today, tasks, education, notifications, household context. |
| 18 | Tasks and responsibilities | 5 | Child goals, rewards, calendar, Today, parent controls. |
| 19 | Location in communication | 3 | Consent, location truth, check-ins, emergency and conversation context. |

### Learning & Growth — EDU — 65 services

| # | System | Services | Platform connection to prove |
|---:|---|---:|---|
| 20 | Subjects and lessons | 6 | Child learning profile, focus, calendar, progress, parent view. |
| 21 | Homework | 6 | Calendar, tasks, reminders, progress, parent-child requests. |
| 22 | Tests and assessment | 6 | Learning profile, adaptive path, progress, insight. |
| 23 | Intelligent tutor | 6 | Child context, explanation, parent controls, learning record. |
| 24 | Adaptive learning | 5 | Assessment, plans, progress, recommendations. |
| 25 | Motivation and rewards | 7 | Tasks, learning, parent rules, child progress, Today. |
| 26 | Quran and Islamic education | 5 | Learning profile, routines, progress, parent settings. |
| 27 | Focus and study environment | 6 | School mode, screen controls, routines, learning progress. |
| 28 | Parent Studio | 18 | Parent creation, content lifecycle, child assignment, community/content governance later. |

### Family Intelligence — AIC — 34 services

| # | System | Services | Platform connection to prove |
|---:|---|---:|---|
| 29 | Signal engine | 6 | Events across systems, explanation, notification thresholds. |
| 30 | Patterns and anomaly engine | 5 | Baselines, confidence, trend context, human review. |
| 31 | Family knowledge store | 6 | Consent, source traceability, privacy, retrieval controls. |
| 32 | Advisor and reports | 6 | Today, parent decision support, explanation, report settings. |
| 33 | Interactive assistant | 6 | Role-aware context, safe action boundaries, correction path. |
| 34 | Delegated agent | 5 | Explicit delegation, limits, audit, notification, reversal. |

### Administration, Trust & Operations — ADM — 42 services

| # | System | Services | Platform connection to prove |
|---:|---|---:|---|
| 35 | Initial setup | 7 | Identity, roles, device pairing, capability truth, first value. |
| 36 | Family and members | 6 | Ownership, guardians, children, invitations, recovery. |
| 37 | Devices | 5 | Pairing, health, capability status, diagnostics, unlinking. |
| 38 | Subscription and billing | 6 | Entitlements, value communication, upgrades, support. |
| 39 | Notifications | 5 | Preference center, urgency, channels, actionability, quiet periods. |
| 40 | Privacy and data | 6 | Visibility, consent, export/delete, audit, support. |
| 41 | Today dashboard | 4 | Shared summary of events, priorities, progress, and actions. |
| 42 | Settings and support | 3 | Findable settings, diagnosis, help, recovery, feedback. |

## 3. Cross-pillar relationships that must be designed, not assumed

| Connection | Required product question |
|---|---|
| Safety ↔ Learning | How do focus, school mode, rewards, and study schedules cooperate instead of competing? |
| Safety ↔ Communication | How does a location check-in or SOS move from signal to trusted family action? |
| Tasks ↔ Learning | How do homework and home responsibilities appear coherently without duplicate reminders? |
| Intelligence ↔ Every pillar | What data can produce an insight, how is it explained, and how can a guardian reject it? |
| Devices ↔ Controls | Which controls are effective on which device, and how does the UI make that truth understandable? |
| Today ↔ Notifications | What merits interruption, what belongs in the daily digest, and what remains available only in history? |
| Privacy ↔ Monitoring | Who can see what, what is visible to the child, and how can the family change or audit the arrangement? |
| Subscription ↔ Value | Which benefit is being offered, and how does an upgrade never obscure safety-critical information? |

## 4. Services without a registered journey

The following 18 services exist in the registry but are not referenced by a current registered journey:

`S-ADM-012`, `S-ADM-013`, `S-ADM-033`, `S-ADM-035`, `S-AIC-004`, `S-AIC-005`, `S-AIC-021`, `S-COM-003`, `S-COM-008`, `S-COM-009`, `S-COM-012`, `S-EDU-006`, `S-EDU-010`, `S-EDU-046`, `S-SEC-012`, `S-SEC-013`, `S-SEC-023`, `S-SEC-029`.

They are not automatically removed or treated as future candidates. Each needs a V2 decision: complete its journey, merge it into another system, defer it as an existing system, or explicitly remove it.

## 5. Future Developments — excluded from current development

| Candidate area | Candidate systems / examples | V2 decision |
|---|---|---|
| Expanded values and religion | Prayer, adhkar, Hijri events, broader values/behaviour product, dedicated children’s values content. | Future development. The registered Quran and Islamic education system remains part of current analysis. |
| Advanced household organization | Shopping lists, meal planning, recipe book, household-planning extensions. | Future development. Registered calendar and tasks remain in current analysis. |
| Financial responsibility | Allowance, savings, savings goals, child wallet, budgets, financial products or partnerships. | Future development. |
| One-way audio / new ambient-context capability | Any standalone audio monitoring or listening product not represented as a complete current system. | Future development; requires separate product decision if ever reconsidered. |

## 6. Classification rule going forward

Every registered system receives exactly one current planning classification:

- **Core:** essential to the launch promise.
- **Differentiator:** strategically valuable and sequenced for launch or an immediate post-launch release.
- **Deferred Existing System:** part of the current platform universe but deliberately not in the first implementation sequence.
- **Explicit Decision Required:** insufficient product, capability, or trust clarity to sequence responsibly.

Future Developments are outside this classification until the Owner explicitly brings them into the platform universe.
