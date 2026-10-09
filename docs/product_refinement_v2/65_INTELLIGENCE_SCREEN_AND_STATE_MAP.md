# Family Intelligence Screen & State Map — Gate G2

> **Status:** Accepted under standing Owner trust
> **Purpose:** Define the approved intelligence surface inventory before implementation. Existing Flutter advisor, pattern, report, assistant, voice, and agent screens are evidence/candidates—not proof of real inference, provider, synchronization, or automation.

## 1. Guardian and co-guardian surfaces

| ID | Surface | Primary job | Existing evidence relationship |
|---|---|---|---|
| P-INT-01 | Family Intelligence Hub | Understand one useful insight, review needs, and reach reports/answers/data controls. | Refines `SCR-FAT-074` advisor-hub evidence into the approved product front door. |
| P-INT-02 | Intelligence Review Queue | Review insight, recommendation, correction and quality items requiring human judgment. | Reconciles advisor suggestions, smart-alert and report action patterns. |
| P-INT-03 | Explainability Detail | Understand observation, sources, coverage, confidence, limits, suggested action, feedback, and history. | Refines `SCR-FAT-020`, `SCR-FAT-066` alert detail patterns. |
| P-INT-04 | Family / Child Insight Timeline | Review authorized source-qualified history and related outcome context. | `SCR-FAT-063` individual timeline evidence. |
| P-INT-05 | Patterns & Evidence | Explore sufficient-evidence trends/baselines without labelling a child. | `SCR-FAT-062` family patterns evidence. |
| P-INT-06 | Knowledge Context | Inspect an approved knowledge item, purpose, source, visibility, and cross-domain links. | `SCR-FAT-064` knowledge-map evidence; social maps remain purpose/capability-gated. |
| P-INT-07 | Weekly Family Report | Read a coverage-qualified report and decide on one supportive next step. | `SCR-FAT-073` weekly-report evidence. |
| P-INT-08 | Report Preferences | Manage authorized audience, cadence, inclusion, format and delivery truth. | Refines weekly-report local preference evidence. |
| P-INT-09 | Ask Family OS | Ask a role-scoped question and receive sources, clarification, honest uncertainty or unavailable state. | `SCR-FAT-074` assistant/free-text evidence; existing implementation is local/mock. |
| P-INT-10 | Answer Detail & Feedback | Inspect cited permitted evidence, rate/correct/re-report an answer, or open linked supported action. | New organizing surface over assistant and feedback seams. |
| P-INT-11 | Intelligence Source & Scope Desk | Set purpose, source/child/domain scope, visibility, pause and notification relevance. | Refines `SCR-FAT-029` brain-control / monitoring settings evidence; no fake feature toggle. |
| P-INT-12 | Memory, Correction & Forget | Inspect, correct, forget/delete or export eligible knowledge with propagation truth. | `SCR-FAT-059` privacy/data and `S-AIC-017` evidence. |
| P-INT-13 | Intelligence Activity & Audit | Review insight, report, answer, feedback, correction and request history. | Uses shared timeline/audit foundation; existing local action logs are not durable proof. |
| P-INT-14 | Delegation Readiness | Explain why delegation is unavailable and the prerequisites for a future trusted capability. | Replaces active interpretation of `SCR-FAT-079`/`SCR-FAT-080` until a separate authorization gate. |

## 2. Child-facing surfaces and touchpoints

| ID | Surface | Child job | Existing evidence relationship |
|---|---|---|---|
| C-INT-01 | Why This Plan | Understand an intelligence-informed visible plan/routine/reminder in age-appropriate language. | New cross-pillar explanation linked from Learning, Family or Safety action. |
| C-INT-02 | Ask for Learning Help | Ask for approved guided help and understand source/capability limits. | `SCR-CHD-017` tutor evidence; no live model/provider implied. |
| C-INT-03 | My Support Context | See approved next-step/review context and ask for clarification or human help. | Reconciles adaptive-plan and result-support evidence. |
| C-INT-04 | Tell Us Context Is Missing | Tell a guardian that an explanation or plan is inaccurate, incomplete, or needs help. | New respectful feedback route; it never reveals private source content or hidden scores. |

Children do not receive a copy of the guardian Intelligence Hub, pattern dashboard, knowledge maps, assistant query history, raw signal detail, private guardian feedback, co-guardian permissions, or delegation controls.

## 3. Capability-gated and deferred surfaces

| Surface / evidence | Current approved treatment |
|---|---|
| Voice conversation (`SCR-FAT-083`, `S-AIC-027`) | Hidden or explicitly unavailable until voice I/O, privacy, retention, supported languages, provider cost, safety and fallback are real. |
| Sensitive-image detection and updateable rules (`S-AIC-004`, `S-AIC-005`) | No guardian “enabled” success state until real supported source, classifier/rule authority, transparency and safety/privacy review are available. |
| Studio generation (`SCR-FAT-043`, `SCR-FAT-044`, `S-AIC-021`) | Governed in Learning Parent Studio; unavailable capability is not represented as a completed generated artifact. |
| Quran recitation analysis (`SCR-CHD-032`, `S-AIC-023`) | Kept as a respectful Learning capability candidate; unavailable until validated speech/recitation quality and safeguards exist. |
| Delegated rules/action log (`SCR-FAT-079`, `SCR-FAT-080`, `S-AIC-030`–`034`) | Replaced by Delegation Readiness / unavailable state; current local/mock behavior is not a production automation contract. |
| Peer comparison | Excluded from default intelligence experience; it is neither an insight nor a child/guardian decision metric. |

## 4. Required state coverage

Every applicable intelligence surface must handle the relevant states below:

- Loading, first-use/no authorized source, empty, and recovery states.
- Role/relationship/child scope allowed, restricted, redacted, consent-changed or no-longer-eligible.
- Source fact available, delayed, offline-local, partial, stale, conflicting, unavailable, redacted, rejected or deleted/retained-by-policy.
- Signal/pattern candidate, insufficient evidence, suppressed, active, reviewed, corrected, expired, retired or unavailable capability.
- Insight/recommendation visible, partial, needs review, acted, deferred, dismissed, not-useful, context-corrected, withdrawn or superseded.
- Report scheduled, collecting, sufficient, partial, insufficient, ready, queued, delivered, viewed, feedback recorded, failed, expired or archived.
- Assistant request authorizing, retrieving, answering with citation, clarification-needed, “I do not know,” safety-route, rate-limited, provider-unavailable or failed.
- Forget/correction request drafted, in review, queued, completed, partially complete, retention-limited, failed or retry-needed.
- Notification queued, delivered, read/acknowledged where supported, expired, failed or suppressed under fatigue rules.
- Delegation explicitly unavailable; after a later authorization only, draft, consented, active, paused, revoked, expired, executed, notified, reversible/undone or partial-recovery.

## 5. Existing-screen reconciliation rule

Every current advisor/intelligence surface receives one outcome during later implementation planning:

- **Retain:** It already serves an approved surface and can be hardened around real sources/states.
- **Refine:** It keeps its purpose but adopts the Intelligence Hub, role, source, truth and accessibility direction.
- **Merge:** It moves under an approved surface without breaking a journey or concealing its source/action history.
- **Defer:** It remains registered but is not in the first implementation sequence because provider, input, privacy, quality, cost, or trust capability is missing.
- **Retire:** It is removed only with a documented replacement and explicit decision.

No existing screen is evidence that the product can answer, analyze, deliver, forget, automate, or undo in production. Fixtures and in-memory/local SQLite adapters remain development/preview evidence only unless a future runtime implementation meets the truth policy.

## 6. G2 completion test

Family Intelligence UX is locked when every Core or capability-gated intelligence action has:

1. a guardian/co-guardian entry appropriate to role;
2. a child explanation or protected non-visibility consequence where relevant;
3. an authorized source, purpose, scope, sensitivity and data-quality state;
4. an explainable insight/report/answer state with a valid “not enough information” outcome;
5. feedback, correction, defer/dismiss, and audit relationship;
6. a linked underlying domain action with independent delivery/capability truth; and
7. an unavailable/deferred state whenever provider, backend, voice, image, analysis, automation, or real reversal is not implemented.
