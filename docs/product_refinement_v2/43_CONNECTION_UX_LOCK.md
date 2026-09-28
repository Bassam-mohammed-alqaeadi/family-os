# Family Connection UX Lock — Gate G2

> **Status:** Accepted under standing Owner trust
> **Scope:** Family Hub, role experience, relationship trust model, coordination journeys, visual direction, and cross-pillar behaviour.
> **Boundary:** This locks product experience and states; it does not claim real chat/call/media/location transport or synchronization.

## 1. Experience intent

Family Connection should feel like a safe family room and a calm household coordinator.

A guardian should understand:

1. What needs a response today?
2. Which family relationships and contact permissions are active?
3. What is happening in the calendar and responsibilities?
4. Did a message, task, check-in, or change actually reach the right person?

A child should understand:

1. Who can I contact and how?
2. What is on my day and what responsibility is mine?
3. Can I safely share a moment or say “I arrived”?
4. What can I request if a contact or action is unavailable?

## 2. Family Hub: parent front door

```text
Today
 └─ Family Hub
     ├─ Coordination pulse
     ├─ Needs response
     ├─ Family conversation and safe circle
     ├─ Today / week calendar
     ├─ Responsibilities and wins
     ├─ Check-ins and location-in-communication
     └─ Connection settings
```

### Family Hub composition

| Zone | Guardian question | Product behaviour |
|---|---|---|
| Coordination pulse | “What is happening in the family?” | A short, prioritized summary of next event, pending task/request, relevant check-in and communication action—not a stream of every message. |
| Needs response | “What needs me?” | Friend/contact request, task review, child check-in, invitation, undelivered communication or other actionable family item. |
| Family relationships | “Who is connected and under which boundary?” | Family members, approved circle, pending requests, blocked/revoked contacts, and a route to relationship settings. |
| Calendar | “What is today/this week?” | Shared events, ownership/color, local time/calendar display, invitation/reminder state. |
| Responsibilities | “Who owns what?” | Assigned/completed/needs-review tasks, fair recognition and a route to create/support. |
| Check-ins | “Did they arrive or respond?” | Explicit check-in/location sharing state with freshness/consent/delivery context. |
| Conversation | “Can I connect now?” | Family conversation state and safe action, with no implication that all call/message transports are active. |

## 3. Relationship trust model

```text
Family member
  → inherently connected by family membership and role

External relative / trusted person
  → guardian-defined relationship → invitation/consent → active circle member

Child-requested friend
  → child request → guardian review → invitation/acceptance → active
  → pause / block / revoke / report as needed
```

### Rules

- A child cannot discover or contact unknown people through Family OS by default.
- A guardian’s approval to contact identifies an allowed relationship; it does not silently grant broad access to private content.
- Family-group messages are visible to participating family members. Any additional child-conversation safety review must be a separate, transparent, capability-gated policy—not an implied default.
- A revoked/blocked relationship produces an understandable child outcome and preserves only the necessary audit context.
- Emergency/SOS contacts remain a distinct safety model and are not broken by ordinary chat/call schedules.

## 4. Parent information architecture

### Parent shell

| Destination | Connection role |
|---|---|
| Today | Shows only coordination items that deserve immediate family attention. |
| Safety | Handles SOS, device/location truth, emergency contacts, and protection policy. |
| Family | Full Family Hub: communication, relationships, calendar, tasks, and check-ins. |
| Learning | Shows learning-linked calendar/tasks/focus/recognition without duplicating Family Hub. |
| More | Family-wide settings, privacy, help, data, subscription, account recovery. |

### Child Family Home

```text
My Family
 ├─ Conversations available to me
 ├─ Today’s events
 ├─ My responsibilities
 ├─ Approved friends / request a friend
 ├─ Share a moment
 ├─ I arrived / check-in
 └─ Safety help always visible separately
```

Children do not see contact administration, other guardians’ controls, family audit, private guardian notes, or unsupported control switches.

## 5. Core family journeys

### A. Communicate

```text
Open family/person thread → compose/reply → send
→ queued/delivered/read/failed state → reply/edit/delete action as allowed
→ relevant notification/timeline update
```

### B. Request a friend

```text
Child opens Friends → request known person → guardian receives context
→ approve/decline/request-more-info → invitation/acceptance when applicable
→ child sees a clear relationship outcome
```

### C. Coordinate an event

```text
Guardian creates/edits event → selects people/time/calendar context
→ event is delivered/visible → reminder/day summary → event changed/cancelled/recovered
```

### D. Close a task loop

```text
Guardian creates task → assigns child → child sees/does/confirms
→ guardian reviews when needed → recognition or recovery → Today/calendar/activity update
```

### E. Check in

```text
Child taps “I arrived” or guardian requests a check-in
→ location/consent/freshness context evaluated → recipient delivery state
→ acknowledgement / follow-up / safety escalation path if configured
```

## 6. Visual direction

### Mood

**Warm family presence.** Connection should feel close and organized, not like a noisy social feed or a corporate work messenger.

| Semantic state | Visual meaning |
|---|---|
| Connected / active | Relationship, event, task, or delivery is current and confirmed. |
| Needs response | A request, assignment, invitation or check-in needs a meaningful person action. |
| Waiting / queued | A message/event/check-in is not confirmed; show recipient/device context without anxiety. |
| Private / restricted | A relationship or action has an explicit permission boundary; explain it calmly. |
| Celebration | Task/win/family moment is shareable within intended circle, never public by default. |
| Safety-sensitive | Location/SOS-related content gets clear priority and truthful state, not decorative urgency. |

### Design rules

- One primary reply/action per card; family coordination never looks like an infinite feed.
- A child sees relationship-friendly labels (“Approved family friend”, “Ask a guardian”) rather than policy jargon.
- Message/call/media state is text/icon explicit; color alone never claims delivery.
- Calendar/task cards align visually with Today and Learning; family members can recognize ownership/color without relying on color alone.
- RTL/LTR direction, multilingual names, time zones, larger fonts, screen readers, and low-motion modes are first-class.

## 7. Cross-pillar contracts

| Connection moment | Required platform tie |
|---|---|
| Child friend request | Identity, role permission, safe circle, notification, audit, child explanation. |
| Family event | Today, calendar timezone, reminders, tasks, learning/focus or safety link, activity history. |
| Task completion | Child profile, recognition policy, optional learning/safety time exception, guardian review, audit. |
| Check-in / shared location | Security location consent/freshness, notification, SOS escalation alternative, data/privacy history. |
| Family message | Relationship rule, device availability, notification delivery, safe reporting/support path. |
| Call attempt | Contact policy, device/platform capability, call state/history, no false emergency guarantee. |
| Shared media | Approved relationship, media source/delivery/removal state, family moment/celebration context. |

## 8. G2 completion criteria

1. Family Hub is the parent entry point and does not duplicate Today.
2. Child Family Home is safe, simple and distinct from guardian administration.
3. Contact permission, content visibility and safety monitoring are separate explicit concepts.
4. Messages, calls, media, events, tasks and check-ins have truthful delivery/lifecycle states.
5. Calendar/task coordination closes loops across guardians/children, not merely shows lists.
6. Location in communication uses consent/freshness/capability truth from Security.
7. Visual design is warm, calm, global and never social-feed driven.
