# Family Connection Settings Desk & State Model — Gate G2

> **Status:** Accepted under standing Owner trust
> **Purpose:** Define clear relationship, coordination, delivery, privacy and recovery controls across connection systems.

## 1. Shared family connection settings pattern

```text
Current state and relationship context
  → affected members / child / contact / device
  → normal permission or coordination rule
  → schedule / notification / availability preference
  → delivery and capability state
  → history, pause, revoke, edit, recover or get help
```

## 2. Relationship and safe-circle desk

| Area | Required controls |
|---|---|
| Relationship | Family member, external relative, approved friend, pending request, paused, blocked, revoked. |
| Authority | Which guardian can approve, invite, pause, block, or change communication permissions. |
| Child view | Clear relationship name/status and request outcome; no adult policy jargon. |
| Contact scope | Message/call/media/location/check-in permissions are distinct and explicit. |
| Privacy | Contact approval does not default to message content visibility; any safety review is separately configured/transparent. |
| Recovery | Correct mistaken approval/block, handle invitation expiry, report or seek support, audit changes. |

### Contact lifecycle

```text
Requested / proposed → guardian review → invitation / verification
→ active relationship → paused | blocked | revoked | reported
```

## 3. Conversation and media state model

### Message lifecycle

```text
Draft → sending → queued → delivered → read
                 ↘ failed / expired / recipient unavailable
```

- Edit/delete behavior names what changes for recipients and what audit metadata remains.
- Pin/lock/subgroup features are unavailable until their trust/journey decisions are complete.
- A delivery receipt does not mean the recipient understood or responded.

### Media/file lifecycle

```text
Selected / captured → permission check → processing/uploading → sent/available
→ viewed/downloaded as supported → removed/expired/reported/failed
```

No UI uses “sent” or “transcribed” unless the relevant storage, transport, processing and receipt are real.

### Call lifecycle

```text
Ready → initiating → ringing/connecting → active → ended
                ↘ queued/unavailable/declined/failed/unsupported
```

A normal call never claims emergency delivery. SOS remains its own incident pathway.

## 4. Calendar settings and event model

| Section | Required controls |
|---|---|
| Scope | Family, selected members, owner, color/label with non-colour identifier. |
| Time | Local time zone, all-day/recurrence, travel/daylight-saving behavior, date/calendar display preference. |
| Context | Linked task, learning/focus routine, place/check-in context if explicitly chosen. |
| Invite / visibility | Who can see/edit/respond; guardian permission and child view. |
| Reminders | Recipient, timing, quiet/urgent behavior, delivery state. |
| Lifecycle | Draft, saved, delivered, changed, cancelled, conflict, archived/history. |

Hijri/Gregorian and prayer-time display are configurable/accurate capability work, not static labels. A family can select its calendar context without forcing it globally.

## 5. Responsibility and recognition model

```text
Draft task → assigned → seen → in progress → child confirms completion
→ guardian accepts / asks for revision / auto-completes only by approved rule
→ recognition or permitted privilege → history / correction / expiry
```

| Control | Required behaviour |
|---|---|
| Assignment | Child, owner, due context, recurrence, instructions, linked calendar/learning context. |
| Completion | Child confirmation, optional evidence/review, guardian response/clarification. |
| Recognition | Non-financial meaning, evidence link, audit; optional time privilege uses Security policy/expiry. |
| Fairness | Chore suggestion may propose but never silently assign; guardian retains review. |
| Recovery | Reassign, reopen, correct a mistaken completion/reward, preserve child-sensitive explanation. |

## 6. Location in communication model

| State | User-visible meaning |
|---|---|
| Sharing active and fresh | Current consented sharing has a recent, supported update. |
| Sharing active but stale | Last update/time/accuracy is visible; no live-location implication. |
| Check-in sent | A child initiated “I arrived”; delivery/acknowledgement is tracked separately. |
| Location requested | Guardian request has a clear recipient/permission/expiry state. |
| Awaiting response | Recipient/device has not responded; no assumption of refusal or safety issue. |
| Unavailable/limited | Permission, device, platform or network prevents requested behavior; show recovery/alternative. |

## 7. Notification and failure rules

| Scenario | Product response |
|---|---|
| Message/call/media cannot reach recipient | Preserve intent/context; show queue/failure/expiry and retry or alternate path. |
| Friend request lacks guardian authority | Explain who can decide and route/request appropriately. |
| Calendar conflict/change | Show affected members and current event version; avoid silently overwriting. |
| Task not completed | Use supportive reminder/recovery, not public shame or automatic punishment. |
| Check-in/location stale | Show freshness/accuracy, response status and appropriate safety path—not a fresh-looking map pin. |
| Call unsupported | Explain limitation and offer available contact/safety option without implying a call happened. |
| Media report/removal | Preserve necessary audit, remove access appropriately, explain outcome to affected people. |
| Co-guardian conflict | Show author/current state and provide a clear resolution path within role permissions. |
