# Learning Capability & Architecture Readiness — Gate G3

> **Status:** Product-readiness technical design complete
> **Purpose:** Define the truthful architecture needed to deliver approved Learning UX without prematurely selecting vendors or claiming that local/mock screens are remote educational services.

## 1. Architecture outcome

The learning platform must make one dependable promise:

> A guardian can approve a meaningful learning activity, a child can receive and complete it, the platform can explain what happened, and the next learning step is based on evidence rather than a decorative score.

The architecture must distinguish these states:

| State | Meaning | Example |
|---|---|---|
| Content source | Where material or an idea came from and what rights/provenance it has. | A guardian-authored math practice or a permitted source reference. |
| Learning artifact | A versioned lesson, assignment, quiz, card set, plan, or Quran routine. | “Fractions review v3.” |
| Approval state | Whether an artifact is merely drafted, reviewed, approved, assigned, withdrawn, or archived. | A generated draft is not child-visible until a guardian approves it. |
| Learning delivery state | Whether a child can receive/see/start the assigned activity. | “Downloaded locally”, “queued for child device”, or “delivery failed”. |
| Learning evidence | What a child actually did and how reliable the result is. | Completed practice, a partial submission, or an assessed skill observation. |
| Learning inference | A recommendation/gap/adaptive action derived from evidence with confidence. | “Review equivalent fractions; evidence is limited.” |

## 2. Target learning topology

```text
Guardian / co-guardian client     Child learning client     Support / moderation tools
             │                           │                           │
             └──── authenticated family-platform API / event gateway ┘
                                         │
 ┌──────────────────────────────────────┼─────────────────────────────────────┐
 │ Family identity, roles & child context│ Content catalog & source provenance │
 │ Learning plan & assignment service    │ Assessment / result service          │
 │ Studio artifact & approval service    │ Focus / routine coordination         │
 │ Reward & recognition policy            │ Learning activity / event timeline    │
 │ Tutor & adaptive orchestration (later)│ Quran learning-path service            │
 │ Reports / learning insights            │ Privacy, audit, support, moderation   │
 └──────────────────────────────────────┴─────────────────────────────────────┘
                                         │
                 Optional capability adapters: files, camera, OCR, speech,
                     AI provider, content partner, local-download/media
```

The domains are responsibility boundaries, not a demand to deploy a large microservice fleet on day one. A modular deployment can evolve while preserving these contracts.

## 3. Architecture principles

1. **Approved content reaches a child intentionally.** Draft, generated, imported, or community content is never silently assigned.
2. **Learning evidence is not merely engagement.** Time, taps, streaks, and completion are contextual data; skill/understanding claims require suitable assessment evidence.
3. **AI is bounded by learning context.** It receives only authorized context, explains source/limits, guides rather than completes work, and records an accountable outcome.
4. **Artifacts are revisioned.** A child’s assignment references a precise artifact revision, not an ever-changing document.
5. **Results are traceable.** A result can identify attempt, content revision, scoring/feedback basis, data quality, and visibility scope.
6. **Focus coordinates; it does not control devices itself.** Focus requests security/time behaviour through the shared policy/capability model.
7. **Rewards are policy-governed recognition.** A reward event cannot silently create a financial entitlement or a time exception outside permitted guardian policy.
8. **Privacy follows child age/context.** Child learning data, tutor interaction, Quran progress, and guardian visibility have explicit scoped access and retention rules.

## 4. Domain responsibilities

| Domain | Owns | Must not own |
|---|---|---|
| Content catalog & provenance | Source metadata, rights/attribution, language/age/subject/level metadata, availability. | Guardian assignment decision or untraceable imported content. |
| Studio artifact & approval | Draft/revision, generation/import status, guardian edit/approval, archive/withdraw. | A generic public publishing network without governance. |
| Learning plan & assignment | Goal, child scope, due context, delivery, lifecycle, guardian/co-guardian authority. | Device-level focus enforcement. |
| Assessment & results | Attempt, question/version, feedback, scoring basis, accommodation, result quality. | Claiming real grading where no assessment model exists. |
| Activity & skill evidence | Completion/activity facts, skill observations, source quality, timeline. | Overstating a learner’s mastery from a single event. |
| Adaptive/tutor orchestration | Grounded suggestion, guided hint policy, confidence, feedback, approved context. | Unbounded answer generation or silent learning-policy mutation. |
| Focus/routine coordination | Learning intent, session/focus event, calendar/task link, security policy request. | Claiming device focus enforcement without a security receipt. |
| Reward/recognition | Points/badges/streak/challenge events, policy condition, privilege link/expiry. | Wallet, allowance, payments, financial balances. |
| Quran learning path | Selected plan, ward/review/recitation progress, child/guardian views. | Claims of audio correction before speech capability is proven. |
| Reporting/insight | Source-qualified aggregates, gap narrative, recommendation/feedback. | Automated punitive or high-stakes academic judgement. |

## 5. Capability programme

| Product capability | Required implementation/discovery | Product behaviour until proven |
|---|---|---|
| Lesson / assignment synchronization | Authenticated remote artifacts, assignment delivery/receipt, offline download/queue, conflict/version handling. | Local state is labelled local; guardian never sees cross-device delivery as confirmed without receipt. |
| File/link/source intake | File/link permissions, fetch/storage/virus/content scanning, format limits, rights/provenance, preview/error/withdraw paths. | Offer manual composition and honest “not available” state. |
| Camera / OCR | Real mobile camera capture, permission lifecycle, image processing, OCR quality, child/guardian data scope, source retention. | Existing mock camera UI never claims capture/analysis happened. |
| Voice / speech / recitation | Recording permission, audio pipeline, speech/recitation model, language/dialect quality, consent, correction confidence. | Manual recitation/progress routes remain; no automatic correction claim. |
| AI tutor / generation | Provider/model selection, approved grounding, prompt/context boundary, guardrails, evaluation, cost/rate limit, fallback, human feedback. | Guided-help UI may show unavailable/limited/manual alternative; no real tutor/generation claim. |
| Adaptive path | Skill graph, attempt evidence, mastery/confidence thresholds, review scheduler, explainable recommendation and override. | Show generic plan or “not enough evidence” rather than invented personalization. |
| Assessment / auto-grading | Item bank, answer model/rubric, accommodation, integrity, feedback rules, subject-specific validity, audit. | Parent/child see formative/local result state only; no verified grade claim. |
| Focus sound/media | Licensed media/content, download/stream/offline strategy, playback state, accessibility, parental settings. | Do not show a playing/available state without actual media capability. |
| Community library | Author identity, attribution/license, moderation, reports, search, age suitability, removal, versioning, abuse/support operation. | Hide publishing/browsing as a production promise until the governance system exists. |

## 6. Client responsibilities

### Guardian client

- Creates, reviews, approves, assigns, pauses, withdraws, and follows up on learning artifacts within delegated permission.
- Displays content/assignment/result/data-quality/delivery state truthfully.
- Does not decide that a child received/completed work merely from local draft state.

### Child client

- Presents a clear next step and permitted child choices.
- Caches only explicitly available content; reports activity/result/focus state with time/source context.
- Explains restrictions and requests in age-appropriate language.
- Does not expose guardian-only notes, content source diagnostics, private report data, or unapproved draft artifacts.

## 7. Architecture decisions deliberately deferred

The product-readiness plan does not select a cloud provider, database, content provider, LMS, AI vendor/model, OCR/speech engine, moderation vendor, storage/CDN, analytics vendor, or curriculum standard. These require later evaluation against the approved contracts, regions, costs, security/privacy posture, content rights, and real operating capability.
