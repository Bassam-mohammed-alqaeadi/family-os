# Family Intelligence Settings Desk & State Model — Gate G2

> **Status:** Accepted under standing Owner trust
> **Purpose:** Define the governed controls and truthful lifecycle states for family intelligence before any Backend, model provider, remote retrieval, or delegated action is built.

## 1. Shared intelligence settings pattern

Every intelligence control follows this sequence:

```text
Purpose and current truth
  → person / family / domain / time scope
  → permitted source and visibility boundary
  → interpretation, report, or assistant behaviour
  → notification and child-explanation rule
  → confidence/data-quality/capability truth
  → history, feedback, pause, correction, forget, recovery
```

A preference alone cannot create an intelligence capability, authorize a data source, make a provider call, bypass a role boundary, or convert a local prototype result into family truth.

## 2. Intelligence policy hierarchy

```text
1. Lawful/safety-critical retention, emergency and accessibility requirements
2. Family membership, identity, role and explicit consent/visibility boundary
3. Active Security / Learning / Family source policy and capability truth
4. Primary-guardian approved intelligence purpose and source scope
5. Child-specific or domain-specific communication/report preference
6. Co-guardian relevance / notification preference within granted authority
7. Family default and product baseline
```

The effective intelligence scope and reason must be inspectable. An insight cannot override a safety policy, learning plan, contact boundary, child accessibility need, or explicit guardian pause.

## 3. Key settings desks

### A. Sources, purpose, and insight scope

| Section | Required controls |
|---|---|
| Purpose | Select only approved purposes such as safety support, learning support, family coordination, or weekly reflection; each names its benefit and data boundary. |
| Scope | Family, selected child, domain, source category, time window, and role visibility. No “all data forever” default. |
| Source truth | Show source capability, consent, freshness, completeness, provenance, and whether it is local/offline versus Render-authoritative. |
| Sensitivity | State redaction level, restricted evidence, child-visible consequence rules, and whether raw detail is unavailable to the viewer. |
| Pause / review | Pause future interpretation or report use where allowed without falsely deleting source records; explain remaining policy/safety retention. |
| History | Show who changed purpose/scope, when it becomes effective, affected insights/reports, and recovery/support path. |

### B. Insight and pattern review desk

| Section | Required controls |
|---|---|
| Eligibility | Evidence window, data sufficiency, supported domain/model/rule version, and confidence criteria required before an item can surface. |
| Presentation | Plain-language title, source/coverage explanation, confidence band, limitations, and sensitivity treatment. |
| Action posture | Suggest dialogue, support, review, wait, or a linked domain action; never attach automatic punishment/restriction/reward. |
| Feedback | Helpful, not useful, inaccurate, context missing, defer, dismiss, or request review—with optional explanatory context. |
| Suppression | Temporarily hide a noisy non-safety insight for a defined scope/time; retain review/audit and do not use it to hide an emergency pathway. |
| Re-evaluation | Describe when new source data, a correction, expiry, or policy change changes/retires an insight. |

### C. Report desk

| Section | Required controls |
|---|---|
| Schedule | Cadence, local time zone, start date, delivery channel, quiet-time compatibility, and manual-open option. |
| Audience | Primary guardian, eligible co-guardian, and never a child by default unless a separate child-appropriate report is approved. |
| Inclusion | Approved domains/source categories with benefit and sensitivity explanation—not arbitrary raw-data switches. |
| Format | Brief/detailed, accessibility/language preference, source-detail level within role scope, and downloadable/export truth when available. |
| Quality gate | Minimum source coverage, stale-data threshold, partial-report behaviour, and “no report yet” outcome. |
| Recommendation | At most one clear, proportionate action with act/defer/not-useful/correct feedback; no automatic execution. |

### D. Assistant and answer desk

| Section | Required controls |
|---|---|
| Availability | Actual backend/provider capability, age/role availability, language, supported question types, outage/fallback state. |
| Retrieval scope | Family/child/domain scope, source categories, visibility/redaction rules, and query purpose; assistant cannot choose a broader scope on its own. |
| Answer standard | Cite permitted sources; distinguish evidence from interpretation; say “I do not know,” ask a clarifying question, or show unavailable as needed. |
| Safety and escalation | Route supported safety concern to its domain workflow; no diagnostic, emergency-delivery, disciplinary, legal, medical, or financial authority claim. |
| History | Viewer-controlled history within retention policy; query/evidence/action audit; correct/report-answer control. |
| Cost/rate control | Render-governed entitlement, rate limit and provider/cost state once a provider exists; no client-held key or Firebase data authority. |

### E. Memory, correction, and forget desk

| Section | Required controls |
|---|---|
| Knowledge item | Purpose, source references, subject/scope, creation/update time, data quality, visibility, retention class, and current use. |
| Correction | Add factual context/correction with author, reason, review state and downstream impact; never silently alter immutable source provenance. |
| Forget/delete | Select eligible item/scope, show what will be deleted, retained, de-identified, or re-evaluated, and provide request status. |
| Export/access | Offer real access/export only when the durable data capability exists; distinguish queued, available, expired, failed, and unsupported. |
| Propagation | Show pending/completed/limited failure state across knowledge, reports, retrieval indexes/caches and derived insights. |
| Audit | Preserve only necessary, permitted audit metadata; an audit trail must not become a hidden permanent behavioural archive. |

### F. Notification and role relevance desk

| Section | Required controls |
|---|---|
| Audience | Primary guardian, co-guardian role, family/child scope, and authorized relevance boundary. |
| Threshold | Needs-review, report-ready, correction/forget outcome, source-quality warning; no notification from an unverified candidate signal. |
| Delivery | Channel, quiet hours, locale/time zone, delivery truth, retry/failure/expiry and in-app fallback. |
| Co-guardian limits | View/support/request-review permissions; no implicit manage/delegation right. |
| Child explanation | Whether a guardian-selected visible action must carry an age-appropriate explanation and support/request path. |
| Fatigue control | Grouping, cooldown, priority, pause, and summary preference; never suppress SOS/incident rules through ordinary intelligence settings. |

### G. Delegation readiness desk — unavailable until later gate

The product may explain what a future delegated assistant would require, but must not expose active automation controls until the capability is real and separately authorized.

| Required future control | Required truth before it can be enabled |
|---|---|
| Exact action contract | Defined permitted action, prohibited actions, target scope, side effects, idempotency and failure behaviour. |
| Authorization | Render-authoritative identity, role, delegation consent, expiry, limits and conflict resolution. |
| Preview and notice | Human-readable preview where appropriate plus immediate recipient/guardian notification of every real action. |
| Reversal | Proven undo/reversal contract with expiry, partial-failure explanation and linked domain state. |
| Audit | Durable, exportable, access-controlled action/audit record with actor, rule, source, time and outcome. |
| Emergency boundary | Never substitutes for SOS or performs high-impact discipline, contact, location, spending, reward, or safety action autonomously. |

## 4. Core intelligence state machines

### A. Source-qualified fact lifecycle

```text
Observed / submitted
→ authorization + integrity + data-quality check
→ available | redacted | rejected | unavailable
→ retained / corrected-context-added / eligible-for-forget
→ expired / deleted / retained-by-required-policy
```

Only an available, authorized, purpose-compatible fact may support a signal. A local cache must identify its source, freshness and unconfirmed state; it cannot claim remote family synchronization.

### B. Signal and pattern lifecycle

```text
Eligible fact(s)
→ candidate signal / baseline update
→ sufficiency + policy + capability check
→ suppressed | insufficient | active signal | pattern proposed
→ reviewed / acknowledged / feedback received
→ expires / corrected / re-evaluated / retired
```

A candidate, baseline update, or confidence score is not automatically a guardian alert or a family fact.

### C. Insight and recommendation lifecycle

```text
Qualified source + supported signal/pattern
→ explanation assembled
→ authorization + quality + sensitivity check
→ visible for review | partial | unavailable
→ guardian acts / defers / dismisses / marks not useful / corrects
→ linked domain outcome observed where supported
→ expires / is revised / withdrawn / retired
```

“Acted” means the guardian initiated a linked supported domain path. It never means that a requested policy, message, delivery, task, reward, or restriction completed without its own lifecycle evidence.

### D. Report lifecycle

```text
Scheduled / manually requested
→ authorized coverage collection
→ sufficient → generated for review/delivery
             ↘ insufficient / partial / unavailable
→ delivered / viewed / feedback or action recorded
→ superseded by correction / archived / retention expiry
```

A report is not delivered merely because it was rendered locally or a notification was queued.

### E. Assistant answer lifecycle

```text
Question submitted
→ identity + role + scope + rate/capability check
→ authorized retrieval
→ sourced answer | clarification requested | “I do not know” | unavailable
→ viewer follows source/action, gives feedback or reports issue
→ retained/redacted/expired according to policy
```

No answer may infer authorization from the question text or convert a model/provider output into a verified fact.

### F. Memory correction / forget lifecycle

```text
Authorized request drafted
→ scope and downstream-impact preview
→ accepted / needs review / not eligible / failed
→ propagation queued
→ completed | partially completed / retained-by-policy / retry-needed
→ outcome and permitted audit visible
```

### G. Delegation lifecycle — later capability only

```text
Draft policy → explicit guardian consent → active narrow delegation
→ eligible command → authorization/limit check → execution attempt
→ domain outcome + immediate notice + audit
→ undo/reversal requested → reversed / partially reversed / unavailable
→ pause / revoke / expire
```

This lifecycle is architectural acceptance criteria, not permission to implement or display functioning delegated automation now.

## 5. Failure and recovery rules

| Scenario | Required product response |
|---|---|
| Evidence is too sparse, stale, or contradictory | State the limit, avoid pattern/recommendation claim, offer wait/review/manual support path. |
| Source capability is unavailable or consent changes | Stop/limit use as policy requires, identify affected insight/report state, explain recovery without leaking restricted data. |
| A guardian disputes an insight | Preserve source provenance, collect correction/feedback, identify re-evaluation status and do not silently repeat the same conclusion. |
| Assistant cannot retrieve authorized evidence | Say it does not know or is unavailable; never fill gaps with invented family detail. |
| Report generation/delivery fails | Preserve schedule/request truth, show queued/failed/expired state and retry/manual-open option; do not claim sent. |
| Co-guardian lacks authority | Explain scope and route a review/request to the appropriate guardian without exposing restricted source content. |
| Forget/delete is partial or retention-bound | Explain what remains, why, what derived use is blocked or pending, and when the person can check again. |
| Offline cache is shown | Mark source/freshness/unconfirmed status and reconcile later; never present it as current cross-device truth. |
| Provider/model outage, safety block, or rate limit | Explain capability state, protect the draft/question, offer manual/domain alternative, and never fabricate a response. |
| Future delegated action cannot be reversed | The action is ineligible for delegation; do not enable it or claim an undo window. |
