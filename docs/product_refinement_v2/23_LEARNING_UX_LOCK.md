# Learning & Growth UX Lock — Gate G2

> **Status:** Accepted under standing Owner trust
> **Scope:** Information architecture, role experience, visual direction, content lifecycle, and cross-pillar learning behaviour.
> **Boundary:** This locks the product experience; it does not claim real content import, AI, grading, speech, or remote sync capability.

## 1. Experience intent

Learning in Family OS should feel like forward movement, not an online school administration panel and not an endless feed of content.

The child should open the app and understand:

> **“Here is my next useful step. I can do it. I can ask for help. My progress matters.”**

The guardian should open the app and understand:

> **“Here is what is going well, what needs support, and the one helpful action I can take now.”**

## 2. Learning Hub: the parent front door

A guardian does not manage nine education systems separately. Learning begins with a single hub reached from Today and available as a principal parent destination.

```text
Today
 └─ Learning Hub
     ├─ Family learning pulse
     ├─ Needs support
     ├─ Child learning cards
     ├─ Focus now / next routine
     ├─ Recent wins and constructive feedback
     ├─ Plans, assignments, and reports
     ├─ Parent Studio
     └─ Optional Quran learning path
```

### Learning Hub composition

| Zone | Guardian question | Product behaviour |
|---|---|---|
| Learning pulse | “How is learning across the family today?” | One concise view of due work, focus, progress, and actionable support—never a raw grade table. |
| Needs support | “Where can I help?” | Overdue work, blocked learner, low-confidence gap, waiting-for-review item, or a child request—ranked by usefulness. |
| Child cards | “What is each child’s next meaningful step?” | Next activity, recent win, focus state, and one path to the child Learning Profile. |
| Focus & routine | “When is study happening?” | Today’s study routine, current focus state, safety/time connection, and ability to adjust in the right settings desk. |
| Wins & progress | “What should I recognize?” | Genuine progress, effort, review milestone, or Quran routine achievement—never a default comparison between children. |
| Plan & report | “What changed over time?” | Source-qualified progress/gap narrative with one recommended supportive action. |
| Studio | “Can I help create the next activity?” | Reviewed creation/approval/assignment lifecycle; no automatic child distribution. |

## 3. Parent information architecture

### Level 1 — Parent shell

| Destination | Learning role |
|---|---|
| Today | Shows only the few learning priorities worth interrupting a parent for. |
| Safety | Coordinates device protection, time, school/focus, and capability truth. |
| Family | Calendar, tasks, communication, praise, and shared events around learning. |
| Learning | The full Learning Hub, child learning profiles, Studio, plans, and reports. |
| More | Family-wide settings, privacy/data, support, subscription, and account controls. |

### Level 2 — Child Learning Profile

```text
Child Learning Profile
 ├─ Current next step and focus state
 ├─ Today’s learning plan
 ├─ Lessons and assignments
 ├─ Assessment and constructive result
 ├─ Skills / review / adaptive plan (when supported)
 ├─ Wins, rewards, and permitted privileges
 ├─ Quran learning path (when selected)
 ├─ Learning activity and report
 └─ Guardian learning settings
```

The profile uses the same child/device/role context as Safety. It never asks a guardian to choose a child again when moving from a study routine, task, safety concern, or Today card.

### Level 3 — Parent Studio is a lifecycle, not a generator screen

```text
Source / idea
  → draft input
  → processing or manual composition
  → draft learning artifact
  → guardian preview & edit
  → approved artifact
  → assignment / plan / reward settings
  → child-visible activity
  → child progress / result
  → guardian follow-up, archive, reuse, or withdraw
```

This protects children from unreviewed imported/generated content and gives guardians a clear answer to “what did I send, to whom, and what happened?”

## 4. Child learning rhythm

```text
Child Learn Home
 ├─ Continue / next step
 ├─ Today’s small plan
 ├─ Focus now
 ├─ My assignments
 ├─ Practice / quiz / result
 ├─ Ask for guided help
 ├─ My wins and progress
 └─ Quran routine (when selected)
```

### Child UX rules

- The child has one primary action, not a complicated curriculum chooser.
- A difficult answer produces a hint, a smaller step, a retry, or a request for help—not a harsh score.
- A due item is visible, but its language is encouraging and it always gives a recovery path.
- Gamification celebrates practice and growth; it does not publicly rank siblings or turn missed days into shame.
- A child can understand whether study time is protected/available, why, and what essential tools remain available.
- AI help is labeled as help, includes context/limits, and never pretends certainty or completes assessed work on behalf of the child.

## 5. Co-guardian experience

Co-guardians use the shared Learning Hub and child profile with explicit permission states:

- **View:** see learning pulse, progress, plans, and relevant activities.
- **Support:** encourage, approve permitted requests, start a focus routine, and review assigned items.
- **Create:** create/edit Studio drafts and assignments if delegated.
- **Manage:** change learning/routine/reward settings if delegated by the primary guardian.

Every assignment, plan, reward policy, and Studio approval identifies its author and history. This prevents duplicate work and invisible changes between guardians.

## 6. Visual direction

### Mood

**Optimistic concentration.** Learning should feel clear, warm, and capable—not childish, loud, competitive, or academically cold.

### Semantic visual language

| State | Meaning | Treatment |
|---|---|---|
| Next step | A meaningful activity is ready. | Brand/primary emphasis and one confident CTA. |
| In progress | The child has begun a learning/focus activity. | Calm progress treatment; no countdown anxiety unless time is material. |
| Needs support | Guardian help or child recovery is useful. | Amber with concrete supportive action. |
| Win / mastery | Genuine progress or effort deserves recognition. | Mint/teal and celebratory micro-moment, never overwhelming confetti by default. |
| Insight / gap | Evidence suggests a useful next learning action. | Neutral-to-brand explanation with source/data-quality context. |
| Awaiting review | Parent/guardian action is needed before content/feedback proceeds. | Distinct review state, author/source visible. |
| Limited / unavailable | Content, AI, source input, or device capability is unavailable. | Calm neutral language; preserve manual alternatives. |

### Layout and accessibility rules

- Parents get concise progress narratives and action cards; children get a focused, visual task sequence.
- Progress has text/icon/context in addition to colour.
- The Arabic-first design foundation is retained while LTR/English, large text, screen readers, reduced motion, and tablet/desktop parent layouts remain first-class.
- Learning progress is never communicated through a single score alone; show context, trend, and next action.
- Quran surfaces use a calm, respectful visual tone and do not reuse generic competitive-game motifs.

## 7. Cross-pillar contracts

| Learning moment | Required connection |
|---|---|
| An assignment is due | Calendar, Today, notification preferences, task context, guardian support action. |
| Child begins focus | Screen-time/school-mode policy, device capability, routine explanation, essential access. |
| Child completes meaningful work | Result/event, progress update, optional non-financial recognition, parent visibility. |
| A reward grants extra time | Explicit security exception with source, scope, guardian policy, expiry, and child explanation. |
| Parent creates Studio content | Family role, source provenance, approval/audit, child assignment, results/follow-up. |
| Tutor identifies a difficulty | Child context, source confidence, adaptive plan only if evidence supports it, guardian insight. |
| Quran routine happens | Child/guardian optional track, focus/routine context, progress and respectful celebration. |
| Device is unhealthy or offline | Learning profile shows limitation; it never marks work delivered or focus protected without confirmation. |

## 8. G2 acceptance criteria

The Learning UX lock is complete when:

1. Learning Hub provides one coherent parent entry rather than nine system destinations.
2. Child Learning Profile connects next action, progress, focus, results, and appropriate optional paths.
3. Parent Studio uses a mandatory review/approval/assignment lifecycle.
4. Guardian/co-guardian/child roles are connected but meaningfully different.
5. Focus, time, tasks, calendar, notifications, rewards, and safety use explicit cross-pillar contracts.
6. AI/adaptive/source-ingestion capabilities present truthful limited/unavailable states until they are real.
7. The visual experience motivates learning without pressure, sibling comparison, or financial scope.
