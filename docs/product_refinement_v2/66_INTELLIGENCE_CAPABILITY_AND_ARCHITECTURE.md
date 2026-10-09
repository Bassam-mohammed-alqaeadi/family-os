# Family Intelligence Capability & Architecture Readiness — Gate G3

> **Status:** Product-readiness technical design complete
> **Infrastructure boundary:** Render is authoritative. Firebase remains only an explicitly approved no-cost auxiliary service under `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md`; it is never intelligence, family-data, authorization, or decision truth.

## 1. Architecture outcome

Family Intelligence must make one limited, dependable promise:

> **It can turn authorized, source-qualified Family OS events into explainable decision support while preserving uncertainty, human control, privacy and a truthful record.**

It must keep five layers distinct:

| Layer | Meaning | Must not be mistaken for |
|---|---|---|
| Source fact | An authorized, provenance-bearing event or user-submitted correction from a domain service. | A model inference, score, recommendation or generalized profile. |
| Signal / baseline | A bounded, versioned interpretation of source facts under a known rule or supported model. | A diagnosis, a child label, an alert automatically requiring action. |
| Insight / recommendation | An explainable suggestion for a guardian based on qualifying evidence. | A command, policy change, successful delivery or completed action. |
| Human decision / domain outcome | A guardian decision and the independently verified Safety, Learning or Family outcome. | Proof that the intelligence output was correct. |
| Model/provider output | An untrusted candidate used only through governed Render orchestration. | A family source of truth or client-side authority. |

## 2. Render-first topology

```text
Guardian / co-guardian / child Flutter clients
                    │
       authenticated, role-scoped Render API
                    │
 ┌──────────────────┼────────────────────────────────────────────────────┐
 │ Render identity/family authorization and consent/visibility service    │
 │ Render source-event intake + schema/version/quality validation          │
 │ Render intelligence eligibility, purpose and policy service             │
 │ Render facts / evidence / knowledge-context service                     │
 │ Render signal, baseline and pattern job service                         │
 │ Render insight/report/recommendation service                            │
 │ Render assistant retrieval, guardrail and provider-adapter service      │
 │ Render notification orchestration and domain-action handoff             │
 │ Render correction/forget propagation + durable audit/export service     │
 │ Render queues/workers, evaluation, observability and support controls   │
 └──────────────────┴────────────────────────────────────────────────────┘
                    │
        Render-authoritative durable data, outbox and job queue
                    │
    Approved external model/provider only through a Render adapter
                    │
  Optional approved FCM: notification transport attempt, not insight truth
```

Flutter may render authorized data, submit feedback/corrections/questions, and invoke explicit domain actions. It must never hold provider credentials, decide authorization, generate a durable intelligence result locally, or present a prototype/local inference as synchronized family truth.

## 3. Domain responsibilities

| Domain | Owns | Must not own |
|---|---|---|
| Identity/family authorization | Family membership, role, child/device context, access decision, consent/visibility claim. | Interpretation of family facts or provider-specific policy. |
| Source-event intake | Schema validation, provenance, source quality/freshness, deduplication, event version and purpose compatibility. | A silent rewrite of a source domain event. |
| Intelligence policy/eligibility | Approved purposes, scopes, retention class, sensitivity/redaction, thresholds, feature/capability gate. | A broad bypass of Security/Learning/Family policy. |
| Evidence/knowledge context | Authorized fact references, cross-domain links, correction context, retrieval-ready visibility/index state. | An opaque permanent behavioural dossier or an unbounded raw-data copy. |
| Signal/pattern service | Versioned rule/model evaluation, baseline sufficiency, confidence semantics, suppression and re-evaluation. | Automated punishment, diagnosis, contact/control decisions or provider access without policy. |
| Insight/report service | Explainability bundle, one proportionate recommendation, feedback, report eligibility/version and domain-action handoff. | Claiming a linked action/delivery is complete without that domain’s receipt. |
| Assistant orchestration | Role-scoped retrieval, prompt/input minimization, output guardrails, citation/uncertainty, provider adapter and invocation audit. | Authority to retrieve beyond permission, invent facts, execute actions or retain hidden conversation memory. |
| Correction/forget service | Scope preview, lifecycle/progression, derived-item re-evaluation, retention-bound outcome and audit. | A false promise of instant deletion from every legally retained record/provider log. |
| Notification orchestrator | Relevance, recipient eligibility, fatigue controls, push/in-app attempt and retry. | Delivery/read/resolution truth or automatic family action. |
| Delegation service, later only | Explicit policy, authorization, idempotent permitted-command executor, notice, reversal and audit. | Any high-impact or irreversible autonomous action. |

## 4. Capability programme

| Capability | Required future work | User behaviour until proven |
|---|---|---|
| Source-qualified event flow | Render family/role API, signed/versioned domain event schema, durable outbox, quality/provenance and consent validation. | Local fixtures/cache are labelled; no cross-device intelligence claim. |
| Evidence / knowledge context | Durable Render store, purpose/visibility policy, redacted retrieval, correction/forget propagation, retention/audit. | Timeline/map screens show empty/unavailable or honestly local state. |
| Signals and reports | Approved source thresholds, deterministic/versioned rules, scheduling, report versioning, feedback and honest insufficiency states. | No generated “weekly insight” or risk result from sample content. |
| Patterns/anomalies | Time-window/baseline design, sufficiency tests, false-positive calibration, impact/fairness review and re-evaluation. | “Not enough information” rather than a pattern or behavioural label. |
| Assistant | Render retrieval/guardrails, provider selection/DPA/cost approval, citations, prompt-injection resistance, rate limits, safe fallback and evaluation. | Ask feature is unavailable or explicitly local preview; no live family answer claim. |
| Voice / image / recitation | Separate input permission, minimization, locale/accuracy evaluation, retention, child-safety and support programmes. | Hidden/unsupported, never represented as analyzed/transcribed/corrected. |
| Studio generation | Learning-governed source rights, provider/output review, guardian approval and assignment lifecycle. | Manual draft/review route only; no completed generated artifact claim. |
| Delegated agent | Narrow command catalogue, Render authorization/execution, immediate notice, durable audit, real undo/recovery and abuse review. | Delegation status unavailable; no enabled rule, auto-action or fake action history. |

## 5. Provider and model boundary

A future model/provider is an implementation dependency, not a family authority. Before any provider/model use, the program must create and approve a capability record covering:

1. intended purpose and prohibited use;
2. exact input minimization/redaction and sensitive-data policy;
3. family role/consent/visibility validation before request creation;
4. provider region, terms/DPA, retention/training/logging and subprocessor review;
5. model/version/prompt/tool/retrieval configuration inventory;
6. cost, quota, rate-limit, outage, fallback and kill-switch design;
7. accuracy, safety, bias, child-dignity, Arabic/RTL and multilingual evaluation plan;
8. output guardrails, source citation/uncertainty representation and incident reporting;
9. invocation, retrieval and output audit retention boundaries; and
10. migration/exit strategy with no provider-held system-of-record data.

No model may receive more family data than needed for an approved question or task. Direct Flutter-to-provider calls, client-side API keys, unbounded family-context prompts, provider-managed durable family memory and Firebase AI/data authority are prohibited.

## 6. Data and security architecture requirements

- Render authorizes every query, source intake, report, answer, feedback, correction and later delegated command using family/role/child/purpose scope.
- Source events use a transactional outbox or equivalent durable handoff; processing is idempotent, versioned and auditable.
- Evidence points to source records and permitted redacted snapshots; a derived item carries event/rule/model/retrieval version and data-quality state.
- Sensitive content is classified/minimized before indexing or provider request. Retrieval filters apply before semantic/ranking logic, not after it.
- Knowledge deletion/forget requests propagate to indexes, caches, report/insight eligibility and provider-facing context as policy permits; each step has durable status.
- Encrypted transport, at-rest protection, secrets isolation/rotation, least-privilege worker roles, tenant/family isolation, abuse/rate limits and tamper-evident audit design are required before production use.
- FCM may be used only after its separate approval record; it carries a notification hint and never raw sensitive intelligence detail unless a future privacy review explicitly allows a minimised payload.

## 7. Intelligence execution requirements

Signals/patterns/reports/assistant answers require:

- policy and source eligibility before work begins;
- stable event-time/processing-time distinction, versioned rules/models and reproducible evidence bundles;
- sufficient-data thresholds that may return insufficient/partial/unavailable;
- output classification: evidence, interpretation, recommendation, unavailable, or safety-domain handoff;
- human feedback/correction and a mechanism to suppress/retire noisy or harmful output;
- no autonomous high-impact consequence; a domain action always uses its own authorization/lifecycle contract;
- replay/backfill controls that do not retroactively surprise families or duplicate notifications; and
- release gates based on quality, privacy, security, human-factors and operational evaluation rather than UI completion alone.

## 8. Architecture decisions deferred

Product readiness does not select a model/provider, embedding/vector store, AI framework, prompt-management product, model-evaluation vendor, data warehouse, event broker, Render datastore plan, provider region, speech/image/recitation technology, or delegated-command catalogue. Any selection must satisfy this document, `16_RUNTIME_TRUTH_POLICY.md`, and `17_RENDER_FIREBASE_SERVICE_BOUNDARY.md` before implementation authorization.
