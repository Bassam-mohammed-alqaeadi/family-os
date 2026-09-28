# Family Intelligence Data & Event Contracts — Gate G3

> **Status:** Product-readiness technical design complete
> **Purpose:** Define authoritative, source-qualified intelligence contracts for future Render-backed services. These contracts do not authorize a model/provider, remote execution, or automation.

## 1. Canonical lineage

```text
Account → Family → Membership / role → child / guardian / device
                                      │
Security / Learning / Family source fact and quality/visibility context
                                      │
         eligibility → signal/baseline → pattern → insight/report/answer
                                      │
       guardian feedback/decision → domain action → verified domain outcome
                                      │
                  activity/audit/correction/forget lifecycle
```

No stage replaces the prior stage. A derived record must remain traceable to its permitted source facts and the rule/model/retrieval version that made it eligible.

## 2. Canonical entities

| Entity | Required contract |
|---|---|
| SourceFact | Immutable source-domain event/reference, family/subject scope, source service/event version, event/observed/server times, provenance, integrity state, quality/freshness, visibility, retention and purpose eligibility. |
| EvidenceReference | Minimal pointer/redacted snapshot of a SourceFact used by a derived record; includes authorization scope and retrieval/redaction version. It is not a copied archive by default. |
| IntelligencePolicy | Purpose, family/child/domain/source scope, role visibility, consent/legal basis, sensitivity, thresholds, notification, retention and capability-gate version. |
| Signal | Versioned, bounded result from one/more evidence references; rule/model version, outcome class, confidence semantics, quality/sufficiency, lifecycle and suppression state. |
| Baseline / Pattern | Cohort-free family/child baseline window or pattern over qualifying signals; coverage, window, method version, confidence/limitations, feedback and retirement state. |
| KnowledgeItem | Purpose-limited contextual link among authorized facts, corrections and derived records; subject scope, visibility, retention, current-use and deletion/index propagation state. |
| Insight | Human-readable explainability bundle: observation, permitted evidence, limits, sensitivity, suggested next step, feedback/decision state and linked domain handoff. |
| RecommendationDecision | Guardian/co-guardian act/defer/dismiss/not-useful/correction response with actor, authority, rationale, time and linked domain intent/outcome references. |
| ReportVersion | Scheduled/manual report request, coverage result, included source categories, authored-at/version, role/audience, recommendation, delivery/view/feedback lifecycle. |
| AssistantInquiry | Viewer role/scope, question, purpose, language, capability/rate state, retrieval authorization and retention classification. |
| AssistantAnswer | Answer type (sourced answer, clarification, no-answer, unavailable, safety handoff), permitted citations, output/model/prompt/retrieval versions, confidence/limitations, viewer feedback. |
| ModelInvocation | Provider/model/version/configuration identity, approved capability record, minimized-input classification/hash/reference, outcome/cost/latency/safety state and audit link; not a place to store raw family content by default. |
| Correction / ForgetRequest | Request scope, requester/authority, reason, eligibility, downstream impact preview, propagation status, retention-bound result and audit reference. |
| IntelligenceAuditEvent | Append-only record of access, policy change, evaluation, surface, feedback, correction/forget, notification, domain handoff and later delegation state. |

## 3. Source-fact contract

```text
SourceFact
- factId, schemaVersion, familyId, subjectMemberId?, childId?, deviceId?
- sourceDomain: security | learning | connection | administration
- sourceService, sourceEventId, sourceRecordVersion, correlationId, causationId
- eventOccurredAt?, observedAt, receivedAtRender, processedAt?
- provenance: user_reported | device_observed | server_verified | imported | local_cache
- integrity: accepted | duplicate | rejected | revoked | unverifiable
- dataQuality: fresh | stale | partial | conflicting | unavailable
- authorizationScope, visibilityClass, consent/reference, retentionClass
- payloadReference / redactedEvidenceReference, payloadHash?
```

Rules:

- A source domain remains the owner of its fact; Intelligence only references a permitted, versioned representation.
- `provenance: local_cache` identifies non-authoritative/offline state and cannot independently create a synchronized insight/report claim.
- Event time, source observed time and Render receipt time remain distinct.
- A later correction adds context/version rather than silently overwriting source provenance.
- A fact must be purpose-compatible and visible to the derived record’s audience before any signal, retrieval or provider request.

## 4. Derived-record contracts

### Signal and pattern

```text
Signal / Pattern
- id, familyId, subjectScope, policyId/version
- evidenceReferences[], sourceCoverageWindow, dataQualitySummary
- evaluatorType: deterministic_rule | supported_model | human_review
- evaluatorVersion, configurationVersion, evaluatedAt
- outcomeClass, confidenceBand, sufficiency: sufficient | insufficient | partial
- explanationReference, sensitivity, visibilityClass
- lifecycle: candidate | active | suppressed | reviewed | corrected | expired | retired
- feedbackSummary, recheckAfter?, auditId
```

`confidenceBand` communicates the quality/coverage of the limited result. It must not be exposed as a universal risk score, diagnosis, probability of a child trait, or substitute for a guardian decision.

### Insight and recommendation

```text
Insight
- insightId, familyId, subjectScope, policy/version
- sourceSignalIds[] / patternIds[] / evidenceReferences[]
- observation, limitationSummary, whyNow, sensitivity, visibilityClass
- supportedActionType?, linkedDomain, actionEligibility
- status: reviewable | partial | unavailable | acted | deferred | dismissed | corrected | withdrawn | retired
- surfacedAt, expiryAt?, feedbackIds[], decisionIds[], auditId
```

A `supportedActionType` is an invitation to a human-owned domain workflow. Its completion status comes only from the linked domain service.

### Report and assistant answer

```text
ReportVersion
- reportId, version, familyId, audienceScope, schedule/request reference
- policy/version, includedDomains, coverageSummary, dataQualitySummary
- contentReference, recommendationInsightId?, generatedAt, expiresAt?
- state: scheduled | collecting | partial | insufficient | ready | queued | delivered | viewed | failed | archived
- notificationIds[], feedbackIds[], auditId

AssistantAnswer
- answerId, inquiryId, familyId, viewerMemberId, scope
- answerType: sourced | clarification | unknown | unavailable | safety_handoff
- permittedCitations[], limitationSummary, outputReference
- retrievalPolicy/version, guardrailVersion, providerInvocationId?
- state: prepared | shown | feedback_received | corrected | withdrawn | retention_expired
- auditId
```

A locally rendered report/answer, a queued notification, or an LLM text string does not change report/answer state to delivered, read, trusted, or factually verified.

## 5. Intelligence event envelope

```text
IntelligenceEvent
- eventId, eventType, schemaVersion, eventVersion
- familyId, actorMemberId?, subjectMemberId?, childId?, deviceId?
- sourceFactId?, signalId?, patternId?, insightId?, reportId?, inquiryId?, answerId?
- policyId/version, visibilityClass, retentionClass
- occurredAt, observedAt?, receivedAtRender, processedAt?
- provenance, dataQuality, capabilityState
- correlationId, causationId, idempotencyKey
- auditId, traceId
```

Examples: source fact accepted/revoked, signal insufficient/activated/suppressed, pattern retired, insight surfaced/deferred/corrected, report partial/ready/delivered, assistant answer unknown, feedback received, correction propagation partial, forget request completed, provider invocation blocked, domain handoff resolved.

## 6. Retrieval and provider contract

```text
AssistantRequest
→ authenticate viewer and establish family/role/purpose/child/domain scope
→ authorize eligible evidence before retrieval
→ produce citations/redacted context within scope
→ evaluate guardrail/capability/rate policy
→ optional Render provider adapter call with minimized request
→ classify answer and persist permitted audit metadata
→ present sourced answer, clarification, unknown, unavailable or domain handoff
```

Required rules:

- Authorization/filtering happens before retrieval ranking, prompt construction, model/tool invocation and client rendering.
- The system persists references/hashes/minimized audit material rather than unrestricted prompt/raw family content whenever possible.
- Provider output may be used only as an untrusted candidate; final surfaced content must preserve citations/limitations and pass product guardrails.
- No answer may provide an unsupported safety, medical, legal, mental-health, financial, disciplinary, relationship or emergency conclusion. It must provide an appropriate limited response or domain/human-support route.
- Retrieval/index/cache deletion follows ForgetRequest propagation state and cannot remain silently eligible after a policy/consent revocation.

## 7. Feedback, correction and forget contracts

### Feedback / decision

```text
FeedbackDecision
- id, targetType/id, familyId, actorMemberId, actorAuthority
- response: acted | deferred | dismissed | useful | not_useful | inaccurate | context_missing | report_issue
- noteReference?, occurredAt, linkedDomainIntentId?, linkedOutcomeId?
- visibility, retention, auditId
```

### Correction / forget

```text
CorrectionOrForgetRequest
- requestId, type: correction | forget | delete | export
- familyId, requesterId, authorityScope, target references and scope
- reason?, impactPreview, policy/retention eligibility
- state: draft | review | accepted | queued | partial | completed | retention_limited | failed | retry_needed
- propagationTargets[], resultSummary, createdAt, resolvedAt?, auditId
```

Correction is additive context and may trigger derived-item re-evaluation. Forget/delete blocks future eligible use as soon as policy requires, then reports the durable propagation/retention outcome honestly.

## 8. Contract acceptance checks

An Intelligence service is acceptable only when it proves family/role/purpose authorization; source provenance and event version; quality/freshness/consent/visibility state; data minimization and redaction; idempotent durable processing; independent domain outcome truth; feedback/correction/forget propagation; model/provider/configuration accountability where relevant; auditability/support reconstruction; and Render authority over every durable intelligence state.
