# 07 — Q-AI-05 Parent Visibility of Raw Content (FROZEN)

**System:** FS-007 — Offline AI Safety  
**Question:** Q-AI-05  
**Status:** **CLOSED** — 2026-09-24  
**Maps to:** **AI-OD-05 = B**  
**Register:** [01_FS007_L2_OWNER_DECISIONS.md](01_FS007_L2_OWNER_DECISIONS.md)  
**Next:** [08_FS007_Q_AI_06_CHILD_TRANSPARENCY_DEPTH.md](08_FS007_Q_AI_06_CHILD_TRANSPARENCY_DEPTH.md)

```
FS-007 DISCOVERY: COMPLETE
FS-007 L2 POLICY: IN PROGRESS — Q-AI-06 OPEN
FS-007 L3: NOT STARTED
IMPLEMENTATION: NOT AUTHORIZED
```

---

## Owner freeze

**Choice: B — Redacted preview + classification metadata**

### Binding visibility rule (AI-OD-05)

Authorized reviewers may see:

- safety **category**;
- **severity/confidence** and other **approved classification metadata**;
- **provenance / model / policy version** metadata when available;
- a **redacted preview** of the relevant content **where a preview is available and permitted**.

**Raw full text/image is not exposed by default.**

### Important boundaries

| Rule |
|---|
| Signal metadata ≠ raw child content |
| **AI-OD-04** = who may access the review surface |
| **Q-AI-12** = retention/deletion semantics |
| Do not invent redaction algorithms, OCR details, retention periods, or storage mechanisms |
| Do not imply every input must produce a viewable preview |
| Unsupported/unavailable preview → **honest state**; never fabricate content |
| Preserve AI-SF-01…21 and AI-OD-01…04 |
| No implementation or technical mechanism selection |

### Options not chosen

| Option | Status |
|---|---|
| A — Category + confidence only | **Rejected** |
| C — Full raw text/image | **Rejected** |
| D — Configurable visibility | **Rejected** |
| E — Other | **Rejected** |

### Note on text vs image preview

Owner did not split text/image; freeze applies to **relevant content** of either modality **when a permitted preview exists**. Unavailable preview is honest empty/unsupported — not a silent full-raw fallback.

---

```
Q-AI-05 STATUS: CLOSED — AI-OD-05 = B
```
