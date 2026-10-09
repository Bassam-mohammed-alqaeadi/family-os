# Learning Data, Event & Delivery Contracts — Gate G3

> **Status:** Product-readiness technical design complete
> **Purpose:** Establish the common data language for child learning, guardian support, content lifecycle, focus/security integration, reporting, and later AI.

## 1. Canonical lineage

```text
Account → Family → Membership / role → Child → Device capability
                                  │
                     Learning plan → artifact revision → assignment
                                  │                   │
                        activity / attempt / result ← child action
                                  │
                  evidence → report / recommendation → guardian support
```

Every learning record must identify its family/child scope, author/source, applicable artifact revision, timestamp(s), access visibility, and data quality.

## 2. Canonical entities

| Entity | Required contract | Why it exists |
|---|---|---|
| Learning profile | Child, age/level/language context, optional learning preferences, active paths. | Personalizes responsibly without assuming mastery. |
| Content source | Source type, creator/provider, rights/attribution, suitability metadata, availability/review state. | Prevents opaque or unlicensed child content. |
| Learning artifact | Versioned lesson/assignment/quiz/card/challenge/Quran routine/project with outcome/metadata. | Makes parent Studio and child consumption traceable. |
| Artifact revision | Immutable version, editor, change reason, source references, approval state. | A submitted result always refers to what the child actually received. |
| Approval | Guardian author, scope, decision, date, reason, review notes, withdrawal state. | Makes reviewed content lifecycle enforceable. |
| Learning plan | Child goal, subjects/skills, routine, focus/calendar relationship, guardian visibility. | Connects activities into coherent progress. |
| Assignment | Child/artifact revision, due context, status, delivery/seen state, child autonomy options. | Drives the parent-child work loop. |
| Activity event | Open/start/pause/resume/complete/review action with device/time/source quality. | Source for progress and support—not mastery alone. |
| Assessment attempt | Item/version, response state, accommodation, attempt/resume/submit lifecycle. | Supports fair formative results. |
| Learning result | Score/feedback/evidence basis, confidence/data quality, next action, guardian/child visibility. | Separates factual result from inferred gap. |
| Skill evidence | Skill taxonomy reference, observations, confidence, source attempts/revisions. | Enables adaptive work only when evidence exists. |
| Tutor interaction | Authorized context, intent, guardrail state, response source/limits, feedback/flag state. | Makes guided AI accountable and reviewable. |
| Focus session | Child/plan context, intent, requested/confirmed focus state, start/end, quality, security-policy link. | Coordinates focus with safety/time truth. |
| Recognition event | Points/badge/streak/challenge outcome, evidence link, policy, visible meaning, privilege/expiry if applicable. | Keeps rewards non-financial and auditable. |
| Quran progress event | Path/ward/review/recitation activity, child/guardian context, evidence/quality. | Supports respectful optional learning routine. |

## 3. Content lifecycle contract

```text
Source declared
  → input validated / provenance recorded
  → draft artifact created
  → manual edit or supported processing/generation
  → guardian review
  → approved revision
  → assignment to named child
  → delivery / seen state
  → child activity/result
  → follow-up / reuse / archive / withdraw
```

Rules:

- An artifact may not become child-visible before required guardian approval.
- A revised artifact does not silently alter an in-progress child assignment; it creates a version-aware choice.
- Withdrawal preserves a child-sensitive explanation, guardian audit trail, and result/history relationship.
- Every external/imported source retains provenance/rights state through archive/removal.

## 4. Assignment and assessment contract

```text
Assignment
- assignmentId, familyId, childId, artifactRevisionId
- author / authorization context
- goal, due context / timezone, priority, focus/calendar/task links
- child choices: retry, ask-for-help, pause, extension request
- delivery/seen/start/submit/review/completion lifecycle
- reward/policy references and audit links

AssessmentAttempt
- attemptId, assignment/artifact revision, childId
- question/item version, accommodation, start/pause/resume/submit state
- response provenance and integrity status
- scoring/feedback source and quality

LearningResult
- attempt/evidence references, outcome/feedback, quality/confidence
- child-visible explanation, guardian narrative, suggested next action
- no automatic high-stakes classification without separate approved policy
```

## 5. Tutor and adaptive contract

### Tutor request

- Must identify child age/context, selected subject/artifact/assignment when applicable, permitted interaction mode, and visible source boundaries.
- Returns a guided response type: clarifying question, hint, scaffolded step, example, practice prompt, or safe refusal/redirect.
- Carries provenance/limitation and feedback/flag channel.
- Cannot submit an assessed answer, change a learning plan, or grant a reward itself.

### Adaptive recommendation

```text
Learning evidence → quality / sufficiency check → proposed recommendation
→ child/guardian explanation → accept / defer / not useful feedback
→ observed follow-up → confidence revision or retirement
```

A recommendation must say when the platform lacks enough evidence. It never labels a child permanently or presents an inference as a fact.

## 6. Focus, reward, and security connections

| Contract | Required behaviour |
|---|---|
| Focus request | Links learning intent to security/time policy; receives confirmed/queued/limited/unsupported state from the security platform. |
| Education-time exception | References exact learning evidence and security policy; has scope, duration, authorizing guardian policy, expiry, child explanation, and reversal. |
| Recognition | Has evidence link, non-financial meaning, guardian policy, correction path, and visibility scope. |
| Calendar/task | Assignment due/change creates a source-linked event; duplicate reminder logic is coordinated by the shared notification/timeline platform. |

## 7. Learning event envelope

```text
LearningEvent
- eventId, type, schemaVersion
- familyId, childId, deviceId?
- artifactRevisionId?, assignmentId?, planId?, attemptId?
- occurredAtDevice?, observedAtServer, receivedAtServer
- actor: child | guardian | co-guardian | approved service | support
- sourceTrust: reported | verified | inferred | unknown
- dataQuality: fresh | partial | stale | unavailable
- causalityId / policyId / focusSessionId?
- visibility and retention classification
```

Examples include assignment approved, assignment delivered, child started lesson, focus session requested, quiz submitted, feedback available, reward issued, Quran review completed, tutor response flagged, or a Studio artifact withdrawn.

## 8. Privacy, child safety, and content boundaries

| Data | Minimum protection contract |
|---|---|
| Child work and results | Scope to the child and authorized guardians; identify result source/quality; prevent broad cross-family access. |
| Tutor conversations | Explicit guardian/child visibility model, age-appropriate safety guardrails, secure retention/access audit, correction/flag workflow. |
| Studio sources | Provenance, rights, creator scope, source sensitivity, approval/audit, withdrawal/removal path. |
| Quran progress | Optional path with respectful visibility; no public ranking by default. |
| Learning insights | Show evidence/quality/explanation; never use it as hidden surveillance or high-stakes judgement. |
| Reward history | Preserve policy/evidence and privilege expiry; no financial balance semantics. |

## 9. Acceptance checks

A future learning service/adapter must prove that it:

1. Validates family/role/child scope on every operation.
2. Preserves content revision and approval lineage from source to child result.
3. Separates activity, assessment result, and inferred learning insight.
4. Handles delayed/duplicate/offline/out-of-order activity safely.
5. Coordinates focus/time privilege only through explicit security contracts.
6. Makes content source, AI limitation, delivery state, and data quality available to the UX.
7. Provides withdrawal, correction, feedback, and audit paths for sensitive learning content/AI outcomes.
