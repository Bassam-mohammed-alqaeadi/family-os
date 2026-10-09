# 03 — Rule 26 Narrow Amendment (Policy Documentation Only)

**System:** FS-007 — Offline AI Safety  
**Authority:** **AI-OD-01** (Q-AI-01 = B) — Owner freeze 2026-09-24  
**Mode:** **POLICY DOCUMENTATION ONLY**  
**Implementation:** **NOT AUTHORIZED** this tick — do not edit production constitution files, Policy Register body, architecture tests, or app code until a later Owner-authorized engineering card.

```
FS-007 DISCOVERY: COMPLETE
FS-007 L2 POLICY: IN PROGRESS — Q-AI-06 OPEN
FS-007 L3: NOT STARTED
IMPLEMENTATION: NOT AUTHORIZED
```

---

## 1. Purpose

Record the **minimum constitutional amendment** to Rule 26 required by **AI-OD-01**, and the **corresponding architecture-test policy change**, so engineering can apply them later without re-litigating product law.

---

## 2. Current Rule 26 text (evidence — pre-amendment)

Source: `handoff/04_POLICY_REGISTER_EN.md` (RULE 26) · mirrored in `.cursor/rules/constitution.mdc` Rule 26.

**Binding gist today (pre-implementation):**

> No inference runs inside the app. All AI features flow through exactly three repository gateways — `AdvisorRepository`, `InsightsRepository`, `TutorRepository` … Sovereignty: `AiSuggestion` has no `execute()` …

Stage-1 code enforces this via:

- `AiStageFlagsRepository.setLocalEnableInference` → **always throws**
- `app/test/core/policy/ai_stage_flags_repository_test.dart` symbol scan forbidding `OnDeviceInference` / `runLocalModel` / `LocalInferenceService` / `enableOnDeviceBrain`

---

## 3. Minimum Rule 26 amendment (target wording — not applied yet)

### 3.1 Keep unchanged

| Clause | Remains |
|---|---|
| Three gateways for Advisor / Insights / Tutor product AI | Unchanged |
| Stages as **server-side feature flags** for those gateways | Unchanged |
| `AiSuggestion` has **no `execute()`** — only `approve()` / `reject()` under FatherSession / Primary session | Unchanged |
| Socratic refusal; licensed Quran; child↔tutor transparency | Unchanged |
| Identity abstraction before events leave device (when egress exists) | Unchanged |
| AI never autonomously mutates policy / SOS / packages / URL lists / Modes | Unchanged (**AI-SF-04…11**) |

### 3.2 Replace / insert (minimum)

**Replace** the absolute sentence:

> No inference runs inside the app.

**With** (minimum target law):

> **No general-purpose inference runs inside the app.** Advisor, Insights, and Tutor intelligence remain gateway-bound (mock now / AI Gateway later) with **no** client-side stage unlock that enables on-device brain inference.  
> **Exception (FS-007 only):** Signed and versioned **on-device ML and/or OCR** may run **solely** to produce **Offline AI Safety classification signals** (typed facts with confidence and provenance). Such inference must not execute policy, mutate package/URL/Mode stores, trigger or escalate SOS, or serve as a general Advisor/Tutor/Insights substitute. Unsigned or unversioned models must not execute.

### 3.3 Optional clarifying sentence (recommended, still documentation)

> Deterministic heuristics/rules used for safety classification are permitted and are not a Rule 26 violation; they remain signals only under the same sovereignty constraints.

---

## 4. Corresponding architecture-test change (policy only — not implemented)

| Current test behavior | Target policy after authorized engineering |
|---|---|
| Ban **all** symbols: `OnDeviceInference`, `runLocalModel`, `LocalInferenceService`, `enableOnDeviceBrain` across `lib/` | **Retarget:** keep ban on **gateway / brain unlock** symbols and on **unscoped** local inference helpers outside an FS-007 allowlist |
| `setLocalEnableInference` always throws | **Keep** — still forbids client unlock of Advisor/Insights/Tutor stages |
| No positive test for signed FS-007 classify path | **Add later** (when implementation authorized): allow only a **named FS-007 safety-classify seam** that requires model **signature + version** checks; reject unsigned/unversioned execution |
| No dependency-name ban | **Optional later:** fail CI if ML/OCR packages appear **without** an authorized FS-007 implementation card / allowlist comment — **not** mandated in this doc |

**Explicit non-goals of the test retarget:**

- Do not allow general `runLocalModel` for Advisor chat  
- Do not remove sovereignty tests (`AiSuggestion` no `execute()`)  
- Do not select TFLite / ONNX / ML Kit / any runtime in tests  

---

## 5. Files that must be updated in a future authorized engineering card

| File | Change type |
|---|---|
| `handoff/04_POLICY_REGISTER_EN.md` | RULE 26 amendment text + log pointer to AI-OD-01 |
| `handoff/02_DECISION_LOG.md` (or Owner decision log convention) | Record AI-OD-01 / Rule 26 narrow amendment |
| `.cursor/rules/constitution.mdc` Rule 26 | Mirror amendment (requires Owner-authorized rules edit) |
| `app/test/core/policy/ai_stage_flags_repository_test.dart` | Retarget symbol ban + keep unlock throw |
| Future FS-007 domain seam (not created now) | Signed/versioned classify API |

**This tick:** **none** of the above are modified.

---

## 6. What “signed/versioned” means as product law (not mechanism)

| Requirement | Product meaning | Not decided here |
|---|---|---|
| **Versioned** | Every executable safety model/OCR asset carries an explicit version id surfaced in classification provenance | Packaging format, semver scheme |
| **Signed** | Device refuses to run assets that fail integrity verification against family/platform trust | Algorithm, key hierarchy, update channel (→ Q-AI-11 / T-AI-10/11) |
| **Provenance** | Each signal records model/OCR version (+ policy version when defined) | Schema shape |

---

## 7. Gate

```
RULE 26 NARROW AMENDMENT: DOCUMENTED (AI-OD-01)
RULE 26 TEXT IN REGISTER / CONSTITUTION: NOT YET EDITED
ARCHITECTURE TESTS: NOT YET RETARGETED
IMPLEMENTATION: NOT AUTHORIZED
```
