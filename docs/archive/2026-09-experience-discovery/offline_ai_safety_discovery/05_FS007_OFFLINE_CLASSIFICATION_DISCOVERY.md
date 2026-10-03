# 05 — FS-007 Offline Classification Discovery

**Mode:** Evidence of offline / hybrid classification surface — **no** mechanism selection.  
**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Target questions (audit, not answers)

What remains available with **zero connectivity**?  
What local inputs are required?  
What local model/assets are required?  
What is queued? What syncs? What must never leave the device?  
How are stale model/policy, model versions, failed updates, and local↔cloud reconciliation represented?

---

## 2. Current zero-connectivity reality

| Capability | Offline today? | Evidence |
|---|---|---|
| Smart Watch tool toggles | In-memory prefs only (same process) | `InMemorySmartAlertsRepository` |
| Actual search/image classify | **No engine** | — |
| Advisor suggestions | Mock local strings (always “available”) | Not real offline AI |
| Stage flags cache | Memory cache of mock server flags | Not a safety model |
| Web Filter decide | Heuristic in-process | FS-002 — not FS-007 ML |

**Verdict:** With airplane mode, the app can show **mock UI** claiming offline analysis — it cannot perform FS-007 classification because **no classifier exists**.

---

## 3. Documented intent (not implemented)

| Source | Claim |
|---|---|
| Prototype `smartWatch.offline` | Offline analysis enabled |
| ARB offline tool subtitle | Local analysis then sync when online |
| AI Core Charter | Stages 1–2 on device (Stage 1 = rules, not LLMs) |
| P-7 | Image classification + search analysis |
| Readiness N-09 | TFLite image analysis deferred P2 |
| RULE 26 | **No inference in the app** → tension |

---

## 4. Input surface candidates (discovered, not authorized)

| Input | Adjacent owner | FS-007 role (hypothesis) |
|---|---|---|
| Search / typed text | Apps / keyboard / notification listen | Classify text signal |
| Images in gallery / chats | Media share / capture | Classify image signal |
| Screenshots on app open | **FS-004** monitoring | Consume **approved** capture inputs only |
| OCR text from images | Future OCR | Text path after extraction |
| URLs / hosts | **FS-002** | Suggest category — not rewrite lists |
| App metadata | **FS-003** | Suggest category — not block packages |

**Anti-surveillance:** FS-004 L2 forbids silent full-device capture; any FS-007 consumption of captures must respect transparency and configured scope (**Q-AI** + FS-004 contracts).

---

## 5. Output surface (missing type)

No Dart type found for e.g.:

`SafetyClassification { category, severity?, confidence, provenance, modelVersion, policyVersion, inputRef, uncertain }`

Schema has `ai_event` / `ai_suggestion` for Advisor-shaped rows — **not** a dedicated offline safety classification table.

---

## 6. Local vs cloud reconciliation

| Topic | Status |
|---|---|
| Local result usable offline | **MISSING** engine |
| Queue raw content for cloud | **MISSING** — and privacy-sensitive (**Q-AI-10/12**) |
| Queue signal-only for sync | **MISSING** |
| Prefer local vs cloud when both exist | **MISSING** / **UNKNOWN** |
| Honest “not classified yet” state | **MISSING** |

---

## 7. Degraded / unsupported states (required by honesty law)

Sibling packs (FS-002/003/004) require honesty when planes unavailable. For FS-007, the following states are **not implemented** and must be designed in L2/L3 without inventing thresholds now:

| State | Present? |
|---|---|
| Missing model | **MISSING** |
| Unsupported device / ABI | **MISSING** |
| Stale model | **MISSING** |
| Language mismatch | **MISSING** |
| OCR uncertainty | **MISSING** |
| Low confidence / unknown | **MISSING** |
| Battery saver / thermal throttle | **MISSING** |
| Storage full | **MISSING** |

---

## 8. Quality / safety discovery checklist

| Provision | Status |
|---|---|
| False positives path | **MISSING** |
| False negatives path | **MISSING** |
| Uncertain / unknown | **MISSING** |
| Confidence thresholds | **UNKNOWN** (do not invent) |
| Human review | **MISSING** for safety hits |
| Explainability | **MISSING** |
| Model version mismatch | **MISSING** |
| Repeated classification / determinism | **UNKNOWN** |
| Adversarial / malformed inputs | **MISSING** |
| Arabic + English | **MISSING** classifier |

---

## 9. Technical questions

See **T-AI-01…20** in doc 12 — feasibility of local inference, cloud fallback, workers, calibration, etc. **No mechanisms selected.**
