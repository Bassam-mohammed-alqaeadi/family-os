# Administration, Trust & Operations UX Lock — Gate G2

> **Status:** Accepted under standing Owner trust
> **Scope:** Today, Trust & Settings information architecture, setup/membership/device/commercial/privacy/support journeys, role experience, visual direction and cross-pillar behaviour.
> **Boundary:** This locks the product experience and truthful states. It does not claim real authentication, pairing, push, entitlement, payment, export/delete, support operations or remote synchronization.

## 1. Experience intent

Administration should feel like **earned family trust**, not an enterprise control panel or a maze of settings. A guardian needs calm confirmation that the family is real, the right people/devices are connected, the day is understandable, and recovery is possible.

A guardian should quickly understand:

1. Is there a real family, member and device context for this action?
2. What needs my decision today, and which source owns it?
3. Which part of setup or protection is incomplete, stale, unavailable or needs repair?
4. Who can see/change this, what changed, and how can we recover?
5. What does the plan cover, and what is the truthful commercial state?

A child should understand:

1. What is linked to my account/device and what is visible to adults?
2. What does a rule, device warning or setup step mean for me?
3. How do I ask for help or say that something is wrong?

## 2. Information architecture

### Today: the family front door

Today is the calm, role-aware summary of actual family state. It prioritizes, links and explains; it does not own Safety, Learning, Family Connection, Intelligence or their outcomes.

```text
Today
 ├─ Family context and truth status
 ├─ One priority requiring attention
 ├─ Needs my decision
 ├─ Children / people context
 ├─ Today’s schedule, routines and responsibilities
 ├─ Confirmed recent changes
 └─ Setup or device health only when action is useful
```

| Zone | Guardian question | Product behaviour |
|---|---|---|
| Family context | “Which real family and role am I viewing?” | Shows active family/role and a truthful state when membership/context is unresolved; never silently falls back to a seeded family. |
| Priority | “What matters most now?” | Shows at most one authorized, source-qualified priority with its owning domain and real state. A missing data source is not converted into a reassuring pulse. |
| Needs my decision | “What is waiting for me?” | Groups eligible child requests, invitations, review items, safety actions, privacy/support outcomes and delivery failures. It exposes source and deadline, not generic counters. |
| People context | “How is each relevant person doing today?” | Shows role-appropriate child/member cards with verified/limited/freshness context and route to the owning profile/domain. |
| Day context | “What is planned?” | Shows only authorized calendar, learning, task and routine context with time-zone/freshness truth. |
| Confirmed changes | “What changed and is it real?” | Shows meaningful membership/device/policy/domain changes after their owning service records a state transition. |
| Setup/device action | “Can I make this family work better?” | Appears only for an actionable incomplete/repairable verified condition; never pads an empty dashboard with a fake completion score. |

### Trust & Settings: the platform control desk

```text
More / Settings
 └─ Trust & Settings
     ├─ Family, members and roles
     ├─ Devices and connection health
     ├─ Notifications and attention
     ├─ Privacy, data and audit
     ├─ Plan and subscription
     ├─ Language and accessibility
     ├─ Account, recovery and security
     └─ Help and support
```

Domain-specific rules remain in Safety, Learning, Family Connection and Intelligence settings. Trust & Settings owns only the shared platform controls, discovers conflicts, and routes people to the relevant domain desk rather than duplicating its settings.

## 3. Setup and family-entry experience

### A. Guardian: create, join or resume a family

```text
Welcome / sign in / recovery
→ choose create family | join invitation | continue verified existing family
→ establish family context and primary-guardian authority
→ choose next useful setup step
→ add child / invite co-guardian / connect device / configure safety
→ see verified completion or honest incomplete/limited state
→ pause and return to Today or setup queue
```

Rules:

- Setup is progressive: a guardian can defer non-essential steps and return later.
- A step is **complete** only when its authoritative lifecycle is complete; “opened QR”, “requested permission”, “created local draft”, or “queued notification” is not success.
- The next setup step explains why it is useful, which person/device is affected, data/permission consequences and recovery path.
- Create, join, account recovery and invitation acceptance never grant a role simply because a person selected it in the client UI.

### B. No-data/demo experience

```text
Welcome → explore how Family OS works
→ clearly marked demo / no connected family
→ learn navigation and examples
→ create or join a real family when ready
```

Demo is isolated from production family context. It may show illustrative UX but cannot send requests, emit alerts, change policies, record a real audit outcome, claim a device is paired, or display demo information as the person’s live family state.

### C. Co-guardian: accept scoped membership

```text
Receive verified invitation / approved recovery request
→ verify account and family context
→ preview role, child/domain visibility and allowed actions
→ accept / decline / report issue
→ membership becomes active only after authoritative confirmation
→ co-guardian sees role-specific Today and settings
```

A co-guardian cannot self-upgrade, alter primary-guardian continuity, access restricted child/private context or activate a device/purchase through invitation acceptance.

### D. Child: understand connection and transparency

```text
Guardian initiates approved child/device link
→ child sees age-appropriate explanation
→ understands device/data/rule visibility and available help
→ consent/acknowledgement when required by policy/capability
→ link progresses to verified / limited / failed / needs guardian help
→ child reaches My Day and My Data, never adult settings
```

The child’s acknowledgement is never misrepresented as legal authorization where policy/law requires guardian authority. The child can still see a respectful explanation and seek support.

## 4. Family, role and device journeys

### A. Membership and role change

```text
Authorized guardian proposes invitation / role change / removal / alternate guardian
→ scope and consequences preview
→ verification and acceptance where required
→ active / declined / expired / revoked / conflict / recovery-needed
→ affected people see appropriate explanation and activity history
```

Membership roles use **primary guardian**, **co-guardian** and **child** as product authority concepts. Localized family labels may be chosen by the household; they cannot change the underlying least-privilege control model.

### B. Link, repair, replace or unlink a device

```text
Choose child and supported device type
→ explain ownership, capability, permissions and data sharing
→ secure pairing attempt / code lifecycle
→ verified device registration and capability assessment
→ healthy | attention needed | offline/stale | unsupported | unlinked
→ repair, replace, pause or unlink with consequences and audit
```

A device card never says “protected,” “connected,” “location current,” or “rules active” merely because a prior local pairing flow was opened. Each claim names its capability/freshness/effective state.

### C. Guardian continuity

```text
Primary guardian proposes alternate guardian / recovery contact
→ verifies identity and scope
→ alternate accepts under defined conditions
→ active continuity arrangement / paused / revoked / expired
→ loss/recovery event follows defined authority and audit path
```

This is a recovery and safety mechanism, not a hidden route to access family data or take over the family.

## 5. Daily attention, notifications and privacy journeys

### A. Today to owning action

```text
Source domain produces an authorized real item
→ relevance/priority policy selects Today placement
→ guardian opens source/context and acts in owning domain
→ independent domain state changes or remains pending/failed
→ Today refreshes with source truth and confirmed history
```

Today may show that an item needs attention. It may not claim the action was delivered, read, completed, accepted or resolved without the linked domain’s receipt.

### B. Notification preference and attention loop

```text
Member opens Notifications
→ sees urgency, purpose, source examples and current channel capability
→ chooses eligible relevance / digest / quiet-time preferences
→ preference becomes saved / pending / failed with scope and time-zone
→ Render later evaluates recipient/priority/fatigue and attempts transport
→ underlying item remains available in Today/domain regardless of push outcome
```

SOS/emergency escalation is a separately protected policy. Ordinary quiet/digest controls cannot claim to mute, receive, deliver or resolve an emergency event.

### C. Privacy, data and audit

```text
Authorized person opens Privacy & Data
→ sees purpose, source categories, visibility and retention context
→ changes eligible collection/sharing policy or requests access/export/correction/forget/delete
→ sees validation, downstream-impact preview and request lifecycle
→ completed / partial / retention-limited / failed status is recorded
→ activity/audit explains permitted history without becoming surveillance
```

A child opens a simpler My Data experience: what categories are active, why, who may see them, limits/capability and how to ask a guardian for help. The child does not see adult audit, billing, legal/recovery or another person’s data.

## 6. Commercial and support journeys

### A. Plan and subscription

```text
Guardian opens plan context
→ sees actual eligible plans, price/currency/tax/trial/renewal terms and included capability truth
→ chooses change / start trial / purchase / restore where supported
→ checkout/store or billing provider lifecycle
→ Render verifies entitlement and shows active / pending / failed / cancelled / expired / refund/restore state
→ family sees capability change and support/recovery path
```

Until this lifecycle is real, the UI presents plan information or an explicitly unavailable state—not an “active” plan, completed purchase, countdown, receipt, restore or price generated from fixture data. Critical safety, privacy/data access and account recovery do not disappear as a coercive billing consequence.

### B. Help, diagnostics and support request

```text
Person opens Help
→ searches/browses current localized guidance or selects a problem
→ sees capability/device/account context they may share
→ sends a support request only after review of included diagnostic data
→ request is submitted / queued / failed / received / in progress / resolved
→ person can recover, reopen or follow up where supported
```

“Received,” “in progress,” and “resolved” require an actual support system state. Automated self-help can be offered honestly but does not impersonate a human agent.

## 7. Visual direction

### Mood

**Quiet confidence.** Administration uses calm, clear hierarchy and earned confirmation—not dense enterprise tables, anxiety colours, fake green checks or sales pressure.

| State | Visual meaning |
|---|---|
| Verified / current | An authoritative supported state has recently confirmed the item. Use restrained positive emphasis plus text/freshness. |
| Needs attention | A person can take a useful action. Use amber and a direct route, not a vague warning count. |
| Pending / waiting | A request is accepted or awaiting another actor/system; show who/what is awaited and expiry/recovery. |
| Limited / unavailable | A capability, permission, device, role or service cannot support the requested behaviour. Use neutral explanation and alternatives. |
| Private / restricted | The viewer may not access/change this item. Explain the boundary without leaking protected content. |
| Sensitive / irreversible | Membership removal, recovery, purchase, privacy deletion and device unlinking require consequence preview and deliberate confirmation. |
| Demo / local-only | Preview state is clearly labelled and visually distinct from live family state on every relevant entry/exit surface. |

### Design rules

- A card shows one truthful status plus a direct next action; status colour is always paired with words, icons and accessible semantics.
- Setup completion is segmented by real outcomes rather than one misleading percentage.
- Role/permission wording names what a person can do now and who can help, instead of exposing implementation jargon.
- Billing uses clear plan, renewal, trial, price/currency/tax and cancellation language; no dark patterns, forced countdowns or blocked exit.
- Data/privacy screens make scope and consequence understandable before a change. Destructive actions show impact/recovery/retention truth.
- Maintain Arabic-first RTL, LTR, multilingual names, local time/calendar, large text, keyboard/screen-reader support and reduced motion.

## 8. Cross-pillar contracts

| Administration moment | Required platform tie |
|---|---|
| Setup / family context | Identity, roles, consent, active family/child context, audit, recovery and truthful no-data state. |
| Device status | Security native capability/permission/freshness, Learning focus, Family Connection availability and support recovery. |
| Today priority | Owning source event, role/visibility, urgency/relevance, action route, freshness and independent outcome state. |
| Notification policy | Today/domain notification, time zone, quiet/fatigue rules, user/device channel capability, transport attempt and audit. |
| Privacy/data lifecycle | Security/Connection/Learning/Intelligence sources, purpose/consent, data inventory, retention, export/delete/forget and provider boundary. |
| Membership change | Safety authority, contact relationship, learning/assignment visibility, intelligence scope, device ownership and audit. |
| Entitlement change | Feature availability explanation, role authority, support/refund path, safety/privacy/recovery non-coercion and audit. |
| Help/support | Capability diagnostics, language/accessibility, account security, source-safe attachment and case/request state. |

## 9. G2 completion criteria

1. Today acts as the source-qualified family front door and routes to, rather than replaces, every domain owner.
2. Trust & Settings contains one coherent platform control desk without duplicating domain settings.
3. Setup, membership, roles, child transparency, devices and guardian continuity have closed journeys and truthful incomplete/verified/recovery states.
4. Notification, privacy/data, billing and support express real lifecycle/delivery/capability truth and never use fixture/local state as product success.
5. Guardian, co-guardian and child paths are materially different and cannot escalate role or data access through a client screen.
6. Demo/no-data mode remains visibly isolated from real family action/state.
7. Visual language is calm, globally accessible and resistant to surveillance, dark-pattern billing and false reassurance.
