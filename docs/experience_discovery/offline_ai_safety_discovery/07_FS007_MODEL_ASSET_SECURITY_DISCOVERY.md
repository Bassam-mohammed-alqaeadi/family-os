# 07 — FS-007 Model, Asset, and Security Discovery

**Mode:** Evidence of model/asset lifecycle — **no** vendor or runtime selection.  
**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Current model/asset reality

| Item | Class |
|---|---|
| Bundled neural model files | **MISSING** |
| Embedding tables / vocab packs | **MISSING** |
| OCR language packs | **MISSING** |
| Signed model manifest | **MISSING** |
| Model version field in app | **MISSING** |
| Update channel for models | **MISSING** |
| Integrity verification (hash/signature) | **MISSING** |
| Secure storage for models | **MISSING** |
| Rollback of failed update | **MISSING** |

**Documented future:** Readiness N-09 names **TFLite image analysis** as **P2 deferred** — evidence of intent, **not** selection of TFLite as product law.

---

## 2. Rule 26 interaction

Architecture tests **forbid** symbols: `OnDeviceInference`, `runLocalModel`, `LocalInferenceService`, `enableOnDeviceBrain`.  
`setLocalEnableInference` **throws**.

If Owner later authorizes on-device ML for FS-007 (**Q-AI-01**), constitutional/test gates must be **explicitly amended** — Discovery does not amend them.

Charter Stage 1 “on device” historically meant **rules engine, no LLMs** — may reconcile with Rule 26 for **heuristics**, not for CNN/LLM weights.

---

## 3. Update lifecycle (missing design)

| Step | Status |
|---|---|
| Discover available model version | **MISSING** |
| Download over privacy-preserving transport | **MISSING** |
| Verify signature / hash | **MISSING** |
| Stage → activate | **MISSING** |
| Device ack of active version | **MISSING** |
| Failed update recovery | **MISSING** |
| Stale-model UI honesty | **MISSING** |

**Q-AI-11** — Who authorizes model updates (Owner only? automatic signed channel?).  
**T-AI-06…11** — packaging, size, signing, secure update, rollback, Android/iOS support.

---

## 4. Security boundaries (discovery)

| Boundary | Evidence |
|---|---|
| Child cannot enable inference unlock | **IMPLEMENTED** throw (stage flags) |
| Child cannot load arbitrary models | N/A (no loader) |
| Tamper with model files | No assets to tamper; anti-tamper P-6 is separate |
| Adversarial evasion of classifiers | **MISSING** provisions |
| Supply-chain of model binaries | **MISSING** |

---

## 5. Runtime / workers (not selected)

| Topic | Status |
|---|---|
| Inference runtime choice | **OPEN** (T-AI) — do not select |
| Background isolate / WorkManager | **MISSING** |
| Battery / thermal budget | **MISSING** |
| Quantization | **MISSING** |
| Device compatibility matrix | **UNKNOWN** |

---

## 6. Feature flags

| Flag plane | Relation to FS-007 |
|---|---|
| `AiStageId` analyze/suggest/coach | Advisor charter stages — **not** offline safety classifier flags |
| Smart Watch tool toggles | Presentation mocks — **not** model gates |
| Dedicated offline-AI-safety flag | **MISSING** |
