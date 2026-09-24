# 06 — FS-007 OCR, Dictionary, and Language Discovery

**Mode:** Evidence only — **no** OCR vendor or dictionary content selection.  
**Master:** [13_FS007_DISCOVERY_CLOSURE_REPORT.md](13_FS007_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. OCR / text extraction

| Item | Class | Evidence |
|---|---|---|
| OCR library in `pubspec.yaml` | **MISSING** | No mlkit / tesseract / vision packages |
| Native OCR plugin | **MISSING** | — |
| OCR quality / RTL handling | **MISSING** | — |
| OCR uncertainty field | **MISSING** | — |
| Documented OCR requirement | **DOCUMENTED ONLY** (indirect) | P-7 image→report implies some text/image path; not named “OCR” in Register |

**T-AI-02** — Arabic OCR feasibility / quality.  
**T-AI-03** — OCR uncertainty representation.

---

## 2. Safety dictionaries / keyword detection

| Item | Class | Owner hint | Evidence |
|---|---|---|---|
| Prototype `webFilter.dict` (قمار، رهان، مواعدة) | **MOCK/SIMULATION** | FS-002 | HTML only |
| FS-002 L2 custom keyword dictionary | **DOCUMENTED ONLY** | **FS-002** | WF-OD-08 |
| Flutter `WebFilterPolicy` dict field | **MISSING** | FS-002 | AllowList only today |
| `WebFilterEvaluator.classifyHost` | **PARTIAL** | FS-002 | English-ish host tokens (`adult`, `gambling`…) — **heuristic** |
| Smart Alerts “suspicious words” / arabizi | **MOCK/SIMULATION** | Presentation | Fixture kinds; no dictionary engine |
| Dedicated FS-007 safety lexicon store | **MISSING** | OPEN | — |

**Boundary:** FS-002 owns **URL/keyword filter lists**. FS-007 must not silently become a second competing dictionary that rewrites WF policy. Possible futures (Owner L2): FS-007 emits **signals** that parents may approve into FS-002 lists — not auto-merge.

---

## 3. Arabic + English classification

| Item | Class | Evidence |
|---|---|---|
| App UI ARB AR+EN | **IMPLEMENTED** | Product i18n |
| Bilingual safety classifier | **MISSING** | — |
| Arabizi detection | **MOCK** | Alert kind `arabiziPhrase` |
| Dialect coverage | **UNKNOWN** | No dataset |
| RTL OCR / bidirectional text | **MISSING** | — |

**T-AI-04** — AR+EN (+ arabizi) classification approach feasibility (without selecting models).

---

## 4. Image / text safety signals (labels only today)

| Label in repo | Real detector? |
|---|---|
| `SmartAlertKind.sensitiveImage` | **No** — enum + fixture |
| `SmartAlertKind.emotion` | **No** |
| `SmartAlertKind.withdrawal` | **No** — behavioral fixture |
| Registry S-SEC image/sexual/sentiment services | **DOCUMENTED ONLY** |

---

## 5. Language handling for parents/children

| Surface | Status |
|---|---|
| Parent alert copy AR+EN | ARB keys for Smart Alerts |
| Child transparency for classify tools | **PARTIAL/MISSING** vs P-7 |
| Explainability in Arabic | **MISSING** (no real hits) |

---

## 6. Open questions

- **Q-AI-07** — Which harmful categories are in v1 (do not invent list here).  
- **T-AI-02…05** — OCR, bilingual, dictionary packaging, test corpora.
