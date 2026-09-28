# Learning Settings Desk & State Model — Gate G2

> **Status:** Accepted under standing Owner trust
> **Purpose:** Give guardians full, understandable learning control while preserving child autonomy, clarity, and joy.

## 1. Shared learning settings pattern

Every learning setting uses a familiar pattern:

```text
Purpose and current state
  → child / activity / device scope
  → normal learning rule or plan
  → schedule and due context
  → guardian permissions and child autonomy
  → focus / reward / notification links
  → capability / delivery truth
  → history, edit, pause, archive, or withdraw
```

## 2. Learning-plan policy hierarchy

```text
1. Child wellbeing, accessibility, emergency, and safety allowances
2. Explicit guardian override or pause with expiry
3. Active focus/school routine
4. Child-specific learning plan / assignment
5. Family learning defaults
6. Platform baseline
```

A learning rule may not silently override a safety, accessibility, or time policy. When two plans conflict, the current effective plan and reason must be visible to both the relevant guardian and child in age-appropriate language.

## 3. Key settings desks

### A. Learning plan and assignment desk

| Section | Required controls |
|---|---|
| Scope | Child, subject/path, assigned artifact, guardian author, applicable device. |
| Goal | Completion, practice, review, mastery intent, or project milestone—never only time spent. |
| Due context | Date/time/time-zone, calendar/task link, reminder preference, recovery path for missed work. |
| Child autonomy | What the child can choose, skip, retry, ask for help, or request extension on. |
| Review | Whether guardian approval, feedback, or result review is needed before next step. |
| Delivery | Draft, assigned, seen, started, submitted, reviewed, returned, completed, withdrawn, expired. |

### B. Assessment and feedback desk

| Section | Required controls |
|---|---|
| Purpose | Practice, formative check, level placement, or parent-created review. |
| Attempt model | Retry, pause/resume, accommodation, feedback timing, and integrity boundaries. |
| Result model | Constructive outcome, next step, source/quality note, guardian visibility. |
| Auto-assistance | Clearly distinguishes suggested help from verified grading; child understands if answer is not final. |
| Recovery | Technical failure, partial submission, invalid/expired item, or “not enough evidence” state. |

### C. Focus and routine desk

| Section | Required controls |
|---|---|
| Routine | Name, times, linked plan/calendar context, repetition, timezone/travel behaviour. |
| Environment | Selected focus resources/sounds only when locally/legally available; no pretend playback state. |
| Safety link | Screen time/school mode/allowed essentials, device support, guardian override. |
| Child view | Clear start/end, purpose, available help, and pause/break option as allowed. |
| Report | Verified focus event source, data quality, parent summary, no false precision. |

### D. Rewards and recognition desk

| Section | Required controls |
|---|---|
| Earning | Clear activity/evidence that earns a point, badge, level, streak, or recognition. |
| Meaning | Explicit non-financial meaning; no wallet, payment, allowance, or money implication. |
| Privilege link | If a reward creates a time exception, show target, duration, authorizing policy, expiry, and reversal. |
| Fairness | Do not default to sibling ranking; provide effort/progress-aware guardrails. |
| Recovery | Correct mistaken award/revocation with audit history and child-sensitive explanation. |

### E. Tutor and adaptive-learning desk

| Section | Required controls |
|---|---|
| Availability | Child age/subject/content context and actual model capability. |
| Help posture | Guided hints, questions, examples, and practice; prohibited direct answer behaviour for assessments. |
| Guardian visibility | Appropriate history/summary/alert boundary; not indiscriminate surveillance. |
| Adaptation | Skill evidence, confidence, recommendation explanation, review cadence, “insufficient data” state. |
| Feedback | Child/guardian can mark a recommendation unhelpful or incorrect; correction is recorded. |

### F. Quran learning-path desk

| Section | Required controls |
|---|---|
| Selection | Family-selected optional path, child plan, language/translation preferences where supported. |
| Routine | Memorization, recitation, review, adhkar and manageable schedule. |
| Progress | Child-visible milestones, guardian view, review/support plan, respectful celebration. |
| Capability truth | Any speech/recitation correction is clearly unavailable/limited until proven. |

### G. Parent Studio desk

| Section | Required controls |
|---|---|
| Source | Manual idea, approved source reference, or future input type with provenance/permissions. |
| Draft | Parent edits content, age/level/outcome, activity type, and source attribution. |
| Approval | Required explicit approval before a child can receive content. |
| Assignment | Child, plan, due context, rewards, focus link, parent/co-guardian visibility. |
| Lifecycle | Draft, processing, review, approved, assigned, withdrawn, archived, reused. |
| Community | Hidden/disabled until governance, moderation, rights, and reporting are implemented. |

## 4. Core learning state machines

### Assignment lifecycle

```text
Draft → pending approval → approved → assigned → delivered/seen
→ started → submitted → reviewed/feedback available → completed
                 ↘ withdrawn / expired / delivery failed / needs recovery
```

### Studio lifecycle

```text
Idea/source → draft → processing (when supported) → generated/imported draft
→ guardian preview/edit → approved → assigned → outcome observed
→ archive / reuse / withdraw / report source issue
```

### Adaptive recommendation lifecycle

```text
Evidence collected → data quality check → recommendation proposed
→ child/guardian sees explanation → accepted / deferred / not useful
→ follow-up evidence → revise confidence or retire recommendation
```

No learning state can appear complete merely because a parent created a local draft or an AI generated text. Completion requires the appropriate child delivery, activity, result, and review state.

## 5. Required failure and recovery experiences

| Scenario | Product response |
|---|---|
| Content cannot be delivered | Preserve draft/assignment context; show target/device state and retry/withdraw option. |
| Child is offline | Clearly distinguish downloaded/locally available work from pending remote work; never mark new work seen. |
| Source import/generation fails | Keep the guardian’s source/draft, state the failure honestly, and offer manual creation or retry. |
| Tutor/adaptation lacks evidence | Say “not enough information yet”; recommend a small practice/review instead of a false personalized plan. |
| Assessment breaks mid-attempt | Preserve permitted progress, explain review state, and prevent unfair completion/score claims. |
| Focus conflicts with time/school rule | Explain the active policy, allow only authorized override, and retain essentials. |
| Reward policy conflicts | Show the effective earning/exception policy and expiry; do not award silently. |
| Quran feature capability is limited | Retain plan/progress; label correction/audio features accurately and offer supported manual route. |
| Guardian permission is insufficient | Explain who can act and whether a request can be routed to the primary guardian. |
