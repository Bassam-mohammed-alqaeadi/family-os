# 02 — FS-007 Current Repo Evidence

**Mode:** Evidence-only map of symbols, screens, docs, and prototypes.  
**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Policy Register (supreme text — AI / monitoring)

Source: `handoff/04_POLICY_REGISTER_EN.md`

| Ruling | Binding gist | Code impact named |
|---|---|---|
| **P-7** | Smart monitoring **with child knowledge**: search analysis / image classification / screenshots; father switches + app picker; on detection save snapshot & report; **permanent transparency card** | No silent surveillance |
| **P-8** | Web filter levels + banned-words dictionary + lists (adjacent, not FS-007 alone) | `WebFilterPolicy` |
| **§7 A-1…A-7** | Family Advisor FAB; Socratic tutor; tutor log + transparency; licensed Quran; RulesEngine; anonymous peer compare; vetted stories | Advisor / Tutor / RulesEngine |
| **RULE 26** | **No inference in the app**; three gateways; EventBus hooks; stages = server flags; `AiSuggestion` approve/reject only | Architecture ban |
| **RULE 7** (constitution) | AI suggests, never executes | Parent-approval button |

---

## 2. Flutter AI / Advisor spine (not offline classifiers)

| Path | Role | Class |
|---|---|---|
| `app/lib/core/policy/advisor_repository.dart` | `AiSuggestion` + `AdvisorRepository` + `MockAdvisorRepository` prototype strings | **MOCK/SIMULATION** |
| `app/lib/core/policy/ai_suggestion_repository.dart` | Inbox approve/reject → RulesEngine | **MOCK/SIMULATION** |
| `app/lib/core/policy/ai_stage_id.dart` | analyze / suggest / coach enum | **IMPLEMENTED** (keys) |
| `app/lib/core/policy/ai_stage_flags.dart` | Enable map | **IMPLEMENTED** |
| `app/lib/core/policy/ai_stage_flags_repository.dart` | Mock remote flags; `setLocalEnableInference` **always throws** | **MOCK** + **IMPLEMENTED ban** |
| `app/lib/core/policy/rules_engine_rule*.dart` | Father if/then outside AI gateways | **PARTIAL** / in-memory |
| `app/lib/core/policy/advisor_memory_store.dart` | Advisor forget memory | **MOCK/SIMULATION** |
| `InsightsRepository` type | Named in Rule 26 / tests | **MISSING** in `app/lib` |
| `TutorRepository` (Rule 26 gateway) | Named in Rule 26 / tests | **MISSING** in `app/lib` |
| `features/n17_child_learn/child_tutor_*` | Scripted Socratic UI (`ChildTutorRepository`) | **MOCK/SIMULATION** — not Rule-26 gateway |

**`AiSuggestion` fields today:** `id`, `title`, `body`, `stage`, `proposedConsequentIds`.  
**Absent vs schema:** `confidence`, `confidence_pct`, model version, provenance, safety category.

---

## 3. Smart Alerts / Smart Watch (P-7 presentation surface)

| Path | Role | Class |
|---|---|---|
| `features/n08_platform/smart_alerts_models.dart` | Alert kinds + tool rows (`searchScan`, `imageScan`, `screenshot`, `offline`) | **MOCK/SIMULATION** |
| `features/n08_platform/smart_alerts_repository.dart` | In-memory toggles; **no classifier runs** | **MOCK/SIMULATION** |
| `features/n08_platform/smart_alerts_screen.dart` | FAT-065 UI | **PARTIAL** (UI loop only) |
| `features/n08_platform/smart_alert_detail_*` | Detail fixtures | **MOCK/SIMULATION** |
| `core/policy/monitoring_feature.dart` | webFilter / appLimits / notificationListen / locationAlways — **omits** search/image/screenshot | **PARTIAL** |
| `features/n08_platform/effective_monitoring_transparency.dart` | Child effective≠desired honesty for `MonitoringFeature` | **PARTIAL** — no P-7 image/search tools |
| ARB `smartAlertsToolImageScan` | “On-device image classification” / «تصنيف الصور على الجهاز» | **DOCUMENTED in UI copy** — overclaims vs impl |

---

## 4. Heuristic classification (adjacent, not ML)

| Path | Role | Class |
|---|---|---|
| `core/policy/web_filter_evaluator.dart` | Host token → category fixture (`classifyHost`) | **PARTIAL** — **heuristic**, not ML |
| `core/policy/web_filter_policy.dart` | Level + categories + allowList | **PARTIAL** — **no** parent dictionary field in Flutter model |
| FS-002 L2 keyword dictionary | First-class Allow/Block/Custom dict | **DOCUMENTED ONLY** (FS-002 owns lists) |

---

## 5. Advisor feature folder (`n07_advisor`) — Stage-1 mocks

All listed surfaces are **MOCK/SIMULATION** repositories + screens (patterns with hardcoded `confidencePercent`, voice, weekly report, knowledge maps, mother AI feed, peer compare, moments, agent action log, brain control, suggestions inbox). None run models.

Architecture tests:

| Test | Covers |
|---|---|
| `app/test/core/policy/ai_stage_flags_repository_test.dart` | Symbol ban: `OnDeviceInference` / `runLocalModel` / `LocalInferenceService`; local unlock throws |
| `app/test/core/policy/ai_suggestion_repository_test.dart` | No `execute()`; RulesEngine outside gateways |
| `app/test/features/n07_advisor/*` | Widget/unit for advisor screens |
| `app/test/features/n08_platform/smart_alerts_screen_test.dart` | Toggle UI |
| `app/test/features/n08_platform/ui_018_platform_honesty_test.dart` | Platform monitoring transparency |

**No test** asserts OCR accuracy, TFLite load, or live classification.

---

## 6. Dependencies / assets

| Asset | Finding |
|---|---|
| `app/pubspec.yaml` | Flutter + intl + go_router + icons + lints — **no** tflite / onnx / mlkit / OCR |
| Bundled `.tflite` / `.onnx` / embedding files under `app/` | **MISSING** |
| Isolates / background inference workers for safety | **MISSING** |

---

## 7. Prototype evidence (frozen HTML)

Source: `prototype/family_os_app.html` / `family-os/family_os_app.html` — `S.smartWatch`.

| Field | Prototype behavior |
|---|---|
| `searchScan` / `imageScan` / `screenshot` / `offline` | Boolean toggles |
| `screenshotApps` | App picker sheet (prototype only) |
| Copy | Local classify / offline analysis language («يصنف محليًا») |
| Alerts | Fixture rows (withdrawal, arabizi, etc.) — **planted**, not emitted by a classifier |

---

## 8. Schema / contracts

| Asset | Finding |
|---|---|
| `family-os/_CONTRACTS/schema.sql` | `ai_confidence` enum; `ai_event`; `ai_suggestion` with confidence + confidence_pct; payload note “excerpt not archive” |
| Flutter Drift tables for offline safety classifications | **MISSING** |
| Registry services S-SEC-032…036 | Suspicious words, sentiment, arabizi, sensitive images — **DOCUMENTED ONLY** (“موجودة” ≠ Flutter reality) |

---

## 9. Charter / readiness / project-plan

| Asset | Finding |
|---|---|
| `family-os/08_AI_CORE_CHARTER.md` | Five stages; hybrid on-device 1–2; seven boundaries; child general notice | **DOCUMENTED ONLY** — tensions with Rule 26 |
| `family-os/00_READINESS_BRIEF.md` N-09 | TFLite image analysis = **P2 deferred** | **DOCUMENTED ONLY** |
| `docs/project-plan/*` | Rule 26 gateways; ADR-038 AiSuggestion vs RulesEngine; SET-014/022/023 closed | **DOCUMENTED** + partially coded |
| `harness/BACKLOG.md` STAGE3-AI | Deferred Advisor/Insights/Tutor gateway work | **DOCUMENTED ONLY** |
| Prior `offline_ai_safety_discovery/` | **Did not exist** before this pack | **MISSING** → now created |

---

## 10. Sibling pack references to FS-007 / AI

| Pack | Finding |
|---|---|
| FS-002 discovery map | **Only explicit “FS-007 Offline AI” label** — “no coupling found” |
| FS-004 L2 | Owns P-7 **screenshot monitoring** policy; Smart Alerts presentation-only |
| FS-003 / FS-005 | No FS-007 coupling |
| FS-006 / SOS Final | AI must not own SOS; “On-device AI triage of SOS” listed as non-goal in SOS product contract |
| Platform overview | Advisor mocks; **no on-device inference** |

---

## 11. What is simulated vs real (summary)

| Claim often heard | Evidence truth |
|---|---|
| “On-device image classification” | **ARB + prototype copy** — **no** classifier code |
| “Offline local analysis” | Smart Watch `offline` **toggle mock only** |
| “AI suggestions protect the family” | Mock strings + parent approve→RulesEngine **in memory** |
| “No on-device inference” | **Enforced** by Rule 26 + architecture tests + unlock throw |
| “InsightsRepository / TutorRepository ready” | **Types missing**; CHD-017 is a separate mock tutor |
| “Schema has AI confidence” | SQL yes; Dart `AiSuggestion` **no** |
| “Keyword safety dictionary” | Prototype / FS-002 L2 intent; Flutter evaluator = host heuristic only |
| “TFLite bridge” | Readiness **deferred P2** — not shipped |
