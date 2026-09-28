# Family Intelligence UX Lock — Gate G2

> **Status:** Accepted under standing Owner trust
> **Scope:** Intelligence Hub, explainability, guardian/co-guardian/child experience, report and assistant journeys, visual direction, and cross-pillar behaviour.
> **Boundary:** This locks the product experience and truthful states. It does not claim live model inference, provider access, voice, source ingestion, cross-device intelligence, or delegated execution.

## 1. Experience intent

Family Intelligence should feel like a calm, respectful family guide. It helps a person notice what may need care, understand the evidence and limits, and decide what to do next. It is neither an all-seeing surveillance console nor a generic AI chat surface.

A guardian should be able to answer:

1. What changed that may matter today?
2. What facts and data limits support this insight?
3. What is the smallest helpful next step?
4. Who can see this, what happens if I act, and where is the record?

A child should be able to answer:

1. If a plan or routine changes for me, what changed and why?
2. What can I do, ask, or correct?
3. Is the system describing me respectfully rather than labelling me?

## 2. Intelligence Hub: the guardian front door

Intelligence is embedded in Safety, Learning, Family, and Today where a decision belongs. The Intelligence Hub is the single place for deeper review, explanation, feedback, and data control; it never becomes a raw event dump.

```text
Today / Safety / Learning / Family
 └─ Family Intelligence Hub
     ├─ One useful insight for today
     ├─ Needs guardian review
     ├─ Family and child insight timeline
     ├─ Weekly family report
     ├─ Ask Family OS
     ├─ Memory, sources, and forget controls
     └─ Delegation status (unavailable until separately authorized)
```

### Hub composition

| Zone | Guardian question | Product behaviour |
|---|---|---|
| Today’s insight | “What is the one thing worth considering?” | Show at most one appropriately prioritized, source-qualified insight with a clear next action; no fear-driven count or score. |
| Review queue | “What needs my judgment?” | Show recommendations, corrections, privacy requests, and source-quality warnings that need a person; a signal alone is not automatically a task. |
| Insight timeline | “What changed over time?” | Show a filtered, understandable chain from authorized source fact to signal, pattern and outcome. A raw source may be redacted or unavailable by role. |
| Weekly report | “What should I understand this week?” | Present a bounded summary, evidence coverage/data limits, one supportive recommendation, and feedback controls. |
| Ask Family OS | “Can the platform answer this from permitted family information?” | Accept a scoped question, retrieve only authorized evidence, cite it, or say it does not know. It does not silently broaden access. |
| Memory and data | “What does the system keep and why?” | Let an authorized guardian inspect purpose/source/visibility, correct factual context, request forget/delete, and see resulting state. |
| Delegation status | “Can an assistant do something for me?” | Until its separate capability and trust gate is approved, show only an honest unavailable state and explanatory criteria—not a fake toggle or action log. |

## 3. The Explainability Card

Every intelligence-derived item uses one consistent expandable pattern:

```text
Plain-language observation
  → why it may matter
  → supporting sources and coverage window
  → confidence and data limitations
  → what the system did not infer
  → one proportionate suggested next step
  → act / defer / not useful / correct / learn more
```

### Required card content

| Element | Requirement |
|---|---|
| Observation | Describes a change or support opportunity, never a fixed child identity or diagnosis. |
| Scope | Names the child/family area and time window only when the viewer has permission. |
| Evidence | Links to source category, source time, data-quality state and permitted redacted detail. |
| Confidence | Uses understandable bands (limited, developing, supported) with a reason; it is not a hidden numeric verdict. |
| Limits | States missing, stale, partial, unsupported, or conflicting evidence prominently. |
| Suggested action | Offers a proportionate human action such as ask, support, review a plan, or wait for more information. |
| Feedback | Supports useful, not useful, inaccurate/context missing, defer, and dismiss with an optional explanation. |
| History | Records what the guardian decided and the eventual outcome without rewriting source facts. |

An insight may not say that it has detected a dangerous condition, a child intention, a relationship quality, learning mastery, delivery, or policy enforcement unless an approved source and capability substantiate that exact claim.

## 4. Role journeys

### A. Guardian: review an insight before acting

```text
Today / domain surface shows one calm insight
→ guardian opens explanation
→ sees sources, coverage, confidence and limits
→ chooses support action, defer, not useful, or correct context
→ appropriate Safety / Learning / Family action opens with source link
→ outcome and feedback are recorded in the intelligence timeline
```

The CTA must lead to a real supported action or an explicit unavailable/recovery state. It may never manufacture a completed action, delivery receipt, policy change, report, or family fact.

### B. Guardian: read the weekly report

```text
Report becomes eligible from sufficient authorized event coverage
→ guardian opens report with coverage/quality note
→ understands progress, concern, and one evidence-backed recommendation
→ acts, defers, rejects, or requests correction
→ report decision is recorded; next report can explain what changed
```

A report with inadequate data is an honest partial/insufficient report, not an empty optimistic summary or a fabricated narrative.

### C. Guardian or authorized co-guardian: ask a question

```text
Choose family / child / domain scope within existing permission
→ ask a question
→ authorization and retrieval check
→ sourced answer | clarifying question | “I do not know” | unavailable
→ viewer rates/corrects answer or follows a linked supported action
→ query, evidence references, and feedback are audited by retention policy
```

The assistant does not expose a source, child, private guardian note, or policy detail merely because a question is phrased naturally.

### D. Co-guardian: receive a relevant insight without overload

```text
Eligible role and relevance setting
→ receives concise notification or Today item
→ sees explanation within their granted scope
→ supports, acknowledges, requests primary-guardian review, or defers
→ author/decision history remains visible
```

A co-guardian never gains primary-guardian data access, delegation authority, or command scope through intelligence surfaces.

### E. Child: understand a visible consequence

```text
A guardian chooses a child-visible plan/routine/support action
→ child receives age-appropriate explanation of the action
→ sees what they can do, ask, pause, or request help with
→ can say “this does not seem right” or ask for clarification
→ guardian receives a respectful correction/request path
```

The child does not see hidden scoring, private guardian notes, raw safety signal details, stigmatizing patterns, or a broad behavioural dossier.

### F. Memory: correct or forget a family knowledge item

```text
Authorized guardian opens source/purpose/visibility detail
→ requests factual correction or forget/delete
→ system identifies linked insight/report/retrieval effects
→ request is pending / completed / limited / failed with reason
→ durable audit preserves only what policy/law/safety necessity permits
```

Correction preserves the original event provenance and adds a corrected context; it does not rewrite historical truth invisibly. Forget/delete must describe scope and propagation truth rather than promise instant universal erasure.

## 5. Information architecture

### Guardian shell

| Destination | Intelligence role |
|---|---|
| Today | Shows only the small number of intelligence items that require timely attention. |
| Safety | Explains safety signals in the safety context and routes to the honest underlying capability. |
| Family | Connects coordination, relationship, task, event, and check-in context to relevant insights. |
| Learning | Connects learning evidence, support plan, guided help, and report context without implying AI grading. |
| Intelligence | Full Hub: review queue, timeline, reports, assistant, memory/data controls, and capability truth. |
| More | Family-wide privacy, support, account, export and subscription controls. |

### Child intelligence touchpoints

```text
Learn Home / My Family / Safety explanation
 ├─ Why this plan or reminder is visible
 ├─ Ask for help or clarification
 ├─ Tell a guardian context is missing
 └─ See only approved age-appropriate progress/support context
```

There is no child-facing Intelligence Hub for inspecting private family intelligence. A child-facing help surface follows the Learning or Family journey where it is useful.

## 6. Visual direction

### Mood

**Calm clarity, never machine authority.** Intelligence should feel humble, composed, and useful. It avoids a surveillance-dashboard aesthetic, alarm-heavy colour, “brain” metaphors, or anthropomorphic claims of certainty.

| Semantic state | Visual meaning |
|---|---|
| Needs review | A guardian’s judgment could help. Use calm amber and a clear action, not danger theatre. |
| Supported insight | Evidence is sufficiently sourced for a limited recommendation. Use neutral/brand emphasis with visible source detail. |
| Insufficient / partial | The platform lacks enough recent/authorized evidence. Use an honest neutral state and manual alternative. |
| Corrected / feedback received | A person added helpful context or challenged the output. Use respectful acknowledgement with history access. |
| Private / restricted | The item is outside this viewer’s role or sensitive source scope. Explain the boundary without leaking content. |
| Unavailable capability | Provider, source, voice, image, or delegated action is not live. Use disabled-but-explained state, never a simulated result. |
| Safety-sensitive | A supported safety signal belongs to Safety’s emergency/incident pathway. Intelligence cards do not substitute for SOS. |

### Design rules

- Start with plain language; make evidence, confidence, and limits one tap away and screen-reader available.
- Every colour state also has text, icon, and accessible semantics.
- Avoid default peer/sibling comparisons, rankings, streak-pressure, predictive labels, and score-only summaries.
- A family timeline groups related events rather than exposing continuous behavioural surveillance.
- Support Arabic-first RTL and global LTR layouts, translated/long names, large text, keyboard navigation, reduced motion, and tablet/desktop guardian review.
- Assistant responses distinguish platform evidence, a proposed interpretation, and any external/general guidance.

## 7. Cross-pillar contracts

| Intelligence moment | Required platform connection |
|---|---|
| Safety insight | Source event, device/capability truth, alert/incident state, consent/redaction, emergency route, audit. |
| Learning insight | Assignment/result/focus evidence, support plan, child explanation, guardian review, no unsupported grading claim. |
| Family insight | Relationship/event/task/check-in context, delivery/freshness truth, permissions, calendar/timeline and recovery. |
| Weekly report | Time zone/schedule, notification preference, authorized source coverage, role visibility, feedback and activity history. |
| Assistant answer | Identity/role/family scope, authorized retrieval, source citation/redaction, rate/cost policy, audit/retention. |
| Memory correction/forget | Purpose, source link, visibility/consent, deletion/retention policy, downstream re-evaluation, audit. |
| Suggested action | Explicit human approval, linked domain action state, notification/timeline record, outcome/undo or recovery if supported. |
| Delegated action later | Explicit delegation policy, Render authorization/execution, immediate notification, durable audit and proven reversal. |

## 8. G2 completion criteria

1. Intelligence has one guardian Hub but remains contextual inside Safety, Learning, Family, and Today.
2. Every insight discloses observation, evidence, limits, confidence meaning, suggested next step, feedback, and history.
3. Guardian, co-guardian, and child routes are distinct, respectful, and cannot expand permissions through AI interaction.
4. Reports and answers are allowed to be partial, unavailable, or “I do not know.”
5. Memory correction/forget controls make purpose, source, propagation and retention state visible.
6. Delegation is visibly unavailable until a separately approved, real capability exists; no fake automation UI is treated as product truth.
7. Visual language is global, accessible, calm, and rejects surveillance, stigma, score-only decisioning, or autonomous authority.
