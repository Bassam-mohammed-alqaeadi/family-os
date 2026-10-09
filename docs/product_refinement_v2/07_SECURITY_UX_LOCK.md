# Security UX Lock — Gate G2 Proposal

> **Gate:** G2 — Security UX lock
> **Status:** Ready for Owner experience approval
> **Scope:** UX, visual direction, role experience, information architecture, and cross-pillar connections.
> **Not authorized by this document:** Backend, Native enforcement, or public production claims.

## 1. Experience intent

Security in Family OS must feel like calm, capable family guidance—not a control panel full of fear or a collection of surveillance widgets.

A guardian should get three answers within seconds:

1. **What needs me now?**
2. **Is each child’s protection actually working?**
3. **What is the safest, simplest next action?**

A child should get three answers with equal clarity:

1. **What is active right now?**
2. **Why did it change?**
3. **What can I ask for or do if I need help?**

## 2. The Safety Hub is the security front door

The parent should not choose among twelve security systems before understanding the family state. Safety begins with one hub, reached from the Today dashboard and available as a primary parent destination.

```text
Today
 └─ Safety Hub
     ├─ Family safety pulse
     ├─ Needs attention
     ├─ Child safety profiles
     ├─ Quick actions
     ├─ Device protection health
     ├─ Safety activity & reports
     └─ Family safety settings
```

### Safety Hub composition

| Zone | User question | Content and behaviour |
|---|---|---|
| Family pulse | “Is the family okay?” | One compact summary: stable, needs review, urgent, or unknown. Never show `safe` when data is stale or device protection is unhealthy. |
| Attention queue | “What requires a decision?” | Ordered, actionable items: SOS, device-health repair, request, place event, expired/failed action, or high-confidence safety signal. |
| Child cards | “Who needs attention?” | One card per child with current routine, device/protection truth, relevant alert, and direct path to that child’s Safety Profile. |
| Quick actions | “What can I do immediately?” | Context-sensitive actions: pause/lock, extend/approve, check location, contact, open SOS response. Unavailable actions explain why. |
| Routine snapshot | “What rules are active today?” | A concise view of routines, school/focus state, and temporary exceptions—not an exhaustive settings list. |
| Protection health | “Can Family OS actually act?” | Connected/awaiting/offline/permission-needed/unsupported state, with one repair action per problem. |
| Insight and report | “What changed over time?” | An explainable weekly signal or simple trend, only when data quality supports it. |

## 3. Parent information architecture

### Level 1 — Parent shell

| Destination | Purpose | Security connection |
|---|---|---|
| Today | Daily family pulse and prioritized actions. | Safety appears as a concise, actionable status—not a duplicate dashboard. |
| Safety | Full family safety hub. | Primary destination for protection, routines, devices, alerts, and reports. |
| Family | People, communication, calendar, tasks, and shared context. | SOS contacts, co-guardian coordination, safe-circle relationships. |
| Learning | Child growth, plans, assignments, focus, and Parent Studio. | School mode, education-time exception, focus routine. |
| More | Settings, support, data, subscription, and account management. | Family-wide defaults, audit/privacy, help and recovery. |

### Level 2 — Child Safety Profile

A child profile is the most important contextual view. It is not a grid of unrelated shortcuts.

```text
Child Safety Profile
 ├─ Current protection state + selected device
 ├─ Quick action row
 ├─ Routine & time
 ├─ Apps & web
 ├─ Location & check-ins
 ├─ Protection health
 ├─ Activity & reports
 └─ Advanced safety signals (only when supported and enabled)
```

The existing child profile, device-health, screen-time, web-filter, lock, location, alert, and report surfaces are source evidence. G2 reorganizes their user purpose; it does not claim they can be discarded without a later screen-by-screen reconciliation.

### Level 3 — A single control desk pattern

Every detailed security setting follows the same hierarchy:

```text
What is this protecting?
  → Who and which device does it affect?
  → What is active right now?
  → Set the normal rule
  → Set schedule / exceptions / notification preference
  → Preview consequence and save
  → See delivery, history, and repair path
```

This shared pattern is what makes time, apps, web, school mode, location, and device-health controls feel like one platform.

## 4. Role experiences

### Primary guardian

- Owns family-wide defaults, child-specific rules, role assignment, safety contacts, recovery, and advanced controls.
- Can make an immediate action, but the interface always distinguishes **requested**, **queued**, **confirmed**, **limited**, and **failed**.
- Sees full activity/audit history appropriate to the family configuration.

### Co-guardian

- Sees the same relevant family truth, not a second disconnected dashboard.
- Receives actions and alerts permitted by the primary guardian’s configurable permission level.
- Can act, approve, or respond only where authorized; the interface explains when approval is unavailable and why.
- Sees who changed a rule and when, reducing conflict and duplicate intervention.

### Child

- Does not see an adult control panel.
- Has a clear “Today” safety/routine status: remaining time, active focus/school routine, pending requests, allowed essentials, and a visible SOS path.
- Every restriction uses plain language: **what changed, why, for how long, and what the child can do next**.
- A request is a respectful flow with its own status: sent, seen, approved, declined with reason, expired, or unavailable.

## 5. Visual direction

### Mood

**Quiet confidence, not digital policing.** The visual system should feel premium, warm, and dependable. It should reduce parent anxiety rather than amplify it.

### Existing design evidence to retain

The current Flutter design source already includes Arabic-first typography, RTL support, a purple family brand palette, mint/amber/coral accents, rounded surfaces, status components, loading/error/empty components, and capability/enforcement honesty components. G2 uses these as implementation evidence, not as an unchangeable prior visual decision.

### Semantic visual language

| Semantic state | Meaning | Visual treatment |
|---|---|---|
| Brand / decision | A guardian can make a normal action. | Purple brand emphasis; never used to imply danger. |
| Confirmed / stable | A rule or safety state is currently confirmed. | Mint/teal with explicit text such as “confirmed” or “active”. |
| Needs review | A non-urgent decision or repair is needed. | Amber; always paired with a concrete next action. |
| Urgent | Immediate family attention is needed. | Coral used sparingly, with a clear action hierarchy and no decorative alarmism. |
| Unknown / limited | The platform cannot currently confirm the state. | Neutral/grey, plain-language reason, and a repair/learn-more action. |
| Disabled / not supported | The capability does not apply on the selected device or plan. | Muted, explanatory, never a misleading toggle. |

### Layout and motion rules

- The highest-priority action is visually singular; no screen has multiple competing primary buttons.
- Child cards use a consistent rhythm: person → state → one meaningful next action.
- Large text, touch targets, and icons remain clear for busy parent use and accessibility needs.
- Motion confirms changes and preserves orientation; it never hides delivery latency or pretends a remote action is complete.
- Directional icons mirror in RTL; status color never carries meaning without an icon/text label.
- The same information architecture supports compact phones, larger phones, tablets, and future desktop/web parent surfaces.

## 6. The four parent journeys

### A. Check — ordinary day

```text
Open Today → see family pulse → open Safety → scan child cards
→ notice no urgent action / choose child if detail is useful → leave confidently
```

Success: the parent does not need to open reports or settings to know whether protection is healthy.

### B. Guide — create or change a rule

```text
Open child profile → select Time / Apps / Web / School routine
→ choose scope → set normal rule → set schedule/exceptions as needed
→ preview outcome → save → receive truthful delivery state
```

Success: a rule is understandable to the parent and explainable to the child before it is applied.

### C. Respond — attention or urgent event

```text
Receive a meaningful alert → open context
→ understand who/what/when and confidence/state → choose action
→ see delivery/acknowledgement → follow recovery or resolution path
```

Success: alerts create an action or a calm resolution, not panic or dead ends.

### D. Understand — a pattern over time

```text
Open report → see a human-readable trend → inspect relevant context
→ choose a proportionate next step → create/update a routine if needed
```

Success: data helps a guardian make one better decision, not monitor every minute.

## 7. Cross-pillar experience contracts

| Security moment | Required platform tie |
|---|---|
| Study time begins | Learning schedule/focus is visible to time controls; the child sees the agreed routine rather than an unexplained block. |
| Child completes an activity | Reward/education rules may create a time exception only when the guardian’s policy permits it, with a visible expiry. |
| SOS begins | Trusted contacts, location truth, notification escalation, acknowledgement, and event history form one response loop. |
| Device protection degrades | Device health appears in Safety, child profile, Today, and support—not merely in an obscure settings screen. |
| Place event occurs | The event can appear in the guardian’s attention queue, relevant family communication, and timeline according to preferences. |
| Safety insight is generated | It shows source, confidence, impact, and a suggested human decision; it never silently imposes a restriction. |
| A guardian changes a rule | Child explanation, co-guardian visibility, audit history, notification preference, and device delivery status are coordinated. |

## 8. Global, accessible, and respectful UX requirements

- Arabic-first and English/LTR parity; translations must fit without truncating controls or hiding risk state.
- Time zone, travel, daylight-saving, school-calendar, and locale-aware schedules are first-class states.
- All core tasks remain usable with larger text, screen readers, reduced motion, and non-colour state cues.
- Child age and maturity influence explanation tone and available request options; the product does not use one infantilizing experience for all children.
- Safety surfaces never shame a child, use raw alarming language for uncertain signals, or turn incomplete data into a claim of misconduct.

## 9. G2 acceptance criteria

G2 is approved only when the Owner confirms that:

1. Safety Hub is the primary security entry point and does not duplicate Today.
2. Parent, co-guardian, and child experiences are distinct but connected.
3. Child Safety Profile is the contextual control center, not a flat feature grid.
4. All security controls use the shared settings-desk pattern.
5. Confirmed, pending, limited, unavailable, and failed states are visible to the user.
6. Advanced/sensitive systems remain hidden from primary navigation until they have approved capability and trust models.
7. The visual direction is calm, premium, clear, global, accessible, and compatible with the current Flutter design foundation.
