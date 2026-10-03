# 03 — FS-007 Capability Inventory

**Mode:** Evidence-only. Do not invent parental-control industry defaults.  
**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

Classification: **IMPLEMENTED** · **PARTIAL** · **MOCK/SIMULATION** · **DOCUMENTED ONLY** · **MISSING** · **UNKNOWN**

**Nature tags (extra):** `real-AI` · `heuristic` · `mock` · `doc-intent`

---

## Matrix

| # | Capability | Class | Nature | Evidence (short) |
|---|---|---|---|---|
| 1 | Named FS-007 discovery pack (pre-this) | **MISSING** → now this pack | doc | First structured pack |
| 2 | Offline AI Safety product identity | **DOCUMENTED ONLY** | doc-intent | FS-002 cross-ref label only |
| 3 | Local text safety classification | **MISSING** | — | No text safety engine |
| 4 | Local image safety classification | **MISSING** | — | No vision model/pipeline |
| 5 | OCR / text extraction | **MISSING** | — | No OCR deps |
| 6 | Safety keyword dictionary (AR) | **MISSING** (Flutter) / **MOCK** (proto) | heuristic/mock | Proto `webFilter.dict`; not FS-007 store |
| 7 | Safety keyword dictionary (EN) | **MISSING** | — | Host token heuristic only in WF evaluator |
| 8 | Bilingual AR+EN safety classify | **MISSING** | — | — |
| 9 | Harmful-content category taxonomy (product) | **DOCUMENTED ONLY** / **UNKNOWN** freeze | doc | Registry S-SEC-*; P-7 language; not FS-007 L2 |
| 10 | Child-safety categorization API | **MISSING** | — | — |
| 11 | Risk score field | **MISSING** (runtime) | — | Schema severity on `ai_event` only |
| 12 | Confidence enum / pct on suggestions | **DOCUMENTED ONLY** (SQL) / **MOCK** (patterns UI) | mock | `ai_confidence`; hardcoded 72/85 |
| 13 | Confidence on safety classification result | **MISSING** | — | No result type |
| 14 | Classification provenance (local/cloud/model) | **MISSING** | — | — |
| 15 | Model version on result | **MISSING** | — | — |
| 16 | Safety policy version on result | **MISSING** | — | — |
| 17 | Local-only processing mode | **MOCK/SIMULATION** | mock | Smart Watch `offline` toggle |
| 18 | Zero-connectivity classify | **MISSING** | — | Nothing to run offline |
| 19 | Cloud-assisted classify when online | **MISSING** | — | No gateway for safety classify |
| 20 | Offline fallback UX honesty | **PARTIAL** (platform pattern) / **MISSING** for AI safety | doc | G-1 offline template exists elsewhere |
| 21 | Human review / parent confirmation of classify | **MISSING** (safety) / **PARTIAL** (Advisor approve) | mock | Advisor inbox ≠ safety review |
| 22 | AI suggestion state (pending/approved/rejected) | **MOCK/SIMULATION** | mock | `AiSuggestionDecision` |
| 23 | Explainability (why flagged) | **MISSING** | — | Fixture alert copy only |
| 24 | False-positive handling path | **MISSING** | — | — |
| 25 | False-negative handling path | **MISSING** | — | — |
| 26 | Unknown / uncertain classification state | **MISSING** | — | — |
| 27 | Confidence thresholds (product) | **MISSING** / **UNKNOWN** | — | Must not invent |
| 28 | AdvisorRepository gateway | **MOCK/SIMULATION** | mock | Prototype suggestions |
| 29 | InsightsRepository gateway | **MISSING** | — | Named in Rule 26 only |
| 30 | TutorRepository gateway (Rule 26) | **MISSING** | — | CHD-017 is separate mock |
| 31 | `AiSuggestion` no-execute sovereignty | **IMPLEMENTED** (type + tests) | — | Structural |
| 32 | Server AI stage flags | **MOCK/SIMULATION** | mock | `MockRemoteAiStageFlags` |
| 33 | Ban local inference unlock | **IMPLEMENTED** | — | Throws + symbol scan test |
| 34 | RulesEngine (deterministic father rules) | **PARTIAL** | heuristic | Outside AI gateways; ADR-038 |
| 35 | Smart Alerts FAT-065 tool toggles | **MOCK/SIMULATION** | mock | search/image/screenshot/offline |
| 36 | Screenshot app picker (P-7) | **MOCK** (proto) / **MISSING** Flutter | mock | FS-004 owns policy L2 |
| 37 | Child transparency card (full P-7 tools) | **PARTIAL** | — | CHD-010 / MonitoringFeature omit image/search |
| 38 | Parent notification on detection | **MISSING** (real pipeline) | mock | Fixture alerts planted |
| 39 | Snapshot save on detection | **MISSING** | — | P-7 documented |
| 40 | Audit events for safety classify | **MISSING** | — | `ai_event` SQL only |
| 41 | Audit for Advisor approve/reject | **MISSING** (append) | — | Decisions in memory map |
| 42 | Encrypted local cache of classifications | **MISSING** | — | — |
| 43 | Encrypted raw content store | **MISSING** | — | Must not invent retention |
| 44 | Model asset packaging | **MISSING** | — | No artifacts |
| 45 | Model integrity / signing | **MISSING** | — | — |
| 46 | Secure model update lifecycle | **MISSING** | — | — |
| 47 | Model update rollback | **MISSING** | — | — |
| 48 | Stale model representation | **MISSING** | — | — |
| 49 | Missing model / unsupported device state | **MISSING** | — | — |
| 50 | Device acknowledgement of model/policy version | **MISSING** | — | — |
| 51 | Multi-device sync of safety policy | **MISSING** | — | — |
| 52 | Outbox for classification results | **MISSING** | — | — |
| 53 | Identity abstraction before cloud | **DOCUMENTED ONLY** | doc | Rule 26 / Charter |
| 54 | Battery / thermal constraints for AI | **MISSING** | — | — |
| 55 | Storage budget for models | **MISSING** / **UNKNOWN** | — | — |
| 56 | Arabic RTL handling for OCR/UI | **PARTIAL** (app RTL) / **MISSING** (OCR) | — | App i18n only |
| 57 | Arabizi / dialect phrase detect | **MOCK/SIMULATION** | mock | Alert kind fixture |
| 58 | Emotion / sentiment detect | **MOCK/SIMULATION** | mock | Alert kind + registry |
| 59 | Sensitive image detect | **MOCK/SIMULATION** | mock | Alert kind; no model |
| 60 | Sexual-content message detect | **DOCUMENTED ONLY** | doc | Registry service |
| 61 | Web Filter host heuristic classify | **PARTIAL** | heuristic | `WebFilterEvaluator` — FS-002 |
| 62 | Custom WF keyword dictionary | **DOCUMENTED ONLY** (FS-002 L2) / **MISSING** Flutter | doc | Not FS-007 ownership |
| 63 | App category ML suggestion (FS-003) | **MISSING** | — | — |
| 64 | Capture input → classify (FS-004) | **MISSING** | — | No pipeline |
| 65 | Mode-config AI suggestion (FS-005) | **MISSING** | — | Advisor mocks unrelated |
| 66 | SOS AI triage / auto-escalate | **MISSING** (correct absence) / forbidden intent | — | SOS Final non-goal |
| 67 | Kernel typed safety-signal fact | **MISSING** | — | — |
| 68 | Silent policy mutation by AI | **MISSING** (good) | — | Approve path only for Advisor |
| 69 | Silent package block by AI | **MISSING** (good) | — | — |
| 70 | Silent URL list rewrite by AI | **MISSING** (good) | — | — |
| 71 | Auto-trigger SOS by AI | **MISSING** (good) | — | — |
| 72 | ML / OCR pubspec dependencies | **MISSING** | — | Confirmed absent |
| 73 | Background isolate for inference | **MISSING** | — | — |
| 74 | Feature flags for offline AI safety | **MISSING** (beyond stage flags) | — | Stages ≠ safety classifier |
| 75 | Parent review surface for safety hits | **MOCK** (Smart Alert detail) | mock | Scripted dialogue |
| 76 | Child-facing safety messaging | **PARTIAL** | — | Tutor transparency; not classify |
| 77 | PII stripping before cloud | **DOCUMENTED ONLY** | doc | Rule 26 identity abstraction |
| 78 | Data retention policy for raw captures | **UNKNOWN** / **MISSING** freeze | — | Q-AI |
| 79 | Adversarial / evasion robustness | **MISSING** | — | — |
| 80 | Deterministic classify where required | **UNKNOWN** | — | No engine |
| 81 | Test datasets / fixtures for safety AI | **MISSING** (real) / **MOCK** alerts | mock | — |
| 82 | Architecture tests forbidding inference symbols | **IMPLEMENTED** | — | Partial gate (not dep-name ban) |
| 83 | Schema `ai_suggestion` / `ai_event` | **DOCUMENTED ONLY** | doc | No Drift mirror |
| 84 | Competitive “image analysis” checklist | **DOCUMENTED ONLY** | doc | Platform foundation Bark ✅ |
| 85 | Deferred TFLite image bridge (N-09) | **DOCUMENTED ONLY** | doc-intent | P2 deferred |
| 86 | STAGE3-AI gateway backlog | **DOCUMENTED ONLY** | doc | Harness deferred |
| 87 | Mother AI feed (suggest→father) | **MOCK/SIMULATION** | mock | R-3 spirit |
| 88 | Dinner-question Advisor feature | **DOCUMENTED ONLY** | doc | Register amendment |
| 89 | Quantization / CPU profiling | **MISSING** | — | — |
| 90 | Cloud↔local result reconciliation | **MISSING** | — | — |

**Capability rows counted:** **90**

---

## Rollup

| Bucket | Count (approx) |
|---|---|
| IMPLEMENTED | 4 |
| PARTIAL | 8 |
| MOCK/SIMULATION | 18 |
| DOCUMENTED ONLY | 16 |
| MISSING | 40 |
| UNKNOWN | 4 |

**Real AI / OCR / on-device ML capability IMPLEMENTED:** **0**

**Heuristic (non-ML) related:** Web Filter host classifier (FS-002 ownership) — **PARTIAL**

---

## Reality distinction (mandatory)

| Kind | Present? |
|---|---|
| **Real AI capability** (inference, OCR engines, trained models) | **No** |
| **Heuristic / mock classification** | Yes — WF host tokens; Smart Alerts fixtures; Advisor strings; hardcoded confidence % |
| **Documented future intent** | Yes — P-7, Charter, schema, TFLite P2, FS-002 dictionary, registry S-SEC-* |
