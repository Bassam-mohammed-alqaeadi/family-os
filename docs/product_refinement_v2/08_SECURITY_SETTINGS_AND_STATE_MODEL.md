# Security Settings Desk & State Model — Gate G2 Proposal

> **Status:** Ready for Owner experience approval
> **Purpose:** Define a reusable control language so security settings remain powerful without becoming overwhelming.

## 1. One settings language for the entire platform

A parent should not have to relearn settings for time, apps, web, location, SOS, school mode, or later learning and communication systems.

Every control desk uses these sections when applicable:

| Section | Parent need it answers |
|---|---|
| Status | What is currently active, for whom, and is it confirmed? |
| Scope | Which child, devices, apps/sites/places, or family members are affected? |
| Normal rule | What happens in everyday use? |
| Schedule | When does the rule apply? |
| Exceptions | What can temporarily override the normal rule, for how long, and why? |
| Notifications | Who learns about a meaningful event and how urgently? |
| Delivery / capability | Can the selected device actually receive/enforce this rule? |
| History | Who changed it, what happened, and how can it be reviewed or reversed? |
| Help | How does the family fix setup or understand the consequence? |

## 2. Policy hierarchy and conflict model

The product needs one understandable precedence model across all control systems:

```text
1. Essential safety / accessibility access
2. Explicit temporary guardian override with expiry
3. Active scheduled routine (sleep, school, focus)
4. Child-specific rule
5. Family default
6. Platform baseline
```

### Conflict rules

- A temporary override always shows its expiry, author, and reason in the affected child’s view and guardian history.
- A guardian can only change controls within their delegated permission scope.
- If two authorized changes conflict, the current effective rule is shown plainly; the audit trail names the most recent authorized change and preserves the prior state.
- A system may not silently merge contradictory rules. It must identify the winning rule and offer the guardian a resolution path.
- Emergency and accessibility allowances are never visually represented as “loopholes”; they are essential states with clear explanations.

## 3. Truthful delivery state

For any action that may affect another device, the UI must use a stateful receipt—not an optimistic toggle.

| State | User language | Required UI behaviour |
|---|---|---|
| Draft | “Not saved yet” | Changes remain local to the form; leaving warns only when needed. |
| Saved locally | “Saved on this device” | Use only when the system has no remote delivery expectation. |
| Sending | “Sending to [device]…” | Show progress without claiming completion. |
| Queued | “Will apply when the device reconnects” | Explain last connection and allow cancel/review. |
| Confirmed | “Active and confirmed” | Show target, effective time, and result. |
| Limited | “Partially available on this device” | Explain the limit and show the actual effect. |
| Needs setup | “Finish setup to activate” | One repair action; never a dead-end toggle. |
| Failed / expired | “Did not apply” / “Request expired” | Preserve context, explain reason where possible, offer retry/change/recovery. |
| Unsupported | “Not available on this device” | Keep the rule understandable; offer supported-device or alternative guidance. |

## 4. Standard parent action pattern

High-impact actions—lock, change a schedule, approve an app, modify web access, start a location check, or respond to SOS—follow:

```text
Intent → Context → Consequence preview → Confirm → Delivery state → Receipt → History / recovery
```

There is no fire-and-forget parent action in the product design.

## 5. Core settings desks

### A. Time & routine desk

| Area | Required controls |
|---|---|
| Daily time | Normal allowance, per-day routine, current consumption truth, child-visible remaining time. |
| Schedules | Sleep, school/focus, custom family routines; calendar/time-zone awareness; next occurrence preview. |
| Per-app boundaries | App-specific allowance or category policy; always-allowed essentials where supported. |
| Requests | Child request path, guardian decision, optional reason, expiry, child result message. |
| Learning-aware exceptions | Explicit earned/education time source, limit, and expiry; never an unexplained time increase. |
| Safety boundary | Emergency/accessibility availability and concise explanation. |

### B. Apps & web desk

| Area | Required controls |
|---|---|
| Apps | Allow/block, categories, new-install approval, app context when available, request/review loop. |
| Web | Category profile, allowed exceptions, safe-search preference where supported, temporary access requests. |
| Scope | Which child/device/browser/network context the rule can actually reach. |
| Explanation | Child sees a humane block reason and an appropriate request route. |
| Delivery | Device/platform support matrix and health state; no universal enforcement claim. |

### C. Location & places desk

| Area | Required controls |
|---|---|
| Sharing state | Active, paused, stale, unavailable, or unsupported—not just “on/off”. |
| Places | Name, purpose, radius, relevant children, arrival/departure preference, schedule. |
| Check-ins | Optional child-facing confirmation action, recipient, and escalation rule. |
| History | Retention/visibility setting and clear data-age/accuracy labels. |
| Battery/device truth | Last location, last connection, battery status where actually available. |
| Recovery | Permission/setup steps and what the guardian can expect while unresolved. |

### D. SOS & emergency desk

| Area | Required controls |
|---|---|
| Readiness | Child device/setup status, trusted responders, location availability, test state. |
| Escalation | Who receives it, order, acknowledgement expectation, and what happens when someone cannot respond. |
| Child experience | Persistent help action, in-progress status, clear cancellation/accidental-trigger protection where appropriate. |
| Response | Location/data truth, acknowledgement, contact/action paths, resolution notes, audit event. |
| Limitations | Delivery channel and unsupported/offline state explained before an emergency occurs. |

### E. Protection health & anti-tamper desk

| Area | Required controls |
|---|---|
| Health card | Device connected, permission state, last check, support level, and exact impact of a failure. |
| Repair | One guided repair task per issue; no generic “something went wrong”. |
| Integrity events | Signal, confidence, time, impact, recommended repair, and dismissal/false-positive path. |
| Advanced enforcement | Only appears after native capability is implemented and the family can understand its effect. |

### F. Reports & school/focus desk

| Area | Required controls |
|---|---|
| Reports | Trend, relevant context, data freshness, selected time range, and one recommended next action. |
| Notifications | What deserves an immediate alert, digest entry, or no interruption. |
| School/focus | Schedule, linked learning context, allowed essentials, guardian override, child-visible routine. |
| Advanced insight | Explanation, source, confidence, and “not useful” feedback; no automatic punishment. |

## 6. Alert and notification model

| Tier | Meaning | Example | Expected action |
|---|---|---|---|
| Urgent | Immediate human response may be needed. | Active SOS or confirmed critical safety event. | Open response flow; acknowledge/escalate/resolve. |
| Action required | Protection or a guardian decision needs attention. | Device permission lost; child app request. | Repair, approve, decline, or defer consciously. |
| Informational | Relevant event with no immediate action. | Arrived at an agreed place; routine started. | View in timeline/digest; preference can reduce interruption. |
| Insight | A trend or recommendation based on sufficient data. | Usage routine changed over a week. | Review context; optionally adjust a rule. |

Rules:

- A notification must name the affected child/context, the real state, and one useful action.
- Duplicate events group into one evolving item rather than alerting repeatedly.
- No high-risk action is executed solely because of an insight notification.
- Quiet hours suppress non-urgent interruptions; they never make an urgent event falsely appear delivered or resolved.

## 7. Required failure and recovery experiences

| Scenario | Product response |
|---|---|
| Child device offline | Show last known state/time, queue only if supported, allow cancel/expiry, and never mark as confirmed. |
| Permission revoked | Mark affected protection limited, explain impact in plain language, guide repair, and record the event. |
| Unsupported device | Make limitation visible before configuration; preserve a usable alternative where possible. |
| Rule conflict | Explain the active rule and the source of precedence; offer a clear resolution screen. |
| Location stale | Display age/accuracy rather than a fresh-looking pin; never imply live tracking. |
| SOS delivery uncertain | Show delivery attempt/state and fallback response path; do not claim family receipt. |
| Alert false positive / not useful | Allow review and feedback; preserve context appropriately rather than silently hiding the event. |
| Subscription changes | Preserve safety understanding; clearly distinguish a product entitlement change from actual loss of protection. |
| Child reaches a limit | Child sees respectful explanation, allowed essentials, request option, and remaining/next available time. |
| Guardian action fails | Preserve the intended action, target, reason, retry path, and history entry. |

## 8. Shared reusable components required later

The approved UX calls for reusable Flutter components—not repeated bespoke layouts:

- Family/child/device context switcher.
- Protection state card and capability-honesty badge.
- Action delivery receipt / queued-action banner.
- Rule summary and schedule preview.
- Exception chip with expiry/author.
- Permission-health repair card.
- Alert context/action card.
- Child explanation panel and request-status card.
- Activity/audit timeline row.
- Empty, loading, unsupported, and recovery states.

These are component requirements for later implementation; G2 does not authorize their coding yet.
